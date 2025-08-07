defmodule Devhub.TerraDesk.Utils.JobSpec do
  @moduledoc false

  import Devhub.TerraDesk.Utils.Container

  def job_spec(job_name, workspace, default_branch, opts) do
    additional_init_containers = Keyword.get(opts, :init_containers, [])
    containers = Keyword.get(opts, :containers, [])
    additional_volumes = Keyword.get(opts, :volumes, [])

    tolerations = [
      %{
        "key" => "kubernetes.io/arch",
        "operator" => "Equal",
        "value" => "arm64",
        "effect" => "NoSchedule"
      }
    ]

    %{
      "apiVersion" => "batch/v1",
      "kind" => "Job",
      "metadata" => %{
        "name" => job_name,
        "namespace" => Application.get_env(:devhub, :namespace)
      },
      "spec" => %{
        "template" => %{
          "spec" => %{
            "initContainers" => init_containers(workspace, default_branch, additional_init_containers),
            "containers" => containers,
            "securityContext" => %{
              "runAsUser" => 1000,
              "runAsGroup" => 1000,
              "fsGroup" => 1000
            },
            "restartPolicy" => "Never",
            "volumes" => [
              %{
                "name" => "workspace",
                "emptyDir" => %{}
              }
              | additional_volumes
            ],
            "tolerations" => tolerations
          }
        },
        "backoffLimit" => 0,
        "ttlSecondsAfterFinished" => 3600
      }
    }
  end

  defp init_containers(workspace, branch, other_containers) do
    secret_name = workspace.id |> String.replace("_", "-") |> String.downcase()

    init_args =
      (workspace.init_args || "")
      |> String.trim()
      |> String.split(" ")
      |> Enum.concat(["-input=false"])
      |> Enum.uniq()
      |> Enum.reject(&(&1 == ""))

    [
      container(
        %{
          "name" => "git",
          "image" => "alpine/git:v2.47.1",
          "args" => [
            "clone",
            "--depth=1",
            "--branch",
            branch,
            "https://x-access-token:$(GITHUB_TOKEN)@github.com/#{workspace.repository.owner}/#{workspace.repository.name}.git",
            "/workspace"
          ]
        },
        secret_name
      ),
      container(
        %{
          "name" => "init",
          "image" => workspace.docker_image,
          "args" => ["init" | init_args],
          "workingDir" => "/workspace/#{workspace.path}"
        },
        secret_name
      )
      | other_containers
    ]
  end
end
