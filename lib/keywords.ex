defmodule Keywords do
  @special_chars [";","\"","'","=",","]
  @special_strings ["print"]
  @keywords @special_chars++@special_strings
  def keywords, do: @keywords
end
