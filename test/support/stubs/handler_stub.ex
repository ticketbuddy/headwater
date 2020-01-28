defmodule HeadwaterSpring.HandlerStub do
  @behaviour HeadwaterSpring.Handler

  def execute(current_state = %FakeApp{}, wish = %FakeApp.ScorePoint{}) do
    {:ok,
     %FakeApp.PointScored{
       value: wish.value
     }}
  end

  def next_state(current_state = %FakeApp{}, event = %FakeApp.PointScored{}) do
    %FakeApp{
      total: current_state.total + event.value
    }
  end
end
