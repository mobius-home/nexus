defmodule Nexus.Products.Metric.Measurement do
  @moduledoc """

  """

  use Ecto.Schema

  @primary_key false

  @type t() :: %__MODULE__{
          time: DateTime.t(),
          value: float(),
          metric_id: integer(),
          device_id: integer(),
          tag_set: [integer()],
          tags: map()
        }

  embedded_schema do
    field :time, :utc_datetime
    field :value, :float
    field :metric_id, :integer
    field :device_id, :integer
    field :tag_set, {:array, :integer}
    field :tags, :map, default: %{}
  end
end
