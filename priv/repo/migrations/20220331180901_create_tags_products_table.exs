defmodule Nexus.Repo.Migrations.CreateTagsProductsTable do
  use Ecto.Migration

  def change() do
    create table("tags_products", primary_key: false) do
      add :tag_id, references("tags"), null: false
      add :product_id, references("products"), null: false
    end
  end
end
