defmodule Devhub.Integrations.Kubernetes.Client do
  @moduledoc false
  use Tesla

  alias Tesla.Middleware.BearerAuth
  alias Tesla.Middleware.JSON
  alias Tesla.Middleware.SSE

  require Logger

  def client(token, middleware \\ []) do
    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl,
         (Devhub.prod?() && "https://kubernetes.default.svc.cluster.local") || "https://127.0.0.1:62667"},
        {BearerAuth, token: token},
        {JSON, decode_content_types: ["text/event-stream"]}
        | middleware
      ],
      {Tesla.Adapter.Finch, name: Devhub.Finch.K8s}
    )
  end

  def get_token do
    namespace = Application.get_env(:devhub, :namespace)

    token =
      case Application.get_env(:devhub, :compile_env) do
        :dev ->
          {token, 0} =
            System.cmd("kubectl", ["create", "token", "devhub", "-n", "devhub", "--context", "docker-desktop"], env: [])

          token

        :test ->
          "k8s-token"

        :prod ->
          File.read!("/var/run/secrets/kubernetes.io/serviceaccount/token")
      end

    token
    |> client()
    |> Tesla.post("/api/v1/namespaces/#{namespace}/serviceaccounts/devhub/token", %{})
  end

  @spec get_log(String.t(), String.t()) :: Tesla.Env.result() | {:error, :failed_to_get_log}
  def get_log(pod, container) do
    namespace = Application.get_env(:devhub, :namespace)

    with :ok <- wait_for_container(pod, container),
         {:ok, %{body: %{"status" => %{"token" => token}}}} <- get_token(),
         {:ok, %{status: status}} = result when status in [200, 204] <-
           token
           |> client([{SSE, only: :data}])
           |> Tesla.get(
             "/api/v1/namespaces/#{namespace}/pods/#{pod}/log?follow=true&container=#{container}",
             opts: [adapter: [response: :stream, receive_timeout: to_timeout(hour: 4)]]
           ) do
      result
    else
      error ->
        Logger.error("Failed to get log for pod: #{pod}, container: #{container}, error: #{inspect(error)}")
        {:error, :failed_to_get_log}
    end
  end

  @spec create_job(map()) :: :ok | :error
  def create_job(job_spec) do
    namespace = Application.get_env(:devhub, :namespace)

    with {:ok, %{body: %{"status" => %{"token" => token}}}} <- get_token(),
         {:ok, %{status: 201}} <- Tesla.post(client(token), "/apis/batch/v1/namespaces/#{namespace}/jobs", job_spec) do
      :ok
    else
      error ->
        Logger.error("Failed to create job: #{inspect(error)}")
        :error
    end
  end

  @spec delete_job(String.t()) :: :ok | :error
  def delete_job(job_name) do
    namespace = Application.get_env(:devhub, :namespace)

    with {:ok, %{body: %{"status" => %{"token" => token}}}} <- get_token(),
         {:ok, %{status: 200}} <-
           Tesla.delete(client(token), "/apis/batch/v1/namespaces/#{namespace}/jobs/#{job_name}") do
      :ok
    else
      {:ok, %{status: 404}} ->
        :ok

      {:ok, %{status: status, body: body}} ->
        Logger.error("Failed to delete job with status #{status}: #{inspect(body)}")
        :error
    end
  end

  @spec find_pod_for_job(String.t()) :: {:ok, map()}
  def find_pod_for_job(job_name) do
    {:ok, %{body: %{"status" => %{"token" => token}}}} = get_token()
    namespace = Application.get_env(:devhub, :namespace)

    token
    |> client()
    |> Tesla.get("/api/v1/namespaces/#{namespace}/pods?labelSelector=job-name=#{job_name}")
    |> case do
      {:ok, %{body: %{"items" => pods}}} when pods != [] ->
        pod = pods |> Enum.sort_by(& &1["metadata"]["creationTimestamp"], :desc) |> List.first()
        {:ok, pod}

      _not_found ->
        if !Devhub.test?(), do: :timer.sleep(1000)
        find_pod_for_job(job_name)
    end
  end

  @spec get_finished_job_status(String.t()) :: {:ok, String.t()}
  def get_finished_job_status(pod) do
    {:ok, %{body: %{"status" => %{"token" => token}}}} = get_token()
    namespace = Application.get_env(:devhub, :namespace)

    token
    |> client()
    |> Tesla.get("/api/v1/namespaces/#{namespace}/pods/#{pod}")
    |> case do
      {:ok, %{body: %{"status" => %{"phase" => phase}}}} when phase in ["Pending", "Running"] ->
        if !Devhub.test?(), do: :timer.sleep(500)
        get_finished_job_status(pod)

      {:ok, %{body: %{"status" => %{"phase" => phase}}}} ->
        {:ok, phase}
    end
  end

  @spec create_or_update_secret(String.t(), list({String.t(), binary()})) :: :ok
  def create_or_update_secret(secret_name, data) do
    {:ok, %{body: %{"status" => %{"token" => token}}}} = get_token()
    namespace = Application.get_env(:devhub, :namespace)

    body = %{
      "apiVersion" => "v1",
      "kind" => "Secret",
      "metadata" => %{
        "name" => secret_name,
        "namespace" => namespace
      },
      "data" => Map.new(data, fn {k, v} -> {k, Base.encode64(v)} end)
    }

    case Tesla.put(client(token), "/api/v1/namespaces/#{namespace}/secrets/#{secret_name}", body) do
      {:ok, %{status: 404}} ->
        {:ok, %{status: 201}} =
          Tesla.post(client(token), "/api/v1/namespaces/#{namespace}/secrets", body)

        :ok

      {:ok, %{status: 200}} ->
        :ok
    end
  end

  @spec delete_secret(String.t()) :: Tesla.Env.result()
  def delete_secret(secret_name) do
    namespace = Application.get_env(:devhub, :namespace)
    {:ok, %{body: %{"status" => %{"token" => token}}}} = get_token()
    Tesla.delete(client(token), "/api/v1/namespaces/#{namespace}/secrets/#{secret_name}")
  end

  defp wait_for_container(pod, container, attempts \\ 60)

  defp wait_for_container(pod, container, attempts) do
    {:ok, %{body: %{"status" => %{"token" => token}}}} = get_token()
    namespace = Application.get_env(:devhub, :namespace)

    token
    |> client()
    |> Tesla.get("/api/v1/namespaces/#{namespace}/pods/#{pod}")
    |> case do
      {:ok, %{body: %{"status" => %{"phase" => phase} = status}}} when phase in ["Pending", "Running"] ->
        containers = Map.get(status, "containerStatuses", []) ++ Map.get(status, "initContainerStatuses", [])
        container_status = Enum.find(containers, &(&1["name"] == container))
        running? = not is_nil(container_status["state"]["running"])
        terminated? = not is_nil(container_status["state"]["terminated"])

        if running? or terminated? do
          :ok
        else
          if !Devhub.test?(), do: :timer.sleep(2000)
          wait_for_container(pod, container, attempts - 1)
        end

      {:ok, %{body: %{"status" => %{"phase" => "Failed"} = status}}} ->
        containers = status["containerStatuses"] ++ status["initContainerStatuses"]
        container_status = Enum.find(containers, &(&1["name"] == container))
        terminated? = not is_nil(container_status["state"]["terminated"])

        if terminated? do
          :ok
        else
          {:error, :container_did_not_run}
        end

      {:ok, %{body: %{"status" => %{"phase" => "Succeeded"}}}} ->
        :ok
    end
  end
end
