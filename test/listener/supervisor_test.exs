defmodule Headwater.Listener.SupervisorTest do
  use ExUnit.Case

  test "builds child process descriptions correctly" do
    assert [
             %{
               id: "headwater_provider_fake_app_bus_consumer",
               start:
                 {Headwater.Listener.Provider, :start_link,
                  [
                    %{
                      bus_id: "fake_app_bus_consumer",
                      event_store: FakeApp.EventStoreMock,
                      from_event_ref: 0
                    }
                  ]}
             },
             %{
               id: "headwater_consumer_fake_app_bus_consumer",
               start:
                 {Headwater.Listener.Consumer, :start_link,
                  [
                    %{
                      bus_id: "fake_app_bus_consumer",
                      event_store: FakeApp.EventStoreMock,
                      handlers: [FakeApp.EventHandlerMock],
                      router: FakeApp
                    }
                  ]}
             },
             %{
               id: "headwater_provider_bus_two",
               start:
                 {Headwater.Listener.Provider, :start_link,
                  [%{bus_id: "bus_two", event_store: FakeApp.EventStoreMock, from_event_ref: 0}]}
             },
             %{
               id: "headwater_consumer_bus_two",
               start:
                 {Headwater.Listener.Consumer, :start_link,
                  [
                    %{
                      bus_id: "bus_two",
                      event_store: FakeApp.EventStoreMock,
                      handlers: [],
                      router: FakeApp
                    }
                  ]}
             }
           ] == FakeAppListener.children()
  end
end
