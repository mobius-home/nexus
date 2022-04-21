defmodule NexusWeb.UserSessionController do
  @moduledoc """
  Controller for user sessions
  """

  use NexusWeb, :controller

  alias Nexus.Accounts
  alias Nexus.Accounts.User
  alias NexusWeb.{Params, UserAuth}

  def new(conn, _params) do
    changeset = Accounts.user_changeset()

    conn
    |> put_layout({NexusWeb.LayoutView, "blank.html"})
    |> render("new.html", changeset: changeset)
  end

  def create(conn, params) do
    schema = [
      token: %{type: :string, required: true}
    ]

    with {:ok, params} <- Params.normalize(schema, params),
         %User{} = user <- Accounts.use_login_token_for_user(params.token) do
      UserAuth.log_in_user(conn, user)
    else
      _error ->
        redirect(conn, to: Routes.live_path(conn, NexusWeb.RequestLoginLive))
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
