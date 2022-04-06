defmodule Nexus.Repo.Migrations.CreateProductTriggers do
  use Ecto.Migration

  def up() do
    query = """
    CREATE OR REPLACE FUNCTION _nexus_catalog.new_product_added_trigger()
      RETURNS trigger
    AS $func$
    BEGIN

      -- create the data schema for the product
      EXECUTE format($$
        CREATE SCHEMA %I
      $$, NEW.data_schema);

      -- partition devices table for product
      -- partition devices with name for the product's data schema
      -- this might seem silly, but the data_schema field should be a safe
      -- and valid name for the database and unique.
      EXECUTE format($$
        CREATE TABLE devices_%I
        PARTITION OF devices FOR VALUES IN (%L)
      $$, NEW.data_schema, NEW.id);

      RETURN NEW;
    END
    $func$
    LANGUAGE PLPGSQL VOLATILE;
    """

    execute query
  end

  def down() do
    execute "DROP FUNCTION _nexus_catalog.new_product_added_trigger"
  end
end
