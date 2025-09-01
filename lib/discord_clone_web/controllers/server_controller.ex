defmodule DiscordCloneWeb.ServerController do
  use DiscordCloneWeb, :controller

  alias DiscordClone.Servers

  def index(conn, _params) do
    current_user = conn.assigns[:current_user]
    servers = Servers.list_member_servers_for_user(current_user.id)
    json(conn, %{servers: servers})
  end

  def create(conn, %{"server" => server_params}) do
    current_user = conn.assigns[:current_user]
    server_params = Map.put(server_params, "user_id", current_user.id)

    case Servers.create_server(server_params) do
      {:ok, server} ->
        conn
        |> put_status(:created)
        |> json(%{server: server})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  def show(conn, %{"id" => id}) do
    current_user = conn.assigns[:current_user]

    case Servers.get_member_server(id, current_user.id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Server not found or you are not a member"})

      server ->
        json(conn, %{server: server})
    end
  end

  def update(conn, %{"id" => id, "server" => server_params}) do
    current_user = conn.assigns[:current_user]

    # Only server admins can update server details
    if Servers.is_server_admin?(id, current_user.id) do
      case Servers.get_server!(id) do
        server ->
          case Servers.update_server(server, server_params) do
            {:ok, server} ->
              json(conn, %{server: server})

            {:error, %Ecto.Changeset{} = changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{errors: format_changeset_errors(changeset)})
          end
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Only server admins can update server details"})
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> json(%{error: "Server not found"})
  end

  def delete(conn, %{"id" => id}) do
    current_user = conn.assigns[:current_user]

    # Only the original server creator (owner) can delete the server
    case Servers.get_user_server(id, current_user.id) do
      nil ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Only the server owner can delete the server"})

      server ->
        case Servers.delete_server(server) do
          {:ok, _server} ->
            send_resp(conn, :no_content, "")

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: format_changeset_errors(changeset)})
        end
    end
  end

  # Server membership endpoints

  def list_members(conn, %{"server_id" => server_id}) do
    current_user = conn.assigns[:current_user]

    if Servers.is_server_member?(server_id, current_user.id) do
      members = Servers.list_server_members(server_id)
      json(conn, %{members: members})
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "You must be a member of this server"})
    end
  end

  def add_member(conn, %{"server_id" => server_id, "user_id" => user_id}) do
    current_user = conn.assigns[:current_user]

    if Servers.is_server_admin?(server_id, current_user.id) do
      case Servers.add_user_to_server(server_id, user_id, "member") do
        {:ok, server_user} ->
          conn
          |> put_status(:created)
          |> json(%{server_user: server_user})

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: format_changeset_errors(changeset)})
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Only server admins can add members"})
    end
  end

  def remove_member(conn, %{"server_id" => server_id, "user_id" => user_id}) do
    current_user = conn.assigns[:current_user]

    if Servers.is_server_admin?(server_id, current_user.id) do
      case Servers.remove_user_from_server(server_id, user_id) do
        {:ok, _server_user} ->
          send_resp(conn, :no_content, "")

        {:error, :not_found} ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "User is not a member of this server"})
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Only server admins can remove members"})
    end
  end

  def update_member_role(conn, %{"server_id" => server_id, "user_id" => user_id, "role" => role}) do
    current_user = conn.assigns[:current_user]

    if Servers.is_server_admin?(server_id, current_user.id) do
      case Servers.update_server_user_role(server_id, user_id, role) do
        {:ok, server_user} ->
          json(conn, %{server_user: server_user})

        {:error, :not_found} ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "User is not a member of this server"})

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: format_changeset_errors(changeset)})
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Only server admins can update member roles"})
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end