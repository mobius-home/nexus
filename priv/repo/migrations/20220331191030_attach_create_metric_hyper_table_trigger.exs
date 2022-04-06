defmodule Nexus.Repo.Migrations.AttachMetricHyperTableTrigger do
  use Ecto.Migration

  def up() do
    query = """
    CREATE TRIGGER new_metric_added
    AFTER INSERT ON metrics
    FOR EACH ROW
    EXECUTE PROCEDURE _nexus_catalog.new_metric_make_hyper_table_trigger();
    """

    execute query
  end

  def down() do
    execute "DROP TRIGGER IF EXISTS new_metric_added ON metrics CASCADE"
  end
end
