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
          channels = Servers.list_channels_for_server(server.id)
          
          # Subscribe to server updates for real-time changes
          if connected?(socket) do
            Phoenix.PubSub.subscribe(DiscordClone.PubSub, "servers:#{current_user.id}")
          end
          
          socket = 
            socket
            |> assign(:server, server)
            |> assign(:members, members)
            |> assign(:channels, channels)
            |> assign(:is_admin, is_server_admin?(server.id, current_user.id))
            |> assign(:is_owner, is_server_owner?(server, current_user.id))
            |> assign(:current_server_id, String.to_integer(id))
            |> assign(:show_create_channel_form, false)
            |> assign(:channel_form, to_form(Servers.change_channel(%DiscordClone.Servers.Channel{})))
            |> assign(:selected_channel, nil)
            |> assign(:socket_token, Phoenix.Token.sign(DiscordCloneWeb.Endpoint, "user_socket", current_user.id))

          {:ok, socket}
      end
    else
      {:ok, redirect(socket, to: ~p"/users/log_in")}
    end
  end

  @impl true
  def handle_event("show_create_channel_form", _params, socket) do
    {:noreply, assign(socket, :show_create_channel_form, true)}
  end

  @impl true
  def handle_event("hide_create_channel_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_create_channel_form, false)
     |> assign(:channel_form, to_form(Servers.change_channel(%DiscordClone.Servers.Channel{})))
    }
  end

  @impl true
  def handle_event("create_channel", %{"channel" => channel_params}, socket) do
    current_user = socket.assigns.current_user
    server = socket.assigns.server

    case Servers.create_channel_for_server(server.id, current_user.id, channel_params) do
      {:ok, channel} ->
        # Reload channels
        channels = Servers.list_channels_for_server(server.id)
        
        socket = 
          socket
          |> assign(:channels, channels)
          |> assign(:show_create_channel_form, false)
          |> assign(:channel_form, to_form(Servers.change_channel(%DiscordClone.Servers.Channel{})))
          |> assign(:selected_channel, channel)
          |> put_flash(:info, "Channel created successfully")

        {:noreply, socket}

      {:error, :not_authorized} ->
        {:noreply, put_flash(socket, :error, "You don't have permission to create channels")}

      {:error, changeset} ->
        {:noreply, assign(socket, :channel_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_channel", %{"channel_id" => channel_id}, socket) do
    current_user = socket.assigns.current_user
    server = socket.assigns.server
    
    case Servers.get_server_channel(server.id, channel_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Channel not found")}
      
      channel ->
        case Servers.delete_channel(channel, current_user.id) do
          {:ok, _channel} ->
            # Reload channels
            channels = Servers.list_channels_for_server(server.id)
            
            # Clear selected channel if it was the one deleted
            selected_channel = 
              if socket.assigns.selected_channel && socket.assigns.selected_channel.id == String.to_integer(channel_id) do
                nil
              else
                socket.assigns.selected_channel
              end
            
            socket = 
              socket
              |> assign(:channels, channels)
              |> assign(:selected_channel, selected_channel)
              |> put_flash(:info, "Channel deleted successfully")

            {:noreply, socket}

          {:error, :not_authorized} ->
            {:noreply, put_flash(socket, :error, "You don't have permission to delete channels")}

          {:error, :cannot_delete_general} ->
            {:noreply, put_flash(socket, :error, "Cannot delete the general channel")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to delete channel")}
        end
    end
  end

  @impl true
  def handle_event("validate_channel", %{"channel" => channel_params}, socket) do
    changeset = 
      %DiscordClone.Servers.Channel{}
      |> Servers.change_channel(channel_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :channel_form, to_form(changeset))}
  end

  @impl true
  def handle_event("select_channel", %{"channel_id" => channel_id}, socket) do
    server = socket.assigns.server
    
    case Servers.get_server_channel(server.id, channel_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Channel not found")}
      
      channel ->
        {:noreply, assign(socket, :selected_channel, channel)}
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