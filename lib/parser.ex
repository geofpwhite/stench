defmodule Parser do
  @infix_operators Operators.infix_operators()
  @prefix_operators Operators.prefix_operators()
  @operators Operators.operators()
  @keywords Keywords.keywords()
  def parse([token | tail]) do
    t = %TreeNode{value: token}

    if t.value not in ["(", "["] do
      parse(t, tail)
    else
      parse(%TreeNode{}, [token | tail])
    end
  end

  def parse([token | tail], statements) do
    t = %TreeNode{value: token}

    if t.value not in ["(", "["] do
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
    case cur_node.value do
      "if" ->
        {node, tail} = parse_if([token | tail])
        [x] = parse(tail)
        statements ++ [node] ++ x

      "pileup" ->
        {node, tail} = parse_pileup([token | tail])
        [x] = parse(tail)
        statements ++ [node] ++ x

      _ ->
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

          "[" ->
            IO.puts(cur_node.value)
            IO.puts(inspect(root))
            IO.puts(inspect(statements))

            if is_var_name?(cur_node.value) and not root do
              {accessor, tail} = parse_list_index(cur_node.value, tail)
              IO.puts("accessor " <> inspect(accessor))
              IO.puts("tail " <> inspect(tail))
              parse(accessor, tail, root, statements)
            else
              if root and cur_node.right != nil and is_var_name?(cur_node.right.value) do
                {accessor, tail} = parse_list_index(cur_node.right.value, tail)
                parse(%{cur_node | right: accessor}, tail, statements: statements)
              else
                {bucket, tail} = parse_list(tail)

                if root do
                  parse(%{cur_node | right: bucket}, tail, statements: statements)
                else
                  parse(bucket, tail, statements: statements)
                end
              end
            end

          ";" ->
            statements ++ [cur_node] ++ parse(tail)

          "=" ->
            parse(%TreeNode{value: "=", left: cur_node}, tail, true, statements)

          ")" ->
            cur_node

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

  def is_var_name?(value) do
    value != nil and to_string(value) != "" and
      not (String.first(value) in String.graphemes("1234567890") or
             value in @operators or
             value in @keywords or
             value in ["=", ","])
  end

  def parse_list_index(var_name, tail) do
    IO.puts(inspect(tail))
    inner = inner_square_bracket(tail)
    IO.puts(inner)
    inner_count = Enum.count(inner)

    {%TreeNode{
       value: %Accessor{
         bucket_name: var_name,
         index: parse(inner)
       }
     }, Enum.slice(tail, inner_count + 1, Enum.count(tail) - inner_count - 1)}
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
    new_tail = Enum.slice(tokens, tail_index + 1, token_count - tail_index - 1)

    if Enum.count(new_tail) != 0 and Enum.at(new_tail, 0) == "else" do
      inner_bracket =
        Enum.take_while(
          Enum.slice(new_tail, 2, Enum.count(new_tail) - 2),
          fn token -> token != "}" end
        )

      {%Conditional{condition: check, do: exec, else: parse(inner_bracket)},
       Enum.slice(
         new_tail,
         Enum.count(inner_bracket) + 1,
         Enum.count(new_tail) - Enum.count(inner_bracket) - 1
       )}
    else
      {%Conditional{condition: check, do: exec}, new_tail}
    end
  end

  def parse_pileup(tokens) do
    until_left_bracket = Enum.take_while(tokens, fn token -> token != "{" end)

    case Enum.reject(Enum.chunk_by(until_left_bracket, fn token -> token == ";" end), fn token ->
           token == [";"]
         end) do
      [begin, check, increment] ->
        [b] = parse(begin)
        c = parse(check)
        i = parse(increment)
        pre_count = Enum.count(until_left_bracket)
        token_count = Enum.count(tokens)

        inner_bracket =
          Enum.take_while(
            Enum.slice(tokens, pre_count + 1, token_count - pre_count - 1),
            fn token -> token != "}" end
          )

        exec = parse(inner_bracket)
        inner_count = Enum.count(inner_bracket)
        tail_index = inner_count + pre_count + 1

        {%Loop{condition: c, do: exec, begin: b, increment: i},
         Enum.slice(tokens, tail_index + 1, token_count - tail_index - 1)}

      _ ->
        if is_for_each?(until_left_bracket) do
        else
          :error
        end
    end
  end

  def for_each([":=" | tokens]) do
    begin = %TreeNode{value: "=", left: %TreeNode{value: "index"}, right: %TreeNode{value: "0"}}

    increment = %TreeNode{
      value: "=",
      left: %TreeNode{value: "index"},
      right: %TreeNode{value: "+", right: %TreeNode{value: "1"}, left: %TreeNode{value: "index"}}
    }

    condition = %TreeNode{
      value: "not",
      right: %TreeNode{
        value: "is",
        left: %TreeNode{
          value: "index"
        },
        right: %TreeNode{
          value: "size",
          right: parse(tokens)
        }
      }
    }
  end

  def is_for_each?([":=" | tail]) do
    true
  end

  def is_for_each?(_) do
    false
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

  def inner_square_bracket(tokens) do
    inner_square_bracket(tokens, [], 1)
  end

  def inner_square_bracket(["[" | tail], inner, parens_count) do
    inner_square_bracket(tail, inner ++ ["["], parens_count + 1)
  end

  def inner_square_bracket(["]" | _], inner, 1) do
    inner
  end

  def inner_square_bracket(["]" | tail], inner, parens_count) do
    inner_square_bracket(tail, inner ++ ["]"], parens_count - 1)
  end

  def inner_square_bracket([], _, _) do
    :error
  end

  def inner_square_bracket([head | tail], inner, parens_count) do
    inner_square_bracket(tail, inner ++ [head], parens_count)
  end

  def parse_list(tokens) do
    until_right_bracket = inner_square_bracket(tokens, [], 1)
    IO.puts(inspect(until_right_bracket) <> " urb")
    inner = remove_unnested_commas(until_right_bracket)

    right_bracket_index = Enum.count(until_right_bracket)

    {%Bucket{garbage: parse_list(inner, [])},
     Enum.slice(tokens, right_bracket_index + 1, Enum.count(tokens) - right_bracket_index - 1)}
  end

  def parse_list([head | tail], list) do
    parse_list(tail, list ++ parse(head))
  end

  def parse_list([], list) do
    list
  end

  def remove_unnested_commas(tokens) do
    remove_unnested_commas(tokens, [], [], 0)
  end

  def remove_unnested_commas(["[" | tail], new_tokens, new_token, num) do
    remove_unnested_commas(tail, new_tokens, new_token ++ ["["], num + 1)
  end

  def remove_unnested_commas(["]" | tail], new_tokens, new_token, num) do
    remove_unnested_commas(tail, new_tokens, new_token ++ ["]"], num - 1)
  end

  def remove_unnested_commas(["," | tail], new_tokens, new_token, 0) do
    remove_unnested_commas(tail, new_tokens ++ [new_token], [], 0)
  end

  def remove_unnested_commas([token | tail], new_tokens, new_token, num) do
    remove_unnested_commas(tail, new_tokens, new_token ++ [token], num)
  end

  def remove_unnested_commas([], new_tokens, new_token, _) do
    new_tokens ++ [new_token]
  end
end
