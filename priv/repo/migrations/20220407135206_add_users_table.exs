defmodule Nexus.Repo.Migrations.AddUsersTable do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table("user_roles") do
      add :name, :string, null: false
    end

    create unique_index("user_roles", [:name])

    create table("users") do
      add :email, :citext, null: false
      add :role_id, references("user_roles"), null: false
      add :first_name, :string, null: false
      add :last_name, :string, null: false

      timestamps()
    end

    create unique_index("users", [:email])
  end
end
