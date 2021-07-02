defmodule Chlorine.Component do
  @doc """

  """

  alias Chlorine.ID

  @type id :: {module(), ID.id()}
  @type data :: struct()
  @type t :: %__MODULE__{id: ID.id(), data: struct()}
  @type not_found() :: {:error, :component_not_found}

  defstruct [:id, :data]

  defmacro __using__(_values) do
    quote do
      # TODO: Maybe don't inject this on the module
      # def _chlorine_build(custom_data) do
      # Use the __struct__ field to identify a component kind

      # The key idea is, have a struct of the module containing an ID.
      # Then we search for the types on the storage using this struct and its __struct__ field and the ID it holds.

      # Entities that reference its components on a list called `components`,
      # will have the same format, `{module_name, component_id}` where component_id is the id of this struct.

      # Data on these structs should be only used in creation, since we would later
      # Store them on the storage map.

      # data = Map.merge(__MODULE__.default(), custom_data)
      # %__MODULE__{id: Chlorine.ID.get(), data: data}
      # %{id: Chlorine.ID.get(), data: custom_data}
      # end
    end
  end

  # # TODO: Document this
  # def build(component_struct) when is_struct(component_struct) do
  #   apply(component_struct.__struct__, :_chlorine_new, [component_struct])
  # end

  # TODO: These probably will only be needed internally
  # defdelegate get(module), to: Chlorine.Component.Storage
  # defdelegate put(component_id, component_value), to: Chlorine.Component.Storage
  # defdelegate delete(component_id), to: Chlorine.Component.Storage

  @doc false
  @spec build(atom | map) :: t()
  def build(component) when is_atom(component) do
    %__MODULE__{id: ID.get(), data: struct!(component)}
  end

  def build(component) when is_struct(component) do
    %__MODULE__{id: ID.get(), data: component}
  end
end
