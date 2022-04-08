defmodule Nexus.AccountsTest do
  use Nexus.DataCase

  import Nexus.Test.AccountsFixtures
  import Ecto.Query

  alias Nexus.Accounts
  alias Nexus.Accounts.{User, UserToken, UserRole}

  describe "adding a user to the database" do
    setup do
      {:ok, user: user_fixture()}
    end

    test "no duplicate emails", %{user: user} do
      assert {:error, changeset} = Accounts.add_user(user.email, "no", "name")

      assert "has already been taken" in errors_on(changeset).email
    end

    test "first name too short" do
      assert {:error, changeset} = user_fixture_with_name("h ello")
      assert "should be at least 2 character(s)" in errors_on(changeset).first_name
    end

    test "first name too long" do
      first_name = String.duplicate("a", 105)

      assert {:error, changeset} = user_fixture_with_name(first_name <> " lastname")

      assert "should be at most 100 character(s)" in errors_on(changeset).first_name
    end

    test "last name too short" do
      assert {:error, changeset} = user_fixture_with_name("hello w")

      assert "should be at least 2 character(s)" in errors_on(changeset).last_name
    end

    test "last name too long" do
      last_name = String.duplicate("a", 105)

      assert {:error, changeset} = user_fixture_with_name("firstname " <> last_name)

      assert "should be at most 100 character(s)" in errors_on(changeset).last_name
    end

    test "case sensitive emails", %{user: user} do
      assert user == Accounts.get_user_by_email(String.upcase(user.email))
      assert user == Accounts.get_user_by_email(String.downcase(user.email))
    end

    test "bad email" do
      assert {:error, changeset} = Accounts.add_user("nogoodemail", "first", "last")
      assert "must have the @ sign and no spaces" in errors_on(changeset).email

      assert {:error, changeset} = Accounts.add_user("this @email.com", "first", "last")
      assert "must have the @ sign and no spaces" in errors_on(changeset).email
    end

    test "add user with 'admin' role" do
      admin = Accounts.get_role_by_name("admin")
      user = user_fixture(role: admin)

      user =
        Accounts.get_user_by_email(user.email)
        |> Nexus.Repo.preload(:role)

      assert user.role.name == "admin"
    end
  end

  describe "tokens" do
    setup do
      {:ok, user: user_fixture()}
    end

    test "create a login token for a user", %{user: user} do
      token = Accounts.create_login_token_for_user(user)
      hashed_token = :crypto.hash(:sha256, Base.url_decode64!(token, padding: false))
      user_token = Repo.one(UserToken, token: hashed_token, user_id: user.id)

      assert hashed_token == user_token.token
    end

    test "query user by login token - good token", %{user: user} do
      token = Accounts.create_login_token_for_user(user)

      assert user == Accounts.get_user_by_login_token(token)
    end

    test "query user by login token - invalid token" do
      invalid_token = Accounts.gen_token() |> Accounts.hash_token() |> Accounts.encode_token()

      assert nil == Accounts.get_user_by_login_token(invalid_token)
    end

    test "use the login token for a user", %{user: user} do
      token = Accounts.create_login_token_for_user(user)
      assert %User{} = Accounts.use_login_token_for_user(token)

      assert [] ==
               Repo.all(
                 from ut in UserToken, where: ut.user_id == ^user.id and ut.context == "login"
               )
    end

    test "have a user issue a login token", %{user: issuer} do
      new_user = user_fixture()
      token = Accounts.create_login_token_for_user(new_user, issuer: issuer)
      hashed_token = token |> Accounts.decode_token!() |> Accounts.hash_token()

      user_token =
        Repo.get_by(UserToken, token: hashed_token, user_id: new_user.id, created_by_id: issuer.id)

      assert user_token.token == hashed_token
      assert user_token.user_id == new_user.id
      assert user_token.created_by_id == issuer.id
    end

    test "generates magic link email for user login", %{user: user} do
      assert {:ok, email} =
               Accounts.send_magic_email_for_user(user, fn login_token ->
                 "[TOKEN]#{login_token}[TOKEN]"
               end)

      [_, token | _] =
        email.text_body
        |> String.split("[TOKEN]")

      token =
        token
        |> Accounts.decode_token!()
        |> Accounts.hash_token()

      assert %UserToken{} = ut = Repo.get_by(UserToken, token: token, user_id: user.id)
      assert ut.token == token
      assert ut.context == "login"
    end

    test "create a session token for a user", %{user: user} do
      token = Accounts.create_user_session_token(user)

      user_token = Repo.get_by(UserToken, token: token, user_id: user.id)

      assert user_token.token == token
      assert user_token.context == "session"
    end

    test "query user by session token - good token", %{user: user} do
      token = Accounts.create_user_session_token(user)

      assert user == Accounts.get_user_by_session_token(token)
    end

    test "query user by session token - invalid token" do
      token = Accounts.gen_token()

      assert nil == Accounts.get_user_by_session_token(token)
    end

    test "delete session token", %{user: user} do
      token = Accounts.create_user_session_token(user)

      :ok = Accounts.delete_session_token(token)

      assert nil == Repo.get_by(UserToken, token: token, user_id: user.id, context: "session")
    end
  end

  describe "user roles" do
    test "create a role" do
      {:ok, r} = Accounts.create_user_role("therole")

      assert r == Repo.get_by(UserRole, name: "therole")
    end

    test "query role by name" do
      {:ok, r} = Accounts.create_user_role("anotherrole")

      assert r == Accounts.get_role_by_name("anotherrole")
    end
  end
end
