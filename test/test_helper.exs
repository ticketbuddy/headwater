Mox.defmock(HeadwaterSpring.HandlerMock, for: HeadwaterSpring.Handler)
Mox.defmock(FakeApp.PrinterMock, for: HeadwaterFisherman.Fisherman.EventHandler)
Mox.defmock(FakeApp.EventStoreMock, for: HeadwaterSpring.EventStore)
Mox.defmock(HeadwaterSpringMock, for: HeadwaterSpring)

Mox.defmock(HeadwaterFisherman.Fisherman.EventHandlerMock,
  for: HeadwaterFisherman.Fisherman.EventHandler
)

Mox.defmock(HeadwaterSpring.EventStoreMock, for: HeadwaterSpring.EventStore)

ExUnit.start()
