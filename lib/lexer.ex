defmodule Lexer do
  @operators Operators.operators()
  @keywords Keywords.keywords()
  @parens ["(", ")","{","}","[","]"]
  def tokenize("", tokens, "") do
    tokens
  end

  def tokenize("", tokens, cur) do
    tokens ++ [cur]
  end

  def tokenize(line, tokens, "") do
    {first, next} = String.split_at(line, 1)

    case first do
      char when char in ["\"", "'"] ->
        case first_quote(next) do
          :error ->
            :error

          {inner_string, next_index} ->
            tokenize(
              String.slice(next, next_index, String.length(next) - next_index),
              tokens ++ ["\"" <> inner_string <> "\""],
              ""
            )
        end

      char
      when char in @operators or
             char in @parens or
             char in @keywords ->
        tokenize(next, tokens ++ [char], "")

      char
      when char in [" ", "\n", "\r"] ->
        tokenize(next, tokens, "")

      char ->
        tokenize(next, tokens, char)
    end
  end

  def tokenize(line, tokens, cur) do
    {first, next} = String.split_at(line, 1)

    case first do
      char when char in ["\"", "'"] ->
        case first_quote(next) do
          :error ->
            :error

          {inner_string, next_index} ->
            tokenize(
              String.slice(next, next_index, String.length(next) - next_index),
              tokens ++ [cur, "\"" <> inner_string <> "\""],
              ""
            )
        end

      char
      when char in @operators or
             char in @parens or
             char in @keywords ->
        tokenize(next, tokens ++ [cur, char], "")

      char
      when char in [" ", "\n", "\r"] ->
        tokenize(next, tokens ++ [cur], "")

      char ->
        tokenize(next, tokens, cur <> char)
    end
  end

  def tokenize(line) do
    tokenize(line, [], "")
  end

  def first_quote(line), do: first_quote(line, 0)

  def first_quote(line, i) do
    if i >= String.length(line) do
      :error
    else
      if String.at(line, i) == "\"" do
        {String.slice(line, 0, i), i + 1}
      else
        first_quote(line, i + 1)
      end
    end
  end
end
