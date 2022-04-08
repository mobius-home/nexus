
alias Nexus.Accounts

user_roles = ["admin", "product_maintainer", "user"]

for role <- user_roles do
  if !Accounts.get_role_by_name(role) do
    {:ok, _role} = Accounts.create_user_role(role)
  end
end
