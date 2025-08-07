defmodule Devhub.Integrations.GitHub.Utils.HasNextPageTest do
  @moduledoc false
  use Devhub.DataCase, async: true

  import Devhub.Integrations.GitHub.Utils.HasNextPage

  test "has next page" do
    # returns false if there is no next page
    refute has_next_page?(false, nil, "2016-05-24T13:26:08Z")

    # returns true if there is a next page and since arg is nil
    assert has_next_page?(true, nil, "2016-05-24T13:26:08Z")

    # returns true if there is a next page and since arg is before data_through
    assert has_next_page?(true, ~D[2024-05-24], "2024-05-25T13:26:08Z")

    # returns false if there is a next page and since arg is after data_through
    refute has_next_page?(true, ~D[2024-05-24], "2024-05-23T13:26:08Z")
  end
end
