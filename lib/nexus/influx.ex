defmodule Nexus.Influx do
  @moduledoc false

  # Client for working with InfluxDB via InfluxEx

  alias InfluxEx.{Bucket, Buckets, Client, Flux, GenData}
  alias Nexus.{DataSeries, Device}

  @type opt() ::
          {:port, :inet.port_number()}
          | {:token, InfluxEx.token()}
          | {:org, InfluxEx.org_name()}
          | {:org_id, InfluxEx.org_id()}

  @type device_query_opt() ::
          {:start, pos_integer()}
          | {:end, pos_integer()}
          | {:aggregate_interval, binary()}
          | opt()

  @doc """
  Create a bucket in InfluxDB
  """
  @spec create_bucket(Bucket.name(), [opt()]) ::
          {:ok, Bucket.t()} | {:error, InfluxEx.error()}
  def create_bucket(bucket_name, opts \\ []) do
    with_client(
      fn client ->
        Buckets.create(client, bucket_name, expires_in: {30, :days})
      end,
      opts
    )
  end

  @doc """
  Delete a bucket
  """
  @spec delete_bucket(Bucket.id(), [opt()]) :: :ok | {:error, InfluxEx.error()}
  def delete_bucket(bucket_id, opts \\ []) do
    with_client(
      fn client ->
        Buckets.delete(client, bucket_id)
      end,
      opts
    )
  end

  @doc """
  Get measurements in a bucket
  """
  @spec get_bucket_measurements(Bucket.name(), [opt()]) ::
          {:ok, [binary()]} | {:error, InfluxEx.error()}
  def get_bucket_measurements(bucket_name, opts \\ []) do
    with_client(
      fn client ->
        Buckets.get_measurements(client, bucket_name)
      end,
      opts
    )
  end

  @doc """
  Get field keys for a measurement
  """
  @spec get_measurement_fields(Bucket.name(), binary(), [opt()]) ::
          {:ok, [binary()]} | {:error, Influx.error()}
  def get_measurement_fields(bucket, measurement, opts \\ []) do
    with_client(
      fn client ->
        Buckets.get_measurement_field_keys(client, bucket, measurement)
      end,
      opts
    )
  end

  @doc """
  Create dummy VM metric data tagged with `"device_serial"`

  This will generate data for the past 5 minutes.
  """
  @spec create_dummy_vm_data(Device.t(), Bucket.name(), [opt()]) ::
          :ok | {:error, InfluxEx.error()}
  def create_dummy_vm_data(device, bucket_name, opts \\ []) do
    points = GenData.generate_vm_memory_metrics(tags: [%{device_serial: device.serial_number}])

    with_client(
      fn client ->
        InfluxEx.write(client, bucket_name, points, precision: :second)
      end,
      opts
    )
  end

  @doc """
  Get a data series for measurement and field by device serial number
  """
  @spec get_device_dataseries(Device.t(), ProductSettings.bucket_name(), binary(), binary(), [
          device_query_opt()
        ]) :: {:ok, [DataSeries.t()]} | {:error, term()}
  def get_device_dataseries(device, bucket_name, measurement, field, opts \\ []) do
    {start, stop} = get_query_window(opts)
    aggregate_interval = opts[:aggregate_interval] || "1m"

    with_client(
      fn client ->
        result =
          Flux.from(bucket_name)
          |> Flux.range(start, stop)
          |> Flux.measurement(measurement)
          |> Flux.field(field)
          |> Flux.tag("device_serial", device.serial_number)
          |> Flux.aggregate_window(aggregate_interval, create_empty: true)
          |> Flux.fill_value_previous()
          |> Flux.run_query(client)

        case result do
          {:ok, tables} ->
            {:ok, DataSeries.from_influx_tables(tables)}

          error ->
            error
        end
      end,
      opts
    )
  end

  defp get_query_window(opts) do
    start = opts[:start]
    stop = opts[:end]

    if stop - start == 0 do
      {start, nil}
    else
      {start, stop}
    end
  end

  def write_points(bucket, points, opts \\ []) do
    with_client(
      fn client ->
        InfluxEx.write(client, bucket, points, opts)
      end,
      opts
    )
  end

  defp with_client(func, opts) do
    client = new_client(opts)

    func.(client)
  end

  defp new_client(_opts) do
    config = Application.get_env(:nexus, :influx)
    token = Keyword.fetch!(config, :token)

    client_opts = Keyword.take(config, [:port, :host, :org, :org_id])

    Client.new(token, client_opts)
  end
end
