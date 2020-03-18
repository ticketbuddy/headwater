defmodule Headwater.Debug do
  def to_list({:ok, recorded_events}), do: to_list(recorded_events)

  def to_list(recorded_events) do
    recorded_events
    |> Enum.map(fn recorded_event ->
      recorded_event
      |> Map.put(:event_type, Atom.to_string(recorded_event.data.__struct__))
      |> Map.put(:data, Map.from_struct(recorded_event.data))
      |> Map.delete(:__struct__)
    end)
  end
end
