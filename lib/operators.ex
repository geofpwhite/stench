defmodule Operators do
  @infix_operators ["and", "or", "is", "xor", "+", "-", "/", "*", "^", ">", "<", "%"]
  @prefix_operators ["not", "size", "typeof", "sniff", "wipe"]

  @spec operators() :: list(String.t())
  def operators, do: @infix_operators ++ @prefix_operators

  @spec infix_operators() :: list(String.t())
  def infix_operators, do: @infix_operators

  @spec prefix_operators() :: list(String.t())
  def prefix_operators, do: @prefix_operators
end
