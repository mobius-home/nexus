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

alias Nexus.Products

product =
  case Products.get_product_by_slug("example-product") do
    nil ->
      {:ok, product} = Products.create_product("Example Product")
      product

    product ->
      product
  end

case Products.get_device_for_product_by_device_slug(product, "ex123board") do
  nil ->
    {:ok, device} = Products.create_device_for_product(product, "EX123BOARD")
    device

  device ->
    device
end

case Products.get_metric_for_product_by_slug(product, "vm-memory-total-last-value") do
  nil ->
    {:ok, metric} = Products.create_metric_for_product(product, "vm.memory.total", "last_value")
    metric

  metric ->
    metric
end
