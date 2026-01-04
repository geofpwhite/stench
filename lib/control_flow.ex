defmodule Loop do
  defstruct begin: [%TreeNode{}],
            condition: [%TreeNode{}],
            increment: [%TreeNode{}],
            do: [%TreeNode{}]

  @type t() :: %Loop{
          begin: list(TreeNode.t()),
          condition: list(TreeNode.t()),
          increment: list(TreeNode.t()),
          do: list(TreeNode.t())
        }
end

defmodule Conditional do
  defstruct condition: [%TreeNode{}], do: [%TreeNode{}], else: [%TreeNode{}]

  @type t() :: %Conditional{
          condition: list(TreeNode.t()),
          do: list(TreeNode.t()),
          else: list(TreeNode.t())
        }
end

# the language's word for Function. <insert bad pun about code smells>
defmodule Odor do
  # Functions will return their final value
  defstruct name: "", params: [], do: [], return_type: %Var{}

  @type t() :: %Odor{
          name: String.t(),
          params: list(Param.t()),
          do: list(TreeNode.t()),
          return_type: Var.t()
        }
end

defmodule Param do
  defstruct name: "", type: nil, value: %Var{}

  @type t() :: %Param{
          name: String.t(),
          type: any(),
          value: Var.t()
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
  defstruct bucket_name: "", index: %TreeNode{}

  def is_accessor(%Accessor{bucket_name: _, index: _}), do: true
  def is_accessor(_), do: false

  @type t() :: %Accessor{
          bucket_name: String.t(),
          index: TreeNode.t()
        }
end

defmodule MultiAccessor do
  defstruct bucket_name: "", indices: []

  def is_multi_accessor(%MultiAccessor{bucket_name: _, indices: _}), do: true
  def is_multi_accessor(_), do: false

  @type t() :: %MultiAccessor{
          bucket_name: String.t(),
          indices: list(TreeNode.t())
        }
end
