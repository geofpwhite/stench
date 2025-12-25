defmodule Loop do
  defstruct begin: %Var{}, condition: [%TreeNode{}], increment: [%TreeNode{}], do: [%TreeNode{}]
end

defmodule Conditional do
  defstruct condition: [%TreeNode{}], do: [%TreeNode{}], else: [%TreeNode{}]
end
