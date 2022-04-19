defmodule NexusWeb.ProductDeviceMetricsLive do
  use NexusWeb, :surface_view

  alias Nexus.Products
  alias NexusWeb.Components.{DeviceViewContainer, Modal}
  alias Surface.Components.{Form, LiveFileInput}
  alias Surface.Components.Form.{ErrorTag, Submit}

  on_mount NexusWeb.UserLiveAuth
  on_mount {NexusWeb.GetResourceLive, [:product, :device, :product_metrics]}

  def mount(_params, _session, socket) do
    socket = allow_upload(socket, :metrics, accept: ~w(.mbf .json), max_entries: 1)
    {:ok, socket}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
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
      <table class="table-auto w-full">
        <thead>
          <tr>
            <th class="text-left border-b-2 font-medium text-sm p-4 pb-2 text-gray-600">Name</th>
            <th class="text-left border-b-2 font-medium text-sm p-4 pb-2 text-gray-600">Type</th>
          </tr>
        </thead>
        <tbody>
          {#for m <- @metrics}
            <tr class="even:bg-gray-100 font-light text-gray-500">
              <td class="p-4">{m.name}</td>
              <td class="p-4">{m.type}</td>
            </tr>
          {/for}
        </tbody>
      </table>

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
end
