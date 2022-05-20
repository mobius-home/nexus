defmodule Nexus.Products.Product do
  @moduledoc """
  An IoT product
  """

  use Ecto.Schema

  alias Nexus.Devices.Device
  alias Nexus.Products.ProductSettings

  @type name() :: binary()

  @type slug() :: binary()

  @type data_bucket() :: binary()

  @type t() :: %__MODULE__{
          name: binary(),
          slug: binary(),
          product_settings: ProductSettings.t() | Ecto.Association.NotLoaded.t(),
          devices: [Device.t()] | Ecto.Association.NotLoaded.t()
        }

  schema "products" do
    field :name, :string
    field :slug, :string

    has_one :product_settings, ProductSettings
    has_many :devices, Device

    timestamps()
  end
end
