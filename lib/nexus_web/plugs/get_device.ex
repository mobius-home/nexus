defmodule NexusWeb.Plugs.GetDevice do
  @moduledoc """

  """

  import Plug.Conn
  import Phoenix.Controller

  alias Ecto.Changeset
  alias Nexus.Products
  alias Nexus.Products.Device
  alias NexusWeb.RequestParams
  alias NexusWeb.RequestParams.GetProductDeviceParams

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    # requires the product to be in the assigns
    product = conn.assigns.product

    with {:ok, params} <- RequestParams.bind(%GetProductDeviceParams{}, conn.params),
         %Device{} = device <-
           Products.get_device_for_product_by_device_slug(product, params.device_slug) do
      assign(conn, :device, device)
    else
      {:error, %Changeset{}} ->
        conn
        |> put_status(:bad_request)
        |> put_view(NexusWeb.ErrorView)
        |> render("400.html")
        |> halt()

      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(NexusWeb.ErrorView)
        |> render("404.html")
        |> halt()
    end
  end
end
