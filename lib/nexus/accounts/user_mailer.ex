defmodule Nexus.Accounts.UserMailer do
  @moduledoc """
  Functions for sending emails to users
  """

  import Swoosh.Email

  alias Nexus.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Nexus", "hello@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  def deliver_magic_link(user, url) do
    deliver(user.email, "Nexus sign in request", """
    Hi #{user.first_name},

    You've been added to a Nexus server by the server admin.

    You can sign in by visiting the URL below:

    #{url}

    If you believe this was a mistake please ignore or message your
    Nexus server admin
    """)
  end
end
