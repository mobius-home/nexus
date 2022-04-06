defmodule Nexus.Products.Device do
  @moduledoc """

  """
  use Ecto.Schema

  alias Nexus.Products.Product

  @type serial_number() :: binary()

  @type slug() :: binary()

  @type t() :: %__MODULE__{
          serial_number: serial_number(),
          product: Product.t() | Ecto.Association.NotLoaded.t(),
          id: integer(),
          slug: slug()
        }

  @primary_key false
  schema "devices" do
    belongs_to :product, Product, primary_key: true
    field :serial_number, :string, primary_key: true
    field :id, :integer

    field :slug, :string, null: false

    timestamps()
  end
end
