defmodule FakeApp do
  defstruct total: 0, game_id: "game-one"

  defmodule ScorePoint do
    defstruct value: 1, game_id: "game-one"
  end

  defmodule PointScored do
    defstruct value: 1, game_id: "game-one"
  end
end

defmodule FakeAppListener do
  use Headwater.Listener,
    from_event_ref: 0,
    event_store: FakeApp.EventStoreMock,
    bus_id: "fake_app_bus_consumer",
    handlers: [FakeApp.PrinterMock]
end

defmodule FakeApp.Headwater.Spring do
  use Headwater.Spring,
    registry: FakeApp.Registry,
    supervisor: FakeApp.StreamSupervisor,
    event_store: FakeApp.EventStoreMock
end
