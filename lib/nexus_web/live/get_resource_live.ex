defmodule NexusWeb.GetResourceLive do
  import Phoenix.LiveView

  alias Nexus.Products
  alias NexusWeb.Params

  def on_mount(:product, params, _session, socket) do
    schema = [
      product_slug: %{type: :string, required: true}
    ]

    {:ok, normalized} = Params.normalize(schema, params)
    product = Products.get_by_slug(normalized.product_slug)

    socket = assign(socket, :product, product)

    {:cont, socket}
  end

  def on_mount(:device, params, _session, socket) do
    schema = [
      device_slug: %{type: :string, required: true}
    ]

    {:ok, normalized} = Params.normalize(schema, params)

    device =
      Products.get_device(
        socket.assigns.product,
        normalized.device_slug
      )

    {:cont, assign(socket, :device, device)}
  end

  def on_mount(:product_measurements, _params, _session, socket) do
    {:ok, measurements} = Products.get_measurements(socket.assigns.product)

    {:cont, assign(socket, :measurements, measurements)}
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
