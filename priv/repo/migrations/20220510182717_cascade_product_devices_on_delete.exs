defmodule Nexus.Repo.Migrations.CascadeProductDevicesOnDelete do
  use Ecto.Migration

  def change do
    alter table("devices") do
      modify :product_id, references("products", on_delete: :delete_all),
        null: false,
        from: references("products")
    end
  end
end
