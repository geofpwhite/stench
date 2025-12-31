defmodule Stench.Eval do
  @infix_operators Operators.infix_operators()

  def eval(cur) do
    eval(cur, %State{})
  end

  def eval([], state) do
    state
  end

  def eval([cur | tail], state) do
    s = eval(cur, state)
    eval(tail, s)
  end

  def eval(
        %TreeNode{
          value: %Accessor{} = a
        },
        state
      ) do
    eval(a, state)
  end

  def eval(
        %Accessor{
          bucket_name: bucket,
          index: tree
        },
        state
      ) do
    index = eval(Stench.Parser.sanitize_inner(tree), state).cur_return.value

    bucket_var = Map.get(state.vars, bucket)

    if bucket_var == nil do
      %{state | cur_return: %Var{}}
    else
      if bucket_var.type != :bucket do
        :error
      else
        %{state | cur_return: Enum.at(bucket_var.value, index, %Var{type: nil, value: nil})}
      end
    end
  end

  def eval(
        %Odor{
          name: name,
          params: _,
          do: _,
          return_type: _
        } = o,
        state
      ) do
    %{state | odors: Map.put(state.odors, name, o)}
  end

  def eval(
        %Sniff{
          odor: name,
          param_values: params
        },
        state
      ) do
    s = eval(params, Map.get(state.odors, name), state)
    %{state | cur_return: s.cur_return}
  end

  def eval(
        %Bucket{
          garbage: _
        } = b,
        state
      ) do
    %{state | cur_return: eval(b, state, [])}
  end

  def eval(
        %Loop{
          condition: condition,
          begin: begin,
          increment: increment,
          do: exec
        },
        state
      ) do
    s = eval(begin, state)

    nested_loop_index_value = Map.get(state.vars, "_index_", nil)
    nested_ary = Map.get(state.vars, "_ary_", nil)
    new_state = iterate(condition, increment, exec, s)

    new_vars =
      Map.reject(new_state.vars, fn {key, _} ->
        Map.get(state.vars, key, nil) == nil or
          find(begin, key)
      end)

    if nested_loop_index_value != nil and nested_ary != nil do
      %{
        state
        | vars:
            Map.put(Map.put(new_vars, "_index_", nested_loop_index_value), "_ary_", nested_ary)
      }
    else
      %{state | vars: new_vars}
    end
  end

  def eval(%Conditional{condition: statements, do: ary, else: to_do_if_false}, state) do
    s = eval(statements, state)

    if s.cur_return.value do
      inner_state = eval(ary, s)
      reassignments = Map.intersect(state.vars, inner_state.vars)
      new_vars = Map.merge(state.vars, reassignments, fn _, _, b -> b end)
      %{state | vars: new_vars, cur_return: inner_state.cur_return, break: inner_state.break}
    else
      inner_state = eval(to_do_if_false, s)
      reassignments = Map.intersect(state.vars, inner_state.vars)
      new_vars = Map.merge(state.vars, reassignments, fn _, _, b -> b end)
      %{state | vars: new_vars, cur_return: inner_state.cur_return, break: inner_state.break}
    end
  end

  def eval(%TreeNode{left: left, right: right, value: value}, state) do
    # entering
    case value do
      "break" ->
        %{state | break: true}

      "true" ->
        %{state | cur_return: %Var{type: :bool, value: true}}

      "false" ->
        %{state | cur_return: %Var{type: :bool, value: false}}

      "not" ->
        e = not_op(eval(right, state).cur_return)
        %{state | cur_return: e}

      v
      when v in @infix_operators ->
        ecl = eval(left, state).cur_return
        ecr = eval(right, state).cur_return

        %{state | cur_return: operator(ecl, ecr, value)}

      "=" ->
        ecr = eval(right, state)
        assign(left.value, ecr.cur_return, state)

      "\"" <> inner ->
        %{
          state
          | cur_return: %Var{
              type: :string,
              value: String.slice(inner, 0, String.length(inner) - 1)
            }
        }

      "dump" ->
        s = eval(right, state).cur_return
        buf = Application.get_env(:stench, :buffer, :stdio)

        if s.type == :bucket,
          do: IO.puts(buf, dump_bucket(s.value)),
          else: IO.puts(buf, inspect(s.value))

        state

      "size" ->
        s = eval(right, state)

        s = s.cur_return

        if s.type != :bucket do
          :error
        else
          %{state | cur_return: %Var{type: :num, value: Enum.count(s.value)}}
        end

      "typeof" ->
        %{state | cur_return: %Var{type: :type, value: eval(right, state).cur_return.type}}

      "wipe" ->
        %{state | vars: Map.delete(state.vars, right.value)}

      nil ->
        state

      ["\"" <> rest] ->
        %{
          state
          | cur_return: %Var{type: :string, value: String.slice(rest, 0, String.length(rest) - 1)}
        }

      _ ->
        value = Stench.Parser.sanitize_inner(value)

        case Integer.parse(value) do
          {num, _} ->
            %{state | cur_return: %Var{type: :num, value: num}}

          :error ->
            %{state | cur_return: Map.get(state.vars, value, %Var{})}
        end
    end
  end

  def eval(
        [param | tail],
        %Odor{params: [p2 | t2]} = odor,
        state
      ) do
    s =
      eval(
        %TreeNode{value: "=", left: %TreeNode{value: p2.name}, right: %TreeNode{value: param}},
        state
      )

    eval(tail, %{odor | params: t2}, s)
  end

  def eval(
        [],
        %Odor{params: [], do: exec, return_type: return},
        state
      ) do
    if return == nil do
      %{eval(exec, state) | cur_return: %Var{}}
    else
      s = eval(exec, state)

      s
    end
  end

  def eval(
        ary,
        %Odor{params: []},
        _
      )
      when length(ary) > 0 do
    :error
  end

  def eval(
        [],
        %Odor{params: ary},
        _
      )
      when length(ary) > 0 do
    :error
  end

  def eval(
        %Bucket{
          garbage: [head | tail]
        },
        state,
        vars
      ) do
    v = eval(head, state).cur_return
    eval(%Bucket{garbage: tail}, state, vars ++ [v])
  end

  def eval(
        %Bucket{
          garbage: []
        },
        _,
        vars
      ) do
    %Var{type: :bucket, value: vars}
  end

  def operator(string1, string2, "+") when string1.type == :string and string2.type == :string do
    %Var{
      type: :string,
      value: string1.value <> string2.value
    }
  end

  def operator(bucket1, bucket2, "+") when bucket1.type == :bucket and bucket2.type == :bucket do
    %Var{
      type: :bucket,
      value: bucket1.value ++ bucket2.value
    }
  end

  def operator(bucket, other, "+") when bucket.type == :bucket do
    %Var{
      type: :bucket,
      value: bucket.value ++ [other.value]
    }
  end

  def operator(other, bucket, "+") when bucket.type == :bucket do
    %Var{
      type: :bucket,
      value: [other.value] ++ bucket.value
    }
  end

  def operator(string1, string2, "+") when string1.type == :num and string2.type == :string do
    %Var{
      type: :string,
      value: to_string(string1.value) <> string2.value
    }
  end

  def operator(string1, string2, "+") when string1.type == :string and string2.type == :num do
    %Var{
      type: :string,
      value: string1.value <> to_string(string2.value)
    }
  end

  def operator(var, %Var{type: nil}, "+") when var.type == :string do
    %Var{type: :string, value: var.value <> typed_value(:string, nil)}
  end

  def operator(%Var{type: nil}, var, "+") when var.type == :string do
    %Var{type: :string, value: typed_value(:string, nil) <> var.value}
  end

  def operator(str, non_str, "+") when str.type == :string and non_str.type != :string do
    %Var{type: :string, value: str.value <> typed_value(:string, non_str.value)}
  end

  def operator(non_str, str, "+") when str.type == :string and non_str.type != :string do
    %Var{type: :string, value: typed_value(:string, non_str.value) <> str.value}
  end

  def operator(num, num2, "is") do
    is_op(num, num2)
  end

  def operator(num, num2, "and") do
    and_op(num, num2)
  end

  def operator(num, num2, "or") do
    or_op(num, num2)
  end

  def operator(num, num2, "xor") do
    xor_op(num, num2)
  end

  def operator(num, num2, ">") do
    gt_op(num, num2)
  end

  def operator(num, num2, "<") do
    lt_op(num, num2)
  end

  def operator(num, num2, "%") do
    mod_op(num, num2)
  end

  def operator(num, num2, op) when num.type == :num and num2.type == :num do
    case op do
      "+" ->
        %Var{
          value: num.value + num2.value,
          type: :num
        }

      "-" ->
        %Var{
          value: num.value - num2.value,
          type: :num
        }

      "*" ->
        %Var{
          value: num.value * num2.value,
          type: :num
        }

      "/" ->
        %Var{
          value: num.value / num2.value,
          type: :num
        }

      "^" ->
        %Var{
          value: :math.pow(num.value, num2.value),
          type: :num
        }

      _ ->
        :error
    end
  end

  def assign(
        %Accessor{
          bucket_name: bucket_name,
          index: index
        },
        rhs,
        state
      ) do
    bucket = Map.get(state.vars, bucket_name)
    e = eval(index, state)

    if bucket.type != :bucket or Enum.count(bucket.value) <= e.cur_return.value do
      :error
    else
      replaced =
        List.replace_at(bucket.value, e.cur_return.value, %Var{value: rhs.value, type: rhs.type})

      %{
        state
        | vars: Map.put(state.vars, bucket_name, %{bucket | value: replaced}),
          cur_return: rhs
      }
    end
  end

  def assign(lhs, rhs, state) do
    %{
      state
      | vars: Map.put(state.vars, lhs, %Var{value: rhs.value, type: rhs.type}),
        cur_return: rhs
    }
  end

  def is_op(left, right) do
    %Var{
      type: :bool,
      value: left.type == right.type and left.value == right.value
    }
  end

  def or_op(left, right) do
    %Var{
      type: :bool,
      value:
        (left.type == :bool and left.value == true) or
          (right.type == :bool and right.value == true)
    }
  end

  def not_op(bool) do
    case bool.type do
      :bool ->
        %Var{
          type: :bool,
          value: not bool.value
        }

      _ ->
        :error
    end
  end

  def and_op(left, right) do
    %Var{
      type: :bool,
      value:
        left.type == right.type and left.type == :bool and left.value == right.value and
          left.value == true
    }
  end

  def xor_op(left, right) do
    %Var{
      type: :bool,
      value:
        left.type == right.type and left.type == :bool and
          ((left.value and not right.value) or (not left.value and right.value))
    }
  end

  def lt_op(left, right) do
    if left.type == right.type and left.type == :num do
      %Var{
        type: :bool,
        value: left.value < right.value
      }
    else
      :error
    end
  end

  def gt_op(left, right) do
    if left.type == right.type and left.type == :num do
      %Var{
        type: :bool,
        value: left.value > right.value
      }
    else
      :error
    end
  end

  def mod_op(left, right) do
    if left.type == right.type and left.type == :num do
      %Var{
        type: :num,
        value: Integer.mod(left.value, right.value)
      }
    else
      :error
    end
  end

  def iterate(condition, increment, exec, state) do
    s = eval(Stench.Parser.sanitize_inner(condition), state)

    #

    if s.cur_return.type == :bool and s.cur_return.value do
      s2 = eval(exec, state)

      if s2.break do
        %{s2 | break: false}
      else
        s3 = eval(increment, s2)
        iterate(condition, increment, exec, %{s3 | cur_return: s2.cur_return})
      end
    else
      state
    end
  end

  def find([cur], key) do
    cur.left.value == key
  end

  def find([cur | tail], key) do
    if cur.left.value == key do
      true
    else
      find(tail, key)
    end
  end

  def find(begin, key) do
    find([begin], key)
  end

  def dump_bucket(vars) do
    dump_bucket(vars, "[")
  end

  def dump_bucket([final], string) do
    case final.type do
      :bucket ->
        inner = dump_bucket(final.value)
        string <> inner <> "]"

      _ ->
        string <> to_string(final.value) <> "]"
    end
  end

  def dump_bucket([head | tail], string) do
    case head.type do
      :bucket ->
        dump_bucket(tail, string <> dump_bucket(head.value) <> ",")

      _ ->
        dump_bucket(tail, string <> to_string(head.value) <> ",")
    end
  end

  def typed_value(type, nil) do
    case type do
      :string ->
        "<nil>"

      :num ->
        0

      :bucket ->
        []

      nil ->
        nil

      _ ->
        :error
    end
  end

  def typed_value(type, value) do
    case type do
      :string ->
        to_string(value)

      :num ->
        case Integer.parse(value) do
          {num, _} ->
            num

          _ ->
            :error
        end
    end
  end
end
