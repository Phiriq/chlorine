defmodule ChlorineTest do
  use ExUnit.Case
  doctest Chlorine

  test "greets the world" do
    assert Chlorine.hello() == :world
  end
end
