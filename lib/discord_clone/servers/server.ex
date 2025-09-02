defmodule DiscordClone.Servers.Server do
  use Ecto.Schema
  import Ecto.Changeset

  schema "servers" do
    field :name, :string
    belongs_to :user, DiscordClone.Accounts.User
    
    has_many :server_users, DiscordClone.Servers.ServerUser
    has_many :channels, DiscordClone.Servers.Channel
    many_to_many :users, DiscordClone.Accounts.User, join_through: "server_users"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(server, attrs) do
    server
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> validate_length(:name, min: 1, max: 100)
    |> foreign_key_constraint(:user_id)
  end
end