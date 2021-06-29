defmodule Chlorine.IDTest do
  use ExUnit.Case, async: true

  alias Chlorine.ID

  test "returns integers" do
    value = ID.get()
    assert is_integer(value)
  end
end
