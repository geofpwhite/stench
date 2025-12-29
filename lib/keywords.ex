defmodule Keywords do
  @special_chars [";", "\"", "'", "=", ",", ":="]
  @special_strings ["pileup", "if", "else", "size", "dump", "odor", "sniff","wipe","break"]
  @keywords @special_chars ++ @special_strings
  def keywords, do: @keywords
end
