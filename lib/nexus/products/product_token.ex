defmodule Nexus.Products.ProductToken do
  @moduledoc """
  Product token
  """

  use Ecto.Schema

  alias Nexus.Accounts.User
  alias Nexus.Products.Product

  @type token() :: binary()

  @type t() :: %__MODULE__{
          token: token(),
          last_used: NaiveDateTime.t(),
          product: Product.t() | Ecto.Association.NotLoaded.t(),
          creator: User.t() | Ecto.Association.NotLoaded.t()
        }

  schema "product_tokens" do
    field :token, :string
    field :last_used, :naive_datetime

    belongs_to :product, Product
    belongs_to :creator, User

    timestamps([:inserted_at])
  end
end
