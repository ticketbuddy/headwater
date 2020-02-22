defmodule Headwater.EventStore.EventSerializerTest do
  use ExUnit.Case
  alias Headwater.EventStore.EventSerializer

  defmodule MyEvent do
    defstruct [:name]
  end

  describe "serialize/1" do
    test "serializes an event" do
      assert ~s({"__struct__":"Elixir.Headwater.EventStore.EventSerializerTest.MyEvent","name":"james"}) ==
               EventSerializer.serialize(%MyEvent{name: "james"})
    end
  end

  describe "deserialize/1" do
    test "deserializes an event" do
      serialised_event =
        ~s({"__struct__":"Elixir.Headwater.EventStore.EventSerializerTest.MyEvent","name":"james"})

      assert %MyEvent{name: "james"} == EventSerializer.deserialize(serialised_event)
    end
  end
end
