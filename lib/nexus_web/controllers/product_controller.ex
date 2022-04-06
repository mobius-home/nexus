defmodule NexusWeb.ProductController do
  use NexusWeb, :controller

  alias Nexus.Products
  alias NexusWeb.RequestParams
  alias NexusWeb.RequestParams.NewProductParams

  def index(conn, _params) do
    render(conn, "index.html", products: Products.all())
  end

  def new(conn, _params) do
    render(conn, "new.html", product: Products.changeset_for_product())
  end

  def create(conn, params) do
    with {:ok, params} <- RequestParams.bind(%NewProductParams{}, params),
         {:ok, new_product} <- Products.create_product(params.name) do
      redirect(conn, to: Routes.product_path(conn, :show, new_product.slug))
    else
      {:error, changeset} ->
        IO.inspect(changeset)
        render(conn, "new.html", product: changeset)
    end
  end

  def show(conn, _params) do
    product = conn.assigns[:product]
    devices = Products.get_devices_for_product(product)

    render(conn, "show.html", product: product, devices: devices)
  end
end
