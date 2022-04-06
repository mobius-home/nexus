defmodule Nexus.Repo.Migrations.CreateNexusCatalogSchema do
  use Ecto.Migration

  def up() do
    query = """
    CREATE SCHEMA _nexus_catalog
    """

    execute query
  end

  def down() do
    execute "DROP SCHEMA _nexus_catalog"
  end
end
