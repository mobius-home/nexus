defmodule Nexus.Repo.Migrations.CreateDevicesTable do
  use Ecto.Migration

  def up() do
    query = """
    CREATE TABLE devices (
      id BIGSERIAL,
      serial_number VARCHAR(100) NOT NULL,
      product_id INTEGER REFERENCES products NOT NULL,
      slug VARCHAR(150) NOT NULL,
      inserted_at TIMESTAMP NOT NULL,
      updated_at TIMESTAMP NOT NULL,
      CONSTRAINT pk_product_serial PRIMARY KEY (product_id, serial_number)
    ) PARTITION BY LIST (product_id)
    """

    execute query

    create index("devices", [:serial_number])
    create unique_index("devices", [:product_id, :serial_number, :slug])
  end

  def down() do
    execute "DROP TABLE devices"
  end
end
