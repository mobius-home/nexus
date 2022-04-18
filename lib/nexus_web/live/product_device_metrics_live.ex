defmodule NexusWeb.ProductDeviceMetricsLive do
  use NexusWeb, :surface_view

  alias NexusWeb.Components.DeviceViewContainer

  on_mount NexusWeb.UserLiveAuth
  on_mount {NexusWeb.GetResourceLive, [:product, :device, :product_metrics]}

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~F"""
    <DeviceViewContainer
      socket={@socket}
      device={@device}
      product_slug={@product.slug}
      page={:metrics}
    >
      <table class="table-auto w-full">
        <thead>
          <tr>
            <th class="text-left border-b-2 font-medium text-sm p-4 pb-2 text-gray-600">Name</th>
            <th class="text-left border-b-2 font-medium text-sm p-4 pb-2 text-gray-600">Type</th>
          </tr>
        </thead>
        <tbody>
          {#for m <- @metrics}
            <tr class="even:bg-gray-100 font-light text-gray-500">
              <td class="p-4">{m.name}</td>
              <td class="p-4">{m.type}</td>
            </tr>
          {/for}
        </tbody>
      </table>
    </DeviceViewContainer>
    """
  end
end
