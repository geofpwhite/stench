defmodule StenchTest do
  use ExUnit.Case
  doctest Stench.CLI

  test "6*2=12" do
    assert Stench.CLI.eval("6*2").cur_return.value == 12
    assert Stench.CLI.eval("(6*2)").cur_return.value == 12
    assert Stench.CLI.eval("(6*2)+(1-1)").cur_return.value == 12
  end

  test "assignment" do
    state = Stench.CLI.eval("a=1;b=2;c=b+a")
    assert state.vars["a"].value == 1 and state.vars["a"].type == :int
    assert state.vars["b"].value == 2 and state.vars["b"].type == :int
    assert state.vars["c"].value == 3 and state.vars["c"].type == :int
  end

  test "string concatenation" do
    state = Stench.CLI.eval("str1=\"hello\";str2=\"world\";str3=str1+str2")
    assert state.vars["str1"].value == "hello" and state.vars["str1"].type == :string
    assert state.vars["str2"].value == "world" and state.vars["str2"].type == :string
    assert state.vars["str3"].value == "helloworld" and state.vars["str3"].type == :string
  end

  test "complex integer operations" do
    state = Stench.CLI.eval("x=10;y=5;z=(x*y)-(x/y)")
    assert state.vars["x"].value == 10 and state.vars["x"].type == :int
    assert state.vars["y"].value == 5 and state.vars["y"].type == :int
    assert state.vars["z"].value == 48 and state.vars["z"].type == :int
  end

  test "variable overwriting" do
    state = Stench.CLI.eval("a=5;a=10")
    assert state.vars["a"].value == 10 and state.vars["a"].type == :int
  end

  test "boolean operators" do
    state = Stench.CLI.eval("1 is 2")
    assert state.cur_return.type == :bool and state.cur_return.value == false
    state = Stench.CLI.eval("1 is 1")
    assert state.cur_return.type == :bool and state.cur_return.value == true
  end

  test "conditional statements" do
    state = Stench.CLI.eval("a = 4; if a is 4 { a = 5 }")
    assert state.cur_return.type == :int and state.vars["a"].value == 5
  end

  test "pileups" do
    state = Stench.CLI.eval("a = 4; pileup i=0 ; i<10 ; i=i+1 { a = 5 };")
    assert state.cur_return.type == :int and state.vars["a"].value == 5
    state = Stench.CLI.eval("a = 4; pileup i := [1,2,3] { a = i }")
    IO.puts(inspect(state))
    assert state.cur_return.type == :int and state.vars["a"].value == 3
  end

  test "prints" do
    state = Stench.CLI.eval("print 4")
    assert state.cur_return.type == :nil
  end

  test "macros" do
    assert Builtins.builtins() != nil
    assert Keywords.keywords() != nil
    assert Operators.operators() != nil
  end
end
