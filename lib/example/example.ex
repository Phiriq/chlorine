defmodule Chlorine.Example.Age do
  use Chlorine.Component

  defstruct age: 0
end

defmodule Chlorine.Example.Move do
  use Chlorine.Component

  defstruct speed: 5
end

defmodule Chlorine.Example.Bunny do
  use Chlorine.Entity

  def components() do
    [
      Chlorine.Example.Age,
      %Chlorine.Example.Move{speed: 10}
    ]
  end
end
