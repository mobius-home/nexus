defmodule NexusWeb.Components.Modal do
  use Surface.LiveComponent

  alias Surface.Components.LivePatch

  slot default

  prop return_to, :string, required: true
  prop title, :string, required: true

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~F"""
    <div
      class="fixed bg-black/40 top-0 left-0 z-1 w-full h-full"
      phx-window-keydown="close"
      phx-key="escape"
      phx-target={@myself}
    >
      <div class="flex justify-center items-center h-screen">
        <div
          class="bg-white w-[500px] min-h-[300px] p-10 pt-6"
          phx-click-away="close"
          phx-target={@myself}
        >
          <div class="flex justify-end mb-4">
            <LivePatch to={@return_to} class="text-xl text-gray-400">
              &times;
            </LivePatch>
          </div>
          <h2 class="text-center text-2xl font-medium tracking-wide">{@title}</h2>
          <#slot />
        </div>
      </div>
    </div>
    """
  end

  def handle_event("close", _, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.return_to)}
  end
end
