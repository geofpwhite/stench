defmodule Loop do
  defstruct begin: %Var{}, condition: [%TreeNode{}], increment: nil, do: [%TreeNode{}]
end

defmodule Conditional do
  defstruct condition: [%TreeNode{}], do: [%TreeNode{}]
end
