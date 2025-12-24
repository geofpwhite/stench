defmodule Eval do
  @infix_operators Operators.infix_operators()
  @prefix_operators Operators.prefix_operators()

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


  def eval(%Conditional{condition: statements, do: ary}, state) do
    s = eval(statements,state)
    if s.cur_return.value do
      inner_state = eval(ary)
      reassignments = Map.intersect(state.vars,inner_state.vars)
      new_vars = Map.merge(state.vars,reassignments,fn _,_,b -> b end)
      %{state|vars: new_vars}
    else
      state
    end
  end

  def eval(%TreeNode{left: left,right: right,value: value}, state) do
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

      _ ->
        case Integer.parse(value) do
          {num, _} ->
            %{state | cur_return: %Var{type: :int, value: num}}

          :error ->
            %{state | cur_return: Map.get(state.vars, value, %Var{})}
        end
    end
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

  def operator(num,num2,">") do
    gt_op(num,num2)
  end
  def operator(num,num2,"<") do
    lt_op(num,num2)
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
          value: :math.pow(num, num2),
          type: :int
        }

      _ ->
        :error
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

  def lt_op(left,right) do
    if left.type == right.type and left.type == :int do
      %Var{
        type: :bool,
        value: left.value < right.value
      }
    else
      :error
    end
  end
  def gt_op(left,right) do
    if left.type == right.type and left.type == :int do
      %Var{
        type: :bool,
        value: left.value > right.value
      }
    else
      :error
    end
  end
end
