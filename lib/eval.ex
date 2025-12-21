defmodule Eval do
  @operators Operators.operators()

  def eval(cur) do
    # entering
    if cur.value in @operators do
      operator(eval(cur.left), eval(cur.right), cur.value)
    else
      {num, _} = Integer.parse(cur.value)
      num
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
end
