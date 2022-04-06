defmodule Nexus.Repo.Migrations.CreateProductsTable do
  use Ecto.Migration

  def change() do
    create table("products") do
      add :name, :string, size: 50, null: false
      add :slug, :string, size: 75, null: false
      add :data_schema, :string, size: 100, null: false

      timestamps()
    end

    create unique_index("products", [:name, :slug, :data_schema])
    create index("products", [:slug])
  end
end
