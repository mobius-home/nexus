defmodule Nexus.Repo.Migrations.TagHelperJsonbFunction do
  use Ecto.Migration

  def up() do
    q1 = """
    CREATE OR REPLACE FUNCTION _nexus_catalog.tag_unnest(tag_array anyarray)
    RETURNS SETOF anyelement
    LANGUAGE SQL
    IMMUTABLE PARALLEL SAFE STRICT ROWS 10
    AS $$ SELECT unnest(tag_array) $$;
    """

    q2 = """
    CREATE OR REPLACE FUNCTION _nexus_catalog.tags_info(INOUT tags BIGINT[], OUT keys TEXT[], OUT vals TEXT[])
    AS $func$
      SELECT ARRAY_AGG(t.id), ARRAY_AGG(t.key), ARRAY_AGG(t.value)
      FROM
        _nexus_catalog.tag_unnest(tags) tag_id
        INNER JOIN tags t on (t.id = tag_id);
    $func$
    LANGUAGE SQL STABLE PARALLEL SAFE;
    """

    q3 = """
    CREATE OR REPLACE FUNCTION _nexus_catalog.key_value_array(tags BIGINT[], OUT keys TEXT[], OUT vals TEXT[])
    AS $func$
      SELECT keys, vals FROM _nexus_catalog.tags_info(tags);
    $func$
    LANGUAGE SQL STABLE PARALLEL SAFE;
    """

    q4 = """
    CREATE OR REPLACE FUNCTION jsonb(tags BIGINT[])
    RETURNS jsonb
    AS $func$
      SELECT
        jsonb_object(keys, vals)
      FROM
        _nexus_catalog.key_value_array(tags);
    $func$
    LANGUAGE SQL STABLE PARALLEL SAFE;
    """

    for q <- [q1, q2, q3, q4] do
      execute q
    end
  end

  def down() do
    query = """
    DROP FUNCTION IF EXISTS jsonb(tags BIGINT[])
    DROP FUNCTION IF EXISTS key_value_array(tags BIGINT[], OUT keys TEXT[], OUT vals TEXT[]);
    DROP FUNCTION IF EXISTS tags_info(INOUT tags BIGINT[], OUT keys TEXT[], OUT vals TEXT[]);
    DROP FUNCTION IF EXISTS tag_unset(tag_array anyarray);
    """

    queries = String.split(query, ";", trim: true) |> Enum.drop(-1)

    for q <- queries do
      execute q
    end
  end
end
