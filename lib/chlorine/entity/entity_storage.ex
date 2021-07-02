defmodule Chlorine.Entity.Storage do
  @doc false
  use Agent

  alias Chlorine.{Component, Entity}
  require Entity

  @spec start_link(any()) :: {:error, any()} | {:ok, pid()}
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @spec add(Entity.id(), list(Component.id())) :: :ok
  def add(entity_id, entity_components) do
    Agent.update(__MODULE__, &Map.put(&1, entity_id, entity_components))
  end

  @spec get(Entity.id()) :: {:ok, Entity.t()} | Entity.not_found()
  def get(entity_id) do
    # Valid entities should not have their components as nil
    case get_components(entity_id) do
      nil ->
        {:error, :entity_not_found}

      components ->
        entity = %Chlorine.Entity{
          id: entity_id,
          components: components
        }

        {:ok, entity}
    end
  end

  def has_entity?(id) when Entity.is_id(id) do
    get(id) |> do_has_entity?()
  end

  defp do_has_entity?({:error, :entity_not_found}), do: false
  defp do_has_entity?({:ok, _entity}), do: true

  @spec remove(Entity.id()) :: :ok | Entity.not_found()
  def remove(entity_id) when Entity.is_id(entity_id) do
    with {:ok, entity} <- get(entity_id),
         :ok <-
           Enum.each(entity.components, fn {mod, _id} ->
             remove_component!(entity.id, mod)
           end),
         do: Agent.update(__MODULE__, &Map.delete(&1, entity_id))
  end

  @spec add_component!(Entity.id(), Component.id()) :: :ok
  def add_component!(entity_id, component_id) do
    entity_components = get_components(entity_id)

    Agent.update(
      __MODULE__,
      &%{&1 | entity_id => [component_id | entity_components]}
    )
  end

  @spec get_component(Entity.id(), module()) ::
          {:ok, Component.id()}
          | Entity.not_found()
  def get_component(id, module) when Entity.is_id(id) do
    if has_entity?(id) do
      res =
        get_components(id)
        |> Enum.filter(fn {mod, _id} -> mod == module end)
        |> List.first()

      {:ok, res}
    else
      {:error, :entity_not_found}
    end
  end

  @spec load!(Entity.id()) :: Chlorine.Entity.t()
  def load!(entity_id) do
    components =
      entity_id
      |> get_components()
      |> Enum.map(&Component.Storage.get/1)

    %Entity{
      id: entity_id,
      components: components
    }
  end

  @spec remove_component!(Entity.id(), module()) :: :ok
  def remove_component!(entity_id, module_to_remove) do
    entity_components = get_components(entity_id)

    new_components =
      Enum.filter(
        entity_components,
        fn {module, _id} = id ->
          if module == module_to_remove do
            :ok = Component.Storage.delete(id)
            false
          else
            true
          end
        end
      )

    Agent.update(__MODULE__, &%{&1 | entity_id => new_components})
  end

  @spec get_components(Entity.id()) :: list(Component.id())
  def get_components(entity_id) do
    # TODO: Maybe this is being overcalled
    Agent.get(__MODULE__, &Map.get(&1, entity_id))
  end
end
