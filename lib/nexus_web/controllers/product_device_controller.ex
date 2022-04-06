defmodule NexusWeb.ProductDeviceController do
  @moduledoc """
  Controller for devices within a product
  """

  use NexusWeb, :controller

  alias Nexus.Products
  alias NexusWeb.RequestParams
  alias NexusWeb.RequestParams.CreateProductDeviceParams

  def new(%{assigns: %{product: product}} = conn, _params) do
    changeset = Products.device_changeset()

    render(conn, "new.html", device: changeset, product_slug: product.slug)
  end

  def create(%{assigns: %{product: product}} = conn, params) do
    with {:ok, params} <- RequestParams.bind(%CreateProductDeviceParams{}, params),
         {:ok, device} <- Products.create_device_for_product(product, params.serial_number) do
      redirect(conn, to: Routes.product_device_path(conn, :show, product.slug, device.slug))
    end
  end

  # show is piped through the `GetDevice` plug in the router
  def show(%{assigns: %{product: product, device: device}} = conn, _params) do
    product = Products.load_product_metrics(product)
    render(conn, "show.html", device: device, product: product)
  end
end
