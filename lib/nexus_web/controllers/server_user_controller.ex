defmodule NexusWeb.ServerUserController do
  @moduledoc """

  """

  use NexusWeb, :controller

  alias Nexus.Accounts
  alias NexusWeb.RequestParams
  alias NexusWeb.RequestParams.CreateUserParams

  def index(conn, _params) do
    render(conn, "index.html", users: Accounts.users())
  end

  def new(conn, _params) do
    render(conn, "new.html", changeset: Accounts.user_changeset())
  end

  def create(conn, params) do
    with {:ok, params} <- RequestParams.bind(%CreateUserParams{}, params),
         {:ok, user} <- Accounts.add_user(params.email, params.first_name, params.last_name),
         {:ok, _email} <-
           Accounts.send_magic_email_for_user(user, &Routes.user_session_url(conn, :create, &1)) do
      redirect(conn, to: Routes.server_user_path(conn, :index))
    else
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
