defmodule Nexus.Repo.Migrations.DropDeviceTokensTable do
  use Ecto.Migration

  def up() do
    drop table("device_tokens")
  end

  def down() do
    create table("device_tokens") do
      add :token, :string, null: false
      add :device_id, references("devices"), null: false
      add :user_id, references("users"), null: false
      add :last_used, :naive_datetime

      timestamps([:inserted_at])
    end
  end
end
