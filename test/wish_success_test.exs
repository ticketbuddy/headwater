defmodule Headwater.WishSuccessTest do
  use ExUnit.Case

  test "when wish result is idempotent success" do
    assert Headwater.Success.success?({:ok, :idempotent_request_succeeded})
  end

  test "when wish result is success" do
    assert Headwater.Success.success?({:ok, "any result"})
  end

  test "when wish result is error atom" do
    refute Headwater.Success.success?(:error)
  end

  test "when wish result is error tuple" do
    refute Headwater.Success.success?({:error, "any reason"})
  end
end
