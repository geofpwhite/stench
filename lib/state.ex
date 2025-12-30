
defmodule Var do
  defstruct type: nil, value: nil

  @type t() :: %Var{
          type: Type.type(),
          value: any()
        }
end

defmodule State do
  defstruct vars: %{}, cur_return: %Var{type: nil, value: nil}, odors: %{}, break: false

  @type t() :: %State{
          vars: map(),
          cur_return: Var.t(),
          odors: map(),
          break: boolean()
        }
end
