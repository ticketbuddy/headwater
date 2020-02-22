defmodule Example.Printer do
  def listener_prefix, do: "printer_"

  def handle_event(event, notes) do
    IO.inspect({event, notes}, label: "printer")
    require Logger
    Logger.log(:info, inspect({event, notes}))

    :ok
  end
end
