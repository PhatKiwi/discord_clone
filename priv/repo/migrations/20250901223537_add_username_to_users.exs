defmodule DiscordClone.Repo.Migrations.AddUsernameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :string
    end

    # Update existing users with a default username based on email
    execute "UPDATE users SET username = SPLIT_PART(email, '@', 1) WHERE username IS NULL"
    
    # Now make the field not null
    alter table(:users) do
      modify :username, :string, null: false
    end

    create unique_index(:users, [:username])
  end
end
