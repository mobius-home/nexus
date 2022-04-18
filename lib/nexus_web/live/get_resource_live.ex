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

  def on_mount(:device, params, _session, socket) do
    schema = %{device_slug: :string}
    {:ok, normalized} = Params.normalize(schema, params)

    device =
      Products.get_device_for_product_by_device_slug(
        socket.assigns.product,
        normalized.device_slug
      )

    {:cont, assign(socket, :device, device)}
  end

  def on_mount(:product_metrics, _params, _session, socket) do
    {:cont, assign(socket, :metrics, Products.get_metrics_for_product(socket.assigns.product))}
  end

  def on_mount(resources, params, session, socket) when is_list(resources) do
    result =
      Enum.reduce_while(resources, socket, fn r, s ->
        case on_mount(r, params, session, s) do
          {:cont, socket} ->
            {:cont, socket}

          {:halt, _socket} = halted ->
            {:halt, halted}
        end
      end)

    case result do
      {:halt, _socket} = halted -> halted
      socket -> {:cont, socket}
    end
  end
end
