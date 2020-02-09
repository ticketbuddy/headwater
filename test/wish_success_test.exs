defmodule Headwater.WishSuccessTest do
  use ExUnit.Case

  test "when wish result is idempotent success" do
    assert Headwater.wish_successful?({:ok, :idempotent_request_succeeded})
  end

  test "when wish result is success" do
    assert Headwater.wish_successful?({:ok, "any result"})
  end

  test "when wish result is error atom" do
    refute Headwater.wish_successful?(:error)
  end

  test "when wish result is error tuple" do
    refute Headwater.wish_successful?({:error, "any reason"})
  end
end
