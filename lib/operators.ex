defmodule Operators do
  @infix_operators ["and", "or", "is", "xor", "+", "-", "/", "*", "^", ">", "<"]
  @prefix_operators ["not", "size"]
  def operators, do: @infix_operators ++ @prefix_operators
  def infix_operators, do: @infix_operators
  def prefix_operators, do: @prefix_operators
end
