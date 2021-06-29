defmodule Chlorine.Entity.Storage do
  @doc false
  use Agent

  alias Chlorine.{Component, Entity}

  # TODO: opts
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @spec add(Entity.id(), list(Component.id())) :: :ok
  def add(entity_id, entity_components) do
    Agent.update(__MODULE__, &Map.put(&1, entity_id, entity_components))
  end

  def get(entity_id) do
    %{
      id: entity_id,
      components: get_components(entity_id)
    }
  end

  @spec add_component(Entity.id(), Component.id()) :: :ok
  def add_component(entity_id, component_id) do
    entity_components = get_components(entity_id)

    Agent.update(
      __MODULE__,
      &%{&1 | entity_id => [component_id | entity_components]}
    )
  end

  # TODO: Handle cases where ID don't belong to an entity
  def load(entity_id) do
    components =
      entity_id
      |> get_components()
      |> Enum.map(&Component.Storage.get/1)

    %{
      id: entity_id,
      components: components
    }
  end

  @spec remove_component(Entity.id(), module()) :: :ok
  def remove_component(entity_id, module_to_remove) do
    entity_components = get_components(entity_id)

    # TODO: Document exactly how this work to have it as a reference.
    # TODO: Write tests for failure cases of what we already have.
    new_components =
      Enum.reject(
        entity_components,
        fn {module, id} ->
          if module == module_to_remove do
            :ok = Component.Storage.delete({module, id})
            true
          else
            false
          end
        end
      )

    Agent.update(
      __MODULE__,
      &%{&1 | entity_id => new_components}
    )
  end

  @spec get_components(Entity.id()) :: list(Component.id())
  def get_components(entity_id) do
    Agent.get(__MODULE__, &Map.get(&1, entity_id))
  end
end
