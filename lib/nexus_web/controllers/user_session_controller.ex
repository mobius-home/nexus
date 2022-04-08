defmodule NexusWeb.UserSessionController do
  @moduledoc """
  Controller for user sessions
  """

  use NexusWeb, :controller

  alias Nexus.Accounts
  alias Nexus.Accounts.User
  alias NexusWeb.{RequestParams, UserAuth}
  alias NexusWeb.RequestParams.{RequestLoginParams, TokenParams}

  def new(conn, _params) do
    changeset = Accounts.user_changeset()

    conn
    |> put_layout({NexusWeb.LayoutView, "blank.html"})
    |> render("new.html", changeset: changeset)
  end

  def create(conn, params) do
    with {:ok, params} <- RequestParams.bind(%TokenParams{}, params),
         %User{} = user <- Accounts.use_login_token_for_user(params.token) do
      UserAuth.log_in_user(conn, user)
    else
      _error ->
        redirect(conn, to: Routes.user_session_path(conn, :new))
    end
  end

  def create_magic_link(conn, params) do
    with {:ok, params} <- RequestParams.bind(%RequestLoginParams{}, params),
         %User{} = user <- Accounts.get_user_by_email(params.email),
         {:ok, _email} <-
           Accounts.send_magic_email_for_user(
             user,
             &Routes.user_session_url(conn, :create, &1)
           ) do
      conn
      |> put_layout({NexusWeb.LayoutView, "blank.html"})
      |> render("new.html", changeset: nil)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)

      nil ->
        conn
        |> put_layout({NexusWeb.LayoutView, "blank.html"})
        |> render("new.html", changeset: nil)
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
