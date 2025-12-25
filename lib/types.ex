defmodule Type do
  @typedoc "a variable's type"
  defstruct type: nil

  @type type :: :string | :int | :bucket | :bool | nil

  @type t() :: %Type{
          type: type()
        }
end

defmodule Bucket do
  defstruct garbage: []

  @type t() :: %Bucket {
    garbage: list(TreeNode)
  }
end

defmodule Accessor do
  defstruct bucket_name: "", index: 0
  @type t() :: %Accessor {
    bucket_name: String.t(),
    index: TreeNode,
  }
end
