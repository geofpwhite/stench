defmodule Loop do
  defstruct begin: %Var{}, condition: [%TreeNode{}], increment: [%TreeNode{}], do: [%TreeNode{}]
end


defmodule Conditional do
  defstruct condition: [%TreeNode{}], do: [%TreeNode{}], else: [%TreeNode{}]
end


# the language's word for Function. <insert bad pun about code smells>
defmodule Odor do
  # Functions will return their final value
  defstruct name: "", params: [], do: [], return_type: %Var{}
end

defmodule Param do
  defstruct name: "", type: nil, value: %Var{}
end

defmodule Sniff do
  defstruct odor: "", param_values: []
end

defmodule Builtins do
  @builtins ["dump"]
  def builtins, do: @builtins
end
