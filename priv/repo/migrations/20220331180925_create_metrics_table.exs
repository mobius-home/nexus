defmodule Nexus.Repo.Migrations.CreateMetricsTable do
  use Ecto.Migration

  def up() do
    query = """
    CREATE TABLE metrics (
      id BIGSERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      slug VARCHAR(200) NOT NULL,
      type VARCHAR(20) NOT NULL,
      table_name NAME NOT NULL,
      product_id INTEGER REFERENCES products NOT NULL,
      updated_at TIMESTAMP NOT NULL,
      inserted_at TIMESTAMP NOT NULL
    )
    """

    execute query

    create unique_index("metrics", [:product_id, :name, :type, :table_name])
    create unique_index("metrics", [:name, :slug])
  end

  def down() do
    drop table("metrics")
  end
end
