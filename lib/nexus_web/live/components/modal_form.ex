defmodule NexusWeb.Components.ModalForm do
  @moduledoc """
  Component for a modal with a form

  This is combination of the `NexusWeb.Components.Modal` and
  `NexusWeb.Components.Form` components.
  """

  alias NexusWeb.Components.{Form, Modal}

  use NexusWeb, :surface_live_component

  @doc """
  Title of the modal
  """
  prop title, :string, required: true

  @doc """
  Where to return if the modal is existed
  """
  prop return_to, :string, required: true

  @doc """
  Event to emit when the form is submitted
  """
  prop submit, :string, required: true

  @doc """
  The name of the form data
  """
  prop for, :atom, required: true

  @doc """
  List of errors to provide to the form
  """
  prop errors, :list, default: []

  @doc """
  The form contents such as in inputs and selects
  """
  slot default

  def render(assigns) do
    ~F"""
    <div>
      <Modal id={@id} title={@title} return_to={@return_to}>
        <div class="mt-10">
          <Form for={@for} submit={@submit} errors={@errors}>
            <#slot />
          </Form>
        </div>
      </Modal>
    </div>
    """
  end
end
