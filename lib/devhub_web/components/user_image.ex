defmodule DevhubWeb.Components.UserImage do
  @moduledoc false
  use DevhubWeb, :html

  attr :class, :string, default: nil

  def user_image(assigns) do
    assigns =
      assign(assigns,
        image_url: assigns.user.picture
        # "https://www.gravatar.com/avatar/#{:md5 |> :crypto.hash(to_string(assigns.user.email)) |> Base.encode16() |> String.downcase()}?d=mp"
      )

    ~H"""
    <img :if={@image_url} class={@class} src={@image_url} alt="user image" />
    <.icon :if={is_nil(@image_url)} name="hero-user-circle" class={@class} />
    """
  end
end
