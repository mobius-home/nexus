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
        Buckets.create(client, bucket_name)
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
          |> tap(fn f -> IO.inspect(to_string(f)) end)
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

  # @doc """
  # Start the InfluxServer
  # """
  # @spec start_link(keyword()) :: GenServer.on_start()
  # def start_link(args) do
  #   GenServer.start_link(__MODULE__, args, name: __MODULE__)
  # end

  # @doc """
  # Create a bucket
  # """
  # @spec create_bucket(binary()) ::
  #         {:ok, Bucket.t()} | {:error, InfluxEx.error()}
  # def create_bucket(bucket_name) do
  #   GenServer.call(__MODULE__, {:create_bucket, bucket_name})
  # end

  # @doc """
  # Delete a bucket
  # """
  # @spec delete_bucket(binary()) :: :ok | {:error, InfluxEx.error()}
  # def delete_bucket(bucket_id) do
  #   GenServer.call(__MODULE__, {:delete_bucket, bucket_id})
  # end

  # @doc """
  # Get information about the bucket schema
  # """
  # @spec schema_info(binary(), schema_info_type()) :: {:ok, [binary()]}
  # def schema_info(bucket, info_type) do
  #   GenServer.call(__MODULE__, {:schema_info, bucket, info_type})
  # end

  # @doc """
  # Write a list of data points (a series) to the server
  # """
  # @spec write_points(binary(), [Point.t()]) :: :ok | {:error, binary()}
  # def write_points(bucket, points) do
  #   GenServer.call(__MODULE__, {:write_points, bucket, points})
  # end

  # @doc """
  # """
  # def get_measurement_data_by_device_serial(device_serial, bucket, opts \\ []) do
  #   GenServer.call(__MODULE__, {:get_measurement_data_by_device_serial, bucket, opts})
  # end

  # @impl GenServer
  # def init(args) do
  #   # required args
  #   token = Keyword.fetch!(args, :token)
  #   org = Keyword.fetch!(args, :org)

  #   # optional args
  #   port = Keyword.get(args, :port) || 8086
  #   host = Keyword.get(args, :host) || "http://localhost"

  #   client = Client.new(token, port: port, host: host, org: org)

  #   case InfluxEx.orgs(client, org: org) do
  #     {:ok, %{orgs: [org]}} ->
  #       client = %{client | org_id: org.id}
  #       {:ok, %{client: client}}

  #     {:error, reason} ->
  #       {:stop, reason}
  #   end
  # end

  # @impl GenServer
  # def handle_call({:create_bucket, bucket}, _from, state) do
  #   case InfluxEx.create_bucket(state.client, bucket) do
  #     {:ok, bucket} ->
  #       {:reply, {:ok, bucket}, state}

  #     error ->
  #       {:reply, error, state}
  #   end
  # end

  # def handle_call({:delete_bucket, bucket_id}, _from, state) do
  #   case InfluxEx.delete_bucket(state.client, bucket_id) do
  #     :ok ->
  #       {:reply, :ok, state}

  #     error ->
  #       {:reply, error, state}
  #   end
  # end

  # def handle_call({:schema_info, bucket, :measurements}, _from, state) do
  #   result = SchemaInfo.get_measurements(state.client, bucket)

  #   {:reply, result, state}
  # end

  # def handle_call({:schema_info, bucket, {:fields, measurement}}, _from, state) do
  #   result = SchemaInfo.get_measurement_field_keys(state.client, bucket, measurement)

  #   {:reply, result, state}
  # end

  # def handle_call({:write_points, bucket, points}, _from, state) do
  #   # don't hardcode precision
  #   result = InfluxEx.write(state.client, bucket, points, precision: :second)
  #   {:reply, result, state}
  # end

  # def handle_call({:query, query}, _from, state) do
  #   {:ok, tables} = InfluxEx.query(state.client, query)

  #   {:reply, DataSeries.from_influx_tables(tables), state}
  # end
end
