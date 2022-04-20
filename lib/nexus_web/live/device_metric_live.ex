defmodule NexusWeb.DeviceMetricLive do
  use NexusWeb, :surface_view

  alias NexusWeb.Components.DeviceViewContainer

  on_mount NexusWeb.UserLiveAuth
  on_mount {NexusWeb.GetResourceLive, [:product, :device]}

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~F"""
    <p>sdf</p>
    """
  end
end
