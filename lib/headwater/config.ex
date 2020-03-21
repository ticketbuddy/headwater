defmodule Headwater.Config do
  @enforce_keys [:event_store, :registry, :supervisor, :directory]
  defstruct @enforce_keys ++ [:listener, :router]
end
