Mox.defmock(Headwater.Spring.HandlerMock, for: Headwater.Spring.Handler)
Mox.defmock(FakeApp.PrinterMock, for: Headwater.Listener.EventHandler)
Mox.defmock(FakeApp.EventStoreMock, for: Headwater.EventStore)
Mox.defmock(Headwater.SpringMock, for: Headwater.Spring)

Mox.defmock(Headwater.Listener.EventHandlerMock,
  for: Headwater.Listener.EventHandler
)

Mox.defmock(Headwater.EventStoreMock, for: Headwater.EventStore)

ExUnit.start()
