defmodule NexusWeb.ServerUserControllerTest do
  use NexusWeb.ConnCase, async: true

  alias Nexus.Accounts
  alias NexusWeb.UserAuth
  import Nexus.Test.AccountsFixtures

  setup %{conn: conn} do
    roles = Accounts.get_roles()

    users =
      Enum.reduce(roles, %{}, fn role, us ->
        user = user_fixture(role: role)

        case role.name do
          "admin" ->
            Map.put(us, :admin, user)

          "product_maintainer" ->
            Map.put(us, :maintainer, user)

          "user" ->
            Map.put(us, :user, user)
        end
      end)

    conn =
      conn
      |> Map.replace!(:secret_key_base, NexusWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    {:ok, Map.merge(users, %{conn: conn})}
  end

  describe "GET /users" do
    test "admin can access page", %{conn: conn, admin: user} do
      conn =
        conn
        |> UserAuth.set_logged_in_session(user)
        |> get(Routes.server_user_path(conn, :index))

      response = html_response(conn, 200)
      assert response =~ "Users"
    end

    test "product maintainer cannot access page", %{conn: conn, maintainer: user} do
      conn =
        conn
        |> UserAuth.set_logged_in_session(user)
        |> get(Routes.server_user_path(conn, :index))

      assert redirected_to(conn) == "/products"
    end

    test "user cannot access page", %{conn: conn, user: user} do
      conn =
        conn
        |> UserAuth.set_logged_in_session(user)
        |> get(Routes.server_user_path(conn, :index))

      assert redirected_to(conn) == "/products"
    end

    test "gets a list of users", %{conn: conn, admin: user} do
      conn =
        conn
        |> UserAuth.set_logged_in_session(user)
        |> get(Routes.server_user_path(conn, :index))

      response = html_response(conn, 200)

      users = Accounts.users()

      for u <- users do
        assert response =~ u.email
      end
    end
  end

  describe "GET /users/new" do
    test "admin can access page", %{conn: conn, admin: user} do
      conn =
        conn
        |> UserAuth.set_logged_in_session(user)
        |> get(Routes.server_user_path(conn, :index))

      response = html_response(conn, 200)
      assert response =~ "Users"
    end

    test "product maintainer cannot access page", %{conn: conn, maintainer: user} do
      conn =
        conn
        |> UserAuth.set_logged_in_session(user)
        |> get(Routes.server_user_path(conn, :index))

      assert redirected_to(conn) == "/products"
    end

    test "user cannot access page", %{conn: conn, user: user} do
      conn =
        conn
        |> UserAuth.set_logged_in_session(user)
        |> get(Routes.server_user_path(conn, :index))

      assert redirected_to(conn) == "/products"
    end
  end

  describe "POST /users" do
    test "admin can access page", %{conn: conn, admin: user} do
      conn =
        conn
        |> UserAuth.set_logged_in_session(user)
        |> get(Routes.server_user_path(conn, :index))

      response = html_response(conn, 200)
      assert response =~ "Users"
    end

    test "product maintainer cannot access page", %{conn: conn, maintainer: user} do
      conn =
        conn
        |> UserAuth.set_logged_in_session(user)
        |> get(Routes.server_user_path(conn, :index))

      assert redirected_to(conn) == "/products"
    end

    test "user cannot access page", %{conn: conn, user: user} do
      conn =
        conn
        |> UserAuth.set_logged_in_session(user)
        |> get(Routes.server_user_path(conn, :index))

      assert redirected_to(conn) == "/products"
    end
  end
end
