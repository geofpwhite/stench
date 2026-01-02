defmodule Type do
  @typedoc "a variable's type"
  defstruct type: nil

  @type type :: :string | :num | :bucket | :bool | nil

  @type t() :: %Type{
          type: type()
        }
end

defmodule Bucket do
  defstruct garbage: []

  @type t() :: %Bucket{
          garbage: list(TreeNode)
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
