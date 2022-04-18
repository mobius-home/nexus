defmodule NexusWeb.ProductMetricsLive do
  use NexusWeb, :surface_view

  on_mount NexusWeb.UserLiveAuth

  alias Nexus.Products
  alias NexusWeb.Params
  alias NexusWeb.Params.ProductURLParams
  alias NexusWeb.Components.ProductViewContainer

  def mount(params, _session, socket) do
    {:ok, params} = Params.bind(%ProductURLParams{}, params)
    product = Products.get_product_by_slug(params.product_slug)

    socket =
      socket
      |> assign(:product, product)
      |> assign(:metrics, Products.get_metrics_for_product(product))

    {:ok, socket, temporary_assigns: [metrics: []]}
  end

  def render(assigns) do
    ~F"""
    <ProductViewContainer product={@product} socket={@socket} page={:metrics}>
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
    </ProductViewContainer>
    """
  end
end
