defmodule Loop do
  defstruct begin: [%TreeNode{}],
            condition: [%TreeNode{}],
            increment: [%TreeNode{}],
            do: [%TreeNode{}]

  @type t() :: %Loop{
          begin: list(%TreeNode{}),
          condition: list(%TreeNode{}),
          increment: list(%TreeNode{}),
          do: list(%TreeNode{})
        }
end

defmodule Conditional do
  defstruct condition: [%TreeNode{}], do: [%TreeNode{}], else: [%TreeNode{}]

  @type t() :: %Conditional{
          condition: list(%TreeNode{}),
          do: list(%TreeNode{}),
          else: list(%TreeNode{})
        }
end

# the language's word for Function. <insert bad pun about code smells>
defmodule Odor do
  # Functions will return their final value
  defstruct name: "", params: [], do: [], return_type: %Var{}

  @type t() :: %Odor{
          name: String.t(),
          params: list(Param),
          do: list(TreeNode),
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
          param_values: list(String.t())
        }
end

defmodule Accessor do
  defstruct bucket_name: "", index: 0

  def is_accessor(%Accessor{}), do: true
  def is_accessor(_), do: false

  @type t() :: %Accessor{
          bucket_name: String.t(),
          index: TreeNode
        }
end

defmodule MultiAccessor do
  defstruct bucket_name: "", indices: []

  def is_multi_accessor(%MultiAccessor{}), do: true
  def is_multi_accessor(_), do: false

  @type t() :: %MultiAccessor{
          bucket_name: String.t(),
          indices: list(TreeNode)
        }
end
