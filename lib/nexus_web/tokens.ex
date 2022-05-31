defmodule NexusWeb.Tokens do
  @moduledoc """
  Module for working with tokens
  """

  alias Nexus.Products.Product

  @context NexusWeb.Endpoint

  @doc """
  Generate a token for a product
  """
  @spec product_token_signer(Product.t()) :: binary()
  def product_token_signer(product) do
    Phoenix.Token.sign(@context, "product", %{product_id: product.id}, max_age: :infinity)
  end

  @doc """
  Verity a product token
  """
  @spec verify_product_token(binary()) :: {:ok, %{product_id: pos_integer()}} | {:error, :invalid}
  def verify_product_token(token) do
    case Phoenix.Token.verify(@context, "product", token) do
      {:ok, %{product_id: product_id}} -> {:ok, product_id}
      _error -> {:error, :invalid}
    end
  end
end
