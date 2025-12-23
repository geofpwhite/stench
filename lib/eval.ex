defmodule Eval do
  @operators Operators.operators()

  def eval(cur) do
    eval(cur, %State{})
  end

  def eval(cur, state) do
    # entering
    case cur.value do
      v
      when v in @operators ->
        ecl = eval(cur.left, state).cur_return
        ecr = eval(cur.right, state).cur_return
        %{state | cur_return: operator(ecl, ecr, cur.value)}

      "=" ->
        ecr = eval(cur.right,state)
        IO.puts(inspect(ecr)<>"rhs")
        assign(cur.left.value, ecr.cur_return, state)

      _ ->
        case Integer.parse(cur.value) do
          {num, _} ->
            %{state | cur_return: num}

          :error ->
            %{state | cur_return: Map.get(state.vars, cur.value)}
        end
    end
  end

  def operator(num, num2, op) do
    case op do
      "+" ->
        num + num2

      "-" ->
        num - num2

      "*" ->
        num * num2

      "/" ->
        num / num2

      "^" ->
        :math.pow(num, num2)

      _ ->
        :error
    end
  end

  def assign(lhs, rhs, state) do
    %{state | vars: Map.put(state.vars, lhs, rhs), cur_return: rhs}
  end
end
