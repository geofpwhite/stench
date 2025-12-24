defmodule Stench.CLI do
  @moduledoc """
  Documentation for `Stench`.
  """

  @doc """
  """
  @operators Operators.operators()
  @infix_operators Operators.infix_operators()
  def main(args \\ nil) do
    if :debug == args do
      repl_cooked(%State{}, true)
    else
      repl_cooked()
    end
  end

  def eval(line, true) do
    eval(line, %State{}, true)
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
          IO.puts(inspect(tree))
          IO.puts(inspect(state))
        end

        state
    end
  end

  def repl(line, state \\ %State{}, debug \\ false) do
    :shell.start_interactive({:noshell, :raw})
    char = IO.getn("")
    IO.write(char)

    case char do
      char when char in ["\n", "\r"] ->
        tokens = Lexer.tokenize(line)
        if debug, do: IO.puts(inspect(tokens))

        case Enum.at(tokens, 0) do
          char when char in @infix_operators ->
            tree = Parser.parse([state.cur_return | tokens])

            state2 = Eval.eval(tree, state)

            if debug do
              IO.puts(inspect(state2))
              IO.puts(inspect(tree))
            end

            IO.puts(state2.cur_return.value())
            repl(state2, debug)

          _ ->
            tree = Parser.parse(tokens)
            state2 = Eval.eval(tree, state)

            if debug do
              IO.puts(inspect(state2))
              IO.puts(inspect(tree))
            end

            IO.puts(state2.cur_return.value())
            repl("", state2, debug)
        end

      _ ->
        repl(line <> char, state, debug)
    end
  end

  def repl_cooked(state \\ %State{cur_return: %Var{}}, debug \\ false) do
    line = IO.gets(">>>>> ")

    if line == "" || line == "\n" || line == "\r" do
      repl_cooked(state, debug)
    else
      tokens = Lexer.tokenize(line)
      if debug, do: IO.puts(inspect(tokens))

      case Enum.at(tokens, 0) do
        char when char in @infix_operators ->
          tree = Parser.parse([state.cur_return | tokens])

          state2 = Eval.eval(tree, state)

          if debug do
            IO.puts(inspect(state2))
            IO.puts(inspect(tree))
          end

          IO.puts(state2.cur_return.value())
          repl_cooked(state2, debug)

        _ ->
          tree = Parser.parse(tokens)
          if debug do
            IO.puts(inspect(tree))
          end
          state2 = Eval.eval(tree, state)
          if debug, do: IO.puts(inspect(state2))


          IO.puts(state2.cur_return.value)
          repl_cooked(state2, debug)
      end
    end
  end
end
