defmodule TreeNode do
  defstruct value: nil, left: nil, right: nil

  @type t() :: %TreeNode{
          value: any(),
          left: any(),
          right: any()
        }
end
