defmodule NexusWeb.ProductDeviceSettingsLive do
  @moduledoc """

  """

  use NexusWeb, :surface_view

  alias NexusWeb.Components.DeviceViewContainer

  on_mount NexusWeb.UserLiveAuth
  on_mount {NexusWeb.GetResourceLive, [:product, :device]}

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("scrape-metrics", _params, socket) do
    IO.inspect("Future feature support")
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <DeviceViewContainer
      socket={@socket}
      page={:settings}
      product_slug={@product.slug}
      device={@device}
      product_name={@product.name}
    >
      <button
        class="text-violet-600 border border-violet-600 py-2 px-5 rounded font-light hover:bg-violet-600 hover:text-white h-[42px]"
        phx-click="scrape-metrics"
      >
        Scrape Metrics
      </button>
    </DeviceViewContainer>
    """
  end
end
