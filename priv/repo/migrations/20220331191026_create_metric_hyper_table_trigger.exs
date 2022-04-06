defmodule Nexus.Repo.Migrations.CreateMetricTableHyperTableTrigger do
  use Ecto.Migration

  def up() do
    query = """
    CREATE OR REPLACE FUNCTION _nexus_catalog.new_metric_make_hyper_table_trigger()
      RETURNS trigger
    AS $func$
    DECLARE
      product_schema NAME;
    BEGIN

      SELECT data_schema FROM products
      WHERE id = NEW.product_id
      INTO product_schema;

      EXECUTE format($$
        CREATE TABLE IF NOT EXISTS %I.%I (
          time TIMESTAMPTZ NOT NULL,
          value DOUBLE PRECISION NOT NULL,
          metric_id INTEGER REFERENCES metrics(id) NOT NULL,
          device_id INTEGER,
          tags INT[] NOT NULL
        )
      $$, product_schema, NEW.table_name);

      PERFORM public.create_hypertable(format('%I.%I', product_schema, NEW.table_name), 'time', if_not_exists => TRUE);

      EXECUTE format($$
        CREATE UNIQUE INDEX IF NOT EXISTS %2$I_time_metric_id_device_id_index
        ON %1$I.%2$I (time, metric_id, device_id) INCLUDE (value)
      $$, product_schema, NEW.table_name);

      raise notice 'Making device_id and time index %', format('%I.%I', product_schema, NEW.table_name);

      EXECUTE format($$
        CREATE INDEX IF NOT EXISTS %2$I_device_id_time_index
        ON %1$I.%2$I (device_id, time)
      $$, product_schema, NEW.table_name);

      raise notice 'Making reorder policy for %', format('%I.%I', product_schema, NEW.table_name);

      PERFORM add_reorder_policy(
        format('%I.%I', product_schema, NEW.table_name),
        format('%I_device_id_time_index', NEW.table_name),
        if_not_exists => TRUE);

      RETURN NEW;
    END
    $func$
    LANGUAGE PLPGSQL VOLATILE;
    """

    execute query
  end

  def down() do
    execute "DROP FUNCTION _nexus_catalog.new_metric_make_hyper_table_trigger"
  end
end
