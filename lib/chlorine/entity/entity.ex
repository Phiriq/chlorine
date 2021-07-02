defmodule Chlorine.Entity do
  @doc """

  """
  alias Chlorine.{Component, ID}
  alias Chlorine.Entity.Storage

  @type id() :: ID.id()
  @type not_found() :: {:error, :entity_not_found}

  @type t() :: %__MODULE__{
          id: id(),
          components: list(Component.id())
        }

  defstruct [:id, :components]

  defguard is_id(entity_id) when is_integer(entity_id)

  @callback components() :: list(Component.data() | atom())

  defmacro __using__(_value) do
    quote do
      @behaviour Chlorine.Entity

      alias Chlorine.{Entity, Component, ID}

      @doc false
      def new(opts \\ []) do
        opts =
          opts
          |> List.wrap()
          |> Enum.map(&Entity.Utils.to_component_struct/1)

        # TODO: Seems to be duplicating some arguments of this function in the components
        # TODO: Maybe find a better way of doing this
        components =
          case opts do
            [] ->
              components()
              |> Enum.map(&Entity.Utils.to_component_struct/1)

            other ->
              components()
              |> Enum.map(&Entity.Utils.to_component_struct/1)
              |> Enum.map(&Entity.Utils.merge_structs(opts, &1))
              |> then(fn x ->
                x ++ Enum.filter(opts, fn x -> x not in components() end)
              end)
          end
          |> Enum.map(&Component.build/1)

        components_formatted =
          Enum.map(
            components,
            &{&1.data.__struct__, &1.id}
          )

        id = ID.get()

        # Add components to the storage
        components_formatted
        |> Enum.zip(components)
        |> Enum.each(fn {a, b} ->
          Component.Storage.put(a, b.data)
        end)

        # Add entity to storage, linking its components
        Entity.Storage.add(id, components_formatted)

        id
      end
    end
  end

  @doc """
  Removes the `component` of the given module from the entity.

      iex> alias Chlorine.Example.{Age, Bunny}
      iex> alias Chlorine.Entity
      iex> bunny = Bunny.new(%Age{age: 3})
      iex> Entity.has_component?(bunny, Age)
      {:ok, true}
      iex> Entity.remove_component(bunny, Age)
      :ok
      iex> Entity.has_component?(bunny, Age)
      {:ok, false}
  """
  @spec remove_component(id(), module()) ::
          :ok
          | not_found()
          | Component.not_found()
  def remove_component(entity_id, component) when is_id(entity_id) do
    with {:ok, true} <- has_component?(entity_id, component) do
      Storage.remove_component!(entity_id, component)
    else
      {:ok, false} -> {:error, :component_not_found}
      err -> err
    end
  end

  @doc """
  Adds the given `component` to `entity`.

      iex> alias Chlorine.Example.{Age, Bunny}
      iex> alias Chlorine.Entity
      iex> defmodule Attack do
      ...>   use Chlorine.Component
      ...>   defstruct damage: 10
      ...> end
      iex> bunny = Bunny.new()
      iex> Entity.has_component?(bunny, Attack)
      {:ok, false}
      # You can also pass it as a initialized component struct
      iex> Entity.add_component(bunny, struct!(Attack, [damage: 1]))
      iex> Entity.has_component?(bunny, Attack)
      {:ok, true}
  """
  @spec add_component(id(), module() | Component.t()) :: :ok | not_found()
  def add_component(entity, component) when is_id(entity) do
    if Storage.has_entity?(entity) do
      %Component{id: id, data: data} = Component.build(component)
      component_id = to_component_id(component, id)

      :ok = Storage.add_component!(entity, component_id)
      :ok = Component.Storage.put(component_id, data)
    else
      {:error, :entity_not_found}
    end
  end

  @doc """
  Loads the components of the given `entity`.

      iex> alias Chlorine.Example.{Bunny, Move}
      iex> bunny = Bunny.new([%Move{speed: 100}])
      iex> {:ok, %Chlorine.Entity{components: components, id: _id}} = Chlorine.Entity.load(bunny)
      iex> components
      # TODO: Remove duplicated component
      [%Chlorine.Example.Age{age: 0}, %Chlorine.Example.Move{speed: 100}, %Chlorine.Example.Move{speed: 100}]
  """
  @spec load(id()) :: {:ok, Chlorine.Entity.t()} | not_found()
  def load(entity) do
    if has_entity?(entity) do
      {:ok, Storage.load!(entity)}
    else
      {:error, :entity_not_found}
    end
  end

  defdelegate has_entity?(id), to: Storage

  @doc """
  Removes the given `entity`.

  iex> bunny = Chlorine.Example.Bunny.new()
  iex> Chlorine.Entity.remove(bunny)
  iex> Chlorine.Entity.load(bunny)
  {:error, :entity_not_found}
  """
  @spec remove(id()) :: :ok | not_found()
  def remove(entity) when is_id(entity) do
    Storage.remove(entity)
  end

  @doc """
  Checks if `entity` contains a component `component`.

  iex> alias Chlorine.Example.{Age, Bunny}
  iex> bunny = Bunny.new() # Our `Bunny` is built with an `Age` component by default.
  iex> Chlorine.Entity.has_component?(bunny, Age)
  {:ok, true}
  """
  @spec has_component?(id(), module()) :: {:ok, boolean()} | not_found()
  def has_component?(entity, component_module) when is_id(entity) do
    if has_entity?(entity) do
      components = Storage.get_components(entity)

      res =
        Enum.any?(
          components,
          fn {mod, _component_id} -> mod == component_module end
        )

      {:ok, res}
    else
      {:error, :entity_not_found}
    end
  end

  @doc """
  Loads and gets the given `component`, from `entity`

      iex> alias Chlorine.Example.{Age, Bunny}
      iex> bunny = Bunny.new()
      iex> Chlorine.Entity.get_component(bunny, Age)
      {:ok, %Chlorine.Example.Age{age: 0}}
  """
  @spec get_component(id(), module()) :: {:ok, Component.t()} | not_found()
  def get_component(entity, component) when is_id(entity) do
    components_id = Storage.get_components(entity)

    with {:ok, true} <- has_component?(entity, component),
         [component | _] = components_id do
      {:ok, Component.Storage.get(component)}
    else
      {:ok, false} -> {:error, :component_not_found}
      res -> res
    end
  end

  defp to_component_id(component, id) when is_atom(component) do
    {component, id}
  end

  defp to_component_id(component, id) when is_struct(component) do
    {component.__struct__, id}
  end
end
