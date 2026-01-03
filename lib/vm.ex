defmodule VM do
  @instructions [:set]
  defstruct registers: [], pc: 0, halted: 0

  def instructions, do: @instructions

  @type t() :: %VM{
          registers: list(),
          pc: integer(),
          halted: integer()
        }
end
