defmodule Headwater.Crypto do
  def web_safe_md5(content) when is_binary(content) do
    :crypto.hash(:md5, content) |> Base.encode16()
  end
end
