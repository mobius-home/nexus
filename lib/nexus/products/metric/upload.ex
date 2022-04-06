defmodule Nexus.Products.Metric.Upload do
  @moduledoc """
  An embedded schema for working with metric uploads
  """

  use Ecto.Schema

  embedded_schema do
    field :filename, :string
    field :path, :string
  end
end
