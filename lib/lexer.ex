defmodule Lexer do
  @operators Operators.operators

  def tokenize("",tokens,"") do
    tokens
  end
  def tokenize("",tokens,cur) do
    tokens++[cur]
  end
  def tokenize(line, tokens, "") do
    {first,next} = String.split_at(line,1)
    case first do
      char when char in @operators or char in ["(", ")"] ->
        tokenize(next, tokens ++ [char], "")
      char when char in [" ","\n","\r","\t","\"","'"] ->
        tokenize(next,tokens,"")
      char->
        tokenize(next,tokens,char)
    end
  end
  def tokenize(line, tokens, cur) do
    {first,next} = String.split_at(line,1)
    case first do
      char when char in @operators or char in ["(", ")"] ->
        tokenize(next, tokens ++ [cur,char], "")
      char when char in [" ","\n","\r","\t","\"","'"] ->
        tokenize(next,tokens,cur)
      char->
        tokenize(next,tokens,cur<>char)
    end
  end



  def tokenize(line) do
    tokenize(line, [], "")
  end
end
