defmodule Headwater.TestSupport.AggregateDirectory do
  @behaviour Headwater.AggregateDirectory
  alias Headwater.AggregateDirectory.{Result, WriteRequest, ReadRequest}

  def handle(write_request = %WriteRequest{}) do
    send(self(), {:_headwater_handle, write_request})

    Process.delete(:_headwater_handle_result) || {:ok, %Result{}}
  end

  def read_state(read_request = %ReadRequest{}) do
    raise "not implemented"
  end

  def set_handle_result(result), do: Process.put(:_headwater_handle_result, result)

  defmacro assert_wish_requested(write_request) do
    quote do
      ExUnit.Assertions.assert_receive({:_headwater_handle, unquote(write_request)}, 1000)
    end
  end
end
