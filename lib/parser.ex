defmodule Parser do
  @operators Operators.operators()
  def parse([token | tail]) do
    t = %TreeNode{value: token}

    if t.value != "(" do
      parse(t, tail)
    else
      p = parse(%TreeNode{}, [token | tail])
      p
    end
  end

  def parse(_, [operator]) when operator in @operators do
    IO.puts("err")
    :error
  end

  def parse(cur, []) do
    cur
  end

  def parse(cur_node, [token | tail]) do
    case token do
      token when token in @operators ->
        new = %TreeNode{value: token, left: cur_node}
        parse(new, tail)

      ")" ->
        cur_node

      "(" ->
        inner_ary = inner(tail, [], 1)
        inner = parse(inner_ary)

        if cur_node.value == nil do
          parse(
            inner,
            Enum.slice(tail, Enum.count(inner_ary) + 1, Enum.count(tail) - Enum.count(inner_ary))
          )
        else
          new = %{cur_node | right: inner}

          parse(
            new,
            Enum.slice(tail, Enum.count(inner_ary) + 1, Enum.count(tail) - Enum.count(inner_ary))
          )
        end

      token ->
        new = %TreeNode{value: token}
        parse(%{cur_node | right: new}, tail)
    end
  end

  def inner(["(" | tail], inner, parens_count) do
    inner(tail, inner ++ ["("], parens_count + 1)
  end

  def inner([")" | _], inner, 1) do
    inner
  end

  def inner([")" | tail], inner, parens_count) do
    inner(tail, inner ++ [")"], parens_count - 1)
  end

  def inner([head | tail], inner, parens_count) do
    inner(tail, inner ++ [head], parens_count)
  end
end
