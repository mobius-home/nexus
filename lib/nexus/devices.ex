defmodule Nexus.Devices do
  @moduledoc """
  API for working with devices
  """

  import Ecto.Query

  alias Nexus.{DataSeries, Influx, Repo}
  alias Nexus.Devices.Device
  alias Nexus.Products.ProductSettings

  @type get_data_opt() ::
          {:resolution, :hour | :day | :week | :month} | {:window, {pos_integer(), pos_integer()}}

  @type get_devices_opt() :: {:product_id, pos_integer()}

  @doc """
  Get a device by it's serial number
  """
  @spec get_device_by_serial_number(Device.serial_number()) :: Device.t() | nil
  def get_device_by_serial_number(serial_number) do
    Repo.get_by(Device, serial_number: serial_number)
  end

  @doc """
  Get devices

  To limit devices to specific product pass the `:product_id` option.

  ```elixir
  Nexus.Devices.get_devices(product_id: 1)
  ```
  """
  @spec get_devices([get_devices_opt()]) :: [Device.t()]
  def get_devices(opts \\ []) do
    from(d in Device)
    |> maybe_for_product(opts)
    |> Repo.all()
  end

  defp maybe_for_product(query, opts) do
    case opts[:product_id] do
      nil ->
        query

      product_id ->
        where(query, [d], d.product_id == ^product_id)
    end
  end

  @doc """
  Create 5 minutes worth of dummy VM metric data for a device
  """
  @spec create_dummy_data_for_device(Device.t(), ProductSettings.bucket_name()) ::
          :ok | {:error, term()}
  def create_dummy_data_for_device(device, bucket_name) do
    Influx.create_dummy_vm_data(device, bucket_name)
  end

  @doc """
  Get a `Nexus.DataSeries.t()` for a measure for  a device
  """
  @spec get_measurement_data(Device.t(), ProductSettings.bucket_name(), binary(), binary(), [
          get_data_opt()
        ]) :: {:ok, DataSeries.t()} | {:error, term()}
  def get_measurement_data(device, bucket_name, measurement, field, opts \\ []) do
    {start_ts, end_ts} = opts[:window]
    every = get_resolution(opts)

    Influx.get_device_dataseries(device, bucket_name, measurement, field,
      start: start_ts,
      end: end_ts,
      aggregate_interval: every
    )
  end

  defp get_resolution(opts) do
    case opts[:resolution] do
      :minute ->
        "1m"

      :hour ->
        "1h"

      :day ->
        "1d"
    end
  end

  @doc """
  Import metrics for a device

  Nexus has first class for the Mobius Binary Format produced by the the
  `:mobius` library.
  """
  @spec import_metrics(Device.t(), Path.t() | binary(), Product.t(), keyword()) :: :ok
  def import_metrics(device, path_or_data, product, opts \\ []) do
    import_type = opts[:type] || :mbf_file
    mbf = get_mbf(import_type, path_or_data)

    {:ok, data} = Mobius.Exports.parse_mbf(mbf)

    Nexus.DataImport.run(product.product_settings.bucket_name, data, %{
      device_serial: device.serial_number
    })

    broadcast_device_metrics_uploaded(device.serial_number, product.slug)

    :ok
  end

  def broadcast_device_metrics_uploaded(device_serial, product_slug) do
    Phoenix.PubSub.broadcast(Nexus.PubSub, "#{product_slug}:#{device_serial}", :new_metrics)
  end

  def subscribe_device_metrics_uploaded(device_serial, product_slug) do
    Phoenix.PubSub.subscribe(Nexus.PubSub, "#{product_slug}:#{device_serial}")
  end

  defp get_mbf(:mbf_file, location) do
    File.read!(location)
  end

  defp get_mbf(:mbf_binary, binary) do
    binary
  end
end
