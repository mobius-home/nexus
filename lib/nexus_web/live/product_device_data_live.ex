defmodule NexusWeb.ProductDeviceDataLive do
  @moduledoc """
  Live view for looking at a metric for a device
  """

  # This needs to be improved a little but gets the job done for now
  use NexusWeb, :surface_view

  alias Nexus.{DataSeries, Devices, Products}
  alias NexusWeb.Params
  alias NexusWeb.Components.{DeviceViewContainer, Modal}
  alias Surface.Components.{Form, LiveFileInput}
  alias Surface.Components.Form.{Select, Submit}

  @resolution_names ["Last hour", "Last 24 hour", "Last 7 days", "Last 30 days"]

  @resolutions Enum.reduce(@resolution_names, %{}, fn
                 "Last hour" = name, table -> Map.put(table, name, :minute)
                 "Last 24 hour" = name, table -> Map.put(table, name, :hour)
                 "Last 7 days" = name, table -> Map.put(table, name, :hour)
                 "Last 30 days" = name, table -> Map.put(table, name, :day)
               end)

  on_mount(NexusWeb.UserLiveAuth)
  on_mount({NexusWeb.GetResourceLive, [:product, :device, :product_measurements]})

  def mount(_params, _session, socket) do
    Devices.subscribe_device_metrics_uploaded(
      socket.assigns.device.serial_number,
      socket.assigns.product.slug
    )

    socket =
      socket
      |> assign(:query_params, %{resolution: "Last hour"})
      |> assign(:measurement_fields, [])
      |> assign(:data_series, DataSeries.empty())
      |> assign(:data_series_payload, nil)
      |> assign(:last_data_fetched_at, nil)
      |> assign(:force_fields, false)
      |> allow_upload(:metrics, accept: ~w(.mbf .json), max_entries: 1)

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    schema = [
      measurement: %{type: :string},
      field: %{type: :string},
      resolution: %{type: :string}
    ]

    case Params.normalize(schema, params) do
      {:ok, normalized_params} ->
        socket =
          socket
          |> update_query_params(normalized_params)
          |> maybe_fetch_data()

        {:noreply, socket}
    end
  end

  defp maybe_fetch_data(socket, opts \\ []) do
    query_params = socket.assigns.query_params
    opts = Keyword.merge(opts, force_fields: socket.assigns.force_fields)

    case which_data(socket.assigns, opts) do
      :none ->
        socket

      :fields ->
        {:ok, fields} =
          Products.get_measurement_fields(socket.assigns.product, query_params[:measurement])

        socket
        |> assign(:measurement_fields, fields)
        |> maybe_fetch_data()

      :force_fields ->
        {:ok, fields} =
          Products.get_measurement_fields(socket.assigns.product, query_params[:measurement])

        socket = assign(socket, :measurement_fields, fields)

        socket
        |> assign(:force_fields, false)
        |> assign(:data_series, DataSeries.empty())
        |> assign(:data_series_payload, nil)

      :measurement_data ->
        {_, now} = window = get_query_window(socket)

        {:ok, data_series} =
          Devices.get_measurement_data(
            socket.assigns.device,
            socket.assigns.product.product_settings.bucket_name,
            query_params.measurement,
            query_params.field,
            window: window,
            resolution: @resolutions[query_params[:resolution]]
          )

        payload =
          if opts[:refresh] do
            Jason.encode!(%{
              action: "update",
              labels: data_series.labels,
              datasets: data_series.datasets
            })
          else
            Jason.encode!(%{
              action: "newMetric",
              labels: data_series.labels,
              datasets: data_series.datasets
            })
          end

        socket
        |> assign(:data_series, data_series)
        |> assign(:data_series_payload, payload)
        |> assign(:last_data_fetched_at, now)
    end
  end

  defp get_query_window(%{assigns: %{last_data_fetched_at: nil}}) do
    now_seconds = now()

    # {start, end}
    {now_seconds - 3600, now_seconds}
  end

  defp get_query_window(socket) do
    start_at = socket.assigns.last_data_fetched_at

    # {start, end}
    {start_at, now()}
  end

  defp now() do
    dt = DateTime.utc_now()
    dt = %{dt | second: 0}

    DateTime.to_unix(dt)
  end

  defp which_data(
         %{
           query_params: query_params,
           measurement_fields: fields,
           data_series: data_series
         },
         opts
       ) do
    refresh = opts[:refresh] || false
    force_fields = opts[:force_fields] || false

    cond do
      force_fields ->
        :force_fields

      query_params[:measurement] && !query_params[:field] && Enum.empty?(fields) ->
        :fields

      query_params[:measurement] && query_params[:field] && Enum.empty?(fields) ->
        :fields

      query_params[:measurement] && query_params[:field] && !Enum.empty?(fields) &&
        !DataSeries.empty?(data_series) && refresh ->
        :measurement_data

      query_params[:measurement] && query_params[:field] && !Enum.empty?(fields) &&
          DataSeries.empty?(data_series) ->
        :measurement_data

      true ->
        :none
    end
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("upload_metrics", _params, socket) do
    consume_uploaded_entries(socket, :metrics, fn %{path: path}, _entry ->
      :ok =
        Devices.import_metrics(
          socket.assigns.device,
          path,
          socket.assigns.product
        )

      {:ok, :done}
    end)

    socket =
      push_patch(socket,
        to:
          Routes.live_path(
            socket,
            __MODULE__,
            socket.assigns.product.slug,
            socket.assigns.device.serial_number
          )
      )

    {:noreply, socket}
  end

  def handle_event("selected_measurement", %{"measurement_select" => params}, socket) do
    schema = [
      measurement: %{type: :string, required: true}
    ]

    case Params.normalize(schema, params) do
      {:ok, normalized} ->
        socket =
          socket
          |> update_query_params(%{measurement: normalized.measurement})
          |> assign(:force_fields, true)

        {:noreply,
         push_patch(socket,
           to:
             Routes.live_path(
               socket,
               __MODULE__,
               socket.assigns.product.slug,
               socket.assigns.device.serial_number,
               socket.assigns.query_params
             )
         )}
    end
  end

  def handle_event("field_selected", %{"field_select" => params}, socket) do
    schema = [
      field: %{type: :string, required: true}
    ]

    case Params.normalize(schema, params) do
      {:ok, normalized} ->
        socket = update_query_params(socket, %{field: normalized.field})

        {:noreply,
         push_patch(socket,
           to:
             Routes.live_path(
               socket,
               __MODULE__,
               socket.assigns.product.slug,
               socket.assigns.device.serial_number,
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
               socket.assigns.device.serial_number,
               socket.assigns.query_params
             )
         )}
    end
  end

  def handle_info(:new_metrics, socket) do
    socket = maybe_fetch_data(socket, refresh: true)

    {:noreply, socket}
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
      modal_button_to={Routes.product_device_data_path(@socket, :metric_upload, @product.slug, @device.serial_number)}
    >
      <div class="flex justify-end mb-10">
        <Form for={:measurement_select} change="selected_measurement">
          <div class="relative text-gray-700">
            <Select
              field="measurement"
              options={@measurements}
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

        <Form for={:field_select} change="field_selected">
          <div class="relative text-gray-700 ml-7">
            <Select
              field="field"
              options={@measurement_fields}
              selected={get_selected_field(@query_params)}
              prompt="Please select a field"
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

      {#if Map.get(@query_params, :measurement) == nil}
        <p class="text-center text-gray-500 pt-20">Please select a metric</p>
      {#elseif @data_series_payload == nil}
        <p class="text-center text-gray-500 pt-20">No metrics reported in time frame</p>
      {#else}
        <canvas
          id="chart"
          phx-hook="MetricChart"
          data-dataseries={@data_series_payload}
          class="max-h-[500px]"
        >
        </canvas>
      {/if}

      {#if @live_action == :metric_upload}
        <Modal
          title="New Device"
          return_to={Routes.live_path(@socket, __MODULE__, @product.slug, @device.serial_number)}
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

  defp get_selected(%{measurement: measurement}), do: "#{measurement}"
  defp get_selected(_), do: ""

  defp get_selected_field(%{field: field}), do: "#{field}"
  defp get_selected_field(_), do: ""

  defp resolution_names(), do: @resolution_names

  defp update_query_params(socket, params) do
    new_params = Map.merge(socket.assigns.query_params, params)

    socket
    |> assign(:query_params, new_params)
    |> assign(:data_series, DataSeries.empty())
    |> assign(:last_data_fetched_at, nil)
  end
end
