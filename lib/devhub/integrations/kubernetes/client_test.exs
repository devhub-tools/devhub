defmodule Devhub.Integrations.Kubernetes.ClientTest do
  use Devhub.DataCase, async: true

  alias Devhub.Finch.K8s
  alias Devhub.Integrations.Kubernetes.Client
  alias Tesla.Adapter.Finch
  alias Tesla.Middleware.BaseUrl
  alias Tesla.Middleware.BearerAuth
  alias Tesla.Middleware.JSON
  alias Tesla.Middleware.SSE

  describe "get_log/2" do
    test "success" do
      Finch
      |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
        assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/serviceaccounts/devhub/token"
        TeslaHelper.response(body: %{"status" => %{"token" => "k8s-token"}})
      end)
      |> expect(:call, fn %Tesla.Env{
                            method: :get,
                            url: url,
                            headers: [{"authorization", "Bearer k8s-token"}]
                          },
                          [name: K8s] ->
        assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/pods/pod-name"

        # wait for container to start
        TeslaHelper.response(
          body: %{
            "status" => %{
              "phase" => "Running",
              "containerStatuses" => [
                %{"name" => "plan", "state" => %{}}
              ]
            }
          }
        )
      end)
      |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
        assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/serviceaccounts/devhub/token"
        TeslaHelper.response(body: %{"status" => %{"token" => "k8s-token"}})
      end)
      |> expect(:call, fn %Tesla.Env{
                            method: :get,
                            url: url,
                            headers: [{"authorization", "Bearer k8s-token"}]
                          },
                          [name: K8s] ->
        assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/pods/pod-name"

        # container started
        TeslaHelper.response(
          body: %{
            "status" => %{
              "phase" => "Running",
              "containerStatuses" => [
                %{"name" => "plan", "state" => %{"running" => %{"startedAt" => "2021-06-01T12:00:00Z"}}}
              ]
            }
          }
        )
      end)
      |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
        assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/serviceaccounts/devhub/token"
        TeslaHelper.response(body: %{"status" => %{"token" => "k8s-token"}})
      end)
      |> expect(:call, fn %Tesla.Env{
                            method: :get,
                            url: url,
                            headers: [{"authorization", "Bearer k8s-token"}],
                            opts: opts,
                            __client__: client
                          },
                          [name: K8s] ->
        assert url ==
                 "https://127.0.0.1:62667/api/v1/namespaces/devhub/pods/pod-name/log?follow=true&container=plan"

        assert opts == [adapter: [response: :stream, receive_timeout: 14_400_000]]

        assert %Tesla.Client{
                 pre: [
                   {BaseUrl, :call, ["https://127.0.0.1:62667"]},
                   {BearerAuth, :call, [[token: "k8s-token"]]},
                   {JSON, :call, [[decode_content_types: ["text/event-stream"]]]},
                   {SSE, :call, [[only: :data]]}
                 ]
               } = client

        TeslaHelper.response(body: ["log"])
      end)

      assert {:ok, _env} = Client.get_log("pod-name", "plan")
    end

    test "container didn't start" do
      Finch
      |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
        assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/serviceaccounts/devhub/token"
        TeslaHelper.response(body: %{"status" => %{"token" => "k8s-token"}})
      end)
      |> expect(:call, fn %Tesla.Env{
                            method: :get,
                            url: url,
                            headers: [{"authorization", "Bearer k8s-token"}]
                          },
                          [name: K8s] ->
        assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/pods/pod-name"

        TeslaHelper.response(
          body: %{
            "status" => %{
              "phase" => "Failed",
              "containerStatuses" => [
                %{"name" => "plan", "state" => %{}}
              ]
            }
          }
        )
      end)

      assert {:error, :failed_to_get_log} = Client.get_log("pod-name", "plan")
    end
  end

  describe "create_job/1" do
    test "success" do
      Finch
      |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
        assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/serviceaccounts/devhub/token"
        TeslaHelper.response(body: %{"status" => %{"token" => "k8s-token"}})
      end)
      |> expect(:call, fn %Tesla.Env{method: :post, url: url}, [name: K8s] ->
        assert url == "https://127.0.0.1:62667/apis/batch/v1/namespaces/devhub/jobs"

        TeslaHelper.response(status: 201)
      end)

      assert :ok = Client.create_job(%{"name" => "job-name"})
    end

    test "failed" do
      Finch
      |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
        assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/serviceaccounts/devhub/token"
        TeslaHelper.response(body: %{"status" => %{"token" => "k8s-token"}})
      end)
      |> expect(:call, fn %Tesla.Env{method: :post, url: url}, [name: K8s] ->
        assert url == "https://127.0.0.1:62667/apis/batch/v1/namespaces/devhub/jobs"

        TeslaHelper.response(status: 400)
      end)

      assert :error = Client.create_job(%{"name" => "job-name"})
    end
  end

  describe "delete_job/1" do
    test "success" do
      Finch
      |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
        assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/serviceaccounts/devhub/token"
        TeslaHelper.response(body: %{"status" => %{"token" => "k8s-token"}})
      end)
      |> expect(:call, fn %Tesla.Env{method: :delete, url: url}, [name: K8s] ->
        assert url == "https://127.0.0.1:62667/apis/batch/v1/namespaces/devhub/jobs/job-name"

        TeslaHelper.response(body: "ok")
      end)

      assert :ok = Client.delete_job("job-name")
    end

    test "not found" do
      Finch
      |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
        assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/serviceaccounts/devhub/token"
        TeslaHelper.response(body: %{"status" => %{"token" => "k8s-token"}})
      end)
      |> expect(:call, fn %Tesla.Env{method: :delete, url: url}, [name: K8s] ->
        assert url == "https://127.0.0.1:62667/apis/batch/v1/namespaces/devhub/jobs/job-name"

        TeslaHelper.response(status: 404)
      end)

      assert :ok = Client.delete_job("job-name")
    end

    test "other error" do
      Finch
      |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
        assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/serviceaccounts/devhub/token"
        TeslaHelper.response(body: %{"status" => %{"token" => "k8s-token"}})
      end)
      |> expect(:call, fn %Tesla.Env{method: :delete, url: url}, [name: K8s] ->
        assert url == "https://127.0.0.1:62667/apis/batch/v1/namespaces/devhub/jobs/job-name"

        TeslaHelper.response(status: 403)
      end)

      assert :error = Client.delete_job("job-name")
    end
  end

  test "find_pod_for_job/1" do
    Finch
    # fails to find first
    |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
      assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/serviceaccounts/devhub/token"
      TeslaHelper.response(body: %{"status" => %{"token" => "k8s-token"}})
    end)
    |> expect(:call, fn %Tesla.Env{method: :get, url: url}, [name: K8s] ->
      assert url ==
               "https://127.0.0.1:62667/api/v1/namespaces/devhub/pods?labelSelector=job-name=job-name"

      TeslaHelper.response(status: 404)
    end)
    # then retries
    |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
      assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/serviceaccounts/devhub/token"
      TeslaHelper.response(body: %{"status" => %{"token" => "k8s-token"}})
    end)
    |> expect(:call, fn %Tesla.Env{method: :get, url: url}, [name: K8s] ->
      assert url ==
               "https://127.0.0.1:62667/api/v1/namespaces/devhub/pods?labelSelector=job-name=job-name"

      TeslaHelper.response(body: %{"items" => [%{"metadata" => %{"name" => "pod-name"}}]})
    end)

    assert {:ok, %{"metadata" => %{"name" => "pod-name"}}} = Client.find_pod_for_job("job-name")
  end

  test "get_finished_job_status/1" do
    Finch
    # still running on first call
    |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
      assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/serviceaccounts/devhub/token"
      TeslaHelper.response(body: %{"status" => %{"token" => "k8s-token"}})
    end)
    |> expect(:call, fn %Tesla.Env{method: :get, url: url}, [name: K8s] ->
      assert url ==
               "https://127.0.0.1:62667/api/v1/namespaces/devhub/pods/pod-name"

      TeslaHelper.response(body: %{"status" => %{"phase" => "Running"}})
    end)
    # then finished
    |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
      assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/serviceaccounts/devhub/token"
      TeslaHelper.response(body: %{"status" => %{"token" => "k8s-token"}})
    end)
    |> expect(:call, fn %Tesla.Env{method: :get, url: url}, [name: K8s] ->
      assert url ==
               "https://127.0.0.1:62667/api/v1/namespaces/devhub/pods/pod-name"

      TeslaHelper.response(body: %{"status" => %{"phase" => "Succeeded"}})
    end)

    assert {:ok, "Succeeded"} = Client.get_finished_job_status("pod-name")
  end

  describe "create_or_update_secret/1" do
    test "create" do
      Finch
      |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
        assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/serviceaccounts/devhub/token"
        TeslaHelper.response(body: %{"status" => %{"token" => "k8s-token"}})
      end)
      |> expect(:call, fn %Tesla.Env{method: :put, url: url}, [name: K8s] ->
        assert url ==
                 "https://127.0.0.1:62667/api/v1/namespaces/devhub/secrets/my-secret"

        TeslaHelper.response(status: 404)
      end)
      |> expect(:call, fn %Tesla.Env{method: :post, url: url}, [name: K8s] ->
        assert url ==
                 "https://127.0.0.1:62667/api/v1/namespaces/devhub/secrets"

        TeslaHelper.response(status: 201)
      end)

      assert :ok = Client.create_or_update_secret("my-secret", [{"key", "value"}])
    end

    test "update" do
      Finch
      |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
        assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/serviceaccounts/devhub/token"
        TeslaHelper.response(body: %{"status" => %{"token" => "k8s-token"}})
      end)
      |> expect(:call, fn %Tesla.Env{method: :put, url: url, body: body}, [name: K8s] ->
        assert %{
                 "apiVersion" => "v1",
                 "kind" => "Secret",
                 "metadata" => %{
                   "name" => "my-secret",
                   "namespace" => "devhub"
                 },
                 "data" => %{"key" => "dmFsdWU="}
               } = Jason.decode!(body)

        assert url ==
                 "https://127.0.0.1:62667/api/v1/namespaces/devhub/secrets/my-secret"

        TeslaHelper.response(status: 200)
      end)

      assert :ok = Client.create_or_update_secret("my-secret", [{"key", "value"}])
    end
  end

  test "delete_secret/1" do
    Finch
    |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
      assert url == "https://127.0.0.1:62667/api/v1/namespaces/devhub/serviceaccounts/devhub/token"
      TeslaHelper.response(body: %{"status" => %{"token" => "k8s-token"}})
    end)
    |> expect(:call, fn %Tesla.Env{method: :delete, url: url}, [name: K8s] ->
      assert url ==
               "https://127.0.0.1:62667/api/v1/namespaces/devhub/secrets/my-secret"

      TeslaHelper.response(body: "ok")
    end)

    assert {:ok, %{status: 200}} = Client.delete_secret("my-secret")
  end
end
