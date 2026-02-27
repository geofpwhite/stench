defmodule Type do
  @typedoc "a variable's type"
  defstruct type: nil

  @type type :: :string | :num | :bucket | :bool | nil | :ref

  @type t() :: %Type{
          type: type()
        }
end

defmodule Bucket do
  defstruct garbage: []

  @type t() :: %Bucket{
          garbage: list(TreeNode.t())
        }
end

defmodule Ref do
  defstruct variable: %TreeNode{}

  @type t() :: %Ref{
          variable: TreeNode.t()
        }
end

defmodule Deref do
  defstruct reference: %TreeNode{}

  @type t() :: %Deref{
          reference: TreeNode.t()
        }
end
