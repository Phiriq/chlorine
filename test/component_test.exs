defmodule Chlorine.ComponentTest do
  use ExUnit.Case, async: true

  alias Chlorine.Component

  defmodule TestComponent do
    use Component

    defstruct test: :values
  end

  setup do
    component = Component.build(%TestComponent{})
    %{c: component}
  end

  test "build/1 returns the component metadata", %{c: component} do
    assert %{
             id: _id,
             data: %TestComponent{test: :values}
           } = component
  end
end
