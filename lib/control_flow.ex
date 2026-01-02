defmodule Loop do
  defstruct begin: %Var{}, condition: [%TreeNode{}], increment: [%TreeNode{}], do: [%TreeNode{}]

  @type t() :: %Loop{
          begin: %Var{},
          condition: [%TreeNode{}],
          increment: [%TreeNode{}],
          do: [%TreeNode{}]
        }
end

defmodule Conditional do
  defstruct condition: [%TreeNode{}], do: [%TreeNode{}], else: [%TreeNode{}]

  @type t() :: %Conditional{
          condition: [%TreeNode{}],
          do: [%TreeNode{}],
          else: [%TreeNode{}]
        }
end

# the language's word for Function. <insert bad pun about code smells>
defmodule Odor do
  # Functions will return their final value
  defstruct name: "", params: [], do: [], return_type: %Var{}

  @type t() :: %Odor{
          name: String.t(),
          params: list(),
          do: list(),
          return_type: %Var{}
        }
end

defmodule Param do
  defstruct name: "", type: nil, value: %Var{}

  @type t() :: %Param{
          name: String.t(),
          type: any(),
          value: %Var{}
        }
end

defmodule Sniff do
  defstruct odor: "", param_values: []

  @type t() :: %Sniff{
          odor: String.t(),
          param_values: list()
        }
end
