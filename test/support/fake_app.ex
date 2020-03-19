defmodule FakeApp do
  def aggregate_prefix, do: ""

  defstruct total: 0, game_id: "game-one"

  defmodule ScoreTwoPoints do
    defstruct value: 2, game_id: "game-one"
  end

  defmodule ScorePoint do
    defstruct value: 1, game_id: "game-one"
  end

  defmodule PointScored do
    defstruct value: 1, game_id: "game-one"
  end

  defmodule TwoPointScored do
    defstruct value: 2, game_id: "game-one"
  end
end

defmodule FakeAppListener do
  use Headwater.Listener.Supervisor,
    from_event_ref: 0,
    event_store: FakeApp.EventStoreMock,
    busses: [
      {"fake_app_bus_consumer", [FakeApp.PrinterMock]},
      {"bus_two", []}
    ]
end

defmodule FakeApp.Headwater.AggregateDirectory do
  use Headwater.AggregateDirectory,
    registry: FakeApp.Registry,
    supervisor: FakeApp.AggregateSupervisor,
    event_store: FakeApp.EventStoreMock
end

defmodule FakeApp.Router do
  @moduledoc """
  For testing Headwater's test helper;
  `Headwater.TestSupport.AggregateDirectory`
  """
  use Headwater.Aggregate.Router, aggregate_directory: Headwater.TestSupport.AggregateDirectory

  defaction([FakeApp.ScorePoint, FakeApp.ScoreTwoPoints], to: FakeApp, by_key: :game_id)
  defread(:get_score, to: FakeApp)
end
