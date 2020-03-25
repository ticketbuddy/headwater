defmodule Headwater.UtilsTest do
  use ExUnit.Case

  describe "to_module/1" do
    test "snake cased string" do
      assert FooBar == Headwater.Utils.to_module("foo_bar")
    end

    test "snake cased string, namespaced" do
      assert FooBar.FoopBaz == Headwater.Utils.to_module("foo_bar.foop_baz")
    end
  end
end
