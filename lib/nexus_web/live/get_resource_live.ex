defmodule NexusWeb.GetResourceLive do
  import Phoenix.LiveView

  alias Nexus.Products
  alias NexusWeb.Params

  def on_mount(:product, params, _session, socket) do
    schema = %{product_slug: :string}
    {:ok, normalized} = Params.normalize(schema, params)
    product = Products.get_product_by_slug(normalized.product_slug)

    socket = assign(socket, :product, product)

    {:cont, socket}
  end
end
