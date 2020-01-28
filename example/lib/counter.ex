defmodule Example.Increment do
  defstruct [:counter_id, :increment_by]
end

defmodule Example.Incremented do
  defstruct [:counter_id, :increment_by]
end

defmodule Example.Counter do
  defstruct [:total]

  def execute(current_state, wish) do
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
