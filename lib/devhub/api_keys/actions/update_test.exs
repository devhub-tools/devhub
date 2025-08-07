defmodule Devhub.ApiKeys.Actions.UpdateTest do
  use Devhub.DataCase

  alias Devhub.ApiKeys

  describe "update/3" do
    test "updates an api key" do
      api_key = insert(:api_key, permissions: [:full_access])

      assert {:ok, %{name: "my api key", permissions: [:querydesk_limited]}} =
               ApiKeys.update(api_key, "my api key", [:querydesk_limited])
    end
  end
end
