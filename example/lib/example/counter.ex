defmodule Example.Counter do
  defstruct [:total]

  def aggregate_prefix, do: ""

  def execute(current_state, wish = %Example.MultiIncrement{}) do
    {:ok,
     [
       %Example.Incremented{increment_by: wish.increment_by},
       %Example.Incremented{increment_by: wish.increment_again}
     ]}
  end

  def execute(current_state, wish = %Example.Increment{}) do
    {:ok, %Example.Incremented{increment_by: wish.increment_by}}
  end

  def next_state(nil, event) do
    %__MODULE__{
      total: event.increment_by
    }
  end

  def next_state(%__MODULE__{total: total}, event) do
    %__MODULE__{
      total: total + event.increment_by
    }
  end
end
