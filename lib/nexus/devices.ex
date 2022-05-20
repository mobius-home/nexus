defmodule Nexus.Devices do
  @moduledoc """
  API for working with devices
  """

  import Ecto.Query

  alias Nexus.{DataSeries, Influx, Repo}
  alias Nexus.Devices.{Device, DeviceToken}
  alias Nexus.Products.ProductSettings

  @type get_data_opt() :: {:resolution, :hour | :day | :week | :month}

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
        ]) :: {:ok, [DataSeries.t()]} | {:error, term()}
  def get_measurement_data(device, bucket_name, measurement, field, opts \\ []) do
    {past, every} = get_resolution(opts)

    Influx.get_device_dataseries(device, bucket_name, measurement, field,
      start: past,
      aggregate_interval: every
    )
  end

  defp get_resolution(opts) do
    case opts[:resolution] do
      :hour ->
        {"-1h", "1m"}

      :day ->
        {"-24h", "1h"}

      :week ->
        {"-7d", "1h"}

      :month ->
        {"-1m", "1h"}
    end
  end

  @doc """
  Get the device's token
  """
  @spec get_token(Device.t()) :: DeviceToken.t()
  def get_token(device) do
    query =
      from dt in DeviceToken,
        join: u in assoc(dt, :user),
        where: u.id == dt.user_id,
        where: dt.device_id == ^device.id,
        preload: [user: u]

    Repo.one(query)
  end

  @doc """
  Delete the token for the device
  """
  @spec delete_token(Device.t()) :: :ok
  def delete_token(device) do
    query = from dt in DeviceToken, where: dt.device_id == ^device.id

    _ = Repo.delete_all(query)

    :ok
  end

  def import_metrics() do
    :ok
  end
end
