defmodule Devhub.Integrations.Linear.Webhook do
  @moduledoc false

  alias Devhub.Integrations.Linear

  def handle(integration, event) do
    do_handle(integration, event)
    :ok
  end

  defp do_handle(integration, %{"type" => "User"} = event) do
    Linear.upsert_user(%{
      organization_id: integration.organization_id,
      external_id: event["data"]["id"],
      name: event["data"]["name"]
    })
  end

  defp do_handle(integration, %{"type" => "Issue", "action" => "remove"} = event) do
    Linear.delete_issue(integration, event["data"]["id"])
  end

  defp do_handle(integration, %{"type" => "Issue"} = event) do
    Linear.upsert_issue(integration, event["data"])
  end

  defp do_handle(integration, %{"type" => "IssueLabel", "action" => "remove"} = event) do
    Linear.delete_label(integration, event["data"]["id"])
  end

  defp do_handle(integration, %{"type" => "IssueLabel"} = event) do
    Linear.upsert_label(integration, event["data"])
  end

  defp do_handle(integration, %{"type" => "Project", "action" => "remove"} = event) do
    Linear.delete_project(integration, event["data"]["id"])
  end

  defp do_handle(integration, %{"type" => "Project"} = event) do
    Linear.upsert_project(integration, event["data"])
  end

  defp do_handle(_integration, _event), do: :ok
end
