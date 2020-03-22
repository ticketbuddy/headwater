defmodule FakeApp do
  import Headwater.Aggregate.Wish, only: [defwish: 3]

  use Headwater.Aggregate.Router,
    config: %Headwater.Config{
      event_store: FakeApp.EventStoreMock,
      registry: nil,
      supervisor: nil,
      directory: Headwater.Aggregate.DirectoryMock
    }

  defwish(ScorePoint, [:game_id, :value], to: FakeApp.Game)
  defwish(ScoreTwoPoints, [game_id: "game-one", value: 1], to: FakeApp.Game)

  defread(:get_score, to: FakeApp.Game)
end

defmodule FakeApp.PointScored do
  defstruct value: 1, game_id: "game-one"
end

defmodule FakeApp.TwoPointsScored do
  defstruct value: 2, game_id: "game-one"
end

defmodule FakeApp.Game do
  defstruct total: 0, game_id: "game-one"

  @behaviour Headwater.Aggregate.Handler

  @impl Headwater.Aggregate.Handler
  def aggregate_prefix, do: ""

  @impl Headwater.Aggregate.Handler
  def execute(_current_state, wish = %FakeApp.ScorePoint{value: value, game_id: game_id}) do
    %FakeApp.PointScored{value: value, game_id: game_id}
  end

  @impl Headwater.Aggregate.Handler
  def next_state(nil, wish = %FakeApp.ScorePoint{value: value, game_id: game_id}) do
    %FakeApp.Game{
      total: value,
      game_id: game_id
    }
  end

  @impl Headwater.Aggregate.Handler
  def next_state(
        current_state = %FakeApp.Game{total: total},
        wish = %FakeApp.ScorePoint{value: value, game_id: game_id}
      ) do
    %FakeApp.Game{
      total: total + value,
      game_id: game_id
    }
  end
end

defmodule FakeAppListener do
  use Headwater.Listener.Supervisor,
    from_event_ref: 0,
    busses: [
      {"fake_app_bus_consumer", [FakeApp.EventHandlerMock]},
      {"bus_two", []}
    ],
    config: %Headwater.Config{
      event_store: FakeApp.EventStoreMock,
      registry: nil,
      supervisor: nil,
      router: FakeApp,
      directory: Headwater.Aggregate.DirectoryMock
    }
end
