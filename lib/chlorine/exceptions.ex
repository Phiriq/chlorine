defmodule Chlorine.InvalidComponentException do
  defexception message: """
               The provided value was not a valid component. Please provide valid components.

               Valid components are either structs or names of modules that `use Chlorine.Component`
               and have a `defstruct` block specifying its fields.
               """
end
