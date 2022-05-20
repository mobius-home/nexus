defmodule Nexus.Products.ProductSettings do
  @moduledoc """
  Settings for a product
  """

  use Ecto.Schema

  alias Nexus.Products.Product

  @typedoc """

  """
  @type bucket_name() :: binary()

  @typedoc """

  """
  @type bucket_id() :: binary()

  @type t() :: %__MODULE__{
          bucket_id: bucket_id(),
          bucket_name: bucket_name(),
          product: Product.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "product_settings" do
    field :bucket_name, :string
    field :bucket_id, :string

    belongs_to :product, Product

    timestamps()
  end
end
