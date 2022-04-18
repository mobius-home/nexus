defmodule NexusWeb.Components.MetricsTable do
  use Surface.LiveComponent

  alias Nexus.Products

  prop product, :struct, required: true

  data metrics, :list, default: []

  def mount(socket) do
    {:ok, socket, temporary_assigns: [metrics: []]}
  end

  def update(assigns, socket) do
    assigns = Map.merge(socket.assigns, assigns)
    socket = Map.put(socket, :assigns, assigns)

    socket = assign(socket, :metrics, Products.get_metrics_for_product(assigns.product))
    {:ok, socket}
  end

  def render(assigns) do
    ~F"""
    <table class="table-auto w-full">
      <thead>
        <tr>
          <th class="text-left border-b-2 font-medium text-sm p-4 pb-2 text-gray-600">Name</th>
          <th class="text-left border-b-2 font-medium text-sm p-4 pb-2 text-gray-600">Type</th>
        </tr>
      </thead>
      <tbody id="metrics" phx-update="prepend">
        {#for m <- @metrics}
          <tr id={m.slug} class="even:bg-gray-100 font-light text-gray-500">
            <td class="p-4">{m.name}</td>
            <td class="p-4">{m.type}</td>
          </tr>
        {/for}
      </tbody>
    </table>
    """
  end
end
