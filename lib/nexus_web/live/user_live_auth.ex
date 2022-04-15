defmodule NexusWeb.UserLiveAuth do
  import Phoenix.LiveView

  alias Nexus.Accounts

  def on_mount(:default, _params, %{"user_token" => token}, socket) do
    socket =
      assign_new(socket, :current_user, fn ->
        Accounts.get_user_by_session_token(token)
      end)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/")}
    end
  end
end
