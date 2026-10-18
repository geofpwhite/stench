defmodule Stench.CLI do
  @moduledoc """
  Documentation for `Stench`.
  """

  @doc """
  """
  @operators Operators.operators()
  @infix_operators Operators.infix_operators()
  def main_repl(raw \\ nil, debug \\ nil) do
    case raw do
      :raw ->
        System.at_exit(fn _status ->
          IO.puts("Terminal mode restored to cooked.")
        end)

        :shell.start_interactive({:noshell, :raw})

        if debug == :debug do
          repl("", %State{}, true)
        else
          repl("", %State{})
        end

        :shell.start_interactive()

      _ ->
        if debug == :debug do
          repl_cooked(%State{}, true)
        else
          repl_cooked()
        end
    end
  end

  def socket() do
  end

  def main(argS \\ []) do
    # if input is piped in, just eval that and exit
    args = System.argv()

    case args do
      ["-s"] ->
        TCPServer.start_server(4040)
        :ok

      ["-e" | tail] ->
        IO.puts(inspect(eval(Enum.join(tail, " "))))
        :ok

      ["--debug" | tail] ->
        eval(Enum.join(tail, " "), true)
        :ok

      _ ->
        if(argS == [:raw] || argS == :raw) do
          main_repl(:raw)
        else
          main_repl()
        end
    end
  end

  def dump_for_repl(%Var{type: :bucket, value: ary}) do
    Stench.Eval.dump_bucket(ary)
  end

  def dump_for_repl(%Var{type: nil, value: nil}) do
    "nil"
  end

  def dump_for_repl(%Var{value: v}) do
    inspect(v)
  end

  def exec(file_name) do
    IO.puts(file_name)

    case File.read(file_name) do
      {:ok, content} ->
        s = eval(to_string(content), %State{})
        # IO.puts(dump_for_repl(s.cur_return))
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
        IO.puts(inspect(s.cur_return.value))
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
    tokens = Stench.Lexer.tokenize(program)

    if debug do
      IO.puts(inspect(tokens))
    end

    if tokens == :error do
      :lex_error
    else
      case Enum.at(tokens, 0) do
        char when char in @operators and char != "not" ->
          :syntax_error

        _ ->
          tree = Stench.Parser.parse(tokens)

          if tree == :error do
            :parse_error
          else
            if debug do
              IO.puts(inspect(tree))
            end

            state = Stench.Eval.eval(tree, state)

            if state == :error do
              :eval_error
            else
              if debug do
                IO.puts(inspect(state))
              end

              state
            end
          end
      end
    end
  end

  def repl(line, state \\ %State{}, debug \\ false, index \\ 0) do
    # char = IO.getn("")
    if line == "" do
      IO.puts(IO.ANSI.cursor_down(100))
      IO.puts(IO.ANSI.cursor_left(100))
      IO.write(IO.ANSI.white() <> "🚽" <> IO.ANSI.color(94) <> "☁ " <> IO.ANSI.reset())
    end

    char = IO.binread(6)

    case char do
      <<127>> ->
        IO.write(IO.ANSI.cursor_left())
        IO.write(" ")
        IO.write(IO.ANSI.cursor_left())
        repl(String.slice(line, 0, max(0, String.length(line) - 1)), state, debug)

      <<27, 91, 65>> ->
        repl("", state, debug)

      <<27, 91, 66>> ->
        repl("", state, debug)

      <<27, 91, 67>> ->
        IO.write(IO.ANSI.cursor_right())
        repl(line, state, debug, min(index + 1, 0))

      <<27, 91, 68>> ->
        IO.write(IO.ANSI.cursor_left())
        repl(line, state, debug, max(index - 1, -String.length(line)))

      char when char in ["\n", "\r", "\r\n"] ->
        IO.puts("")
        IO.write(IO.ANSI.cursor_left(100))
        tokens = Stench.Lexer.tokenize(line)

        if debug, do: IO.puts(inspect(tokens))

        if line == "exit" do
          :exit
        else
          case Enum.at(tokens, 0) do
            char when char in @infix_operators ->
              tree = Stench.Parser.parse([state.cur_return | tokens])

              state2 = Stench.Eval.eval(tree, state)

              if debug do
                IO.puts(inspect(state2))
                IO.puts(inspect(tree))
              end

              IO.puts("\n" <> IO.ANSI.cursor_left(100) <> dump_for_repl(state2.cur_return))
              IO.write(IO.ANSI.cursor_left(String.length(line) + 15))
              repl("", state2, debug, index)

            _ ->
              tree = Stench.Parser.parse(tokens)
              state2 = Stench.Eval.eval(tree, state)

              if debug do
                IO.puts(inspect(state2))
                IO.puts(inspect(tree))
              end

              IO.puts("\n" <> IO.ANSI.cursor_left(100) <> dump_for_repl(state2.cur_return))
              repl("", state2, debug, index)
          end
        end

      _ ->
        case index do
          0 ->
            IO.write(char)
            repl(line <> char, state, debug)

          _ ->
            {first, second} = String.split_at(line, String.length(line) + index)
            IO.write(char <> second)
            IO.write(IO.ANSI.cursor_left(String.length(second)))

            repl(first <> char <> second, state, debug, index)
        end
    end
  end

  def repl_cooked(state \\ %State{cur_return: %Var{}}, debug \\ false) do
    line =
      IO.gets(
        IO.ANSI.red() <>
          ">" <> IO.ANSI.green() <> ">" <> IO.ANSI.blue() <> "> " <> IO.ANSI.reset()
      )

    if line == "" || line == "\n" || line == "\r" do
      repl_cooked(state, debug)
    else
      tokens = Stench.Lexer.tokenize(line)
      if debug, do: IO.puts(inspect(tokens))

      case Enum.at(tokens, 0) do
        char when char in @infix_operators ->
          tree = Stench.Parser.parse([state.cur_return | tokens])

          state2 = Stench.Eval.eval(tree, state)

          if debug do
            IO.puts(inspect(state2))
            IO.puts(inspect(tree))
          end

          IO.puts(inspect(state2.cur_return.value))
          repl_cooked(state2, debug)

        _ ->
          tree = Stench.Parser.parse(tokens)

          if debug do
            IO.puts(inspect(tree))
          end

          state2 = Stench.Eval.eval(tree, state)
          if debug, do: IO.puts(inspect(state2))

          case state2.cur_return.type do
            :bucket ->
              IO.puts(Stench.Eval.dump_bucket(state2.cur_return.value))

            _ ->
              IO.puts(state2.cur_return.value)
          end

          repl_cooked(state2, debug)
      end
    end
  end
end
