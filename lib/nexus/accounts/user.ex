defmodule Nexus.Accounts.User do
  @moduledoc """

  """

  use Ecto.Schema

  alias Nexus.Accounts.UserRole

  @type email() :: binary()

  @type first_name() :: binary()

  @type last_name() :: binary()

  @type t() :: %__MODULE__{
          email: email(),
          first_name: first_name(),
          last_name: last_name(),
          role: UserRole.t() | Ecto.Association.NotLoaded.t()
        }

  schema "users" do
    field :email, :string, null: false
    field :first_name, :string, null: false
    field :last_name, :string, null: false
    belongs_to :role, UserRole, foreign_key: :role_id

    timestamps()
  end
end
