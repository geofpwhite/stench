defmodule Stench.Parser do
  @infix_operators Operators.infix_operators()
  @prefix_operators Operators.prefix_operators()
  @operators Operators.operators()
  @keywords Keywords.keywords()
  # parse/1
  @spec parse(any()) :: any()
  def parse([token | tail]) do
    t = %TreeNode{value: token}

    if t.value not in ["(", "["] do
      parse(t, tail)
    else
      parse(%TreeNode{}, [token | tail])
    end
  end

  # parse/2
  @spec parse(any(), any()) :: any()
  def parse([token | tail], statements) do
    t = %TreeNode{value: token}

    if t.value not in ["(", "["] do
      parse(t, tail, false, statements)
    else
      parse(%TreeNode{}, [token | tail], false, statements)
    end
  end

  # parse/3
  @spec parse(any(), maybe_improper_list(), any()) :: any()
  def parse(_, [operator], _) when operator in @operators do
    :error
  end

  # parse/4
  @spec parse(any(), maybe_improper_list(), any(), any()) :: any()
  def parse(cur, ary \\ [], root \\ false, statements \\ [])

  def parse(cur, [], _, statements) do
    statements ++ [cur]
  end

  def parse([], [], _, statements) do
    statements
  end

  def parse(%TreeNode{value: nil, left: nil, right: t}, ary, root, statements) when t != nil do
    parse(t, ary, root, statements)
  end

  def parse(%Bucket{garbage: _} = b, [token | tail], root, statements)
      when token in ["+", "-"] do
    parse(%TreeNode{value: token, left: b}, tail, root, statements)
  end

  def parse(cur_node, [token | tail], root, statements) do
    case cur_node.value do
      ";" ->
        parse(%TreeNode{}, [token | tail], root, statements)

      "if" ->
        {node, tail} = parse_if([token | tail])

        case parse(tail) do
          [x] ->
            statements ++ [node] ++ x

          [x, []] ->
            statements ++ [node] ++ x

          %TreeNode{value: nil, left: nil, right: nil} ->
            statements ++ [node]

          x ->
            statements ++ [node] ++ x
        end

      "pileup" ->
        {node, tail} = parse_pileup([token | tail])

        case parse(tail) do
          [x] ->
            statements ++ [node] ++ x

          ary when is_list(ary) ->
            statements ++ [node] ++ ary

          other ->
            statements ++ [node] ++ [other]
        end

      "sniff" ->
        {node, tail} = parse_sniff([token | tail])

        case parse(tail) do
          [x] ->
            statements ++ [node] ++ x

          ary when is_list(ary) ->
            statements ++ [node] ++ ary

          other ->
            statements ++ [node] ++ [other]
        end

      "odor" ->
        {node, tail} = parse_odor([token | tail])

        case parse(tail) do
          [x] ->
            statements ++ [node] ++ x

          ary when is_list(ary) ->
            statements ++ [node] ++ ary

          other ->
            statements ++ [node] ++ [other]
        end

      _ ->
        case token do
          token when token in @infix_operators ->
            # if we are assigning
            if root or cur_node.value in @prefix_operators do
              n = %TreeNode{value: token, left: cur_node.right, right: parse(tail)}

              new = %{cur_node | right: n}
              new
            else
              new = %TreeNode{value: token, left: cur_node}
              parse(new, tail, root, statements)
            end

          token when token in @prefix_operators ->
            if root do
              %{cur_node | right: parse(%TreeNode{value: token}, tail, true)}
            else
              new = %TreeNode{value: token}
              parse(new, tail, true, statements: statements)
            end

          "[" ->
            IO.inspect(cur_node)

            cond do
              Accessor.is_accessor(cur_node.value) ||
                  MultiAccessor.is_multi_accessor(cur_node.value) ->
                {accessor, tail} = parse_multi_index(cur_node.value, tail)
                IO.puts("accessor " <> inspect(accessor))
                IO.puts("tail " <> inspect(tail))

                if root do
                  parse(%{cur_node | right: %TreeNode{value: accessor}}, tail, root, statements)
                else
                  parse(%TreeNode{value: accessor}, tail, root, statements)
                end

              is_var_name?(cur_node.value) and not root ->
                {accessor, tail} = parse_list_index(cur_node.value, tail)

                parse(accessor, tail, root, statements)

              cur_node.right != nil and is_var_name?(cur_node.right.value) and
                  (root or cur_node.value in @infix_operators) ->
                {accessor, tail} = parse_list_index(cur_node.right.value, tail)
                parse(%{cur_node | right: accessor}, tail, statements: statements)

              true ->
                {bucket, tail} = parse_list(tail)

                if cur_node == nil or cur_node.value == nil do
                  parse(bucket, tail)
                else
                  parse(%{cur_node | right: bucket}, tail)
                end
            end

          ";" ->
            if cur_node.value == nil and cur_node.left == nil and cur_node.right == nil do
              statements ++ parse(tail)
              # statements ++ parse([token|tail])
            else
              statements ++ [cur_node] ++ parse(tail)
            end

          "=" ->
            assignment = Enum.take_while(tail, fn token -> token not in [";", "}"] end)

            next =
              Enum.slice(
                tail,
                min(Enum.count(tail), Enum.count(assignment)),
                max(0, Enum.count(tail) - Enum.count(assignment))
              )

            #
            pn = parse(next)

            if Enum.empty?(pn) or pn == [[]] do
              statements ++
                [sanitize_inner(parse(%TreeNode{value: "=", left: cur_node}, assignment, true))]
            else
              statements ++
                [sanitize_inner(parse(%TreeNode{value: "=", left: cur_node}, assignment, true))] ++
                pn
            end

          char when char in [")", "]", "}"] ->
            cur_node

          "(" ->
            inner_ary = inner(tail, [], 1)

            case parse(inner_ary) do
              [inner] ->
                ilength = Enum.count(inner_ary)
                tlength = Enum.count(tail)

                if cur_node.value == nil and cur_node.right == nil do
                  x =
                    sanitize_inner(
                      parse(
                        inner,
                        Enum.slice(tail, ilength + 0, tlength - ilength - 0),
                        root
                      )
                    )

                  x
                else
                  if cur_node.value == nil do
                    parse(
                      cur_node.right,
                      Enum.slice(tail, ilength + 1, tlength - ilength - 1),
                      root
                    )
                  else
                    new = %{cur_node | right: inner}

                    x =
                      parse(
                        new,
                        Enum.slice(tail, ilength + 1, tlength - ilength - 1),
                        root
                      )

                    x
                  end
                end

              inner ->
                ilength = Enum.count(inner_ary)
                tlength = Enum.count(tail)

                if cur_node.value == nil do
                  x =
                    parse(
                      inner,
                      Enum.slice(tail, ilength + 1, tlength - ilength - 1),
                      root
                    )

                  x
                else
                  new = %{cur_node | right: inner}

                  x =
                    parse(
                      new,
                      Enum.slice(tail, ilength + 1, tlength - ilength - 1),
                      root
                    )

                  x
                end
            end

          token ->
            new = %TreeNode{value: token}
            parse(%{cur_node | right: new}, tail, root, statements)
        end
    end
  end

  # parse_sniff/1
  @spec parse_sniff(nonempty_maybe_improper_list()) :: {Sniff.t(), list()}
  def parse_sniff([odor, "(" | tail]) do
    within = inner(tail)
    new_tail = Enum.slice(tail, Enum.count(within) + 1, Enum.count(tail) - Enum.count(within) - 1)

    param_values =
      Enum.reject(Enum.chunk_by(inner(tail), fn t -> t == "," end), fn t -> t == [","] end)

    {%Sniff{
       odor: odor,
       param_values: param_values
     }, new_tail}
  end

  # sanitize_inner/1
  @spec sanitize_inner(any()) :: any()
  def sanitize_inner([inner, []]) do
    inner
  end

  def sanitize_inner([inner]) do
    inner
  end

  def sanitize_inner(inner) do
    inner
  end

  # is_var_name?/1
  @spec is_var_name?(any()) :: boolean()
  def is_var_name?(value) do
    value != nil and to_string(value) != "" and
      not (String.first(value) in String.graphemes("1234567890") or
             value in @operators or
             value in @keywords or
             value in ["=", ","])
  end

  def parse_multi_index(
        %Accessor{
          bucket_name: bucket_name,
          index: index
        },
        tail
      ) do
    inner = inner_square_bracket(tail)
    next_index = parse(inner)
    inner_size = Enum.count(inner)
    total_size = Enum.count(tail)

    {%MultiAccessor{bucket_name: bucket_name, indices: [index, next_index]},
     Enum.slice(tail, inner_size + 1, total_size - inner_size - 1)}
  end

  def parse_multi_index(
        %MultiAccessor{
          bucket_name: bucket_name,
          indices: indices
        },
        tail
      ) do
    inner = inner_square_bracket(tail)
    next_index = parse(inner)
    inner_size = Enum.count(next_index)
    total_size = Enum.count(tail)

    {
      %MultiAccessor{bucket_name: bucket_name, indices: indices ++ [next_index]},
      Enum.slice(tail, inner_size + 1, total_size - inner_size - 1)
    }
  end

  def parse_multi_index(arg1, arg2) do
    IO.inspect(arg1)
    IO.inspect(arg2)
    :error
  end

  # parse_list_index/2
  @spec parse_list_index(any(), maybe_improper_list()) :: {TreeNode.t(), list()}
  def parse_list_index(var_name, tail) do
    inner = inner_square_bracket(tail)

    inner_count = Enum.count(inner)

    {%TreeNode{
       value: %Accessor{
         bucket_name: var_name,
         index: parse(inner)
       }
     }, Enum.slice(tail, inner_count + 1, Enum.count(tail) - inner_count - 1)}
  end

  # remove_empty/1
  @spec remove_empty(any()) :: list()
  def remove_empty(ary) do
    Enum.reject(ary, fn element -> element == [] end)
  end

  # parse_if/1
  @spec parse_if(any()) :: {Conditional.t(), list()}
  def parse_if(tokens) do
    until_left_bracket = Enum.take_while(tokens, fn token -> token != "{" end)

    check = parse(until_left_bracket)
    condition_count = Enum.count(until_left_bracket)
    token_count = Enum.count(tokens)
    x = Enum.slice(tokens, condition_count + 1, token_count - condition_count - 1)

    inner_bracket =
      inner_curly_bracket(x)

    inner_count = Enum.count(inner_bracket)
    tail_index = inner_count + condition_count + 1
    exec = remove_empty(parse(inner_bracket))

    new_tail = Enum.slice(tokens, tail_index + 1, token_count - tail_index - 1)

    if Enum.count(new_tail) != 0 and Enum.at(new_tail, 0) == "else" do
      inner_bracket = inner_curly_bracket(Enum.slice(new_tail, 2, Enum.count(new_tail) - 2))

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

  # parse_odor/1
  @spec parse_odor(nonempty_maybe_improper_list()) :: {Odor.t(), list()}
  def parse_odor([func_name, "(" | tail]) do
    param_tokens = inner(tail)

    new_tail =
      Enum.slice(
        tail,
        Enum.count(param_tokens) + 1,
        Enum.count(tail) - Enum.count(param_tokens) - 1
      )

    {return_type, todo_tokens} = get_return_value(new_tail)

    params_by_types =
      Enum.reject(Enum.chunk_by(param_tokens, fn token -> token == "," end), fn ary ->
        ary == [","]
      end)

    params =
      Enum.map(params_by_types, fn [name, ":", type] ->
        %Param{
          name: name,
          type: type
        }
      end)

    exec = parse(todo_tokens)

    {%Odor{
       name: func_name,
       params: params,
       do: exec,
       return_type: return_type
     },
     Enum.slice(
       new_tail,
       min(Enum.count(todo_tokens) + 3, Enum.count(new_tail) - 1),
       max(0, Enum.count(new_tail) - Enum.count(todo_tokens) - 3)
     )}
  end

  # get_return_value/1
  @spec get_return_value(any()) :: :error | {any(), any()}
  def get_return_value(tail) do
    case tail do
      ["{" | tail] ->
        todo = inner_curly_bracket(tail)
        {nil, todo}

      [return_type, "{" | tail] ->
        todo = inner_curly_bracket(tail)
        {return_type, todo}

      _ ->
        :error
    end
  end

  # parse_pileup/1
  @spec parse_pileup(any()) :: :error | {Loop.t(), list()}
  def parse_pileup(tokens) do
    until_left_bracket = Enum.take_while(tokens, fn token -> token != "{" end)

    pre_count = Enum.count(until_left_bracket)
    token_count = Enum.count(tokens)

    inner_check =
      Enum.slice(tokens, min(token_count, pre_count + 1), max(0, token_count - pre_count - 1))

    inner_bracket =
      inner_curly_bracket(inner_check)

    inner_count = Enum.count(inner_bracket)
    tail_index = inner_count + pre_count + 1

    if is_for_each?(until_left_bracket) do
      {%{for_each(until_left_bracket) | do: parse(inner_bracket)},
       Enum.slice(tokens, tail_index + 1, token_count - tail_index - 1)}
    else
      case Enum.reject(
             Enum.chunk_by(until_left_bracket, fn token -> token == ";" end),
             fn token ->
               token == [";"]
             end
           ) do
        [begin, check, increment] ->
          [b] = parse(begin)
          c = parse(check)
          i = parse(increment)
          exec = parse(inner_bracket)

          if tail_index + 1 < Enum.count(tokens) do
            {%Loop{condition: c, do: exec, begin: b, increment: i},
             Enum.slice(tokens, tail_index + 1, token_count - tail_index - 1)}
          else
            {%Loop{condition: c, do: exec, begin: b, increment: i}, []}
          end

        _ ->
          :error
      end
    end
  end

  # for_each/1
  @spec for_each(nonempty_maybe_improper_list()) :: Loop.t()
  def for_each([name, ":=" | bucket]) do
    begin = [
      %TreeNode{value: "=", left: %TreeNode{value: "_index_"}, right: %TreeNode{value: "0"}},
      %TreeNode{value: "=", left: %TreeNode{value: "_ary_"}, right: parse(bucket)},
      %TreeNode{
        value: "=",
        left: %TreeNode{value: name},
        right: %Accessor{bucket_name: "_ary_", index: %TreeNode{value: "_index_"}}
      }
    ]

    condition = %TreeNode{
      value: "<",
      left: %TreeNode{
        value: "_index_"
      },
      right: %TreeNode{
        value: "size",
        right: %TreeNode{
          value: "_ary_"
        }
      }
    }

    increment = [
      %TreeNode{
        value: "=",
        left: %TreeNode{value: "_index_"},
        right: %TreeNode{
          value: "+",
          right: %TreeNode{value: "1"},
          left: %TreeNode{value: "_index_"}
        }
      },
      %TreeNode{
        value: "=",
        left: %TreeNode{
          value: name
        },
        right: %TreeNode{
          value: %Accessor{
            bucket_name: "_ary_",
            index: %TreeNode{value: "_index_"}
          }
        }
      }
    ]

    %Loop{
      begin: begin,
      increment: increment,
      condition: condition
    }
  end

  # is_for_each?/1
  @spec is_for_each?(any()) :: boolean()
  def is_for_each?([_, ":=" | _]) do
    true
  end

  def is_for_each?(_) do
    false
  end

  # inner/1
  @spec inner(nonempty_maybe_improper_list()) :: any()
  def inner(ary) do
    inner(ary, [], 1)
  end

  # inner/3
  @spec inner(nonempty_maybe_improper_list(), any(), integer()) :: any()
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

  # inner_square_bracket/1
  @spec inner_square_bracket(maybe_improper_list()) :: any()
  def inner_square_bracket(tokens) do
    inner_square_bracket(tokens, [], 1)
  end

  # inner_square_bracket/3
  @spec inner_square_bracket(maybe_improper_list(), any(), any()) :: any()
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

  # inner_curly_bracket/1
  @spec inner_curly_bracket(maybe_improper_list()) :: any()
  def inner_curly_bracket(tokens) do
    inner_curly_bracket(tokens, [], 1)
  end

  # inner_curly_bracket/3
  @spec inner_curly_bracket(maybe_improper_list(), any(), any()) :: any()
  def inner_curly_bracket(["{" | tail], inner, parens_count) do
    inner_curly_bracket(tail, inner ++ ["{"], parens_count + 1)
  end

  def inner_curly_bracket(["}" | _], inner, 1) do
    inner
  end

  def inner_curly_bracket(["}" | tail], inner, parens_count) do
    inner_curly_bracket(tail, inner ++ ["}"], parens_count - 1)
  end

  def inner_curly_bracket([], _, _) do
    :error
  end

  def inner_curly_bracket([head | tail], inner, parens_count) do
    inner_curly_bracket(tail, inner ++ [head], parens_count)
  end

  # parse_list/1
  @spec parse_list(maybe_improper_list()) :: {Bucket.t(), list()}
  def parse_list(tokens) do
    until_right_bracket = inner_square_bracket(tokens, [], 1)

    inner = remove_unnested_commas(until_right_bracket)

    right_bracket_index = Enum.count(until_right_bracket)

    {%Bucket{garbage: parse_list(inner, [])},
     Enum.slice(tokens, right_bracket_index + 1, Enum.count(tokens) - right_bracket_index - 1)}
  end

  # parse_list/2
  @spec parse_list(list(), any()) :: any()
  def parse_list([head | tail], list) do
    parse_list(tail, list ++ parse(head))
  end

  def parse_list([], list) do
    list
  end

  # remove_unnested_commas/1
  @spec remove_unnested_commas(list()) :: [...]
  def remove_unnested_commas(tokens) do
    remove_unnested_commas(tokens, [], [], 0)
  end

  # remove_unnested_commas/4
  @spec remove_unnested_commas(list(), list(), any(), any()) :: [...]
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
