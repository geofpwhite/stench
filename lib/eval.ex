defmodule Stench.Eval do
  @infix_operators Operators.infix_operators()

  @spec eval(
          maybe_improper_list(
            maybe_improper_list(maybe_improper_list(any(), [] | map()) | map(), [] | map())
            | %{
                :__struct__ => Accessor | Bucket | Conditional | Loop | Odor | Sniff | TreeNode,
                optional(any()) => any()
              },
            []
            | %{
                :__struct__ => Accessor | Bucket | Conditional | Loop | Odor | Sniff | TreeNode,
                optional(any()) => any()
              }
          )
          | %{
              :__struct__ => Accessor | Bucket | Conditional | Loop | Odor | Sniff | TreeNode,
              optional(any()) => any()
            }
        ) :: any()
  def eval(cur) do
    eval(cur, %State{})
  end

  @spec eval(
          maybe_improper_list(
            maybe_improper_list(maybe_improper_list(any(), [] | map()) | map(), [] | map())
            | %{
                :__struct__ => Accessor | Bucket | Conditional | Loop | Odor | Sniff | TreeNode,
                optional(any()) => any()
              },
            []
            | %{
                :__struct__ => Accessor | Bucket | Conditional | Loop | Odor | Sniff | TreeNode,
                optional(any()) => any()
              }
          )
          | %{
              :__struct__ => Accessor | Bucket | Conditional | Loop | Odor | Sniff | TreeNode,
              optional(any()) => any()
            },
          any()
        ) :: any()
  def eval([], state) do
    state
  end

  @spec eval([any()], any()) :: any()
  def eval([cur | tail], state) do
    s = eval(cur, state)
    eval(tail, s)
  end

  @spec eval(%Accessor{bucket_name: String.t(), index: TreeNode}, State) :: any()
  def eval(
        %Accessor{
          bucket_name: bucket,
          index: tree
        },
        state
      ) do
    new_state = eval(Stench.Parser.sanitize_inner(tree), state)

    if new_state == :error or new_state.cur_return == nil or new_state.cur_return == :error do
      :error
    else
      index = new_state.cur_return.value
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
  end

  @spec eval(%TreeNode{value: %Accessor{}}, %State{}) :: any()
  def eval(
        %TreeNode{
          value: %Accessor{} = a
        },
        state
      ) do
    eval(a, state)
  end

  @spec eval(%Odor{name: any(), params: any(), do: any(), return_type: any()}, any()) :: any()
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
        %MultiAccessor{} = m,
        state
      ) do
    eval(m, state, [])
  end

  @spec eval(%Sniff{odor: any(), param_values: any()}, any()) :: any()
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

  @spec eval(%Bucket{garbage: any()}, any()) :: any()
  def eval(
        %Bucket{
          garbage: _
        } = b,
        state
      ) do
    %{state | cur_return: eval(b, state, [])}
  end

  @spec eval(%Loop{condition: any(), begin: any(), increment: any(), do: any()}, any()) :: any()
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

  @spec eval(%Conditional{condition: any(), do: any(), else: any()}, any()) :: any()
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

  @spec eval(%TreeNode{left: any(), right: any(), value: any()}, any()) :: any()
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
        IO.puts(inspect(right))
        IO.puts(inspect(state))

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
        %MultiAccessor{
          indices: [head | tail]
        } = m,
        state,
        index_values
      ) do
    s = eval(head, state)

    if s == :error or s.cur_return in [:error, nil] do
      IO.puts("here2")
      :error
    else
      eval(%{m | indices: tail}, state, index_values ++ [s.cur_return.value])
    end
  end

  def eval(
        %MultiAccessor{bucket_name: bucket_name, indices: []},
        state,
        index_values
      ) do
    bucket = Map.get(state.vars, bucket_name, nil)

    if bucket == nil or bucket.type != :bucket do
      IO.puts("here")
      :error
    else
      %{state | cur_return: get_value_from_multi_index(index_values, bucket.value)}
    end
  end

  @spec eval([any()], %Odor{params: [any()]}, any()) :: any()
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

  @spec eval([], %Odor{params: [], do: any(), return_type: any()}, any()) :: any()
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

  @spec eval(maybe_improper_list(any(), [] | Bucket.t()) | Bucket.t(), any(), any()) :: any()
  def eval(
        ary,
        %Odor{params: []},
        _
      )
      when length(ary) > 0 do
    :error
  end

  @spec eval([], %Odor{}, any()) :: any()
  def eval(
        [],
        %Odor{params: ary},
        _
      )
      when length(ary) > 0 do
    :error
  end

  @spec eval(%Bucket{garbage: [any()]}, any(), any()) :: any()
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

  @spec eval(%Bucket{garbage: []}, any(), any()) :: %Var{type: :bucket, value: any()}
  def eval(
        %Bucket{
          garbage: []
        },
        _,
        vars
      ) do
    %Var{type: :bucket, value: vars}
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(string1, string2, "+") when string1.type == :string and string2.type == :string do
    %Var{
      type: :string,
      value: string1.value <> string2.value
    }
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(bucket1, bucket2, "+") when bucket1.type == :bucket and bucket2.type == :bucket do
    %Var{
      type: :bucket,
      value: bucket1.value ++ bucket2.value
    }
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(bucket, other, "+") when bucket.type == :bucket do
    %Var{
      type: :bucket,
      value: bucket.value ++ [other.value]
    }
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(other, bucket, "+") when bucket.type == :bucket do
    %Var{
      type: :bucket,
      value: [other.value] ++ bucket.value
    }
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(string1, string2, "+") when string1.type == :num and string2.type == :string do
    %Var{
      type: :string,
      value: to_string(string1.value) <> string2.value
    }
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(string1, string2, "+") when string1.type == :string and string2.type == :num do
    %Var{
      type: :string,
      value: string1.value <> to_string(string2.value)
    }
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(var, %Var{type: nil}, "+") when var.type == :string do
    %Var{type: :string, value: var.value <> typed_value(:string, nil)}
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(%Var{type: nil}, var, "+") when var.type == :string do
    %Var{type: :string, value: typed_value(:string, nil) <> var.value}
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(str, non_str, "+") when str.type == :string and non_str.type != :string do
    %Var{type: :string, value: str.value <> typed_value(:string, non_str.value)}
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(non_str, str, "+") when str.type == :string and non_str.type != :string do
    %Var{type: :string, value: typed_value(:string, non_str.value) <> str.value}
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(num, num2, "is") do
    is_op(num, num2)
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(num, num2, "and") do
    and_op(num, num2)
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(num, num2, "or") do
    or_op(num, num2)
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(num, num2, "xor") do
    xor_op(num, num2)
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(num, num2, ">") do
    gt_op(num, num2)
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(num, num2, "<") do
    lt_op(num, num2)
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
  def operator(num, num2, "%") do
    mod_op(num, num2)
  end

  @spec operator(any(), any(), any()) :: :error | Var.t()
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
        %MultiAccessor{
          indices: [final]
        },
        rhs,
        _,
        cur_list
      ) do
    replaced = List.replace_at(cur_list, eval(final).cur_return.value, rhs)
    %Var{type: :bucket, value: replaced}
  end

  def assign(
        %MultiAccessor{
          indices: [head | tail]
        } = b,
        rhs,
        state,
        cur_list
      ) do
    replaced = assign(%{b | indices: tail}, rhs, state, Enum.at(cur_list, head, nil))
    li = List.replace_at(cur_list, head, replaced)
    %Var{type: :bucket, value: li}
  end

  def assign(
        %MultiAccessor{
          bucket_name: bucket_name,
          indices: [head | tail]
        } = b,
        rhs,
        state
      ) do
    cur_bucket = Map.get(state.vars, bucket_name, %Var{}).value
    e = eval(%Accessor{bucket_name: bucket_name, index: head}, state).cur_return
    replaced = assign(%{b | indices: tail}, rhs, state, e.value)

    %{
      state
      | vars:
          Map.put(state.vars, bucket_name, %Var{
            type: :bucket,
            value: List.replace_at(cur_bucket, eval(head, state).cur_return.value, replaced)
          })
    }
  end

  @spec assign(
          %Accessor{},
          %Var{},
          %State{}
        ) :: :error | %{:cur_return => any(), :vars => map(), optional(any()) => any()}
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

  @spec assign(any(), any(), any()) :: %{
          :cur_return => any(),
          :vars => map(),
          optional(any()) => any()
        }
  def assign(lhs, rhs, state) do
    %{
      state
      | vars: Map.put(state.vars, lhs, %Var{value: rhs.value, type: rhs.type}),
        cur_return: rhs
    }
  end

  @spec is_op(any(), any()) :: Var.t()
  def is_op(left, right) do
    %Var{
      type: :bool,
      value: left.type == right.type and left.value == right.value
    }
  end

  @spec or_op(any(), any()) :: Var.t()
  def or_op(left, right) do
    %Var{
      type: :bool,
      value:
        (left.type == :bool and left.value == true) or
          (right.type == :bool and right.value == true)
    }
  end

  @spec not_op(any()) :: :error | Var.t()
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

  @spec and_op(any(), any()) :: Var.t()
  def and_op(left, right) do
    %Var{
      type: :bool,
      value:
        left.type == right.type and left.type == :bool and left.value == right.value and
          left.value == true
    }
  end

  @spec xor_op(any(), any()) :: Var.t()
  def xor_op(left, right) do
    %Var{
      type: :bool,
      value:
        left.type == right.type and left.type == :bool and
          ((left.value and not right.value) or (not left.value and right.value))
    }
  end

  @spec lt_op(any(), any()) :: :error | Var.t()
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

  @spec gt_op(any(), any()) :: :error | Var.t()
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

  @spec mod_op(any(), any()) :: :error | Var.t()
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

  @spec iterate(any(), any(), any(), any()) :: any()
  def iterate(condition, increment, exec, state) do
    s = eval(Stench.Parser.sanitize_inner(condition), state)

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

  @spec find(any(), any()) :: boolean()
  def find([cur], key) do
    cur.left.value == key
  end

  @spec find(any(), any()) :: boolean()
  def find([cur | tail], key) do
    if cur.left.value == key do
      true
    else
      find(tail, key)
    end
  end

  @spec find(any(), any()) :: boolean()
  def find(begin, key) do
    find([begin], key)
  end

  @spec dump_bucket([...]) :: nonempty_binary()
  def dump_bucket(vars) do
    dump_bucket(vars, "[")
  end

  @spec dump_bucket([...], binary()) :: nonempty_binary()
  def dump_bucket([final], string) do
    case final.type do
      :bucket ->
        inner = dump_bucket(final.value)
        string <> inner <> "]"

      _ ->
        string <> to_string(final.value) <> "]"
    end
  end

  @spec dump_bucket([...], binary()) :: nonempty_binary()
  def dump_bucket([head | tail], string) do
    case head.type do
      :bucket ->
        dump_bucket(tail, string <> dump_bucket(head.value) <> ",")

      _ ->
        dump_bucket(tail, string <> to_string(head.value) <> ",")
    end
  end

  @spec typed_value(any(), any()) :: :error | nil | binary() | [] | integer()
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

  @spec typed_value(any(), any()) :: :error | nil | binary() | [] | integer()
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

  def get_value_from_multi_index(_, nil) do
    IO.puts("here")
    :error
  end

  def get_value_from_multi_index([final], list) do
    e = Enum.at(list, final, nil)
    e
  end

  def get_value_from_multi_index([head | tail], list) do
    get_value_from_multi_index(tail, Enum.at(list, head, %Var{}).value)
  end
end
