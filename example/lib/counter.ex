defmodule Example.IncrementCounter do
  defstruct [:qty]
end

defmodule Example.CounterIncremented do
  defstruct [:qty]
end

defmodule Example.Counter do
  defstruct [:total]

  def execute(current_state, wish) do
    {:ok, %Example.CounterIncremented{qty: wish.qty}}
  end

  def next_state(nil, event) do
    %__MODULE__{
      total: event.qty
    }
  end

  def next_state(%__MODULE__{total: current_qty}, event) do
    %__MODULE__{
      total: current_qty + event.qty
    }
  end
end
