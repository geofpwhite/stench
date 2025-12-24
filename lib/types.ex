defmodule Type do
  @typedoc "a variable's type"
  defstruct [:type]

  @type type :: :string | :int | :list | :bool | nil

  @type t() :: %Type{
          type: type()
        }
end
