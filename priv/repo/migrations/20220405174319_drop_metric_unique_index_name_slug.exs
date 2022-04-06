defmodule Nexus.Repo.Migrations.DropMetricUniqueIndexNameSlug do
  use Ecto.Migration

  def change() do
    drop unique_index("metrics", [:name, :slug])
  end
end
