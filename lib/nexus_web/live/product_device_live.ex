defmodule NexusWeb.ProductDeviceLive do
  use NexusWeb, :surface_view

  alias NexusWeb.Components.DeviceViewContainer

  on_mount NexusWeb.UserLiveAuth
  on_mount {NexusWeb.GetResourceLive, [:product, :device]}

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~F"""
    <DeviceViewContainer
      device={@device}
      product_slug={@product.slug}
      page={:overview}
      socket={@socket}
    >
      <p>Some information about the device</p>
    </DeviceViewContainer>
    """
  end
end
