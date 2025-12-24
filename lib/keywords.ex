defmodule Keywords do
  @special_chars [";", "\"", "'", "=", ","]
  @special_strings ["for","if","else"]
  @keywords @special_chars ++ @special_strings
  def keywords, do: @keywords
end
