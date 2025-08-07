defmodule DevhubWeb.Components.CredentialDropdown do
  @moduledoc false
  use DevhubWeb, :html

  def credential_dropdown(assigns) do
    ~H"""
    <div class="relative">
      <div
        phx-click={JS.toggle(to: "#credential-options")}
        phx-click-away={JS.hide(to: "#credential-options")}
        class="cursor-pointer"
      >
        <div class="flex items-center rounded text-sm">
          <span class="mr-1">
            <span class="text-alpha-64 mr-1 text-xs">RUN AS:</span> {@current_credential.username}
          </span>
          <.icon name="hero-chevron-down" class="h-4" />
        </div>
      </div>
      <ul
        class="bg-surface-4 divide-alpha-4 absolute bottom-10 left-1/2 z-10 hidden w-56 -translate-x-1/2 divide-y overflow-auto rounded-md py-1 text-base shadow-lg ring-1 ring-gray-100 ring-opacity-5 focus:outline-none"
        id="credential-options"
        role="listbox"
      >
        <li
          :for={credential <- @credentials}
          class="whitespace-no-wrap block px-4 py-2 text-sm hover:bg-alpha-4"
          phx-click="select_credential"
          phx-value-id={credential.id}
        >
          <div class="flex flex-row justify-between">
            <div class="flex flex-col items-start gap-y-2">
              <div class="w-full truncate whitespace-nowrap text-left">
                {credential.username}
              </div>
              <div class="text-xs text-gray-600">
                {credential.reviews_required} reviews required
              </div>
            </div>
          </div>
        </li>
      </ul>
    </div>
    """
  end
end
