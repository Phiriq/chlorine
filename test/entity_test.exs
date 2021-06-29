defmodule Chlorine.EntityTest do
  use ExUnit.Case, async: true

  alias Chlorine.{Entity, Component}

  defmodule Age do
    use Component

    defstruct age: 0
  end

  defmodule Position do
    use Component

    defstruct x: 0, y: 0
  end

  defmodule Alive do
    use Component

    defstruct health: 100
  end

  # Preferentially without naming a process
  defmodule Bunny do
    use Entity

    def components(), do: [%Age{age: 2}, Position]
  end

  setup do
    entity = Bunny.new()
    %{e: entity}
  end

  test "is a struct of Chlorine.Entity", %{e: entity} do
    assert %Entity{} = entity
  end

  # test "can create a new entity passing other parameters", %{e: entity} do
  #   assert %Entity{} = Bunny.new()
  # end

  test "can get data of the struct components", %{e: entity} do
    id = entity.id
    response = Entity.load(id)
    assert response.id == id
    assert [%Age{age: 2}, %Position{}] = response.components
  end

  test "can add a component to an entity", %{e: entity} do
    assert Entity.has_component?(entity, Alive) == false
    entity = Entity.add_component(entity.id, Alive)
    assert Entity.has_component?(entity, Alive) == true
  end

  test "can remove a component from an entity", %{e: entity} do
    {Position, position_component_id} = Entity.get_component(entity, Position)

    assert Entity.has_component?(entity, Position) == true
    entity = Entity.remove_component(entity, Position)
    assert Entity.has_component?(entity, Position) == false

    # Removing a component from an entity also removes it from the storage
    assert is_nil(Component.Storage.get({Position, position_component_id}))
  end
end
