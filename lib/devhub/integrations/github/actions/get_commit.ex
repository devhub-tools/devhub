defmodule Devhub.Integrations.GitHub.Actions.GetCommit do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.GitHub.Commit
  alias Devhub.Repo

  @callback get_commit(Keyword.t()) :: {:ok, Commit.t()} | {:error, :commit_not_found}
  def get_commit(by) do
    case Repo.get_by(Commit, by) do
      %Commit{} = commit ->
        {:ok, commit}

      nil ->
        {:error, :commit_not_found}
    end
  end
end
