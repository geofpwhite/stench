defmodule Loop do
  defstruct begin: %Var{}, condition: [%TreeNode{}], increment: [%TreeNode{}], do: [%TreeNode{}]
end

defmodule Conditional do
  defstruct condition: [%TreeNode{}], do: [%TreeNode{}], else: [%TreeNode{}]
end

defmodule Func do
  # Functions will return the final value
  defstruct name: "", params: [], do: []
end

defmodule Builtins do
  @builtins []
  def builtins, do: @builtins
end
