defmodule Nexus.Repo.Migrations.CreateProductSettingsTable do
  use Ecto.Migration

  def change do
    create table("product_settings") do
      add :bucket_name, :string
      add :bucket_id, :string
      add :product_id, references("products"), null: false

      timestamps()
    end
  end
end
