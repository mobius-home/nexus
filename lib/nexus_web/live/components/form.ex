defmodule NexusWeb.Components.Form do
  @moduledoc """

  """

  use NexusWeb, :surface_component

  alias Surface.Components.Form
  alias Surface.Components.Form.Submit

  prop for, :atom, required: true
  prop submit, :string, required: true
  prop errors, :list, default: []

  slot default

  def render(assigns) do
    ~F"""
    <Form for={@for} submit={@submit} errors={@errors}>
      <#slot />
      <div class="pt-6 flex justify-end">
        <Submit
          label="Add"
          class="bg-violet-600 text-white pt-1 pb-1 pl-5 pr-5 rounded font-light hover:bg-violet-700"
        />
      </div>
    </Form>
    """
  end
end
