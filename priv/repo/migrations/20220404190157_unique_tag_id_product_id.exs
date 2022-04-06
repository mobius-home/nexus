defmodule Nexus.Repo.Migrations.UniqueTagIdProductId do
  use Ecto.Migration

  def change do
    create unique_index("tags_products", [:tag_id, :product_id])
  end
end
