defmodule DiscordCloneWeb.SidebarLive do
  use DiscordCloneWeb, :live_component

  alias DiscordClone.Servers

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    servers = Servers.list_member_servers_for_user(assigns.current_user.id)
    
    {:ok, 
     socket
     |> assign(assigns)
     |> assign(servers: servers)
     |> assign(current_server_id: Map.get(assigns, :current_server_id, nil))}
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-full flex-col bg-gray-900">
      <!-- Sidebar header -->
      <div class="flex h-16 items-center justify-center border-b border-gray-800 px-4">
        <.link navigate={~p"/servers"} class="flex items-center gap-2 text-white hover:text-gray-300">
          <.icon name="hero-server" class="h-6 w-6" />
          <span class="font-semibold">Servers</span>
        </.link>
      </div>

      <!-- Server list -->
      <div class="flex-1 overflow-y-auto py-4">
        <nav class="space-y-1 px-3">
          <%= for server <- @servers do %>
            <.link
              navigate={~p"/servers/#{server.id}"}
              class={[
                "group flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors",
                if(@current_server_id && @current_server_id == server.id,
                  do: "bg-indigo-600 text-white",
                  else: "text-gray-300 hover:bg-gray-800 hover:text-white"
                )
              ]}
            >
              <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-gray-700 text-xs font-semibold text-white group-hover:bg-gray-600">
                <%= String.first(server.name) |> String.upcase() %>
              </div>
              <span class="truncate"><%= server.name %></span>
            </.link>
          <% end %>

          <!-- Create server button -->
          <.link
            navigate={~p"/servers/new"}
            class="group flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-gray-400 hover:bg-gray-800 hover:text-white transition-colors"
          >
            <div class="flex h-8 w-8 items-center justify-center rounded-lg border-2 border-dashed border-gray-600 group-hover:border-gray-500">
              <.icon name="hero-plus" class="h-4 w-4" />
            </div>
            <span>Add Server</span>
          </.link>
        </nav>
      </div>

      <!-- User info at bottom -->
      <div class="border-t border-gray-800 p-3">
        <div class="flex items-center gap-3">
          <div class="h-8 w-8 rounded-full bg-indigo-600 flex items-center justify-center">
            <span class="text-xs font-medium text-white">
              <%= String.first(@current_user.username) |> String.upcase() %>
            </span>
          </div>
          <div class="flex-1 truncate">
            <p class="text-sm font-medium text-white truncate"><%= @current_user.username %></p>
            <p class="text-xs text-gray-400 truncate"><%= @current_user.email %></p>
          </div>
        </div>
      </div>

    </div>
    """
  end

end