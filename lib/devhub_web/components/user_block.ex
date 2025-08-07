defmodule DevhubWeb.Components.UserBlock do
  @moduledoc false
  use DevhubWeb, :html

  def user_block(assigns) do
    assigns =
      assign(assigns,
        picture:
          assigns.user.picture ||
            "https://www.gravatar.com/avatar/#{:md5 |> :crypto.hash(to_string(assigns.user.email)) |> Base.encode16() |> String.downcase()}?d=retro"
      )

    ~H"""
    <div class="flex items-center gap-x-3">
      <div class="flex rounded-full text-sm focus:outline-none">
        <img class="h-8 w-8 rounded-full" src={@picture} alt="profile picture" />
      </div>
      <div class="flex flex-col items-start justify-center">
        <div>
          {@user.name}
        </div>
        <div class="text-alpha-64 text-xs">
          {@user.email}
        </div>
      </div>
    </div>
    """
  end
end
