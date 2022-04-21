defmodule NexusWeb.Components.Form.TextInput do
  @moduledoc """

  """

  use NexusWeb, :surface_component

  alias Surface.Components.Form.{ErrorTag, TextInput}

  prop field_name, :atom, required: true
  prop placeholder, :string

  def render(assigns) do
    ~F"""
    <div>
      <TextInput
        field={@field_name}
        class="shadow appearance-none border rounded w-full py-2 px-3 text-grey-darker"
        opts={placeholder: @placeholder}
      />

      <ErrorTag field={@field_name} class="text-red-400 font-light" />
    </div>
    """
  end
end
