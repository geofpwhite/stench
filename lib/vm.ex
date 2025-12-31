defmodule VM do
  @instructions [:set]
  defstruct registers: [], pc: 0, halted: 0
end
