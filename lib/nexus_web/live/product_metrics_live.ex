defmodule NexusWeb.ProductMetricsLive do
  use NexusWeb, :surface_view

  alias Nexus.Products
  alias NexusWeb.Params
  alias NexusWeb.Components.{ModalForm, ProductViewContainer}
  alias NexusWeb.Components.Form.TextInput

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
        <ModalForm
          id={:modal}
          title="New Metric"
          return_to={Routes.live_path(@socket, __MODULE__, @product.slug)}
          for={:new_metric}
          submit="add_metric"
          errors={@new_metric_errors}
        >
          <div class="mb-6">
            <TextInput field_name={:name} placeholder="Name" />
          </div>

          <div class="mb-6">
            <TextInput field_name={:type} placeholder="Type" />
          </div>
        </ModalForm>
      {/if}
    </ProductViewContainer>
    """
  end
end
