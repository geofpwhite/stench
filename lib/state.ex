defmodule State do
  defstruct vars: %{}, cur_return: %{type: nil, value: nil}, funcs: []

  @type t() :: %State{
          vars: map()
        }
end

defmodule Var do
  defstruct type: nil, value: nil

  @type t() :: %Var{
          type: Type.type(),
          value: any()
        }
end
