defmodule NexusWeb.ServerUsersLive do
  use NexusWeb, :surface_view

  alias Nexus.Accounts
  alias NexusWeb.Params
  alias NexusWeb.Components.Modal
  alias NexusWeb.Components.Form.TextInput
  alias Surface.Components.{Form, LivePatch}
  alias Surface.Components.Form.Submit

  on_mount NexusWeb.UserLiveAuth

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:users, Accounts.users())
      |> assign(:new_user_errors, [])

    {:ok, socket, temporary_assigns: [users: []]}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div class="w-full bg-white rounded drop-shadow-sm min-h-[700px] p-8 filter-none">
      <div class="border-b pb-2 flex justify-between">
        <h1 class="text-xl pt-[14px]">Users</h1>

        <LivePatch
          to={Routes.server_users_path(@socket, :add_user)}
          class="text-violet-600 border border-violet-600 py-2 px-5 rounded font-light hover:bg-violet-600 hover:text-white h-[42px]"
        >
          Add User
        </LivePatch>
      </div>

      <table class="table-auto w-full mt-10">
        <thead>
          <tr>
            <th class="text-left border-b-2 font-medium text-sm p-4 pb-2 text-gray-600">Name</th>
            <th class="text-left border-b-2 font-medium text-sm p-4 pb-2 text-gray-600">Email</th>
          </tr>
        </thead>

        <tbody id="users" phx-update="prepend">
          {#for u <- @users}
            <tr id={u.email} class="even:bg-gray-100 font-light text-gray-500">
              <td class="p-4">{full_name(u)}</td>
              <td class="p-4">{u.email}</td>
            </tr>
          {/for}
        </tbody>
      </table>

      {#if @live_action == :add_user}
        <Modal title="New Device" return_to={Routes.live_path(@socket, __MODULE__)} id={:modal}>
          <Form for={:new_user} submit="add_user" class="mt-12" errors={@new_user_errors}>
            <div class="mb-6">
              <TextInput field_name={:first_name} placeholder="First name" />
            </div>

            <div class="mb-6">
              <TextInput field_name={:last_name} placeholder="Last name" />
            </div>

            <div class="mb-6">
              <TextInput field_name={:email} placeholder="Email" />
            </div>

            <div class="pt-6 flex justify-end">
              <Submit
                label="Add"
                class="bg-violet-600 text-white pt-1 pb-1 pl-5 pr-5 rounded font-light hover:bg-violet-700"
              />
            </div>
          </Form>
        </Modal>
      {/if}
    </div>
    """
  end

  def handle_event("add_user", %{"new_user" => params}, socket) do
    new_user_schema = %{first_name: :string, last_name: :string, email: :string}

    with {:ok, normalized} <- Params.normalize(new_user_schema, params),
         {:ok, new_user} <-
           Accounts.add_user(normalized.email, normalized.first_name, normalized.last_name) do
      send(self(), {:user_added, new_user})

      socket =
        socket
        |> assign(:new_user_errors, [])
        |> push_patch(to: Routes.live_path(socket, __MODULE__))

      {:noreply, socket}
    else
      {:error, changeset} ->
        {:noreply, assign(socket, :new_user_errors, changeset.errors)}
    end
  end

  def handle_info({:user_added, new_user}, socket) do
    socket = update(socket, :users, fn users -> [new_user | users] end)

    {:noreply, socket}
  end

  defp full_name(user) do
    "#{user.first_name} #{user.last_name}"
  end
end
