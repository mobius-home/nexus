defmodule Nexus.Repo.Migrations.CreateDeviceTokenTable do
  use Ecto.Migration

  def change do
    create table("device_tokens") do
      add :token, :string, null: false
      add :device_id, :integer, null: false
      add :user_id, references("users"), null: false
      add :last_used, :naive_datetime

      timestamps([:inserted_at])
    end
  end
end
