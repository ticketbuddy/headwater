defmodule FakeApp do
  defstruct total: 0

  defmodule ScorePoint do
    defstruct value: 1
  end

  defmodule PointScored do
    defstruct value: 1
  end
end
