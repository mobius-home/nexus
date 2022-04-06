defmodule Nexus.Products.Tag do
  @moduledoc """

  """

  use Ecto.Schema

  alias Nexus.Products.{Product, TagProduct}

  @typedoc """

  """
  @type key() :: binary()

  @typedoc """

  """
  @type value() :: binary()

  @typedoc """

  """
  @type t() :: %__MODULE__{
          key: key(),
          value: value()
        }

  schema "tags" do
    field :key, :string, null: false
    field :value, :string, null: false
    many_to_many :products, Product, join_through: TagProduct
  end
end
