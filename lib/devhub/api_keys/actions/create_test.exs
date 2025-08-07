defmodule Devhub.ApiKeys.Actions.CreateTest do
  use Devhub.DataCase, async: true

  alias Devhub.ApiKeys
  alias Devhub.ApiKeys.Schemas.ApiKey

  describe "create/3" do
    test "sucessfully create api_key" do
      organization = insert(:organization)

      {:ok, %ApiKey{}, _token} = ApiKeys.create(organization, "test", [:coverbot])
    end

    test "fail to create api key" do
      organization = insert(:organization)
      {:error, "Failed to create api key"} = ApiKeys.create(organization, "", [:coverbot])
    end
  end
end
