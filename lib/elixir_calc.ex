defmodule ElixirCalc do
  @moduledoc """
  Documentation for `ElixirCalc`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> ElixirCalc.hello()
      :world

  """
  @operators Operators.operators()
  def main(:debug) do
    repl("0", :debug)
  end

  def main do
    repl("0")
  end

  def eval(program) do
    program = to_string(program)
    program = String.replace(program, "^^", "^")
    tokens = Lexer.tokenize(program)

    case Enum.at(tokens, 0) do
      char when char in @operators ->
        :error

      _ ->
        tree = Parser.parse(tokens)
        Eval.eval(tree)
    end
  end

  def eval(program, :print) do
    program = to_string(program)
    program = String.replace(program, "^^", "^")
    tokens = Lexer.tokenize(program)

    case Enum.at(tokens, 0) do
      char when char in @operators ->
        :error

      _ ->
        tree = Parser.parse(tokens)
        e = Eval.eval(tree)
        IO.puts(e)
        e
    end
  end

  def repl(ans, :debug) do
    line = IO.gets("")

    tokens = Lexer.tokenize(line)

    case Enum.at(tokens, 0) do
      char when char in @operators ->
        tree = Parser.parse([to_string(ans) | tokens])
        IO.puts(inspect(tree))
        new = Eval.eval(tree)
        IO.puts(new)
        repl(new, :debug)

      _ ->
        tree = Parser.parse(tokens)
        IO.puts(inspect(tree))
        new = Eval.eval(tree)
        IO.puts(new)
        repl(new, :debug)
    end
  end

  def repl(ans) do
    line = IO.gets("")
    tokens = Lexer.tokenize(line)

    case Enum.at(tokens, 0) do
      char when char in @operators ->
        tree = Parser.parse([to_string(ans) | tokens])
        new = Eval.eval(tree)
        IO.puts(new)
        repl(new, :debug)

      _ ->
        tree = Parser.parse(tokens)
        new = Eval.eval(tree)
        IO.puts(new)
        repl(new, :debug)
    end
  end
end
