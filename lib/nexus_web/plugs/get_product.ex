defmodule NexusWeb.Plugs.GetProduct do
  @moduledoc """
  A plug for getting the product by the slug name that should be in request
  params
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Ecto.Changeset
  alias Nexus.Products
  alias Nexus.Products.Product
  alias NexusWeb.RequestParams
  alias NexusWeb.RequestParams.ProductSlugParams

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, params} <- RequestParams.bind(%ProductSlugParams{}, conn.params),
         %Product{} = product <- Products.get_product_by_slug(params.product_slug) do
      assign(conn, :product, product)
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
