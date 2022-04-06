defmodule NexusWeb.DeviceMetricController do
  @moduledoc """
  Controller that handles individual metrics for a device
  """

  use NexusWeb, :controller

  alias Ecto.Changeset
  alias Nexus.Products
  alias NexusWeb.RequestParams
  alias NexusWeb.RequestParams.DeviceMetricUploadParams

  alias VegaLite, as: Vl

  plug NexusWeb.Plugs.GetDeviceMetric when action in [:show]

  def show(%{assigns: %{metric: metric, device: device, product: product}} = conn, _params) do
    measurements = Products.query_measurements_for_device(product, metric, device)
    graph = make_vega_lite_graph(measurements)

    render(conn, "show.html", metric: metric, measurements: measurements, graph: graph)
  end

  ##### Complete hack for now, will do better soon
  def make_vega_lite_graph(data) do
    data =
      Enum.map(data, fn data ->
        data
        |> Map.from_struct()
        |> Map.put(:time, DateTime.to_string(data.time))
        |> Map.put(:tags, Jason.encode!(data.tags))
      end)

    Vl.new(width: 800, height: 400)
    |> Vl.data_from_values(data)
    |> Vl.mark(:line)
    |> Vl.encode_field(:x, "time", type: :temporal)
    |> Vl.encode_field(:y, "value", type: :quantitative)
    |> Vl.encode_field(:color, "tags", type: :nominal)
    |> Vl.Export.to_json()
  end

  def new_upload(%{assigns: %{product: product, device: device}} = conn, _params) do
    changeset = Products.upload_changeset()
    render(conn, "upload.html", changeset: changeset, product: product, device: device)
  end

  def upload(%{assigns: %{device: device, product: product}} = conn, params) do
    # probably should refactor this a bit at some point
    with {:ok, params} <- RequestParams.bind(%DeviceMetricUploadParams{}, params),
         :ok <- File.cp(params.source, params.target),
         :ok <- Products.import_upload(product, device, params.target) do
      conn
      |> put_flash(:info, "Import successful!")
      |> redirect(to: Routes.product_device_path(conn, :show, product.slug, device.slug))
    else
      {:error, %Changeset{} = changeset} ->
        IO.inspect(changeset)

        conn
        |> put_flash(:error, "Import failed")
        |> render("upload.html", changeset: changeset, product: product, device: device)

      {:error, _posix} ->
        conn
        |> put_status(500)
        |> halt()
    end
  end
end
