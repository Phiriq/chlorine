defmodule Chlorine.SystemTest do
  use ExUnit.Case

  defmodule MockSystem do
    use Chlorine.System, for: [Age, Human]
  end
end
