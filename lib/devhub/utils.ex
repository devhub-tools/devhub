defmodule Devhub.Utils do
  @moduledoc false
  def delete_if_empty(map, key) do
    if map[key] == "" or is_nil(map[key]) do
      Map.delete(map, key)
    else
      map
    end
  end

  def update_in(list, item_to_replace) do
    Enum.map(list, fn item ->
      if item.id == item_to_replace.id do
        item_to_replace
      else
        item
      end
    end)
  end

  def sort_permissions(object) do
    permissions =
      Enum.sort_by(object.permissions, fn permission ->
        sort_name =
          case permission do
            %{role: %{name: name}} ->
              name

            %{organization_user: %{user: %{name: name, email: email}}} ->
              name || email
          end

        {is_nil(permission.role_id), String.downcase(sort_name)}
      end)

    %{object | permissions: permissions}
  end
end
