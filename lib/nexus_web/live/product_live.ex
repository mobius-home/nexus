defmodule NexusWeb.ProductLive do
  use NexusWeb, :surface_view

  alias NexusWeb.Components.ProductViewContainer

  on_mount NexusWeb.UserLiveAuth
  on_mount {NexusWeb.GetResourceLive, :product}

  def mount(_params, _session, socket) do
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
