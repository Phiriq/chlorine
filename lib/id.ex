defmodule Chlorine.ID do
  use Agent

  @type id :: pos_integer()

  def get(), do: System.unique_integer([:positive])
end
