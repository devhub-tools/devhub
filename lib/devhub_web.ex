defmodule DevhubWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use DevhubWeb, :controller
      use DevhubWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def home_page(organization) do
    cond do
      :dev_portal in organization.license.products ->
        "/"

      :querydesk in organization.license.products ->
        "/querydesk"

      :coverbot in organization.license.products ->
        "/coverbot"

      :terradesk in organization.license.products ->
        "/terradesk"
    end
  end

  def static_paths, do: ~w(assets fonts images favicon.svg robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Phoenix.Controller
      import Phoenix.LiveView.Router
      import Plug.Conn
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: DevhubWeb.Layouts]

      use Gettext, backend: DevhubWeb.Gettext

      import DevhubWeb.Helpers
      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {DevhubWeb.Layouts, :app}

      import DevhubWeb.Helpers

      on_mount Sentry.LiveViewHook
      on_mount DevhubWeb.Middleware.LiveFlash

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import DevhubWeb.Helpers
      import DevhubWeb.Middleware.LiveFlash, only: [push_flash: 3]

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      import DevhubWeb.Helpers

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Core UI components and translation
      use Gettext, backend: DevhubWeb.Gettext

      import DevhubWeb.CoreComponents
      import Phoenix.HTML
      import PolymorphicEmbed.HTML.Component
      import PolymorphicEmbed.HTML.Form

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: DevhubWeb.Endpoint,
        router: DevhubWeb.Router,
        statics: DevhubWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
