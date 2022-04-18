defmodule NexusWeb.ProductLive do
  use NexusWeb, :surface_view

  alias Nexus.Products
  alias NexusWeb.Params
  alias NexusWeb.Params.ProductURLParams
  alias NexusWeb.Components.ProductViewContainer

  on_mount NexusWeb.UserLiveAuth

  def mount(params, _session, socket) do
    {:ok, params} = Params.bind(%ProductURLParams{}, params)
    product = Products.get_product_by_slug(params.product_slug)

    socket =
      socket
      |> assign(:product, product)

    {:ok, socket}
  end

  def render(assigns) do
    ~F"""
    <ProductViewContainer product={@product} socket={@socket} page={:overview}>
      <p>Add some overview information about this product</p>
    </ProductViewContainer>
    """
  end
end
