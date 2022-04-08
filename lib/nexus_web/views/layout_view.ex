defmodule NexusWeb.LayoutView do
  use NexusWeb, :view

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def user_full_name(user) do
    user.first_name <> " " <> user.last_name
  end

  def user_admin?(user) do
    user.role.name == "admin"
  end
end
