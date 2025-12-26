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

  def exec(file_name) do
    IO.puts(file_name)

    case File.read(file_name) do
      {:ok, content} ->
        s = eval(to_string(content), %State{})
        IO.puts(inspect(s))
        s

      e ->
        IO.puts(inspect(e))
    end
  end

  def exec(file_name, :debug) do
    IO.puts(file_name)

    case File.read(file_name) do
      {:ok, content} ->
        s = eval(to_string(content), %State{}, true)
        IO.puts(inspect(s))
        s

      e ->
        IO.puts(inspect(e))
    end
  end

  def eval(line, true) do
    eval(line, %State{}, true)
  end

  def eval(lines, state \\ %State{}, debug \\ nil)

  def eval(line, state, debug) do
    program = String.replace(to_string(line), "^^", "^")
    tokens = Lexer.tokenize(program)

    if debug do
      IO.puts(inspect(tokens))
    end

    case Enum.at(tokens, 0) do
      char when char in @operators ->
        :error

      _ ->
        tree = Parser.parse(tokens)

        if debug do
          IO.puts(inspect(tree))
        end

        state = Eval.eval(tree, state)

        if debug do
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

          IO.puts(inspect(state2.cur_return.value))
          repl_cooked(state2, debug)

        _ ->
          tree = Parser.parse(tokens)

          if debug do
            IO.puts(inspect(tree))
          end

          state2 = Eval.eval(tree, state)
          if debug, do: IO.puts(inspect(state2))

          case state2.cur_return.type do
            :bucket ->
              IO.puts(print_bucket(state2.cur_return.value))

            _ ->
              IO.puts(state2.cur_return.value)
          end

          repl_cooked(state2, debug)
      end
    end
  end

  def print_bucket(vars) do
    print_bucket(vars, "[")
  end

  def print_bucket([final], string) do
    case final.type do
      :bucket ->
        inner = print_bucket(final.value)
        string <> inner <> "]"

      _ ->
        string <> to_string(final.value) <> "]"
    end
  end

  def print_bucket([head | tail], string) do
    case head.type do
      :bucket ->
        print_bucket(tail, string <> print_bucket(head.value) <> ",")

      _ ->
        print_bucket(tail, string <> to_string(head.value) <> ",")
    end
  end
end
