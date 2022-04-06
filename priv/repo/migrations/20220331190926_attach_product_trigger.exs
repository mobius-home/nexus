defmodule Nexus.Repo.Migrations.AttachProductTrigger do
  use Ecto.Migration

  def up() do
    query = """
    CREATE TRIGGER new_product_added
    AFTER INSERT ON products
    FOR EACH ROW
    EXECUTE PROCEDURE _nexus_catalog.new_product_added_trigger();
    """

    execute query
  end

  def down() do
    execute "DROP TRIGGER IF EXISTS new_product_added ON products CASCADE"
  end
end
