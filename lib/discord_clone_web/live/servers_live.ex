defmodule DiscordCloneWeb.ServersLive do
  use DiscordCloneWeb, :live_view

  alias DiscordClone.Servers
  alias DiscordClone.Servers.Server

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    if current_user do
      member_servers = Servers.list_member_servers_for_user(current_user.id)
      
      socket = 
        socket
        |> assign(:servers, member_servers)
        |> assign(:show_create_form, false)
        |> assign(:form, to_form(Servers.change_server(%Server{})))

      {:ok, socket}
    else
      {:ok, redirect(socket, to: ~p"/users/log_in")}
    end
  end

  @impl true
  def handle_event("show_create_form", _params, socket) do
    {:noreply, assign(socket, :show_create_form, true)}
  end

  @impl true
  def handle_event("hide_create_form", _params, socket) do
    socket = 
      socket
      |> assign(:show_create_form, false)
      |> assign(:form, to_form(Servers.change_server(%Server{})))
    
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_server", %{"server" => server_params}, socket) do
    changeset = 
      %Server{}
      |> Servers.change_server(server_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("create_server", %{"server" => server_params}, socket) do
    current_user = socket.assigns.current_user
    server_params = Map.put(server_params, "user_id", current_user.id)

    case Servers.create_server(server_params) do
      {:ok, server} ->
        # Refresh the server list
        member_servers = Servers.list_member_servers_for_user(current_user.id)
        
        socket = 
          socket
          |> assign(:servers, member_servers)
          |> assign(:show_create_form, false)
          |> assign(:form, to_form(Servers.change_server(%Server{})))
          |> put_flash(:info, "Server \"#{server.name}\" created successfully!")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
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
end