defmodule Headwater do
  def uuid do
    UUID.uuid4(:hex)
  end

  def web_safe_md5(content) when is_binary(content) do
    :crypto.hash(:md5, content) |> Base.encode16()
  end

  defdelegate wish_successful?(wish_results), to: Headwater.Success, as: :success?
end
