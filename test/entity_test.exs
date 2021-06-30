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

  test "raises if invalid components are provided" do
    defmodule InvalidComponents do
      use Entity

      def components(), do: [23, Age]
    end

    defmodule ValidComponents do
      use Entity

      def components(), do: [Position, Age]
    end

    assert_raise Chlorine.InvalidComponentException, fn ->
      InvalidComponents.new()
    end

    assert_raise Chlorine.InvalidComponentException, fn ->
      ValidComponents.new(["invalid component argument"])
    end
  end

  test "non-bang functions returns a tuple", %{e: start_entity} do
    # Add and remove components
    assert {:ok, entity} = Entity.add_component(start_entity.id, Alive)
    assert %Alive{} in Entity.load(entity.id).components
    assert {:ok, entity} = Entity.remove_component(entity, Alive)
    assert entity == start_entity

    new_id = Chlorine.ID.get()
    assert {:error, :entity_not_found} = Entity.add_component(new_id, Alive)
    assert {:error, :entity_not_found} = Entity.remove_component(new_id, Alive)
  end

  test "can remove an entity", %{e: entity} do
    %{id: id, components: components} = entity

    Entity.remove(id)
    assert is_nil(Entity.get(id))
    Enum.each(components, &assert_component_nil/1)
  end

  test "can override default parameters of components" do
    entity = Bunny.new(%Age{age: 10})
    assert %Entity{components: components} = Entity.load(entity.id)
    assert %Age{age: 10} in components == true
  end

  test "can create a new entity passing other components than defaults" do
    health = 10_000
    entity = Bunny.new([%Alive{health: health}])

    assert %Entity{components: components} = Entity.load(entity.id)
    assert %Alive{health: 10_000} in components
  end

  test "can load data of the struct components", %{e: %{id: id}} do
    entity = Entity.load(id)
    assert entity.id == id
    assert [%Age{age: 2}, %Position{x: 0, y: 0}] = entity.components
  end

  test "can add a component to an entity", %{e: entity} do
    assert Entity.has_component?(entity, Alive) == false
    entity = Entity.add_component!(entity.id, Alive)
    assert Entity.has_component?(entity, Alive) == true
  end

  test "can remove a component from an entity", %{e: entity} do
    {Position, position_component_id} = Entity.get_component(entity, Position)

    assert Entity.has_component?(entity, Position) == true
    entity = Entity.remove_component!(entity, Position)
    assert Entity.has_component?(entity, Position) == false

    # Removing a component from an entity also removes it from the storage
    assert_component_nil({Position, position_component_id})
  end

  defp assert_component_nil(component) do
    assert is_nil(Component.Storage.get(component))
  end
end
