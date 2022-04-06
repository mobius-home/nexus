defmodule NexusWeb.Plugs.GetDeviceMetric do
  @moduledoc """

  """

  import Plug.Conn
  import Phoenix.Controller

  alias Ecto.Changeset
  alias Nexus.Products
  alias Nexus.Products.Metric
  alias NexusWeb.RequestParams
  alias NexusWeb.RequestParams.MetricSlugParams

  def init(opts), do: opts

  def call(%{assigns: %{product: product}} = conn, _opts) do
    with {:ok, params} <- RequestParams.bind(%MetricSlugParams{}, conn.params),
         %Metric{} = metric <-
           Products.get_metric_for_product_by_slug(product, params.metric_slug) do
      assign(conn, :metric, metric)
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
