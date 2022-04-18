defmodule NexusWeb.ProductDevicesLive do
  use NexusWeb, :surface_view

  alias Nexus.Products
  alias NexusWeb.Params
  alias NexusWeb.Components.{Modal, ProductViewContainer}
  alias Surface.Components.{Form, LiveRedirect}
  alias Surface.Components.Form.{ErrorTag, TextInput, Submit}

  on_mount NexusWeb.UserLiveAuth
  on_mount {NexusWeb.GetResourceLive, :product}

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:devices, Products.get_devices_for_product(socket.assigns.product))
      |> assign(:new_device_errors, [])

    {:ok, socket, temporary_assigns: [devices: []]}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def handle_event("add_device", %{"new_device" => params}, socket) do
    product = socket.assigns.product
    schema = %{serial_number: :string}

    with {:ok, params} <- Params.normalize(schema, params),
         {:ok, device} <- Products.create_device_for_product(product, params.serial_number) do
      socket =
        socket
        |> update(:devices, fn devices -> [device | devices] end)
        |> push_patch(to: Routes.live_path(socket, __MODULE__, product.slug))

      {:noreply, socket}
    else
      {:error, changeset} ->
        {:noreply, assign(socket, :new_device_errors, changeset.errors)}
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
              <td class="p-4">
                <LiveRedirect to={Routes.live_path(@socket, NexusWeb.ProductDeviceLive, @product.slug, d.slug)}>
                  {d.serial_number}
                </LiveRedirect>
              </td>
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
          <Form for={:new_device} submit="add_device" class="mt-12" errors={@new_device_errors}>
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
