defmodule Nexus.Products.MetricImports do
  @moduledoc """
  A context for importing metric data into a product

  Currently the only important format supported is Mobius Binary format (MBF).


  Currently this will important only configured metrics for a product.

  ## Note

  This is currently very experimental and will be refactored in the
  future. This code is not optimized and is currently fragile. This will most
  likely move into to some type of job queuing system in the future.
  """

  require Logger

  alias Mobius.Exports
  alias Nexus.Products
  alias Nexus.Products.{Product, Device}

  @spec run_import_for_device(Product.t(), Device.t(), Path.t()) :: :ok | {:error, any()}
  def run_import_for_device(product, device, filename) do
    with {:ok, contents} <- read_file(filename),
         {:ok, parsed} <- Exports.parse_mbf(contents),
         prepared <- prepare_and_group(parsed, device),
         fully_prepared <- prepare_groups(product, prepared),
         tags_prepared <- prepare_tags(fully_prepared),
         tag_table <- insert_tags(tags_prepared),
         :ok <- run_insert(product, fully_prepared, tag_table) do
      :ok
    end
  end

  defp read_file(filename) do
    if Path.extname(filename) == ".mbf" do
      File.read(filename)
    else
      {:ok, :format_not_supported}
    end
  end

  defp prepare_and_group(import_measurements, device) do
    Enum.reduce(import_measurements, [], fn new, prepared ->
      case DateTime.from_unix(new.timestamp) do
        {:ok, dt} ->
          new_prepared =
            new
            |> Map.put(:type, Atom.to_string(new.type))
            |> Map.put(:device_id, device.id)
            |> Map.put(:time, dt)

          prepared ++ [new_prepared]

        error ->
          Logger.warn(
            "Dropping measurement, unable to parse timestamp due to error #{inspect(error)}: #{inspect(new)}"
          )

          prepared
      end
    end)
    |> Enum.group_by(fn %{name: name, type: type} -> {name, type} end)
  end

  defp prepare_groups(product, new_grouped) do
    Enum.reduce(new_grouped, %{}, fn {{m_name, m_type}, metrics}, updated ->
      case Products.get_metric_for_product_by_name_and_type(product, m_name, m_type) do
        nil ->
          Logger.warn(
            "Metric #{inspect(m_name)} #{inspect(m_type)} is not configured for product, dropping"
          )

          updated

        metric ->
          new_key = {m_name, m_type, metric.table_name}

          metrics =
            Enum.map(metrics, fn m ->
              Map.put(m, :metric_id, metric.id) |> Map.drop([:name, :timestamp, :type])
            end)

          Map.put(updated, new_key, metrics)
      end
    end)
  end

  def prepare_tags(grouped_metrics) do
    Enum.reduce(grouped_metrics, [], fn {_g, metrics}, tag_list ->
      new_tags = Enum.flat_map(metrics, &metric_tags_to_tag_list/1)
      tag_list ++ new_tags
    end)
    |> Enum.uniq()
  end

  def insert_tags(tag_list) do
    # refactor this
    tag_records =
      tag_list
      |> Enum.map(fn tag_map -> tag_map |> Map.put(:key, Atom.to_string(tag_map.key)) end)
      |> Products.create_many_tags()

    Enum.reduce(tag_records, %{}, fn tag, table ->
      Map.put(table, {String.to_existing_atom(tag.key), tag.value}, tag.id)
    end)
  end

  def run_insert(product, metric_group, tag_table) do
    Enum.each(metric_group, fn {{_n, _t, table}, metrics} ->
      metrics = transform_metric_tags(metrics, tag_table)

      Nexus.Repo.insert_all(table, metrics, on_conflict: :nothing, prefix: product.data_schema)
    end)
  end

  defp metric_tags_to_tag_list(metric) do
    Enum.reduce(metric.tags, [], fn {k, v}, tag_list ->
      tag_list ++ [%{key: k, value: v}]
    end)
  end

  defp transform_metric_tags(metrics, tag_table) do
    IO.inspect(tag_table)
    IO.inspect(metrics)

    Enum.map(metrics, fn metric ->
      tag_array =
        Enum.reduce(metric.tags, [], fn {key, value}, array ->
          case Map.get(tag_table, {key, value}) do
            nil ->
              array

            tag_id ->
              array ++ [tag_id]
          end
        end)

      Map.put(metric, :tags, tag_array)
    end)
  end
end
