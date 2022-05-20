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
                 "Last hour" = name, table -> Map.put(table, name, :hour)
                 "Last 24 hour" = name, table -> Map.put(table, name, :day)
                 "Last 7 days" = name, table -> Map.put(table, name, :week)
                 "Last 30 days" = name, table -> Map.put(table, name, :month)
               end)

  on_mount(NexusWeb.UserLiveAuth)
  on_mount({NexusWeb.GetResourceLive, [:product, :device, :product_measurements]})

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:query_params, %{resolution: "Last hour"})
      |> assign(:measurement_fields, [])
      |> assign(:data_series, DataSeries.empty())
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

  defp maybe_fetch_data(socket) do
    query_params = socket.assigns.query_params

    case which_data(socket.assigns) do
      :none ->
        socket

      :fields ->
        {:ok, fields} =
          Products.get_measurement_fields(socket.assigns.product, query_params[:measurement])

        socket = assign(socket, :measurement_fields, fields)

        maybe_fetch_data(socket)

      :measurement_data ->
        {:ok, data_series} =
          Devices.get_measurement_data(
            socket.assigns.device,
            socket.assigns.product.product_settings.bucket_name,
            query_params.measurement,
            query_params.field,
            resolution: @resolutions[query_params[:resolution]]
          )

        assign(socket, :data_series, data_series)
    end
  end

  defp which_data(%{
         query_params: query_params,
         measurement_fields: fields,
         data_series: data_series
       }) do
    cond do
      query_params[:measurement] && !query_params[:field] && Enum.empty?(fields) ->
        :fields

      query_params[:measurement] && query_params[:field] && Enum.empty?(fields) ->
        :fields

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
    consume_uploaded_entries(socket, :metrics, fn %{path: path} = stuff, entry ->
      # :ok = Products.import_upload(socket.assigns.product, socket.assigns.device, path)
      :ok =
        Devices.import_metrics(
          socket.assigns.device,
          path,
          socket.assigns.product.product_settings
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
        socket = update_query_params(socket, %{measurement: normalized.measurement})

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
      {#elseif DataSeries.empty?(@data_series)}
        <p class="text-center text-gray-500 pt-20">No metrics reported in time frame</p>
      {#else}
        <canvas
          id="chart"
          phx-hook="MetricChart"
          data-dataseries={prepare_data_series(@data_series)}
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

  defp prepare_data_series(data_series) do
    data_series
    |> Map.from_struct()
    |> Jason.encode!()
  end

  defp resolution_names(), do: @resolution_names

  defp update_query_params(socket, params) do
    new_params = Map.merge(socket.assigns.query_params, params)

    socket
    |> assign(:query_params, new_params)
    |> assign(:data_series, DataSeries.empty())
  end
end
