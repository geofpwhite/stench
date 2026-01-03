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
