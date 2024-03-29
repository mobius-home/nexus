defmodule Nexus.Devices.Device do
  @moduledoc """

  """

  use Ecto.Schema

  alias Nexus.Products.Product

  @type serial_number() :: binary()

  @type t() :: %__MODULE__{
          serial_number: serial_number(),
          product: Product.t() | Ecto.Association.NotLoaded.t()
        }

  schema "devices" do
    belongs_to :product, Product
    field :serial_number, :string

    timestamps()
  end
end
