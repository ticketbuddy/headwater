defmodule Headwater.TimeTraveler do
  @moduledoc """
  Behaviour for running callbacks reliably in the distant
  future.
  """
  @type time_travel_opts :: {non_neg_integer(), :minutes | :hours}
  @type action :: {module(), :atom, list()}
  @type now :: DateTime.t()

  @callback remember(time_travel_opts, action) :: :ok | :error
  @callback remember(time_travel_opts, action, now) :: :ok | :error
end
