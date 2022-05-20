defmodule Nexus.Repo.Migrations.CascadeProductSettingsOnDelete do
  use Ecto.Migration

  def change() do
    alter table("product_settings") do
      modify :product_id, references("products", on_delete: :delete_all),
        null: false,
        from: references("products")
    end
  end
end
