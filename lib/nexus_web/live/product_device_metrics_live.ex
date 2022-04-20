defmodule NexusWeb.ProductDeviceMetricsLive do
  @moduledoc """
  Live view for looking at a metric for a device
  """

  # This needs to be improved a little but gets the job done for now
  use NexusWeb, :surface_view

  alias Nexus.Products
  alias NexusWeb.Params
  alias NexusWeb.Components.{DeviceViewContainer, Modal}
  alias Surface.Components.{Form, LiveFileInput}
  alias Surface.Components.Form.{Select, Submit}

  on_mount NexusWeb.UserLiveAuth
  on_mount {NexusWeb.GetResourceLive, [:product, :device, :product_metrics]}

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:selected_metric, nil)
      |> assign(:selected_metric_type, nil)
      |> assign(:measurements, [])
      |> allow_upload(:metrics, accept: ~w(.mbf .json), max_entries: 1)

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    schema = [
      metric_name: %{type: :string},
      metric_type: %{type: :string}
    ]

    case Params.normalize(schema, params) do
      {:ok, normalized_params} ->
        socket = maybe_fetch_measurements(normalized_params, socket)

        {:noreply, socket}
    end
  end

  defp maybe_fetch_measurements(%{metric_name: metric_name, metric_type: metric_type}, socket) do
    metric =
      Enum.find(socket.assigns.metrics, fn metric ->
        metric.name == metric_name && metric.type == metric_type
      end)

    case metric do
      nil ->
        socket

      metric ->
        measurements =
          Products.query_measurements_for_device(
            socket.assigns.product,
            metric,
            socket.assigns.device
          )

        socket
        |> assign(:selected_metric, metric_name)
        |> assign(:selected_metric_type, metric_type)
        |> assign(:measurements, measurements)
    end
  end

  defp maybe_fetch_measurements(_params, socket) do
    socket
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("upload_metrics", _params, socket) do
    consume_uploaded_entries(socket, :metrics, fn %{path: path}, _entry ->
      :ok = Products.import_upload(socket.assigns.product, socket.assigns.device, path)

      {:ok, :done}
    end)

    {:noreply,
     push_patch(socket,
       to:
         Routes.live_path(
           socket,
           __MODULE__,
           socket.assigns.product.slug,
           socket.assigns.product.device.slug
         )
     )}
  end

  def handle_event("selected_metric", %{"metric_select" => params}, socket) do
    schema = %{metric_name: :string}

    case Params.normalize(schema, params) do
      {:ok, normalized} ->
        [name, type] = String.split(normalized.metric_name, "-")

        {:noreply,
         push_patch(socket,
           to:
             Routes.live_path(
               socket,
               __MODULE__,
               socket.assigns.product.slug,
               socket.assigns.device.slug,
               metric_name: name,
               metric_type: type
             )
         )}
    end
  end

  def render(assigns) do
    ~F"""
    <DeviceViewContainer
      socket={@socket}
      device={@device}
      product_slug={@product.slug}
      product_name={@product.name}
      page={:metrics}
      modal_button_label="Upload metrics"
      modal_button_to={Routes.product_device_metrics_path(@socket, :metric_upload, @product.slug, @device.slug)}
    >
      <div class="flex justify-end mb-10">
        <Form for={:metric_select} change="selected_metric">
          <div class="relative text-gray-700">
            <Select
              field="metric_name"
              options={metrics_as_options(@metrics)}
              prompt="Please select a metric"
              selected={get_selected(@selected_metric, @selected_metric_type)}
              class="border border-gray-300 rounded px-4 py-2 text-base font-normal appearance-none"
            />
            <div class="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none">
              <svg class="w-4 h-4 fill-current" viewBox="0 0 20 20"><path
                  d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
                  clip-rule="evenodd"
                  fill-rule="evenodd"
                /></svg>
            </div>
          </div>
        </Form>

        <Form for={:time_window} change="update_time_window" class="ml-8">
          <div class="relative text-gray-700">
            <Select
              field="time_window"
              options={["Last hour", "Last 24 hours", "Last 7 days", "Last 30 days"]}
              class="border border-gray-300 rounded px-4 py-2 text-base font-normal appearance-none"
            />
            <div class="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none">
              <svg class="w-4 h-4 fill-current" viewBox="0 0 20 20"><path
                  d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
                  clip-rule="evenodd"
                  fill-rule="evenodd"
                /></svg>
            </div>
          </div>
        </Form>
      </div>

      <canvas id="chart" phx-hook="MetricChart" data-measurements={prepare_measurements(@measurements)}>
      </canvas>

      {#if @live_action == :metric_upload}
        <Modal
          title="New Device"
          return_to={Routes.live_path(@socket, __MODULE__, @product.slug, @device.slug)}
          id={:modal}
        >
          <Form for={:metric_upload} submit="upload_metrics" class="mt-12" errors={[]} change="validate">
            <LiveFileInput upload={@uploads.metrics} />

            <div class="pt-6 flex justify-end">
              <Submit
                label="Add"
                class="bg-violet-600 text-white pt-1 pb-1 pl-5 pr-5 rounded font-light hover:bg-violet-700"
              />
            </div>
          </Form>
        </Modal>
      {/if}
    </DeviceViewContainer>
    """
  end

  defp metrics_as_options(metrics) do
    Enum.map(metrics, fn metric ->
      "#{metric.name}-#{metric.type}"
    end)
  end

  defp get_selected(nil, _), do: ""
  defp get_selected(metric, type), do: "#{metric}-#{type}"

  defp prepare_measurements(measurements) do
    Enum.reduce(measurements, %{labels: [], data: []}, fn measurement, chart_config ->
      if measurement.value != nil do
        new_labels = chart_config.labels ++ [DateTime.to_iso8601(measurement.time)]
        new_data = chart_config.data ++ [measurement.value]

        %{chart_config | labels: new_labels, data: new_data}
      else
        chart_config
      end
    end)
    |> Jason.encode!()
  end
end
