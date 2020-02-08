defmodule Headwater.Aggregate.Handler do
  @type completed_event :: any()
  @type reason :: any()
  @type wish :: any()
  @type aggregate_state :: any()
  @type event :: any()

  @callback execute(aggregate_state, wish) :: {:ok, completed_event} | {:error, reason}
  @callback next_state(aggregate_state, completed_event) :: aggregate_state | {:error, reason}
end
