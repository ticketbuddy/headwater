Mox.defmock(Headwater.Aggregate.HandlerMock, for: Headwater.Aggregate.Handler)
Mox.defmock(FakeApp.PrinterMock, for: Headwater.Listener.EventHandler)
Mox.defmock(FakeApp.EventStoreMock, for: Headwater.EventStore)
Mox.defmock(Headwater.AggregateMock, for: Headwater.AggregateDirectory)

Mox.defmock(Headwater.Listener.EventHandlerMock,
  for: Headwater.Listener.EventHandler
)

Mox.defmock(Headwater.EventStoreMock, for: Headwater.EventStore)

ExUnit.start()
