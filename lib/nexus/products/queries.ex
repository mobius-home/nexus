defmodule Nexus.Products.Queries do
  @moduledoc false

  # helper queries to compose queries
  # queries use named bindings so be sure to read the documentation to ensure
  # binding name align correctly

  import Ecto.Query

  alias Nexus.Products.{Product, ProductSettings, ProductToken}

  @doc """
  Select from products

  The product's named binding is `:product`
  """
  @spec from_products() :: Ecto.Query.t()
  def from_products() do
    from(p in Product, as: :product)
  end

  @doc """
  Join in product settings


  The product settings named binding is `:product_settings`

  You will need to add ths to your `Ecto.Query.preload3` call at the end of the
  query.

  ```elixir
  Queries.from_products()
  |> Queries.join_product_settings()
  |> Ecto.Query.preload([product_settings: ps], product_settings: ps)
  ```
  """
  @spec join_product_settings(Ecto.Query.t()) :: Ecto.Query.t()
  def join_product_settings(query) do
    join(query, :inner, [product: p], ps in ProductSettings,
      on: ps.product_id == p.id,
      as: :product_settings
    )
  end

  @doc """
  Filter on product id
  """
  def where_product_id(query, product_id) do
    where(query, [product: p], p.id == ^product_id)
  end

  @doc """
  Filter on product slug
  """
  def where_product_slug(query, product_slug) do
    where(query, [product: p], p.slug == ^product_slug)
  end

  def from_product_settings() do
    from(ps in ProductSettings, as: :product_settings)
  end

  def where_product_settings_for_product_id(query, product_id) do
    where(query, [product_settings: ps], ps.product_id == ^product_id)
  end

  def join_product_token(query, opts \\ []) do
    type = opts[:type] || :inner

    from_tokens = from_product_tokens()

    join(query, type, [product: p], pt in ^from_tokens,
      on: pt.product_id == p.id,
      as: :product_token
    )
  end

  def from_product_tokens() do
    from(pt in ProductToken, as: :product_token)
  end

  def join_product_token_creator(query) do
    join(query, :inner, [product_token: pt], ptc in assoc(pt, :creator),
      as: :product_token_creator
    )
  end

  def where_product_token(query, token) do
    where(query, [product_token: pt], pt.token == ^token)
  end
end
