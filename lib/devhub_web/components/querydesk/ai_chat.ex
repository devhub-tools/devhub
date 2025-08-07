defmodule DevhubWeb.Components.QueryDesk.AiChat do
  @moduledoc false
  use DevhubWeb, :live_component

  alias Devhub.Integrations.AI
  alias Devhub.Permissions

  def update(assigns, socket) do
    filters = if assigns.search, do: [search: assigns.search], else: []
    conversations = AI.get_conversations(assigns.organization_user, filters)

    selected_conversation =
      conversations
      |> Enum.find(&(&1.id == assigns.selected_conversation_id))
      |> Devhub.Repo.preload(:messages)

    socket
    |> assign(assigns)
    |> assign(conversations: conversations, selected_conversation: selected_conversation)
    |> push_event("load_from_local_storage", %{localStorageKey: assigns.selected_conversation_id, default: ""})
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div>
      <.link
        navigate={~p"/querydesk/databases/#{@database_id}/query"}
        class="ml-4 text-sm font-medium text-blue-600"
      >
        <.icon name="hero-arrow-left-solid" class="size-3" /> Tables
      </.link>
      <div class="border-alpha-8 mt-4 flex items-center justify-between border-b px-4 pb-3">
        <p class="text-alpha-64 text-sm">Conversations</p>
        <.button variant="text" size="sm" phx-click="clear_conversation" phx-target={@myself}>
          New
        </.button>
      </div>
      <.form
        :let={f}
        for={%{"search" => @search}}
        class="border-alpha-8 mt-4 border-b px-4 pb-4"
        phx-change="search_conversations"
        phx-target={@myself}
      >
        <.input field={f[:search]} type="text" placeholder="Search" phx-debounce />
      </.form>
      <ul class="divide-alpha-8 divide-y">
        <li
          :for={conversation <- @conversations}
          class="bg-surface-1 group relative cursor-pointer p-4 text-xs hover:bg-alpha-4"
          phx-click="select_conversation"
          phx-value-id={conversation.id}
          phx-target={@myself}
        >
          <p class="truncate">{conversation.title}</p>
          <div class="mt-1 truncate text-gray-600">
            <format-date date={conversation.updated_at} format="relative" />
          </div>
        </li>
      </ul>

      <.sidebar
        organization_user={@organization_user}
        selected_conversation={@selected_conversation}
        database_adapter={@database_adapter}
        ai_setup?={@ai_setup?}
        myself={@myself}
      />
    </div>
    """
  end

  def handle_event("select_conversation", %{"id" => conversation_id}, socket) do
    socket
    |> patch_current(%{"conversation_id" => conversation_id, "search" => socket.assigns.search})
    |> noreply()
  end

  def handle_event("clear_conversation", _params, socket) do
    socket
    |> assign(selected_conversation: nil)
    |> push_patch(to: ~p"/querydesk/databases/#{socket.assigns.database_id}/ai")
    |> noreply()
  end

  def handle_event("search_conversations", %{"search" => search}, socket) do
    conversations = AI.get_conversations(socket.assigns.organization_user, search: search)

    socket
    |> assign(conversations: conversations)
    |> assign(search: search)
    |> noreply()
  end

  def handle_event("recommend_query", %{"question" => question}, socket) do
    conversation = socket.assigns.selected_conversation
    database_id = socket.assigns.database_id
    organization_user = socket.assigns.organization_user

    case AI.add_message_to_conversation(conversation, :user, question) do
      {:ok, message} ->
        messages = [message | conversation.messages]
        conversation = %{conversation | messages: messages}

        socket
        |> assign(selected_conversation: conversation)
        |> start_async(:recommend_query, fn ->
          AI.recommend_query(organization_user, database_id, conversation)
        end)
        |> noreply()

      _error ->
        socket |> put_flash(:error, "Failed to send message.") |> noreply()
    end
  end

  def handle_event("start_conversation", %{"question" => question}, socket) do
    organization_id = socket.assigns.organization.id
    organization_user = socket.assigns.organization_user
    database_id = socket.assigns.database_id

    {:ok, title} = AI.conversation_title(socket.assigns.organization, question)

    case AI.start_conversation(%{
           organization_id: organization_id,
           user_id: organization_user.user_id,
           title: title,
           messages: [%{organization_id: organization_id, sender: :user, message: question}]
         }) do
      {:ok, conversation} ->
        socket
        |> assign(selected_conversation: conversation)
        |> assign(conversations: [conversation | socket.assigns.conversations])
        |> push_patch(to: ~p"/querydesk/databases/#{socket.assigns.database_id}/ai?conversation_id=#{conversation.id}")
        |> start_async(:recommend_query, fn ->
          AI.recommend_query(organization_user, database_id, conversation)
        end)
        |> noreply()

      _error ->
        socket |> put_flash(:error, "Failed to start conversation.") |> noreply()
    end
  end

  def handle_event("insert_query", %{"query" => query}, socket) do
    socket
    |> push_event("insert_query", %{"query" => "\n" <> query, adapter: socket.assigns.database_adapter})
    |> noreply()
  end

  def handle_async(:recommend_query, {:ok, data}, socket) do
    conversation = socket.assigns.selected_conversation

    with {:ok, query} <- data,
         {:ok, message} <- AI.add_message_to_conversation(conversation, :ai, query) do
      messages = [message | conversation.messages]
      conversation = %{conversation | messages: messages}

      socket
      |> assign(selected_conversation: conversation)
      |> noreply()
    else
      _error ->
        socket |> put_flash(:error, "Failed to generate query.") |> noreply()
    end
  end

  defp sidebar(%{ai_setup?: false} = assigns) do
    ~H"""
    <div class="bg-surface-1 fixed inset-4 left-auto z-10 w-96 rounded-lg text-sm">
      <div class="flex h-full flex-col p-4 text-sm">
        <p class="text-alpha-64 border-alpha-8 mb-4 border-b pb-1">Setup required</p>
        <%= if Permissions.can?(:manage_integrations, @organization_user) do %>
          <div>
            <.link_button navigate={~p"/settings/integrations"}>
              <.icon name="hero-cube" class="size-5" />
              <span class="ml-2">Setup AI</span>
            </.link_button>
          </div>
        <% else %>
          <div class="border-alpha-16 rounded-lg border-2 border-dashed p-12 text-center hover:border-alpha-24">
            <.icon name="hero-cube" class="size-10 mx-auto text-gray-500" />
            <h3 class="mt-2 text-sm font-semibold text-gray-900">
              Please contact your admin to enable AI features.
            </h3>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp sidebar(%{selected_conversation: nil} = assigns) do
    ~H"""
    <div class="bg-surface-1 fixed inset-4 left-auto z-10 w-96 rounded-lg text-sm">
      <div class="flex h-full flex-col justify-between p-4 text-sm">
        <p class="text-alpha-64 border-alpha-8 mb-4 border-b pb-1">Start a conversation</p>
        <.form :let={f} for={%{}} phx-submit="start_conversation" phx-target={@myself}>
          <.input
            field={f[:question]}
            type="textarea"
            placeholder="Ask a question"
            phx-hook="TextAreaSubmit"
          />
          <div class="flex items-center justify-end">
            <.button type="submit" class="mt-2">Recommend query</.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  defp sidebar(assigns) do
    ~H"""
    <div class="bg-surface-1 fixed inset-4 left-auto z-10 w-96 rounded-lg text-sm">
      <div class="flex h-full flex-col-reverse justify-between overflow-y-auto p-4">
        <div>
          <div :for={message <- Enum.reverse(@selected_conversation.messages)} class="flex">
            <div :if={message.sender == :ai} class="relative">
              <div class="bg-surface-2 mt-2 w-full overflow-y-auto rounded">
                <div class="max-w-80 overflow-auto p-4">
                  <pre
                    id={"ai-message-#{message.id}"}
                    phx-hook="SqlHighlight"
                    data-query={message.message}
                    data-adapter={@database_adapter}
                  />
                </div>
              </div>
              <div class="absolute top-0 -right-6 bottom-6 flex flex-col items-center justify-center">
                <copy-button value={message.message} />
              </div>

              <div class="flex items-center gap-x-2">
                <.button
                  variant="text"
                  phx-click="insert_query"
                  phx-value-query={message.message}
                  phx-target={@myself}
                >
                  Insert
                </.button>
                <.button
                  variant="text"
                  phx-click="run_query"
                  phx-value-query={message.message}
                  phx-value-selection=""
                >
                  Run
                </.button>
              </div>
            </div>
            <div :if={message.sender == :user} class="ml-12 w-full">
              <div class="mt-2 ml-auto w-fit rounded bg-blue-200 p-4">
                <div class="overflow-auto">
                  {message.message}
                </div>
              </div>
            </div>
          </div>
          <.form :let={f} for={%{}} phx-submit="recommend_query" class="mt-auto" phx-target={@myself}>
            <.input
              field={f[:question]}
              type="textarea"
              placeholder="Ask a question"
              phx-hook="TextAreaSubmit"
            />
            <div class="flex items-center justify-end">
              <.button type="submit" class="mt-2">Recommend query</.button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
