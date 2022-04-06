defmodule Nexus.Products.Product do
  @moduledoc """
  A product

  A product is the fundamental building block the Nexus server. It provides a
  namespace for devices and allows the backend to optimize metric data for a
  fleet of devices within a product.
  """

  use Ecto.Schema

  alias Nexus.Products.{Device, Metric, Tag, TagProduct}

  @typedoc """
  The name of the product

  This name is normally used for contexts for when a human will be the end
  user.
  """
  @type name() :: binary()

  @typedoc """
  A slug of the product name

  This name is mostly used for URLs and APIs to search for product records. This
  should only be programmatically generated.
  """
  @type slug() :: binary()

  @typedoc """
  Schema for where the metrics data for the product will live
  """
  @type data_schema() :: binary()

  @type t() :: %__MODULE__{
          name: name(),
          slug: slug(),
          data_schema: data_schema()
        }

  schema "products" do
    has_many :devices, Device
    has_many :metrics, Metric
    many_to_many :tags, Tag, join_through: TagProduct
    field :name, :string, null: false
    field :slug, :string, null: false
    field :data_schema, :string, null: false

    timestamps()
  end
end
