defmodule DiscordClone.Servers.ServerUser do
  use Ecto.Schema
  import Ecto.Changeset

  @roles ["admin", "member"]

  schema "server_users" do
    field :role, :string, default: "member"
    belongs_to :server, DiscordClone.Servers.Server
    belongs_to :user, DiscordClone.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(server_user, attrs) do
    server_user
    |> cast(attrs, [:role, :server_id, :user_id])
    |> validate_required([:role, :server_id, :user_id])
    |> validate_inclusion(:role, @roles)
    |> unique_constraint([:server_id, :user_id])
    |> foreign_key_constraint(:server_id)
    |> foreign_key_constraint(:user_id)
  end

  def roles, do: @roles
end