defmodule Nexus.DataSeries do
  @moduledoc """

  """

  @type dataset() :: %{
          label: binary(),
          data: [number()]
        }

  @type t() :: %__MODULE__{
          labels: [binary()],
          datasets: [dataset()]
        }

  defstruct labels: [], datasets: []

  def empty() do
    %__MODULE__{}
  end

  @doc """
  Check if the DataSeries is empty
  """
  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{labels: [], datasets: []}) do
    true
  end

  def empty?(%__MODULE__{}), do: false

  @doc """
  Transform an `InfluxEx.tables()` data structure into a Nexus data series for
  better use within Nexus
  """
  @spec from_influx_tables(InfluxEx.tables()) :: t()
  def from_influx_tables(influx_tables) when map_size(influx_tables) == 0 do
    %__MODULE__{}
  end

  def from_influx_tables(influx_tables) do
    datasets =
      Enum.reduce(influx_tables, [], fn {table_num, rows}, ds ->
        values = Enum.map(rows, fn row -> row.value end)
        dataset = %{label: table_num, data: values}
        ds ++ [dataset]
      end)

    %__MODULE__{labels: get_labels(influx_tables), datasets: datasets}
  end

  defp get_labels(table) do
    [first_table | _] = Map.keys(table)

    Enum.map(table[first_table], fn r ->
      r.time
    end)
  end
end
