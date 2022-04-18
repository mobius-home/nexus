defmodule NexusWeb.ProductDevicesLive do
  use NexusWeb, :surface_view

  on_mount NexusWeb.UserLiveAuth

  alias Nexus.Products
  alias NexusWeb.Params
  alias NexusWeb.Params.{ProductURLParams, NewDevice}
  alias NexusWeb.Components.{Modal, ProductViewContainer}
  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, TextInput, Submit}

  def mount(params, _session, socket) do
    {:ok, params} = Params.bind(%ProductURLParams{}, params)
    product = Products.get_product_by_slug(params.product_slug)

    socket =
      socket
      |> assign(:product, product)
      |> assign(:devices, Products.get_devices_for_product(product))

    {:ok, socket, temporary_assigns: [devices: []]}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def handle_event("add_device", params, socket) do
    product = socket.assigns.product

    with {:ok, params} <- Params.bind(%NewDevice{}, params),
         {:ok, device} <- Products.create_device_for_product(product, params.serial_number) do
      socket =
        socket
        |> update(:devices, fn devices -> [device | devices] end)
        |> push_patch(to: Routes.live_path(socket, __MODULE__, product.slug))

      {:noreply, socket}
    else
      {:error, changeset} ->
        {:noreply, assign(socket, :device_changeset, changeset)}
    end
  end

  def render(assigns) do
    ~F"""
    <ProductViewContainer
      product={@product}
      socket={@socket}
      page={:devices}
      modal_button_label="Add device"
      modal_button_to={Routes.product_devices_path(@socket, :add_device, @product.slug)}
    >
      <table class="table-auto w-full">
        <thead>
          <tr>
            <th class="text-left border-b-2 font-medium text-sm p-4 pb-2 text-gray-600">Serial number</th>
            <th class="text-left border-b-2 font-medium text-sm p-4 pb-2 text-gray-600">Last reported</th>
          </tr>
        </thead>
        <tbody id="devices" phx-update="prepend">
          {#for d <- @devices}
            <tr id={d.serial_number} class="even:bg-gray-100 font-light text-gray-500">
              <td class="p-4">{d.serial_number}</td>
              <td class="p-4" />
            </tr>
          {/for}
        </tbody>
      </table>

      {#if @live_action == :add_device}
        <Modal
          title="New Device"
          return_to={Routes.live_path(@socket, __MODULE__, @product.slug)}
          id={:modal}
        >
          <Form for={:new_device} submit="add_device" class="mt-12">
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
    </ProductViewContainer>
    """
  end
end
