defmodule NexusWeb.ProductsLive do
  use NexusWeb, :surface_view

  alias Nexus.Products
  alias NexusWeb.Params
  alias NexusWeb.Components.Modal
  alias Surface.Components.{Form, LivePatch, LiveRedirect}
  alias Surface.Components.Form.{ErrorTag, Submit, TextInput}

  on_mount NexusWeb.UserLiveAuth

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:products, Products.all())
      |> assign(:new_product_errors, [])

    {:ok, socket, temporary_assigns: [products: []]}
  end

  def handle_params(_params, _session, socket) do
    {:noreply, socket}
  end

  def handle_event("add_product", %{"new_product" => params}, socket) do
    schema = [
      name: %{type: :string, required: true}
    ]

    with {:ok, normalized} <- Params.normalize(schema, params),
         {:ok, new_product} <- Products.create_product(normalized.name) do
      socket =
        socket
        |> assign(:new_product_errors, [])
        |> update(:products, fn products -> [new_product | products] end)
        |> push_patch(to: Routes.live_path(socket, __MODULE__))

      {:noreply, socket}
    else
      {:error, changeset} ->
        {:noreply, assign(socket, :new_product_errors, changeset.errors)}
    end
  end

  def render(assigns) do
    ~F"""
    <div>
      <h2 class="mb-8 text-gray-500 text-xl font-bold tracking-wide">Products</h2>
      <div class="grid grid-cols-2 gap-10">
        <div id="products" phx-update="append" class="contents">
          {#for product <- @products}
            <div class="w-100 bg-white rounded drop-shadow-sm h-[200px] p-5" id={product.name}>
              <LiveRedirect
                label={product.name}
                to={Routes.live_path(@socket, NexusWeb.ProductLive, product.slug)}
                class="block"
              />

              <div class="flex justify-start mt-10">
                <div class="border-r py-2 w-1/4">
                  <p class="font-extralight mb-2">Devices</p>
                  <p>500</p>
                </div>

                <div class="border-r py-2 pl-5 w-1/4">
                  <p class="font-extralight mb-2">Metrics</p>
                  <p>20</p>
                </div>

                <div class="border-r py-2 pl-5 w-1/4">
                  <p class="font-extralight mb-2">Latest Firmware</p>
                  <p>1.5.5</p>
                </div>

                <div class="py-2 pl-5 w-1/4">
                  <p class="font-extralight mb-2">Other Info</p>
                  <p>1234</p>
                </div>
              </div>
            </div>
          {/for}
        </div>
        <div class="w-100 rounded h-[200px] p-5 border hover:bg-gray-300 hover:cursor-pointer">
          <LivePatch to={Routes.products_path(@socket, :add_product)}>
            <div class="flex justify-center items-center min-h-full">
              <p>+ New product</p>
            </div>
          </LivePatch>
        </div>
      </div>
      {#if @live_action == :add_product}
        <Modal id="modal" title="New product" return_to={Routes.live_path(@socket, __MODULE__)}>
          <Form for={:new_product} submit="add_product" errors={@new_product_errors} class="mt-10">
            <TextInput
              field={:name}
              class="shadow appearance-none border rounded w-full py-2 px-3 text-grey-darker"
              opts={placeholder: "Product name"}
            />

            <ErrorTag field={:name} class="text-red-400 font-light" />

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
end
