defmodule Nexus.Accounts.UserRole do
  @moduledoc """

  """

  use Ecto.Schema

  @type name() :: binary()

  @type t() :: %__MODULE__{
          name: binary()
        }

  schema "user_roles" do
    field :name, :string
  end
end
