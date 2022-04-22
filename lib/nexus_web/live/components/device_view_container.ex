defmodule NexusWeb.Components.DeviceViewContainer do
  @moduledoc """
  A common container component for live views for a device
  """
  use NexusWeb, :surface_component

  alias Surface.Components.{LiveRedirect, LivePatch}

  prop device, :struct, required: true
  prop socket, :struct, required: true
  prop page, :atom, required: true, values: [:overview, :settings, :metrics]
  prop product_slug, :string, required: true
  prop product_name, :string, required: true

  prop modal_button_label, :string
  prop modal_button_to, :string

  slot default, required: true

  def render(assigns) do
    ~F"""
    <div class="w-full bg-white rounded drop-shadow-sm min-h-[700px] p-8 filter-none">
      <div>
        <LiveRedirect
          label={@product_name}
          to={Routes.live_path(@socket, NexusWeb.ProductLive, @product_slug)}
          class="text-sm text-gray-500 font-light"
        />
      </div>
      <div class="border-b pb-2 flex justify-between">
        <h2 class="text-xl pt-[14px]">{@device.serial_number}</h2>

        {#if @modal_button_label}
          <LivePatch
            to={@modal_button_to}
            class="text-violet-600 border border-violet-600 py-2 px-5 rounded font-light hover:bg-violet-600 hover:text-white h-[42px]"
          >
            {@modal_button_label}
          </LivePatch>
        {/if}
      </div>

      <div class="flex justify-start mt-5">
        <LiveRedirect
          class={"mr-4", "text-sm", "font-bold": @page == :overview}
          to={Routes.live_path(@socket, NexusWeb.ProductDeviceLive, @product_slug, @device.slug)}
        >Overview</LiveRedirect>
        <LiveRedirect
          class={"mr-4", "text-sm", "font-bold": @page == :metrics}
          to={Routes.live_path(@socket, NexusWeb.ProductDeviceMetricsLive, @product_slug, @device.slug)}
        >Metrics</LiveRedirect>
        <LiveRedirect
          class={"mr-4", "text-sm", "font-bold": @page == :settings}
          to={Routes.live_path(@socket, NexusWeb.ProductDeviceSettingsLive, @product_slug, @device.slug)}
        >Settings</LiveRedirect>
      </div>

      <div class="mt-10">
        <#slot />
      </div>
    </div>
    """
  end
end
