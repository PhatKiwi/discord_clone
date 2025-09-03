defmodule DiscordClone.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :content, :string
    belongs_to :user, DiscordClone.Accounts.User
    belongs_to :channel, DiscordClone.Servers.Channel

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :user_id, :channel_id])
    |> validate_required([:content, :user_id, :channel_id])
    |> validate_length(:content, min: 1, max: 2000)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:channel_id)
  end
end
