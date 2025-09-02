defmodule DiscordClone.Servers do
  @moduledoc """
  The Servers context.
  """

  import Ecto.Query, warn: false
  alias DiscordClone.Repo

  alias DiscordClone.Servers.Server
  alias DiscordClone.Servers.ServerUser
  alias DiscordClone.Servers.Channel

  @doc """
  Returns the list of servers for a user (owned servers).

  ## Examples

      iex> list_servers_for_user(user_id)
      [%Server{}, ...]

  """
  def list_servers_for_user(user_id) do
    Server
    |> where([s], s.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Returns the list of servers a user is a member of (including owned).

  ## Examples

      iex> list_member_servers_for_user(user_id)
      [%Server{}, ...]

  """
  def list_member_servers_for_user(user_id) do
    Server
    |> join(:inner, [s], su in ServerUser, on: s.id == su.server_id)
    |> where([s, su], su.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Gets a single server.

  Raises `Ecto.NoResultsError` if the Server does not exist.

  ## Examples

      iex> get_server!(123)
      %Server{}

      iex> get_server!(456)
      ** (Ecto.NoResultsError)

  """
  def get_server!(id), do: Repo.get!(Server, id)

  @doc """
  Gets a single server by id and user_id (admin only).

  Returns `nil` if the Server does not exist or user is not admin.

  ## Examples

      iex> get_user_server(123, 456)
      %Server{}

      iex> get_user_server(123, 999)
      nil

  """
  def get_user_server(id, user_id) do
    Server
    |> where([s], s.id == ^id and s.user_id == ^user_id)
    |> Repo.one()
  end

  @doc """
  Gets a single server by id if user is a member.

  Returns `nil` if the Server does not exist or user is not a member.

  ## Examples

      iex> get_member_server(123, 456)
      %Server{}

      iex> get_member_server(123, 999)
      nil

  """
  def get_member_server(id, user_id) do
    Server
    |> join(:inner, [s], su in ServerUser, on: s.id == su.server_id)
    |> where([s, su], s.id == ^id and su.user_id == ^user_id)
    |> Repo.one()
  end

  @doc """
  Creates a server and automatically adds the creator as admin and creates a general channel.

  ## Examples

      iex> create_server(%{field: value})
      {:ok, %Server{}}

      iex> create_server(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_server(attrs \\ %{}) do
    result = Repo.transaction(fn ->
      case %Server{} |> Server.changeset(attrs) |> Repo.insert() do
        {:ok, server} ->
          # Add the creator as admin
          case %ServerUser{}
               |> ServerUser.changeset(%{server_id: server.id, user_id: server.user_id, role: "admin"})
               |> Repo.insert() do
            {:ok, _server_user} -> 
              # Create the default "general" channel
              case %Channel{}
                   |> Channel.changeset(%{name: "general", server_id: server.id})
                   |> Repo.insert() do
                {:ok, _channel} -> server
                {:error, changeset} -> Repo.rollback(changeset)
              end
            {:error, changeset} -> Repo.rollback(changeset)
          end
        {:error, changeset} -> 
          Repo.rollback(changeset)
      end
    end)

    case result do
      {:ok, server} -> {:ok, server}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Updates a server.

  ## Examples

      iex> update_server(server, %{field: new_value})
      {:ok, %Server{}}

      iex> update_server(server, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_server(%Server{} = server, attrs) do
    server
    |> Server.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a server.

  ## Examples

      iex> delete_server(server)
      {:ok, %Server{}}

      iex> delete_server(server)
      {:error, %Ecto.Changeset{}}

  """
  def delete_server(%Server{} = server) do
    Repo.delete(server)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking server changes.

  ## Examples

      iex> change_server(server)
      %Ecto.Changeset{data: %Server{}}

  """
  def change_server(%Server{} = server, attrs \\ %{}) do
    Server.changeset(server, attrs)
  end

  # Server membership functions

  @doc """
  Checks if a user is an admin of a server.

  ## Examples

      iex> is_server_admin?(server_id, user_id)
      true

      iex> is_server_admin?(server_id, non_admin_user_id)
      false

  """
  def is_server_admin?(server_id, user_id) do
    ServerUser
    |> where([su], su.server_id == ^server_id and su.user_id == ^user_id and su.role == "admin")
    |> Repo.exists?()
  end

  @doc """
  Checks if a user is a member of a server.

  ## Examples

      iex> is_server_member?(server_id, user_id)
      true

      iex> is_server_member?(server_id, non_member_user_id)
      false

  """
  def is_server_member?(server_id, user_id) do
    ServerUser
    |> where([su], su.server_id == ^server_id and su.user_id == ^user_id)
    |> Repo.exists?()
  end

  @doc """
  Adds a user to a server with the specified role.

  ## Examples

      iex> add_user_to_server(server_id, user_id, "member")
      {:ok, %ServerUser{}}

      iex> add_user_to_server(server_id, user_id, "invalid_role")
      {:error, %Ecto.Changeset{}}

  """
  def add_user_to_server(server_id, user_id, role \\ "member") do
    %ServerUser{}
    |> ServerUser.changeset(%{server_id: server_id, user_id: user_id, role: role})
    |> Repo.insert()
  end

  @doc """
  Removes a user from a server.

  ## Examples

      iex> remove_user_from_server(server_id, user_id)
      {:ok, %ServerUser{}}

      iex> remove_user_from_server(non_existent_server_id, user_id)
      {:error, :not_found}

  """
  def remove_user_from_server(server_id, user_id) do
    case Repo.get_by(ServerUser, server_id: server_id, user_id: user_id) do
      nil -> {:error, :not_found}
      server_user -> Repo.delete(server_user)
    end
  end

  @doc """
  Gets all members of a server with their roles.

  ## Examples

      iex> list_server_members(server_id)
      [%ServerUser{}, ...]

  """
  def list_server_members(server_id) do
    ServerUser
    |> where([su], su.server_id == ^server_id)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Updates a user's role in a server.

  ## Examples

      iex> update_server_user_role(server_id, user_id, "admin")
      {:ok, %ServerUser{}}

      iex> update_server_user_role(server_id, user_id, "invalid_role")
      {:error, %Ecto.Changeset{}}

  """
  def update_server_user_role(server_id, user_id, role) do
    case Repo.get_by(ServerUser, server_id: server_id, user_id: user_id) do
      nil -> {:error, :not_found}
      server_user ->
        server_user
        |> ServerUser.changeset(%{role: role})
        |> Repo.update()
    end
  end

  # Channel functions

  @doc """
  Returns the list of channels for a server.

  ## Examples

      iex> list_channels_for_server(server_id)
      [%Channel{}, ...]

  """
  def list_channels_for_server(server_id) do
    Channel
    |> where([c], c.server_id == ^server_id)
    |> order_by([c], asc: c.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single channel.

  Raises `Ecto.NoResultsError` if the Channel does not exist.

  ## Examples

      iex> get_channel!(123)
      %Channel{}

      iex> get_channel!(456)
      ** (Ecto.NoResultsError)

  """
  def get_channel!(id), do: Repo.get!(Channel, id)

  @doc """
  Gets a single channel by id and server_id.

  Returns `nil` if the Channel does not exist.

  ## Examples

      iex> get_server_channel(server_id, channel_id)
      %Channel{}

      iex> get_server_channel(server_id, non_existent_id)
      nil

  """
  def get_server_channel(server_id, channel_id) do
    Channel
    |> where([c], c.server_id == ^server_id and c.id == ^channel_id)
    |> Repo.one()
  end

  @doc """
  Creates a channel for a server. Only server admins can create channels.

  ## Examples

      iex> create_channel_for_server(server_id, admin_user_id, %{name: "new-channel"})
      {:ok, %Channel{}}

      iex> create_channel_for_server(server_id, non_admin_user_id, %{name: "new-channel"})
      {:error, :not_authorized}

      iex> create_channel_for_server(server_id, admin_user_id, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  def create_channel_for_server(server_id, user_id, attrs) do
    if is_server_admin?(server_id, user_id) do
      %Channel{}
      |> Channel.changeset(Map.put(attrs, "server_id", server_id))
      |> Repo.insert()
    else
      {:error, :not_authorized}
    end
  end

  @doc """
  Updates a channel. Only server admins can update channels.

  ## Examples

      iex> update_channel(channel, admin_user_id, %{name: "updated-name"})
      {:ok, %Channel{}}

      iex> update_channel(channel, non_admin_user_id, %{name: "updated-name"})
      {:error, :not_authorized}

      iex> update_channel(channel, admin_user_id, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  def update_channel(%Channel{} = channel, user_id, attrs) do
    if is_server_admin?(channel.server_id, user_id) do
      channel
      |> Channel.changeset(attrs)
      |> Repo.update()
    else
      {:error, :not_authorized}
    end
  end

  @doc """
  Deletes a channel. Only server admins can delete channels.
  The "general" channel cannot be deleted.

  ## Examples

      iex> delete_channel(channel, admin_user_id)
      {:ok, %Channel{}}

      iex> delete_channel(channel, non_admin_user_id)
      {:error, :not_authorized}

      iex> delete_channel(general_channel, admin_user_id)
      {:error, :cannot_delete_general}

  """
  def delete_channel(%Channel{} = channel, user_id) do
    cond do
      !is_server_admin?(channel.server_id, user_id) ->
        {:error, :not_authorized}
      channel.name == "general" ->
        {:error, :cannot_delete_general}
      true ->
        Repo.delete(channel)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking channel changes.

  ## Examples

      iex> change_channel(channel)
      %Ecto.Changeset{data: %Channel{}}

  """
  def change_channel(%Channel{} = channel, attrs \\ %{}) do
    Channel.changeset(channel, attrs)
  end
end