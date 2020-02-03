Mox.defmock(HeadwaterSpring.HandlerMock, for: HeadwaterSpring.Handler)

Mox.defmock(HeadwaterFisherman.Fisherman.EventHandlerMock,
  for: HeadwaterFisherman.Fisherman.EventHandler
)

Mox.defmock(HeadwaterSpring.EventStoreMock, for: HeadwaterSpring.EventStore)

ExUnit.start()
