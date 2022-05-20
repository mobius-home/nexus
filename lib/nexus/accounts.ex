defmodule Nexus.Accounts do
  @moduledoc """
  Context for user accounts
  """

  import Ecto.Query

  alias Ecto.Changeset
  alias Nexus.Accounts.{User, UserMailer, UserRole, UserToken}
  alias Nexus.{Device, DeviceToken, Repo}
  alias Swoosh.Email

  @rand_size 32
  @hash_algorithm :sha256

  @typedoc """
  """
  @type login_token() :: binary()

  @typedoc """

  """
  @type session_token() :: binary()

  @typedoc """

  """
  @type add_user_opt() :: {:role, UserRole.t()}

  @typedoc """

  """
  @type create_login_token_opt() :: {:issuer, User.t()}

  @doc """
  Create a user changeset
  """
  @spec user_changeset() :: Changeset.t()
  def user_changeset() do
    Changeset.change(%User{}, %{})
  end

  @doc """
  Get all users on the server
  """
  @spec users() :: [User.t()]
  def users() do
    Repo.all(User)
  end

  @doc """
  Get the users full name
  """
  @spec user_full_name(User.t()) :: binary()
  def user_full_name(user) do
    "#{user.first_name} #{user.last_name}"
  end

  @doc """
  Add a user to the server
  """
  @spec add_user(User.email(), User.first_name(), User.last_name(), [add_user_opt()]) ::
          {:ok, User.t()} | {:error, Changeset.t()}
  def add_user(email, first_name, last_name, opts \\ []) do
    user_role = opts[:role] || get_role_by_name("user")

    %User{}
    |> Changeset.change(%{
      email: email,
      first_name: first_name,
      last_name: last_name,
      role_id: user_role.id
    })
    |> validate_email()
    |> Changeset.unsafe_validate_unique(:email, Repo)
    |> Changeset.unique_constraint(:email)
    |> Changeset.validate_length(:first_name, min: 2, max: 100)
    |> Changeset.validate_length(:last_name, min: 2, max: 100)
    |> Repo.insert()
  end

  @doc """
  Validate a changeset that contains an email
  """
  @spec validate_email(Changeset.t()) :: Changeset.t()
  def validate_email(changeset) do
    changeset
    |> Changeset.validate_required([:email])
    |> Changeset.validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> Changeset.validate_length(:email, max: 160)
  end

  @doc """
  Get a user by their email
  """
  @spec get_user_by_email(User.email()) :: User.t() | nil
  def get_user_by_email(user_email) do
    Repo.get_by(User, email: user_email)
  end

  @doc """
  Builds a token and its hash to be delivered to the user's email.

  The non-hashed token is sent to the user email while the
  hashed part is stored in the database. The original token cannot be reconstructed,
  which means anyone with read-only access to the database cannot directly use
  the token in the application to gain access. Furthermore, if the user changes
  their email in the system, the tokens sent to the previous email are no longer
  valid.

  If another user in the system is issuing the token the `:issuer` option can be
  passed to link the issuer to the token.
  """
  @spec create_login_token_for_user(User.t(), [create_login_token_opt()]) :: login_token()
  def create_login_token_for_user(user, opts \\ []) do
    token = gen_token()
    hashed_token = hash_token(token)
    created_by = opts[:issuer]
    created_by_id = created_by && created_by.id

    user_token = %UserToken{
      token: hashed_token,
      context: "login",
      user_id: user.id,
      sent_to: user.email,
      created_by_id: created_by_id
    }

    Repo.insert!(user_token)

    encode_token(token)
  end

  @doc """
  Create a user session token for a user
  """
  @spec create_user_session_token(User.t()) :: session_token()
  def create_user_session_token(user) do
    token = gen_token()
    Repo.insert!(%UserToken{token: token, context: "session", user_id: user.id})
    token
  end

  @doc """
  Send a magic link email
  """
  @spec send_magic_email_for_user(User.t(), (login_token() -> binary())) ::
          {:ok, Email.t()} | {:error, any()}
  def send_magic_email_for_user(user, url_func) when is_function(url_func, 1) do
    encoded_token = create_login_token_for_user(user)
    UserMailer.deliver_magic_link(user, url_func.(encoded_token))
  end

  @doc """
  Validates the login token and deletes it as it has been used

  If the token is valid it will return the user the token was used for.
  """
  @spec use_login_token_for_user(login_token()) :: User.t() | nil
  def use_login_token_for_user(token) do
    case get_user_by_login_token(token) do
      %User{} = user ->
        delete_query = from t in UserToken, where: t.user_id == ^user.id and t.context == "login"

        Repo.delete_all(delete_query)
        user

      nil ->
        nil
    end
  end

  @doc """
  Get a user by the login token
  """
  @spec get_user_by_login_token(login_token()) :: User.t() | nil
  def get_user_by_login_token(token) do
    case decode_token(token) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from t in UserToken,
            where: t.token == ^hashed_token,
            where: t.context == "login",
            join: user in assoc(t, :user),
            where: t.inserted_at > ago(1, "day") and t.sent_to == user.email,
            select: user

        Repo.one(query)

      _error ->
        nil
    end
  end

  @doc """
  Query for a user with a session token
  """
  @spec get_user_by_session_token(session_token()) :: User.t() | nil
  def get_user_by_session_token(session_token) do
    query =
      from t in UserToken,
        where: t.token == ^session_token,
        where: t.context == "session",
        join: user in assoc(t, :user),
        where: t.inserted_at > ago(122, "day"),
        select: user

    Repo.one(query)
    |> Repo.preload(:role)
  end

  @doc """
  Get a role by the role name
  """
  @spec get_role_by_name(UserRole.name()) :: UserRole.t() | nil
  def get_role_by_name(role_name) do
    Repo.get_by(UserRole, name: role_name)
  end

  @doc """
  Get all roles
  """
  @spec get_roles() :: [UserRole.t()]
  def get_roles() do
    Repo.all(UserRole)
  end

  @doc """
  Create a new user role
  """
  @spec create_user_role(UserRole.name()) :: {:ok, UserRole.t()} | {:error, Changeset.t()}
  def create_user_role(role_name) do
    %UserRole{}
    |> Changeset.change(%{name: role_name})
    |> Changeset.validate_length(:name, min: 1, max: 50)
    |> Changeset.unique_constraint([:name])
    |> Repo.insert()
  end

  @doc """
  Deletes the signed token with the given context.
  """
  @spec delete_session_token(session_token()) :: :ok
  def delete_session_token(token) do
    query =
      from t in UserToken,
        where: t.token == ^token and t.context == "session"

    Repo.delete_all(query)
    :ok
  end

  @doc false
  def gen_token() do
    :crypto.strong_rand_bytes(@rand_size)
  end

  @doc false
  def hash_token(token) do
    :crypto.hash(@hash_algorithm, token)
  end

  @doc false
  def encode_token(token) do
    Base.url_encode64(token, padding: false)
  end

  @doc false
  def decode_token(token) do
    Base.url_decode64(token, padding: false)
  end

  @doc false
  def decode_token!(token) do
    Base.url_decode64!(token, padding: false)
  end

  @doc """
  A user to create a token a device
  """
  @spec create_device_token(User.t(), Device.t()) ::
          {:ok, DeviceToken.t()} | {:error, Changeset.t()}
  def create_device_token(user, device) do
    # decouple NexusWeb here
    token =
      Phoenix.Token.sign(NexusWeb.Endpoint, "device", %{device_id: device.id}, max_age: :infinity)

    device
    |> Ecto.build_assoc(:device_token)
    |> Changeset.change(%{user_id: user.id, token: token})
    |> Repo.insert()
  end
end
