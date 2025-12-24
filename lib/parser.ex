defmodule Parser do
  @infix_operators Operators.infix_operators()
  @prefix_operators Operators.prefix_operators()
  @operators Operators.operators()
  def parse([token | tail]) do
    t = %TreeNode{value: token}

    if t.value != "(" do
      parse(t, tail)
    else
      parse(%TreeNode{}, [token | tail])
    end
  end

  def parse([token | tail], statements) do
    t = %TreeNode{value: token}

    if t.value != "(" do
      parse(t, tail, false, statements)
    else
      parse(%TreeNode{}, [token | tail], false, statements)
    end
  end

  def parse(_, [operator], _) when operator in @operators do
    :error
  end

  def parse(cur, ary \\ [], root \\ false, statements \\ [])

  def parse(cur, [], _, statements) do
    statements ++ [cur]
  end
  def parse([], [], _, statements) do
    statements
  end

  def parse(cur_node, [token | tail], root, statements) do

    if cur_node.value == "if" do
      {node, tail} = parse_if([token | tail])
      [x] = parse(tail)
      statements ++ [node] ++ x
    else
      case token do
        token when token in @infix_operators ->
          # if we are assigning

          if root do
            n = %TreeNode{value: token, left: cur_node.right}

            new = %{cur_node | right: parse(n, tail)}
            new
          else
            new = %TreeNode{value: token, left: cur_node}
            parse(new, tail, statements)
          end

        token when token in @prefix_operators ->
          if root do
            %{cur_node | right: parse(%TreeNode{value: token}, tail)}
          else
            new = %TreeNode{value: token}
            parse(new, tail, statements)
          end

        ";" ->
          statements ++ [cur_node] ++ parse(tail)

        "=" ->
          parse(%TreeNode{value: "=", left: cur_node}, tail, root: true, statements: statements)

        ")" ->
          cur_node

        # parse(cur_node,tail,root,statements)

        "(" ->
          inner_ary = inner(tail, [], 1)
          [inner] = parse(inner_ary)
          ilength = Enum.count(inner_ary)
          tlength = Enum.count(tail)

          if cur_node.value == nil do
            x =
              parse(
                inner,
                Enum.slice(tail, ilength + 1, tlength - ilength),
                root
              )

            x
          else
            new = %{cur_node | right: inner}

            x =
              parse(
                new,
                Enum.slice(tail, ilength + 1, tlength - ilength),
                root
              )

            x
          end

        token ->
          new = %TreeNode{value: token}
          parse(%{cur_node | right: new}, tail, root, statements)
      end
    end
  end

  def parse_if(tokens) do
    until_left_bracket = Enum.take_while(tokens, fn token -> token != "{" end)

    check = parse(until_left_bracket)
    condition_count = Enum.count(until_left_bracket)
    token_count = Enum.count(tokens)

    inner_bracket =
      Enum.take_while(
        Enum.slice(tokens, condition_count + 1, token_count - condition_count - 1),
        fn token -> token != "}" end
      )

    inner_count = Enum.count(inner_bracket)
    tail_index = inner_count + condition_count + 1
    exec = parse(inner_bracket)

    {%Conditional{condition: check, do: exec},
     Enum.slice(tokens, tail_index + 1, token_count - tail_index - 1)}
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
