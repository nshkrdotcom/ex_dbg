defmodule ElixirScope.TestSupport.TestCallbackChecker do
  @moduledoc """
  A module to help Elixir's type checker verify that callbacks are properly handled.
  This is only used during compile time to detect type errors.
  """
  use GenServer
  
  def init(args) do
    {:ok, args}
  end
  
  def terminate(reason, _state) do
    # Explicitly implement terminate
    IO.puts("Terminating with reason: #{inspect(reason)}")
    :ok
  end
end 