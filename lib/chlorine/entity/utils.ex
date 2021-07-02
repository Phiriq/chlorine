defmodule Chlorine.Entity.Utils do
  @moduledoc false

  @doc false
  # @spec merge_structs([struct()], struct()) :: struct()
  def merge_structs(opts, component) do
    res = Enum.find(opts, fn y -> component.__struct__ == y.__struct__ end)

    unless is_nil(res) do
      Map.merge(component, res)
    else
      component
    end
  end

  @doc false
  @spec to_component_struct(module() | struct()) :: struct()
  def to_component_struct(component) when is_atom(component) do
    struct(component)
    # struct!(component)
  end

  def to_component_struct(component) when is_struct(component), do: component

  def to_component_struct(_component) do
    raise(Chlorine.InvalidComponentException)
  end
end
