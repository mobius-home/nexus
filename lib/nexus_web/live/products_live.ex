defmodule NexusWeb.ProductsLive do
  use NexusWeb, :surface_view

  alias Nexus.Products
  alias Surface.Components.LiveRedirect

  on_mount NexusWeb.UserLiveAuth

  def mount(_params, _session, socket) do
    socket = assign(socket, :products, Products.all())

    {:ok, socket}
  end

  def render(assigns) do
    ~F"""
    <div>
      <h2 class="mb-8 text-gray-500 text-xl font-bold tracking-wide">Products</h2>
      <div class="grid grid-cols-2 gap-10">
        {#for product <- @products}
          <div class="w-100 bg-white rounded drop-shadow-sm h-[200px] p-5">
            <LiveRedirect
              label={product.name}
              to={Routes.live_path(@socket, NexusWeb.ProductLive, product.slug)}
              class="block"
            />
          </div>
        {/for}
      </div>
    </div>
    """
  end
end
