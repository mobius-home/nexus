defmodule Nexus.Accounts.UserToken do
  @moduledoc """

  """

  use Ecto.Schema

  alias Nexus.Accounts.User

  @type token() :: binary()

  @type context() :: binary()

  @type sent_to() :: User.email()

  @type t() :: %__MODULE__{
          token: token(),
          context: context(),
          user: User.t() | Ecto.Association.NotLoaded.t(),
          created_by: User.t() | Ecto.Association.NotLoaded.t(),
          sent_to: sent_to()
        }

  schema "users_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :user, User
    belongs_to :created_by, User

    timestamps(updated_at: false)
  end
end
