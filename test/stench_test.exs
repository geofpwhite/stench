defmodule StenchTest do
  use ExUnit.Case
  doctest Stench.CLI

  test "6*2=12" do
    assert Stench.CLI.eval("6*2").cur_return == 12
    assert Stench.CLI.eval("(6*2)").cur_return == 12
    assert Stench.CLI.eval("(6*2)+1-1").cur_return == 12
  end
end
