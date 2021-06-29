defmodule Chlorine.Entity do
  @doc """

  """

  alias Chlorine.Component

  @type id :: Chlorine.ID.id()
  # TODO
  @type t :: none()

  defmacro __using__(_value) do
    quote do
      @behaviour Chlorine.Entity

      import Chlorine.Entity, only: [component: 1]

      def new() do
        components =
          __MODULE__.components()
          |> Enum.map(&unquote(__MODULE__).component/1)

        components_formatted = Enum.map(components, &{&1.data.__struct__, &1.id})
        id = Chlorine.ID.get()

        # Add components to the storage
        components_formatted
        |> Enum.zip(components)
        |> Enum.each(fn {a, b} -> Chlorine.Component.Storage.put(a, b.data) end)

        # Add entity to storage, linking its components
        Chlorine.Entity.Storage.add(id, components_formatted)

        components = %Chlorine.Entity{
          id: id,
          components: components_formatted
        }
      end
    end
  end

  defstruct [:id, :components]

  @callback components() :: list(Component.data() | atom())

  def component(component) when is_atom(component) do
    %{id: Chlorine.ID.get(), data: struct!(component)}
  end

  def component(component) when is_struct(component) do
    %{id: Chlorine.ID.get(), data: component}
  end

  def remove_component(entity, module_to_remove) do
    Chlorine.Entity.Storage.remove_component(entity.id, module_to_remove)
    get(entity.id)
  end

  def add_component(entity_id, comp) do
    %{id: id, data: _data} = component(comp)

    component_id = to_component_id(comp, id)
    :ok = Chlorine.Entity.Storage.add_component(entity_id, component_id)

    get(entity_id)
  end

  defp to_component_id(component, id) when is_atom(component) do
    {component, id}
  end

  defp to_component_id(component, id) when is_struct(component) do
    {component.__struct__, id}
  end

  # defdelegate remove_component(entity_id, module_to_remove), to: Chlorine.Entity.Storage
  defdelegate load(entity_id), to: Chlorine.Entity.Storage
  defdelegate get(entity_id), to: Chlorine.Entity.Storage

  @spec has_component?(atom | %{:components => any, optional(any) => any}, any) :: boolean
  def has_component?(entity, component_module) do
    Enum.any?(
      entity.components,
      fn {mod, _component_id} -> mod == component_module end
    )
  end

  def get_component(entity, module) do
    entity.components
    |> Enum.filter(fn {mod, _id} -> mod == module end)
    |> List.first()
  end
end
