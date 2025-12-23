defmodule Stench.CLI do
  @moduledoc """
  Documentation for `Stench`.
  """

  @doc """
  """
  @operators Operators.operators()
  def main(args \\ nil) do
    if :debug == args do
      repl(%State{cur_return: 0}, true)
    else
      repl()
    end
  end

  def eval(lines, state \\ %State{}, debug \\ nil)

  def eval(line, state, debug) do
    program = String.replace(to_string(line), "^^", "^")
    tokens = Lexer.tokenize(program)

    case Enum.at(tokens, 0) do
      char when char in @operators ->
        :error

      _ ->
        tree = Parser.parse(tokens)
        state = Eval.eval(tree, state)

        if debug do
          IO.puts(inspect(state))
        end

        state
    end
  end

  def eval([line | tail], state, debug) do
    program = String.replace(to_string(line), "^^", "^")
    tokens = Lexer.tokenize(program)

    case Enum.at(tokens, 0) do
      char when char in @operators ->
        :error

      _ ->
        tree = Parser.parse(tokens)
        state = Eval.eval(tree, state)

        if debug do
          IO.puts(inspect(state))
        end

        eval(tail, state, debug)
    end
  end

  def repl(state \\ %State{}, debug \\ false) do
    line = IO.gets(">>>>> ")

    if line == "" || line == "\n" || line == "\r" do
      IO.puts("")
      repl(state, debug)
    else
      tokens = Lexer.tokenize(line)

      case Enum.at(tokens, 0) do
        char when char in @operators ->
          tree = Parser.parse([state.cur_return | tokens])

          state2 = Eval.eval(tree, state)

          if debug do
            IO.puts(inspect(state2))
            IO.puts(inspect(tree))
          end

          IO.puts(state2.cur_return)
          repl(state2, debug)

        _ ->
          tree = Parser.parse(tokens)
          state2 = Eval.eval(tree,state)

          if debug do
            IO.puts(inspect(state2))
            IO.puts(inspect(tree))
          end
          IO.puts(state2.cur_return)
          repl(state2, debug)
      end
    end
  end
end
