# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Nexus.Repo.insert!(%Nexus.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Nexus.Accounts

user_roles = ["admin", "product_maintainer", "user"]

for role <- user_roles do
  if !Accounts.get_role_by_name(role) do
    {:ok, _role} = Accounts.create_user_role(role)
  end
end

### Create admin user

user_email = "mobuis@nexus.com"
admin_role = Accounts.get_role_by_name("admin")

admin_user =
  case Accounts.get_user_by_email(user_email) do
    nil ->
      {:ok, user} = Accounts.add_user(user_email, "Agent", "Mobius", role: admin_role)
      user

    user ->
      user
  end

login_token = Accounts.create_login_token_for_user(admin_user)

login_url = NexusWeb.Router.Helpers.user_session_url(NexusWeb.Endpoint, :create, login_token)

IO.puts("""

======================= FINISH SET UP INSTRUCTION BELOW =====================

#########################
## Login as admin user ##
#########################

Run the phoenix server:

iex -S mix phx.server

And navigate to

#{login_url}
""")
