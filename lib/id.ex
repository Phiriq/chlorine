defmodule Chlorine.ID do
  @type id :: pos_integer()

  def get(), do: System.unique_integer([:positive])
end
