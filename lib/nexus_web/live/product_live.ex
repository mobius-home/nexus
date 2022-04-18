defmodule NexusWeb.ProductLive do
  use NexusWeb, :surface_view

  alias Nexus.Products
  alias NexusWeb.Params
  alias NexusWeb.Params.{ProductURLParams, NewDevice}
  alias NexusWeb.Components.{DeviceTable, MetricsTable, Modal}
  alias Surface.Components.{Form, LivePatch}
  alias Surface.Components.Form.{ErrorTag, TextInput, Submit}

  on_mount NexusWeb.UserLiveAuth

  def mount(params, _session, socket) do
    {:ok, params} = Params.bind(%ProductURLParams{}, params)
    product = Products.get_product_by_slug(params.product_slug)

    socket =
      socket
      |> assign(:product, product)
      |> assign(:devices, Products.get_devices_for_product(product))
      |> assign(:device_changeset, NewDevice.changeset())

    {:ok, socket, temporary_assigns: [devices: []]}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div class="w-full bg-white rounded drop-shadow-sm min-h-[700px] p-8 filter-none">
      <div class="border-b pb-2 flex justify-between">
        <h2 class="text-xl pt-[14px]">{@product.name}</h2>

        <LivePatch
          to={Routes.product_path(@socket, :add_device, @product.slug)}
          class="text-violet-600 border border-violet-600 py-2 px-5 rounded font-light hover:bg-violet-600 hover:text-white h-[42px]"
        >
          Add Device
        </LivePatch>
      </div>

      <div class="flex justify-start mt-5">
        <LivePatch class={sub_nav_item_class(@live_action, "overview")} to={Routes.live_path(@socket, __MODULE__, @product.slug)}>Overview</LivePatch>
        <LivePatch class={sub_nav_item_class(@live_action, "devices")} to={Routes.product_path(@socket, :devices, @product.slug)}>Devices</LivePatch>
        <LivePatch class={sub_nav_item_class(@live_action, "metrics")} to={Routes.product_path(@socket, :metrics, @product.slug)}>Metrics</LivePatch>
      </div>

      <div class="mt-10">
        {#case @live_action}
          {#match :devices}
            <DeviceTable id="device-table" product={@product} />
          {#match :metrics}
            <MetricsTable id="metrics-table" product={@product} />
          {#match _}
            <p>This is where some product level metrics can be shown</p>
        {/case}
      </div>

      {#if @live_action == :add_device}
        <Modal
          title="New Device"
          return_to={Routes.live_path(@socket, __MODULE__, @product.slug)}
          id={:modal}
        >
          <Form for={@device_changeset} submit="add_device" class="mt-12">
            <TextInput
              field={:serial_number}
              class="shadow appearance-none border rounded w-full py-2 px-3 text-grey-darker"
              opts={placeholder: "Serial number"}
            />

            <ErrorTag field={:serial_number} class="text-red-400 font-light" />

            <div class="pt-6 flex justify-end">
              <Submit
                label="Add"
                class="bg-violet-600 text-white pt-1 pb-1 pl-5 pr-5 rounded font-light hover:bg-violet-700"
              />
            </div>
          </Form>
        </Modal>
      {/if}
    </div>
    """
  end

  def handle_event("add_device", params, socket) do
    product = socket.assigns.product

    with {:ok, params} <- Params.bind(%NewDevice{}, params),
         {:ok, device} <- Products.create_device_for_product(product, params.serial_number) do
      send(self(), {:new_device, device})
      socket = push_patch(socket, to: Routes.live_path(socket, __MODULE__, product.slug))
      {:noreply, socket}
    else
      {:error, changeset} ->
        {:noreply, assign(socket, :device_changeset, changeset)}
    end
  end

  def handle_info({:new_device, device}, socket) do
    socket =
      socket
      |> update(:devices, fn devices -> [device | devices] end)

    {:noreply, socket}
  end

  def sub_nav_item_class(nil, "overview") do
    "mr-4 text-sm font-bold"
  end

  def sub_nav_item_class(:metrics, "metrics") do
    "mr-4 text-sm font-bold"
  end

  def sub_nav_item_class(:devices, "devices") do
    "mr-4 text-sm font-bold"
  end

  def sub_nav_item_class(_, _) do
    "mr-4 text-sm"
  end
end
