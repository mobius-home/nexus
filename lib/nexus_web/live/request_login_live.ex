defmodule NexusWeb.RequestLoginLive do
  @moduledoc """

  """

  use NexusWeb, :surface_view

  alias Ecto.Changeset
  alias Nexus.Accounts
  alias Nexus.Accounts.User
  alias NexusWeb.Params
  alias NexusWeb.Params.RequestLogin
  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, TextInput, Submit}

  def mount(_params, _session, socket) do
    socket = socket |> assign(:changeset, RequestLogin.changeset()) |> assign(:complete, false)
    {:ok, socket}
  end

  def render(assigns) do
    ~F"""
    <div class="container mx-auto flex items-center justify-center h-screen">
      <div class="bg-white pt-5 w-[400px] min-h-max drop-shadow-sm rounded pb-8">
        <h1 class="text-center text-4xl font-extralight tracking-wider text-violet-500">
          Nexus
        </h1>

        {#if !@complete}
          <div class="max-w-xs mx-auto pt-12">
            <Form for={@changeset} submit="request_login">
              <TextInput
                field={:email}
                class="shadow appearance-none border rounded w-full py-2 px-3 text-grey-darker"
                opts={placeholder: "Email address"}
              />

              <ErrorTag field={:email} class="text-red-400 font-light" />

              <div class="pt-6 flex justify-end">
                <Submit
                  label="Request login"
                  class="bg-violet-600 text-white pt-1 pb-1 pl-5 pr-5 rounded font-light hover:bg-violet-700"
                />
              </div>
            </Form>
          </div>
        {#else}
          <p class="text-center font-light pt-10 pb-4">See Email for login information</p>
        {/if}
      </div>
    </div>
    """
  end

  def handle_event("request_login", params, socket) do
    with {:ok, request_login} <- Params.bind(%RequestLogin{}, params),
         %User{} = user <- Accounts.get_user_by_email(request_login.email),
         {:ok, _email} <-
           Accounts.send_magic_email_for_user(user, &Routes.user_session_url(socket, :create, &1)) do
      {:noreply, assign(socket, :complete, true)}
    else
      nil ->
        {:noreply, assign(socket, :complete, true)}

      {:error, %Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
