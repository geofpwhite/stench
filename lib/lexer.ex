defmodule Lexer do
  @operators Operators.operators()
  @keywords Keywords.keywords()
  @parens ["(", ")"]
  def tokenize("", tokens, "") do
    tokens
  end

  def tokenize("", tokens, cur) do
    tokens ++ [cur]
  end

  def tokenize(line, tokens, "") do
    {first, next} = String.split_at(line, 1)

    case first do
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
end
