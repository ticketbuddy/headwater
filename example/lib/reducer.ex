defmodule Example.Reduce do
  defstruct [:counter_id, :reduce_by]
end

defmodule Example.Reduced do
  defstruct [:counter_id, :reduce_by]
end

defmodule Example.Reducer do
  defstruct [:counter_id, :total]

  def aggregate_prefix, do: "reducer_"

  def execute(current_state, wish) do
    {:ok, %Example.Reduced{counter_id: wish.counter_id, reduce_by: wish.reduce_by}}
  end

  def next_state(nil, event) do
    %__MODULE__{
      counter_id: event.counter_id,
      total: -event.reduce_by
    }
  end

  def next_state(%__MODULE__{total: total}, event) do
    %__MODULE__{
      counter_id: event.counter_id,
      total: total - event.reduce_by
    }
  end
end
