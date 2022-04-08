defmodule NexusWeb.UserSessionControllerTest do
  use NexusWeb.ConnCase, async: true

  alias Nexus.Accounts
  import Nexus.Test.AccountsFixtures

  setup do
    {:ok, %{user: user_fixture()}}
  end

  describe "GET /users/login/:token" do
    test "using a valid login token to authenticate", %{conn: conn, user: user} do
      login_token = Accounts.create_login_token_for_user(user)

      conn = get(conn, Routes.user_session_path(conn, :create, login_token))

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == "/products"
    end

    test "remember the user", %{conn: conn, user: user} do
      login_token = Accounts.create_login_token_for_user(user)

      conn = get(conn, Routes.user_session_path(conn, :create, login_token))

      assert conn.resp_cookies["_nexus_web_user_remember_me"]
      assert redirected_to(conn) == "/products"
    end

    test "does not login with invalid token", %{conn: conn} do
      invalid_token = Accounts.gen_token() |> Accounts.hash_token() |> Accounts.encode_token()
      conn = get(conn, Routes.user_session_path(conn, :create, invalid_token))

      assert redirected_to(conn) == "/"
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end

  describe "POST /users/login" do
    test "handles when no email is provided", %{conn: conn} do
      conn =
        post(conn, Routes.user_session_path(conn, :create_magic_link), %{
          "login_request" => %{"email" => ""}
        })

      response = html_response(conn, 200)

      assert response =~ "can&#39;t be blank"
    end

    test "handles invalid email format", %{conn: conn} do
      conn =
        post(conn, Routes.user_session_path(conn, :create_magic_link), %{
          "login_request" => %{"email" => "notvalid"}
        })

      response = html_response(conn, 200)

      assert response =~ "must have the @ sign and no spaces"
    end

    test "handles user request", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create_magic_link), %{
          "login_request" => %{"email" => user.email}
        })

      response = html_response(conn, 200)

      assert response =~ "See Email for login information"
    end

    test "handles unknown user request", %{conn: conn} do
      conn =
        post(conn, Routes.user_session_path(conn, :create_magic_link), %{
          "login_request" => %{"email" => "nota@user.com"}
        })

      response = html_response(conn, 200)

      assert response =~ "See Email for login information"
    end
  end
end
