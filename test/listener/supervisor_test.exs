defmodule Headwater.Listener.SupervisorTest do
  use ExUnit.Case

  test "builds child process descriptions correctly" do
    assert [
             {Headwater.Listener.Provider,
              %{
                bus_id: "fake_app_bus_consumer",
                event_store: FakeApp.EventStoreMock,
                from_event_ref: 0
              }},
             {Headwater.Listener.Consumer,
              %{
                bus_id: "fake_app_bus_consumer",
                event_store: FakeApp.EventStoreMock,
                handlers: [FakeApp.EventHandlerMock],
                router: FakeApp
              }},
             {Headwater.Listener.Provider,
              %{bus_id: "bus_two", event_store: FakeApp.EventStoreMock, from_event_ref: 0}},
             {Headwater.Listener.Consumer,
              %{
                bus_id: "bus_two",
                event_store: FakeApp.EventStoreMock,
                handlers: [],
                router: FakeApp
              }}
           ] == FakeAppListener.children()
  end
end
