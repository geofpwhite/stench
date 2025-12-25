defmodule Eval do
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
    },state)do
      eval(a,state)
    end
  def eval(
        %Accessor{
          bucket_name: bucket,
          index: tree
        },
        state
      ) do
    index = eval(tree).cur_return.value
    bucket_var = Map.get(state.vars, bucket)

    if bucket_var.type != :bucket do
      :error
    else
      %{state|cur_return: Enum.at(bucket_var.value,index)}
    end
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
    new_state = iterate(condition, increment, exec, s)

    new_vars =
      Map.reject(new_state.vars, fn {key, _} ->
        Map.get(state.vars, key, nil) == nil or begin.left.value == key
      end)

    %{state | vars: new_vars}
  end

  def eval(%Conditional{condition: statements, do: ary,else: to_do_if_false}, state) do
    s = eval(statements, state)

    if s.cur_return.value do
      inner_state = eval(ary)
      reassignments = Map.intersect(state.vars, inner_state.vars)
      new_vars = Map.merge(state.vars, reassignments, fn _, _, b -> b end)
      %{state | vars: new_vars,cur_return: inner_state.cur_return}
    else
      inner_state = eval(to_do_if_false)
      reassignments = Map.intersect(state.vars, inner_state.vars)
      new_vars = Map.merge(state.vars, reassignments, fn _, _, b -> b end)
      %{state | vars: new_vars,cur_return: inner_state.cur_return}
    end
  end


  def eval(%TreeNode{left: left, right: right, value: value}, state) do
    # entering
    case value do
      "true" ->
        %{state | cur_return: %Var{type: :bool, value: true}}

      "false" ->
        %{state | cur_return: %Var{type: :bool, value: false}}

      "not" ->
        e = not_op(eval(right).cur_return)
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

      nil->
        state

      _ ->
        case Integer.parse(value) do
          {num, _} ->
            %{state | cur_return: %Var{type: :int, value: num}}

          :error ->
            %{state | cur_return: Map.get(state.vars, value, %Var{})}
        end
    end
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

  def operator(num, num2, op) when num.type == :int and num2.type == :int do
    case op do
      "+" ->
        %Var{
          value: num.value + num2.value,
          type: :int
        }

      "-" ->
        %Var{
          value: num.value - num2.value,
          type: :int
        }

      "*" ->
        %Var{
          value: num.value * num2.value,
          type: :int
        }

      "/" ->
        %Var{
          value: num.value / num2.value,
          type: :int
        }

      "^" ->
        %Var{
          value: :math.pow(num.value, num2.value),
          type: :int
        }

      _ ->
        :error
    end
  end

  def assign(%Accessor{
    bucket_name: bucket_name,
    index: index
  }, rhs, state) do
    bucket = Map.get(state.vars,bucket_name)
    e = eval(index,state)
    if bucket.type != :bucket or Enum.count(bucket.value) <= e.cur_return.value do
      :error
    else
        replaced = List.replace_at(bucket.value,e.cur_return.value,%Var{value: rhs.value, type: rhs.type})
        %{state| vars: Map.put(state.vars,bucket_name,%{bucket|value: replaced}),cur_return: rhs}

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
    if left.type == right.type and left.type == :int do
      %Var{
        type: :bool,
        value: left.value < right.value
      }
    else
      :error
    end
  end

  def gt_op(left, right) do
    if left.type == right.type and left.type == :int do
      %Var{
        type: :bool,
        value: left.value > right.value
      }
    else
      :error
    end
  end

  def iterate(condition, increment, exec, state) do
    s = eval(condition, state)

    if s.cur_return.type == :bool and s.cur_return.value do
      s2 = eval(exec, s)
      s3 = eval(increment, s2)
      iterate(condition, increment, exec, s3)
    else
      state
    end
  end
end
