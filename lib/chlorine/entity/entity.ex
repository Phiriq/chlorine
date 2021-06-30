defmodule Chlorine.Entity do
  @doc """

  """

  alias Chlorine.{Component, ID}
  alias Chlorine.Entity.Storage

  @type id :: ID.id()

  @type t :: %__MODULE__{
          id: id(),
          components: list(Component.id())
        }

  defstruct [:id, :components]

  @callback components() :: list(Component.data() | atom())

  defmacro __using__(_value) do
    quote do
      @behaviour Chlorine.Entity

      import Chlorine.Entity, only: [component: 1]

      def new(opts \\ []) do
        opts =
          opts
          |> List.wrap()
          |> Enum.map(&Chlorine.Entity.to_component_struct/1)

        # TODO: Maybe find a better way of doing this
        components =
          case opts do
            [] ->
              components()
              |> Enum.map(&Chlorine.Entity.to_component_struct/1)

            other ->
              components()
              |> Enum.map(&Chlorine.Entity.to_component_struct/1)
              |> Enum.map(&Chlorine.Entity.merge_structs(opts, &1))
              |> then(fn x ->
                x ++ Enum.filter(opts, fn x -> x not in components() end)
              end)
          end
          |> Enum.map(&Chlorine.Entity.component/1)

        components_formatted =
          Enum.map(
            components,
            &{&1.data.__struct__, &1.id}
          )

        id = Chlorine.ID.get()

        # Add components to the storage
        components_formatted
        |> Enum.zip(components)
        |> Enum.each(fn {a, b} ->
          Chlorine.Component.Storage.put(a, b.data)
        end)

        # Add entity to storage, linking its components
        Chlorine.Entity.Storage.add(id, components_formatted)

        %Chlorine.Entity{
          id: id,
          components: components_formatted
        }
      end
    end
  end

  def merge_structs(opts, component) do
    res = Enum.find(opts, fn y -> component.__struct__ == y.__struct__ end)

    unless is_nil(res) do
      Map.merge(component, res)
    else
      component
    end
  end

  # TODO: Make this return the chlorine Component type of struct
  # TODO: Move some things to an internal Utils module
  def component(component) when is_atom(component) do
    %{id: ID.get(), data: struct!(component)}
  end

  def component(component) when is_struct(component) do
    %{id: ID.get(), data: component}
  end

  # TODO: Add typespecs

  def remove_component!(entity, module_to_remove) do
    :ok = Storage.remove_component(entity.id, module_to_remove)
    get(entity.id)
  end

  def remove_component(entity, comp) when is_struct(entity) do
    remove_component(entity.id, comp)
  end

  def remove_component(entity_id, module_to_remove) do
    if Storage.has_entity?(entity_id) do
      :ok = Storage.remove_component(entity_id, module_to_remove)
      {:ok, get(entity_id)}
    else
      {:error, :entity_not_found}
    end
  end

  def add_component(entity, comp) when is_struct(entity) do
    add_component(entity.id, comp)
  end

  def add_component(entity_id, comp) when is_integer(entity_id) do
    %{id: id, data: data} = component(comp)
    component_id = to_component_id(comp, id)

    # TODO: Make a macro or function for this kind of things
    if Storage.has_entity?(entity_id) do
      :ok = Chlorine.Entity.Storage.add_component(entity_id, component_id)
      :ok = Component.Storage.put(component_id, data)
      {:ok, get(entity_id)}
    else
      {:error, :entity_not_found}
    end
  end

  def add_component!(entity_id, comp) do
    %{id: id, data: data} = component(comp)
    component_id = to_component_id(comp, id)
    :ok = Chlorine.Entity.Storage.add_component(entity_id, component_id)
    :ok = Component.Storage.put(component_id, data)

    get(entity_id)
  end

  defdelegate load(entity_id), to: Storage
  defdelegate get(entity_id), to: Storage
  defdelegate remove(entity_id), to: Storage

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

  def to_component_struct(component) when is_atom(component) do
    struct!(component)
  end

  def to_component_struct(component) when is_struct(component), do: component

  def to_component_struct(_component) do
    raise(Chlorine.InvalidComponentException)
  end

  defp to_component_id(component, id) when is_atom(component) do
    {component, id}
  end

  defp to_component_id(component, id) when is_struct(component) do
    {component.__struct__, id}
  end
end
