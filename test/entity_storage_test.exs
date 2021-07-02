defmodule Chlorine.EntityStorageTest do
  use ExUnit.Case, async: true

  alias Chlorine.Entity.Storage
  alias Chlorine.ID

  @components [{Foo, 1000}, {Bar, 10}]
  @other_component {Test, 23}

  test "can add entities in the storage" do
    data = 234_234
    Storage.add(data, [{Foo, 234}])
  end

  test "can retrieve elements from the storage" do
    id1 = ID.get()
    id2 = ID.get()

    other = [@other_component | @components]

    Storage.add(id1, @components)
    Storage.add(id2, other)

    assert Storage.get_components(id1) == @components
    assert Storage.get_components(id2) == other
  end

  test "can add components to existing entities" do
    id = ID.get()
    new_component = {Baz, 1200}

    Storage.add(id, @components)
    Storage.add_component!(id, new_component)
    assert Storage.get_components(id) == [new_component | @components]
  end

  test "returns nil if the key is not found" do
    assert is_nil(Storage.get_components({ModuleBar, 45}))
  end
end
