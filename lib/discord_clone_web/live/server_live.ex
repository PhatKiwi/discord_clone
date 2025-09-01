defmodule DiscordCloneWeb.ServerLive do
  use DiscordCloneWeb, :live_view

  alias DiscordClone.Servers

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    current_user = socket.assigns.current_user

    if current_user do
      case Servers.get_member_server(id, current_user.id) do
        nil ->
          socket = 
            socket
            |> put_flash(:error, "Server not found or you don't have access")
            |> redirect(to: ~p"/servers")
          
          {:ok, socket}

        server ->
          members = Servers.list_server_members(server.id)
          
          # Subscribe to server updates for real-time changes
          if connected?(socket) do
            Phoenix.PubSub.subscribe(DiscordClone.PubSub, "servers:#{current_user.id}")
          end
          
          socket = 
            socket
            |> assign(:server, server)
            |> assign(:members, members)
            |> assign(:is_admin, is_server_admin?(server.id, current_user.id))
            |> assign(:is_owner, is_server_owner?(server, current_user.id))
            |> assign(:current_server_id, String.to_integer(id))

          {:ok, socket}
      end
    else
      {:ok, redirect(socket, to: ~p"/users/log_in")}
    end
  end

  @impl true
  def handle_event("leave_server", _params, socket) do
    current_user = socket.assigns.current_user
    server = socket.assigns.server

    # Don't allow owner to leave their own server
    if is_server_owner?(server, current_user.id) do
      {:noreply, put_flash(socket, :error, "You cannot leave a server you own. Delete it instead.")}
    else
      case Servers.remove_user_from_server(server.id, current_user.id) do
        {:ok, _} ->
          socket = 
            socket
            |> put_flash(:info, "You have left the server")
            |> redirect(to: ~p"/servers")
          
          {:noreply, socket}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to leave server")}
      end
    end
  end

  defp is_server_owner?(server, user_id) do
    server.user_id == user_id
  end

  defp is_server_admin?(server_id, user_id) do
    Servers.is_server_admin?(server_id, user_id)
  end

  @impl true
  def handle_info({:server_created, _server}, socket) do
    # Update the sidebar component when a new server is created
    current_user = socket.assigns.current_user
    
    send_update(DiscordCloneWeb.SidebarLive, 
      id: "sidebar",
      current_user: current_user,
      current_server_id: socket.assigns[:current_server_id])
    
    {:noreply, socket}
  end

  @impl true
  def handle_info({:server_updated, _server}, socket) do
    # Update the sidebar component when a server is updated
    current_user = socket.assigns.current_user
    
    send_update(DiscordCloneWeb.SidebarLive, 
      id: "sidebar",
      current_user: current_user,
      current_server_id: socket.assigns[:current_server_id])
    
    {:noreply, socket}
  end

  @impl true
  def handle_info({:server_deleted, _server_id}, socket) do
    # Update the sidebar component when a server is deleted
    current_user = socket.assigns.current_user
    
    send_update(DiscordCloneWeb.SidebarLive, 
      id: "sidebar",
      current_user: current_user,
      current_server_id: socket.assigns[:current_server_id])
    
    {:noreply, socket}
  end
end