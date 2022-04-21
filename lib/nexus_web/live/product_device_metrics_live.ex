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

  @resolution_names ["Last hour", "Last 24 hour", "Last 7 days", "Last 30 days"]

  @resolutions Enum.reduce(@resolution_names, %{}, fn
                 "Last hour" = name, table -> Map.put(table, name, :hour)
                 "Last 24 hour" = name, table -> Map.put(table, name, :day)
                 "Last 7 days" = name, table -> Map.put(table, name, :week)
                 "Last 30 days" = name, table -> Map.put(table, name, :month)
               end)

  on_mount NexusWeb.UserLiveAuth
  on_mount {NexusWeb.GetResourceLive, [:product, :device, :product_metrics]}

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:query_params, %{resolution: :hour})
      |> assign(:measurements, [])
      |> allow_upload(:metrics, accept: ~w(.mbf .json), max_entries: 1)

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    schema = [
      metric_name: %{type: :string},
      metric_type: %{type: :string},
      resolution: %{type: :string}
    ]

    case Params.normalize(schema, params) do
      {:ok, normalized_params} ->
        socket =
          socket
          |> update_query_params(normalized_params)
          |> maybe_fetch_measurements()

        {:noreply, socket}
    end
  end

  defp maybe_fetch_measurements(%{assigns: %{query_params: params}} = socket)
       when map_size(params) == 0 do
    socket
  end

  defp maybe_fetch_measurements(
         %{
           assigns: %{
             query_params: %{
               metric_name: metric_name,
               metric_type: metric_type,
               resolution: resolution
             }
           }
         } = socket
       ) do
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
            socket.assigns.device,
            resolution: @resolutions[resolution]
          )

        socket
        |> assign(:selected_metric, metric_name)
        |> assign(:selected_metric_type, metric_type)
        |> assign(:measurements, measurements)
    end
  end

  defp maybe_fetch_measurements(socket) do
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

    socket =
      push_patch(socket,
        to:
          Routes.live_path(
            socket,
            __MODULE__,
            socket.assigns.product.slug,
            socket.assigns.device.slug
          )
      )

    {:noreply, socket}
  end

  def handle_event("selected_metric", %{"metric_select" => params}, socket) do
    schema = %{metric_name: :string}

    case Params.normalize(schema, params) do
      {:ok, normalized} ->
        [name, type] = String.split(normalized.metric_name, "-")
        socket = update_query_params(socket, %{metric_name: name, metric_type: type})

        {:noreply,
         push_patch(socket,
           to:
             Routes.live_path(
               socket,
               __MODULE__,
               socket.assigns.product.slug,
               socket.assigns.device.slug,
               socket.assigns.query_params
             )
         )}
    end
  end

  def handle_event("update_resolution", %{"resolution" => params}, socket) do
    schema = [
      resolution: %{type: :string, required: true}
    ]

    case Params.normalize(schema, params) do
      {:ok, normalized} ->
        socket = update_query_params(socket, normalized)

        {:noreply,
         push_patch(socket,
           to:
             Routes.live_path(
               socket,
               __MODULE__,
               socket.assigns.product.slug,
               socket.assigns.device.slug,
               socket.assigns.query_params
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
              selected={get_selected(@query_params)}
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

        <Form for={:resolution} change="update_resolution" class="ml-8">
          <div class="relative text-gray-700">
            <Select
              field="resolution"
              options={resolution_names()}
              selected={@query_params.resolution}
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

      {#if Map.get(@query_params, :metric_name) == nil}
        <p class="text-center text-gray-500 pt-20">Please select a metric</p>
      {#elseif Enum.empty?(@measurements)}
        <p class="text-center text-gray-500 pt-20">No metrics reported in time frame</p>
      {#else}
        <canvas
          id="chart"
          phx-hook="MetricChart"
          data-measurements={prepare_measurements(@measurements)}
          class="max-h-[500px]"
        >
        </canvas>
      {/if}

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

  defp get_selected(%{metric_name: metric, metric_type: type}), do: "#{metric}-#{type}"
  defp get_selected(_), do: ""

  defp prepare_measurements(measurements) do
    Enum.reduce(measurements, %{labels: [], data: []}, fn measurement, chart_config ->
      if measurement.value != nil do
        new_labels = [time_to_string(measurement.time) | chart_config.labels]
        new_data = [measurement.value | chart_config.data]

        %{chart_config | labels: new_labels, data: new_data}
      else
        chart_config
      end
    end)
    |> Jason.encode!()
  end

  defp time_to_string(date_time) do
    "#{date_time.hour}:#{date_time.minute}"
  end

  defp resolution_names(), do: @resolution_names

  defp update_query_params(socket, params) do
    new_params = Map.merge(socket.assigns.query_params, params)
    assign(socket, :query_params, new_params)
  end
end
