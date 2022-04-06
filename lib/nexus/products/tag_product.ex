defmodule Nexus.Products.TagProduct do
  @moduledoc false

  use Ecto.Schema

  alias Nexus.Products.{Product, Tag}

  @primary_key false
  schema "tags_products" do
    belongs_to :tag, Tag
    belongs_to :product, Product
  end
end
