defmodule Chlorine.ComponentStorageTest do
  use ExUnit.Case, async: true

  alias Chlorine.Component.Storage
  alias Chlorine.ID

  @id1 ID.get()
  @id2 ID.get()

  @component1 {ModuleFoo, @id1}
  @component2 {ModuleFoo, @id2}

  @data %{
    hello: :world,
    foo: :bar
  }

  @data2 %{
    hello: :john,
    bar: :foo
  }

  test "put elements in the storage" do
    Storage.put(@component1, @data)
  end

  test "retrieve elements from the storage" do
    Storage.put(@component1, @data)
    Storage.put(@component2, @data2)

    # Retrieve a single component of the module
    assert Storage.get(@component1) == @data

    # Retrieve all the components of given type
    assert Storage.get(ModuleFoo) == %{
             @id1 => @data,
             @id2 => @data2
           }
  end

  test "delete components in the storage" do
    Storage.put(@component1, @data)

    Storage.delete(@component1)
    assert is_nil(Storage.get(@component1))
  end

  test "returns nil if the key is not found" do
    assert is_nil(Storage.get(InexistentModule))
    assert is_nil(Storage.get({ModuleBar, 45}))
  end
end
