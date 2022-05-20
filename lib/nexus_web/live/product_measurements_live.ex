defmodule NexusWeb.ProductMeasurementsLive do
  use NexusWeb, :surface_view

  alias Nexus.Products
  alias NexusWeb.Components.ProductViewContainer

  on_mount NexusWeb.UserLiveAuth
  on_mount {NexusWeb.GetResourceLive, :product}

  def mount(_params, _session, socket) do
    {:ok, measurements} = Products.get_measurements(socket.assigns.product)

    socket =
      socket
      |> assign(:measurements, measurements)
      |> assign(:new_metric_errors, [])

    {:ok, socket, temporary_assigns: [measurements: []]}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <ProductViewContainer product={@product} socket={@socket} page={:measurements}>
      <table class="table-auto w-full">
        <thead>
          <tr>
            <th class="text-left border-b-2 font-medium text-sm p-4 pb-2 text-gray-600">Name</th>
          </tr>
        </thead>
        <tbody id="metrics" phx-update="prepend">
          {#for m <- @measurements}
            <tr id={m} class="even:bg-gray-100 font-light text-gray-500">
              <td class="p-4">{m}</td>
            </tr>
          {/for}
        </tbody>
      </table>
    </ProductViewContainer>
    """
  end
end
