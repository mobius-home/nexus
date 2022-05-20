defmodule Nexus.DataImport do
  @moduledoc false

  require Logger

  alias InfluxEx.Point
  alias Nexus.Influx

  @doc """
  Run a data import
  """
  @spec run(binary(), term(), map()) :: :ok
  def run(to, data, extra_tags) do
    points = to_points(data, extra_tags)

    case Influx.write_points(to, points, precision: :second) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warn("Error on data import to InfluxDB: #{inspect(reason)}")

        :ok
    end
  end

  def to_points(data, extra_tags) do
    data
    |> Enum.group_by(&group_by_name_timestamp_tags/1)
    |> Enum.reduce([], fn {{measurement, timestamp, tags}, metrics}, points ->
      tags = Map.merge(tags, extra_tags)
      point = make_point(measurement, timestamp, tags, metrics)
      points ++ [point]
    end)
    |> Enum.sort_by(fn point -> point.timestamp end)
  end

  defp group_by_name_timestamp_tags(record) do
    name = parse_measurement_name(record.name)

    {name, record.timestamp, record.tags}
  end

  defp make_point(measurement, timestamp, tags, metrics) do
    measurement
    |> Point.new(precision: :second, timestamp: timestamp)
    |> Point.add_fields(get_fields_from_metrics(metrics))
    |> Point.add_tags(tags)
  end

  defp get_fields_from_metrics(metrics) do
    Enum.reduce(metrics, %{}, fn metric, fields ->
      field_name = parse_field_name(metric.name)
      Map.put(fields, field_name, metric.value)
    end)
  end

  defp parse_field_name(name) do
    name
    |> String.split(".", trim: true)
    |> Enum.take(-1)
    |> hd()
  end

  defp parse_measurement_name(name) do
    name
    |> String.split(".", trim: true)
    |> Enum.drop(-1)
    |> Enum.join(".")
  end
end
