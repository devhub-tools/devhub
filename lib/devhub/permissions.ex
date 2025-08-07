defmodule Devhub.Permissions do
  @moduledoc false

  alias DevhubPrivate.Permissions.Can

  if Code.ensure_loaded?(DevhubPrivate.Permissions) do
    @behaviour Can
    @impl Can
    defdelegate can?(action, resource \\ nil, organization_user), to: Can
  else
    def can?(_action, _resource \\ nil, _organization_user), do: not Code.ensure_loaded?(DevhubPrivate.Permissions)
  end
end
