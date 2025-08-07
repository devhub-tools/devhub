defmodule Devhub.Integrations.GitHub.Actions.GetApp do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Schemas.GitHubApp
  alias Devhub.Repo

  @callback get_app(Keyword.t()) :: {:ok, GitHubApp.t()} | {:error, :github_app_not_found}
  def get_app(by) do
    case Repo.get_by(GitHubApp, by) do
      %GitHubApp{} = app -> {:ok, app}
      nil -> {:error, :github_app_not_found}
    end
  end
end
