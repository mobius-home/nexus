defmodule NexusWeb.Params.ProductURLParams do
  @moduledoc """
  Params for a view a product
  """

  alias Ecto.Changeset
  alias Nexus.Products.Product

  @types %{product_slug: :string}

  @typedoc """

  """
  @type t() :: %__MODULE__{
          product_slug: Product.slug()
        }

  defstruct [:product_slug]

  @doc """
  Create an empty changeset
  """
  @spec changeset() :: Changeset.t()
  def changeset() do
    {%__MODULE__{}, @types}
    |> Changeset.change(%{})
  end

  defimpl NexusWeb.Params do
    alias NexusWeb.Params.ProductURLParams

    def bind(_url_params, params) do
      ProductURLParams.changeset()
      |> Changeset.cast(params, [:product_slug])
      |> Changeset.validate_required([:product_slug])
      |> Changeset.apply_action(:insert)
    end
  end
end
