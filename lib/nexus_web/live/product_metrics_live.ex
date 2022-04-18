defmodule NexusWeb.ProductMetricsLive do
  use NexusWeb, :surface_view

  alias Nexus.Products
  alias NexusWeb.Params
  alias NexusWeb.Components.{Modal, ProductViewContainer}
  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, TextInput, Submit}

  on_mount NexusWeb.UserLiveAuth
  on_mount {NexusWeb.GetResourceLive, :product}

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:metrics, Products.get_metrics_for_product(socket.assigns.product))
      |> assign(:new_metric_errors, [])

    {:ok, socket, temporary_assigns: [metrics: []]}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def handle_event("add_metric", %{"new_metric" => params}, socket) do
    new_metric_schema = %{name: :string, type: :string}
    product = socket.assigns.product

    with {:ok, normalized} <- Params.normalize(new_metric_schema, params),
         {:ok, new_metric} <-
           Products.create_metric_for_product(product, normalized.name, normalized.type) do
      socket =
        socket
        |> assign(:new_metric_errors, [])
        |> update(:metrics, fn metrics -> [new_metric | metrics] end)
        |> push_patch(to: Routes.live_path(socket, __MODULE__, product.slug))

      {:noreply, socket}
    else
      {:error, changeset} ->
        IO.inspect(changeset)
        {:noreply, assign(socket, :new_metric_errors, changeset.errors)}
    end
  end

  def render(assigns) do
    ~F"""
    <ProductViewContainer
      product={@product}
      socket={@socket}
      page={:metrics}
      modal_button_label="Add metric"
      modal_button_to={Routes.product_metrics_path(@socket, :add_metric, @product.slug)}
    >
      <table class="table-auto w-full">
        <thead>
          <tr>
            <th class="text-left border-b-2 font-medium text-sm p-4 pb-2 text-gray-600">Name</th>
            <th class="text-left border-b-2 font-medium text-sm p-4 pb-2 text-gray-600">Type</th>
          </tr>
        </thead>
        <tbody id="metrics" phx-update="prepend">
          {#for m <- @metrics}
            <tr id={m.slug} class="even:bg-gray-100 font-light text-gray-500">
              <td class="p-4">{m.name}</td>
              <td class="p-4">{m.type}</td>
            </tr>
          {/for}
        </tbody>
      </table>

      {#if @live_action == :add_metric}
        <Modal
          title="New Device"
          return_to={Routes.live_path(@socket, __MODULE__, @product.slug)}
          id={:modal}
        >
          <Form for={:new_metric} submit="add_metric" class="mt-12" errors={@new_metric_errors}>
            <div class="mb-6">
              <TextInput
                field={:name}
                class="shadow appearance-none border rounded w-full py-2 px-3 text-grey-darker"
                opts={placeholder: "Name"}
              />

              <ErrorTag field={:name} class="text-red-400 font-light" />
            </div>

            <div class="mb-6">
              <TextInput
                field={:type}
                class="shadow appearance-none border rounded w-full py-2 px-3 text-grey-darker"
                opts={placeholder: "Type"}
              />

              <ErrorTag field={:type} class="text-red-400 font-light" />
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
    </ProductViewContainer>
    """
  end
end
