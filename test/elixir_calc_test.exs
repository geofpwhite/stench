defmodule ElixirCalcTest do
  use ExUnit.Case
  doctest ElixirCalc

  test "greets the world" do
    assert ElixirCalc.hello() == :world
  end
end
