defmodule Keywords do
  @special_chars [";", "\"", "'", "=", ",", ":="]
  @special_strings ["pileup", "if", "else", "size"]
  @keywords @special_chars ++ @special_strings
  def keywords, do: @keywords
end
