defmodule Keywords do
  @special_chars [";", "\"", "'", "=", ",", ":="]
  @special_strings [
    "pileup",
    "if",
    "else",
    "size",
    "dump",
    "odor",
    "sniff",
    "wipe",
    "break",
    "ref",
    "deref"
  ]
  @keywords @special_chars ++ @special_strings

  @spec keywords() :: list(String.t())
  def keywords, do: @keywords
end
