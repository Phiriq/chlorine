defmodule Chlorine.System do
  defmacro __using__(for: block) do
    quote do
      defstruct components: unquote(List.wrap(block))
    end
  end
end
