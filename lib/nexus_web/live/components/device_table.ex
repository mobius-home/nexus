defmodule NexusWeb.Components.DeviceTable do
  use Surface.LiveComponent

  alias Nexus.Products

  prop product, :struct, required: true

  data devices, :list, default: []

  def mount(socket) do
    {:ok, socket, temporary_assigns: [devices: []]}
  end

  def update(assigns, socket) do
    assigns = Map.merge(socket.assigns, assigns)
    socket = Map.put(socket, :assigns, assigns)

    socket = assign(socket, :devices, Products.get_devices_for_product(assigns.product))
    {:ok, socket}
  end

  def render(assigns) do
    ~F"""
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
            <td class="p-4"></td>
          </tr>
        {/for}
      </tbody>
    </table>
    """
  end
end
