defmodule Headwater do
  def uuid do
    UUID.uuid4(:hex)
  end

  defdelegate wish_successful?(wish_results), to: Headwater.WishSuccess, as: :success?
end
