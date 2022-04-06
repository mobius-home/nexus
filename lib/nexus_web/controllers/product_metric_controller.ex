defmodule NexusWeb.ProductMetricController do
  @moduledoc """
  Controller for working with metrics from a product level
  """

  use NexusWeb, :controller

  alias Nexus.Products
  alias Nexus.Products.Metric
  alias NexusWeb.RequestParams
  alias NexusWeb.RequestParams.{CreateProductMetricParams, MetricSlugParams}

  def new(%{assigns: %{product: product}} = conn, _params) do
    changeset = Products.metric_changeset()

    render(conn, "new.html", changeset: changeset, product_slug: product.slug)
  end

  def create(%{assigns: %{product: product}} = conn, params) do
    with {:ok, params} <- RequestParams.bind(%CreateProductMetricParams{}, params),
         {:ok, metric} <- Products.create_metric_for_product(product, params.name, params.type) do
      redirect(conn, to: Routes.product_metric_path(conn, :show, product.slug, metric.slug))
    end
  end

  def show(%{assigns: %{product: product}} = conn, params) do
    with {:ok, params} <- RequestParams.bind(%MetricSlugParams{}, params),
         %Metric{} = metric <-
           Products.get_metric_for_product_by_slug(product, params.metric_slug) do
      render(conn, "show.html", metric: metric)
    end
  end
end
