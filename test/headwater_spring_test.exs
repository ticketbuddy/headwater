defmodule HeadwaterSpringTest do
  use ExUnit.Case
  doctest HeadwaterSpring

  test "greets the world" do
    assert HeadwaterSpring.hello() == :world
  end
end
