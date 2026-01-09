defmodule StenchTest.Arithmetic do
  use ExUnit.Case

  test "6*2=12" do
    assert Stench.CLI.eval("6*2").cur_return.value == 12
    assert Stench.CLI.eval("(6*2)").cur_return.value == 12
    assert Stench.CLI.eval("(6*2)+(1-1)").cur_return.value == 12
    assert Stench.CLI.eval("6*2+1-1").cur_return.value == 12
  end

  test "complex integer operations" do
    state = Stench.CLI.eval("x=10;y=5;z=(x*y)-(x/y)")
    assert state.vars["x"].value == 10 and state.vars["x"].type == :num
    assert state.vars["y"].value == 5 and state.vars["y"].type == :num
    assert state.vars["z"].value == 48 and state.vars["z"].type == :num
  end
end

defmodule StenchTest.Assignment do
  use ExUnit.Case

  test "assignment" do
    state = Stench.CLI.eval("a=1;b=2;c=b+a")
    assert state.vars["a"].value == 1 and state.vars["a"].type == :num
    assert state.vars["b"].value == 2 and state.vars["b"].type == :num
    assert state.vars["c"].value == 3 and state.vars["c"].type == :num
  end
end

defmodule StenchTest.StringOperations do
  use ExUnit.Case

  test "string concatenation" do
    state = Stench.CLI.eval("str1=\"hello\";str2=\"world\";str3=str1+str2")
    assert state.vars["str1"].value == "hello" and state.vars["str1"].type == :string
    assert state.vars["str2"].value == "world" and state.vars["str2"].type == :string
    assert state.vars["str3"].value == "helloworld" and state.vars["str3"].type == :string
  end
end

defmodule StenchTest.Variable do
  use ExUnit.Case

  test "variable overwriting" do
    state = Stench.CLI.eval("a=5;a=10")
    assert state.vars["a"].value == 10 and state.vars["a"].type == :num
  end
end

defmodule StenchTest.BooleanOperators do
  use ExUnit.Case

  test "boolean operators" do
    state = Stench.CLI.eval("not true;")
    assert state.cur_return.type == :bool and state.cur_return.value == false
    state = Stench.CLI.eval("not false")
    assert state.cur_return.type == :bool and state.cur_return.value == true
    state = Stench.CLI.eval("false")
    assert state.cur_return.type == :bool and state.cur_return.value == false
    state = Stench.CLI.eval("true")
    assert state.cur_return.type == :bool and state.cur_return.value == true
    state = Stench.CLI.eval("false and true ")
    assert state.cur_return.type == :bool and state.cur_return.value == false
    state = Stench.CLI.eval("true and not false")
    assert state.cur_return.type == :bool and state.cur_return.value == true
    state = Stench.CLI.eval("true and not true")
    assert state.cur_return.type == :bool and state.cur_return.value == false
    state = Stench.CLI.eval("1 is 2")
    assert state.cur_return.type == :bool and state.cur_return.value == false
    state = Stench.CLI.eval("1 is 1")
    assert state.cur_return.type == :bool and state.cur_return.value == true
    state = Stench.CLI.eval("((1 is 2) and (1 is 1));")
    assert state.cur_return.type == :bool and state.cur_return.value == false
    state = Stench.CLI.eval("2 is 2 and (1 is 1);")
    assert state.cur_return.type == :bool and state.cur_return.value == true
    state = Stench.CLI.eval("(1 is 1) or (1 is 2);")
    assert state.cur_return.type == :bool and state.cur_return.value == true
    state = Stench.CLI.eval("1 is 1 or (1 is 2);")
    assert state.cur_return.type == :bool and state.cur_return.value == true
  end
end

defmodule StenchTest.ControlFlow do
  use ExUnit.Case

  test "conditional statements" do
    state = Stench.CLI.eval("a = 4; if a is 4 { a = 5 }")
    assert state.cur_return.type == :num and state.vars["a"].value == 5

    state = Stench.CLI.eval("a = 4; if a is 5 { a = 5; } else { a = 6; }")
    assert state.vars["a"].type == :num and state.vars["a"].value == 6
  end

  test "pileups" do
    state = Stench.CLI.eval("a = 4; pileup i=0 ; i<10 ; i=i+1 { a = i;}")
    assert state.cur_return.type == :num and state.vars["a"].value == 9
    state = Stench.CLI.eval("a = 4; pileup i := [1,2,3] { a = i;}")
    assert state.cur_return.type == :num and state.vars["a"].value == 3
    state = Stench.CLI.eval("""
    a = 4;
    pileup i := [1,2]{
      pileup i := [1,2,3] {
        a = i;
        if a is 2 {
          break;
        }
      }
      break;
    }
    """)
    assert state.vars["a"].type == :num and state.vars["a"].value == 2
  end
end

defmodule StenchTest.Dumps do
  use ExUnit.Case

  test "dumps" do
    state = Stench.CLI.eval("dump 4")
    assert state.cur_return.type == nil
  end
end

defmodule StenchTest.FileExecution do
  use ExUnit.Case

  test "interpret file" do
    s = Stench.CLI.exec("stench_examples/example.stench")
    assert s.vars["a"].type == :num and s.vars["a"].value == 71
    s = Stench.CLI.exec("stench_examples/for_each.stench")
    assert s.vars["a"].type == :num and s.vars["a"].value == 141
    s = Stench.CLI.exec("stench_examples/nested_normal_pileups.stench")
    assert s.vars["a"].type == :num and s.vars["a"].value == 91
    s = Stench.CLI.exec("stench_examples/odors.stench")
    assert s.vars["x"].type == :num and s.vars["x"].value == 5
    s = Stench.CLI.exec("stench_examples/factorial.stench")
    assert s.vars["x"].type == :num and s.vars["x"].value == 120
  end
end

defmodule StenchTest.ArrayAccesses do
  use ExUnit.Case

  test "array accesses" do
    state = Stench.CLI.eval("arr = [1, 2, 3, 4, 5]; x = arr[2]")
    assert state.vars["arr"].type == :bucket
    assert state.vars["arr"].value == Enum.map(1..5, fn num -> %Var{type: :num, value: num} end)
    assert state.vars["x"].type == :num
    assert state.vars["x"].value == 3

    state = Stench.CLI.eval("arr = [10, 20, 30]; arr[1] = 15")
    assert state.vars["arr"].type == :bucket

    assert state.vars["arr"].value ==
             Enum.map([10, 15, 30], fn num -> %Var{type: :num, value: num} end)

    state = Stench.CLI.eval("arr = [1, 2, 3]; y = arr[0] + arr[2]")
    assert state.vars["y"].type == :num
    assert state.vars["y"].value == 4
  end

  test "nested bucket accesses" do
    state = Stench.CLI.eval("arr = [[10, 20], [30, 40]]; arr[0][1] = 25")
    assert state.vars["arr"].type == :bucket

    assert state.vars["arr"].value == [
             %Var{
               type: :bucket,
               value: Enum.map([10, 25], fn num -> %Var{type: :num, value: num} end)
             },
             %Var{
               type: :bucket,
               value: Enum.map([30, 40], fn num -> %Var{type: :num, value: num} end)
             }
           ]

    state = Stench.CLI.eval("arr = [[1, 2], [3, 4]]; x =  arr[1][0] ")
    assert state.vars["arr"].type == :bucket

    assert state.vars["arr"].value == [
             %Var{
               type: :bucket,
               value: Enum.map([1, 2], fn num -> %Var{type: :num, value: num} end)
             },
             %Var{
               type: :bucket,
               value: Enum.map([3, 4], fn num -> %Var{type: :num, value: num} end)
             }
           ]

    assert state.vars["x"].type == :num
    assert state.vars["x"].value == 3
  end
end

defmodule StenchTest.OdorsAndSniffs do
  use ExUnit.Case

  test "basic odor definition and sniffing" do
    state = Stench.CLI.eval("odor my_odor() { x = 10; y = 20; (dump x ; )} sniff my_odor;")
    assert state.vars["x"] == nil
    assert state.vars["y"] == nil
  end

  test "odor with parameters" do
    state =
      Stench.CLI.eval(
        "odor my_odor(a: num, b: num) num { c = a + b;  c; } c = sniff my_odor(5, 7);"
      )

    assert state.vars["c"].type == :num and state.vars["c"].value == 12
  end

  test "invalid number of parameters" do
    x =
      Stench.CLI.eval("""
      odor my_odor(a: num, b: num) num {
        c = a + b;
        c;
      }
      c = sniff my_odor(5);
      """)

    assert x == :eval_error
    x =
      Stench.CLI.eval("""
      odor my_odor(a: num, b: num) num {
        c = a + b;
        c;
      }
      c = sniff my_odor(5,6,7);
      """)

    assert x == :eval_error
  end

  test "nested odors" do
    state =
      Stench.CLI.eval("""
      odor outer_odor() bucket {
        x = 5;
        odor inner_odor(n: num) num {
          y = n * 2;
          y;
        }
        y = sniff inner_odor(x);
        [x,y,"y"]
      }
      ary = sniff outer_odor();
      """)

    assert state.vars["ary"].type == :bucket and Enum.count(state.vars["ary"].value) == 3
  end

  test "odor with return value" do
    state = Stench.CLI.eval("odor my_odor() num { 42; } result = sniff my_odor();")
    assert state.vars["result"].type == :num and state.vars["result"].value == 42
  end

  test "odor with conditional logic" do
    state =
      Stench.CLI.eval("""
      odor conditional_odor(a: num) string {
        result = "";
        if a > 10 {
          result = "greater";
          result;
        } else {
          result = "smaller";
          result;
        }
      }
      result = sniff conditional_odor(15);
      result2 = sniff conditional_odor(5);
      """)

    assert state.vars["result"].type == :string and state.vars["result"].value == "greater"
    assert state.vars["result2"].type == :string and state.vars["result2"].value == "smaller"
  end

  test "odor with loops" do
    state =
      Stench.CLI.eval("""
      odor loop_odor() num{
        sum = 0;
        pileup i=1; i<6; i=i+1 {
          sum = sum + i;
        }
        sum;
      }
      num = sniff loop_odor();
      dump (num + " is da num");
      """)

    assert state.vars["num"].type == :num and state.vars["num"].value == 15
  end

  test "recursive odor" do
    state =
      Stench.CLI.eval("""
      odor recursive(n: num) num{
        dump ("n is " + n);
        r = 0;
        if n < 10 {
          dump "true";
          x = n + 1 ;
          s = sniff recursive(x);
          r = n + s;
          r;
        }else{
          dump "false";
          r = n;
          r;
        }
      }
      num = sniff recursive(0);
      """)

    assert state.vars["num"].type == :num and state.vars["num"].value == 55
  end

  test "invalid odor" do
    x =
      Stench.CLI.eval("""
      odor invalid() {
      "
      }
      """)

    assert x == :lex_error
  end
end

defmodule StenchTest.IsChecks do
  use ExUnit.Case
  test "\"is\" checks" do
    assert not MultiAccessor.is_multi_accessor(0)
    assert MultiAccessor.is_multi_accessor(%MultiAccessor{})
    assert not Accessor.is_accessor(0)
    assert Accessor.is_accessor(%Accessor{})
  end
end


# for more coverage

defmodule StenchTest.SpecialKeywords do
  use ExUnit.Case

  test "use of special keywords" do
    state = Stench.CLI.eval(" x = [1,2,3]; sizex = size x; wipe x; ")
    IO.inspect(state,label: "Final State")
    assert (Map.get(state.vars,"x",%Var{}).type == :nil) and state.vars["sizex"].type == :num and state.vars["sizex"].value == 3

    state = Stench.CLI.eval("""
    x = [1,2,3];
    typex = typeof x;
    y = 2 ;
    typey = typeof y;
    z = "hello";
    typez = typeof z;
    """)

    assert state.vars["typex"].type == :type and state.vars["typex"].value == :bucket
    assert state.vars["typey"].type == :type and state.vars["typey"].value == :num
    assert state.vars["typez"].type == :type and state.vars["typez"].value == :string
    state = Stench.CLI.eval(" x = 10; typeof x;")
    assert state.cur_return.type== :type and state.cur_return.value== :num
  end
end

defmodule StenchTest.DumpTests do
  use ExUnit.Case

  test "dumping various types" do
    state = Stench.CLI.eval("dump 42")
    assert state.cur_return.type == nil

    state = Stench.CLI.eval("dump \"Hello, World!\"")
    assert state.cur_return.type == nil

    state = Stench.CLI.eval("dump true")
    assert state.cur_return.type == nil

    state = Stench.CLI.eval("dump [1, 2, 3]")
    assert state.cur_return.type == nil
  end
end
defmodule StenchTest.IfElseTests do
  use ExUnit.Case

  test "if-else statements" do
    state = Stench.CLI.eval("a = 10; if a > 5 { a = a + 1; } else { a = a - 1; }")
    assert state.vars["a"].type == :num and state.vars["a"].value == 11

    state = Stench.CLI.eval("a = 3; if a > 5 { a = a + 1; } else { a = a - 1; }")
    assert state.vars["a"].type == :num and state.vars["a"].value == 2
  end
end

defmodule StenchTest.BucketOperations do
  use ExUnit.Case

  test "operators with buckets" do

    state = Stench.CLI.eval("arr = [1, 2, 3]; x = arr + [[2,3]];")
    assert state.vars["x"].type == :bucket and Enum.count(state.vars["x"].value) == 4
    state = Stench.CLI.eval("x[3][1]=4;dump x;",state)
    check_var = Enum.at(state.vars["x"].value,3).value |> Enum.at(1)
    IO.inspect(state)
    assert check_var.type == :num and check_var.value== 4
    state = Stench.CLI.eval("arr = [1, 2, 3]; x = arr + 2;")
    assert state.vars["x"].type == :bucket and Enum.count(state.vars["x"].value) == 4
    state = Stench.CLI.eval("arr = [1, 2, 3]; x = arr + [2];")
    assert state.vars["x"].type == :bucket and Enum.count(state.vars["x"].value) == 4
    state = Stench.CLI.eval("arr = [1, 2, 3]; x = 2+ arr + [2];")
    assert state.vars["x"].type == :bucket and Enum.count(state.vars["x"].value) == 5
  end
end
