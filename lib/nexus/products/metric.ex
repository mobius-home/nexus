defmodule Nexus.Products.Metric do
  @moduledoc """

  """

  use Ecto.Schema

  alias Nexus.Products.Product

  @type name() :: binary()

  @type type() :: binary()

  @type slug() :: binary()

  @type table_name() :: binary()

  @type t() :: %__MODULE__{
          name: name(),
          type: type(),
          slug: slug(),
          table_name: table_name()
        }

  schema "metrics" do
    belongs_to :product, Product

    field :name, :string, null: false
    field :table_name, :string, null: false
    field :slug, :string, null: false
    field :type, :string, null: false

    timestamps()
  end
end
