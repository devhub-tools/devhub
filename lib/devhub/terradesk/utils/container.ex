defmodule Devhub.TerraDesk.Utils.Container do
  @moduledoc false
  def container(params, secret_name) do
    Map.merge(
      %{
        "envFrom" => [%{"secretRef" => %{"name" => secret_name}}],
        "securityContext" => %{
          "allowPrivilegeEscalation" => false,
          "capabilities" => %{"drop" => ["ALL"]},
          "runAsUser" => 1000,
          "runAsGroup" => 1000,
          "runAsNonRoot" => true,
          "seccompProfile" => %{"type" => "RuntimeDefault"}
        },
        "volumeMounts" => [
          %{"name" => "workspace", "mountPath" => "/workspace"}
        ]
      },
      params
    )
  end
end
