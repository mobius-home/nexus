defmodule Nexus.Repo.Migrations.CreateDevicesTable do
  use Ecto.Migration

  def change() do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table("devices") do
      add :serial_number, :citext, null: false
      add :product_id, references("products"), null: false

      timestamps()
    end

    create index("devices", [:serial_number])
    create unique_index("devices", [:product_id, :serial_number])
  end
end
