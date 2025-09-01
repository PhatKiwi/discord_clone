defmodule DiscordClone.Repo.Migrations.CreateServerUsers do
  use Ecto.Migration

  def change do
    create table(:server_users) do
      add :server_id, references(:servers, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :role, :string, default: "member", null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:server_users, [:server_id, :user_id])
    create index(:server_users, [:server_id])
    create index(:server_users, [:user_id])

    # Add the server admin (creator) to the server_users table automatically
    execute """
    INSERT INTO server_users (server_id, user_id, role, inserted_at, updated_at)
    SELECT id, user_id, 'admin', now(), now() FROM servers
    """, ""
  end
end
