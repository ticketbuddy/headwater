defmodule HeadwaterFisherman.FishermanTest do
  use ExUnit.Case
  alias HeadwaterFisherman.Fisherman.EventHandlerMock

  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    HeadwaterFisherman.Fisherman.start_link()
    HeadwaterFisherman.HandleFish.start_link()

    :ok
  end

  describe "when event should be handled" do
    test "calls the event handle mock" do
      test_process = self()

      EventHandlerMock
      |> expect(:handle_event, fn _ ->
        send(test_process, :test_event_handled)

        :ok
      end)

      HeadwaterFisherman.Fisherman.sync_notify(%HeadwaterFisherman.Fisherman.Event{
        event_id: 1,
        handler: EventHandlerMock
      })

      assert_receive(:test_event_handled, 200)
    end
  end

  describe "when event should not be handled as event_id is not the next event to be handled" do
    test "the event handler is not called" do
      test_process = self()

      EventHandlerMock
      |> expect(:handle_event, 0, fn _ ->
        flunk("Should not be ran")
      end)

      HeadwaterFisherman.Fisherman.sync_notify(%HeadwaterFisherman.Fisherman.Event{
        event_id: 2,
        handler: EventHandlerMock
      })
    end
  end
end
