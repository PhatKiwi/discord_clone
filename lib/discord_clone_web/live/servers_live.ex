defmodule DiscordCloneWeb.ServersLive do
  use DiscordCloneWeb, :live_view
  
  require Logger
  alias DiscordClone.Servers
  alias DiscordClone.Servers.Server

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    if current_user do
      member_servers = Servers.list_member_servers_for_user(current_user.id)
      
      # Subscribe to server updates for real-time changes
      if connected?(socket) do
        Phoenix.PubSub.subscribe(DiscordClone.PubSub, "servers:#{current_user.id}")
      end
      
      socket = 
        socket
        |> assign(:servers, member_servers)
        |> assign(:form, to_form(Servers.change_server(%Server{})))

      {:ok, socket}
    else
      {:ok, redirect(socket, to: ~p"/users/log_in")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "My Servers")
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Create Server")
  end


  @impl true
  def handle_event("delete_server", %{"id" => id}, socket) do
    current_user = socket.assigns.current_user

    case Servers.get_user_server(id, current_user.id) do
      nil ->
        {:noreply, put_flash(socket, :error, "You don't have permission to delete this server")}

      server ->
        case Servers.delete_server(server) do
          {:ok, _server} ->
            # Broadcast server deletion for real-time updates
            Phoenix.PubSub.broadcast(
              DiscordClone.PubSub,
              "servers:#{current_user.id}",
              {:server_deleted, server.id}
            )
            
            # Refresh the server list
            member_servers = Servers.list_member_servers_for_user(current_user.id)
            
            socket = 
              socket
              |> assign(:servers, member_servers)
              |> put_flash(:info, "Server \"#{server.name}\" deleted successfully!")

            {:noreply, socket}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to delete server")}
        end
    end
  end

  def is_server_owner?(server, user_id) do
    server.user_id == user_id
  end

  def is_server_admin?(server_id, user_id) do
    Servers.is_server_admin?(server_id, user_id)
  end

  @impl true
  def handle_info({:server_created, _server}, socket) do
    # Refresh server list when a new server is created
    current_user = socket.assigns.current_user
    member_servers = Servers.list_member_servers_for_user(current_user.id)
    
    # Update the sidebar component
    send_update(DiscordCloneWeb.SidebarLive, 
      id: "sidebar",
      current_user: current_user,
      current_server_id: socket.assigns[:current_server_id])
    
    {:noreply, assign(socket, :servers, member_servers)}
  end

  @impl true
  def handle_info({:server_updated, _server}, socket) do
    # Refresh server list when a server is updated
    current_user = socket.assigns.current_user
    member_servers = Servers.list_member_servers_for_user(current_user.id)
    
    # Update the sidebar component
    send_update(DiscordCloneWeb.SidebarLive, 
      id: "sidebar",
      current_user: current_user,
      current_server_id: socket.assigns[:current_server_id])
    
    {:noreply, assign(socket, :servers, member_servers)}
  end

  @impl true
  def handle_info({:server_deleted, _server_id}, socket) do
    # Refresh server list when a server is deleted
    current_user = socket.assigns.current_user
    member_servers = Servers.list_member_servers_for_user(current_user.id)
    
    # Update the sidebar component
    send_update(DiscordCloneWeb.SidebarLive, 
      id: "sidebar",
      current_user: current_user,
      current_server_id: socket.assigns[:current_server_id])
    
    {:noreply, assign(socket, :servers, member_servers)}
  end
end