defmodule Devhub.TerraDesk.Actions.UpdateWorkspaceTest do
  use Devhub.DataCase, async: true

  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Workspace

  test "success" do
    %{id: organization_id} = organization = insert(:organization)

    %{id: workspace_id} =
      workspace =
      :workspace
      |> insert(organization: organization, repository: build(:repository, organization: organization), name: "old")
      |> Devhub.Repo.preload([:env_vars, :secrets, :workload_identity])

    %{id: agent_id} = insert(:agent, organization: organization)

    params = %{
      "agent_id" => agent_id,
      "env_var_sort" => ["0"],
      "env_vars" => %{
        "0" => %{"_persistent_id" => "0", "name" => "MY_ENV_VAR", "value" => "test"}
      },
      "init_args" => "--refresh=false",
      "name" => "server",
      "path" => "terraform",
      "run_plans_automatically" => "true",
      "required_approvals" => "1",
      "secret_sort" => ["0"],
      "secrets" => %{
        "0" => %{
          "_persistent_id" => "0",
          "name" => "MY_SECRET",
          "value" => "secret"
        }
      },
      "workload_identity" => %{
        "_persistent_id" => "0",
        "enabled" => "true",
        "provider" => "projects/973501356954/locations/global/workloadIdentityPools/terradesk/providers/terradesk",
        "service_account_email" => "terradesk@cloud-57.iam.gserviceaccount.com"
      }
    }

    assert {:ok,
            %Workspace{
              id: ^workspace_id,
              organization_id: ^organization_id,
              name: "server",
              agent_id: ^agent_id,
              env_vars: [%Devhub.TerraDesk.Schemas.EnvVar{name: "MY_ENV_VAR", value: "test"}],
              init_args: "--refresh=false",
              path: "terraform",
              run_plans_automatically: true,
              required_approvals: 1,
              secrets: [%Devhub.TerraDesk.Schemas.Secret{name: "MY_SECRET", value: "secret"}],
              workload_identity: %Devhub.TerraDesk.Schemas.WorkloadIdentity{
                enabled: true,
                service_account_email: "terradesk@cloud-57.iam.gserviceaccount.com",
                provider: "projects/973501356954/locations/global/workloadIdentityPools/terradesk/providers/terradesk",
                organization_id: ^organization_id
              }
            }} =
             TerraDesk.insert_or_update_workspace(workspace, params)
  end
end
