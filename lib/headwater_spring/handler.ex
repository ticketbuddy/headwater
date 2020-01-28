defmodule HeadwaterSpring.Handler do
  @type completed_event :: any()
  @type reason :: any()
  @type wish :: any()
  @type stream_state :: any()
  @type event :: any()

  @callback execute(stream_state, wish) :: {:ok, completed_event} | {:error, reason}
  @callback next_state(stream_state, completed_event) :: stream_state | {:error, reason}
end
