defmodule Chlorine.EntityTest do
  use ExUnit.Case, async: true
  doctest Chlorine.Entity

  alias Chlorine.{Entity, Component, ID}

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

  defmodule Bunny do
    use Entity

    def components(), do: [%Age{age: 2}, Position]
  end

  setup do
    entity = Bunny.new()
    %{e: entity}
  end

  test "entity new/1 returns an integer", %{e: entity} do
    assert is_integer(entity)
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

  describe "add and remove" do
    test "remove/1 removes an entity and its components", %{e: entity} do
      components = Entity.Storage.get_components(entity)
      assert :ok = Entity.remove(entity)
      assert {:error, :entity_not_found} = Entity.load(entity)
      assert Enum.all?(components, &assert_component_nil/1)
    end

    test "remove/1 errors out if entity does not exist" do
      assert {:error, :entity_not_found} = Entity.remove(ID.get())
    end

    test "remove_component/2 can remove a component from an entity", %{e: entity} do
      {:ok, {Position, position_component_id}} = Entity.Storage.get_component(entity, Position)

      assert {:ok, true} = Entity.has_component?(entity, Position)
      :ok = Entity.remove_component(entity, Position)
      assert {:ok, false} = Entity.has_component?(entity, Position)

      assert_component_nil({Position, position_component_id})
    end

    test "remove_component/2 errors out if entity or component does not exist", %{e: entity} do
      assert {:error, :component_not_found} = Entity.remove_component(entity, FooBar)
      assert {:error, :entity_not_found} = Entity.remove_component(ID.get(), Alive)
    end

    test "add_component/2 can add a module component to an entity", %{e: entity} do
      assert {:ok, false} = Entity.has_component?(entity, Alive)
      :ok = Entity.add_component(entity, Alive)
      assert {:ok, true} = Entity.has_component?(entity, Alive)
    end

    test "add_component/2 can add a struct component to an entity", %{e: entity} do
      assert {:ok, false} = Entity.has_component?(entity, Alive)
      :ok = Entity.add_component(entity, %Alive{health: 25})
      assert {:ok, true} = Entity.has_component?(entity, Alive)
    end

    test "add_component/2 errors out if component or entity does not exist", %{e: _entity} do
      # TODO: assert {:error, :component_not_found} = Entity.add_component(entity, FooBar)
      assert {:error, :entity_not_found} = Entity.add_component(ID.get(), Alive)
    end
  end

  describe "loading entities" do
    test "load/1 loads an entity and its components", %{e: entity} do
      assert {:ok, %Entity{components: components}} = Entity.load(entity)
      assert [%Age{age: 2}, %Position{x: 0, y: 0}] = components
    end

    test "load/1 errors out if an entity does not exist" do
      assert {:error, :entity_not_found} = Entity.load(ID.get())
    end

    test "get_component/2 returns the given component", %{e: entity} do
      assert {:ok, %Age{age: 2}} = Entity.get_component(entity, Age)
    end

    test "get_component/2 errors out if entity or component does not exist", %{e: entity} do
      assert {:error, :component_not_found} = Entity.get_component(entity, FooBar)
      assert {:error, :entity_not_found} = Entity.get_component(ID.get(), Age)
    end
  end

  describe "entity creation" do
    test "can override default parameters of components" do
      entity = Bunny.new(%Age{age: 10})
      assert {:ok, %Entity{components: components}} = Entity.load(entity)
      assert %Age{age: 10} in components == true
    end

    test "can create a new entity passing other components than defaults" do
      health = 10_000
      entity = Bunny.new([%Alive{health: health}])

      assert {:ok, %Entity{components: components}} = Entity.load(entity)
      assert %Alive{health: 10_000} in components
    end
  end

  defp assert_component_nil(component) do
    assert is_nil(Component.Storage.get(component))
  end
end
