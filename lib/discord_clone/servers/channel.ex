defmodule DiscordClone.Servers.Channel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "channels" do
    field :name, :string
    belongs_to :server, DiscordClone.Servers.Server

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:name, :server_id])
    |> validate_required([:name, :server_id])
    |> validate_length(:name, min: 1, max: 100)
    |> foreign_key_constraint(:server_id)
  end
end
