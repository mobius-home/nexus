defmodule NexusWeb.RequestLoginLiveTest do
  use NexusWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  import Nexus.Test.AccountsFixtures

  test "initial render", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    rendered = render(view)

    assert rendered =~ "Email address"
    assert rendered =~ "Request login"
    assert rendered =~ "<form"
  end

  test "submitting empty email address", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    rendered =
      view
      |> element("form")
      |> render_submit(%{request_login: %{email: ""}})

    assert rendered =~ "can&#39;t be blank"
  end

  test "submitting unknown user email", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    rendered =
      view
      |> element("form")
      |> render_submit(%{request_login: %{email: "someoneelse@test.com"}})

    assert rendered =~ "See Email for login information"
  end

  test "submitting known user email", %{conn: conn} do
    user = user_fixture()
    {:ok, view, _html} = live(conn, "/")

    rendered =
      view
      |> element("form")
      |> render_submit(%{request_login: %{email: user.email}})

    assert rendered =~ "See Email for login information"
  end
end
