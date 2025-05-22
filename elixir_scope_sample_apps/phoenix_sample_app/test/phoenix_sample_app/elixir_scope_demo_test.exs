defmodule PhoenixSampleApp.ElixirScopeDemoTest do
  use ExUnit.Case, async: false
  
  alias PhoenixSampleApp.ElixirScopeDemo
  alias PhoenixSampleApp.Counter
  
  setup do
    # Make sure Counter is running
    # This will also restart it if it was already running
    {:ok, _pid} = Counter.start_link([])
    
    # Reset to a known state
    Counter.reset(0)
    
    # Clear TraceDB before each test
    ElixirScope.TraceDB.clear()
    
    # Give processes time to start
    :timer.sleep(100)
    
    :ok
  end
  
  test "analyze_counter_state_changes tracks state changes" do
    # Perform some counter operations
    Counter.increment(5)
    Counter.decrement(2)
    Counter.set(10)
    
    # Analyze should not raise errors
    assert ElixirScopeDemo.analyze_counter_state_changes() == :ok
  end
  
  test "trace_counter_module starts tracing" do
    # Start tracing
    assert ElixirScopeDemo.trace_counter_module() == :ok
    
    # Perform some counter operations
    Counter.increment(5)
    Counter.get()
    
    # Show function calls should not raise errors
    assert ElixirScopeDemo.show_counter_function_calls() == :ok
  end
  
  test "time_travel_debug demonstrates time travel debugging" do
    # Perform some counter operations to create history
    Counter.increment(5)
    Counter.decrement(2)
    Counter.set(10)
    
    # Time-travel debug should not raise errors
    assert ElixirScopeDemo.time_travel_debug() == :ok
  end
  
  test "show_supervision_tree demonstrates process hierarchy" do
    # Use a Task with a timeout to prevent the test from crashing
    # if there's an issue with show_supervision_tree
    task = Task.async(fn -> ElixirScopeDemo.show_supervision_tree() end)
    
    result = case Task.yield(task, 1000) do
      {:ok, result} -> result
      nil ->
        # The task is taking too long, kill it and consider it a failure
        Task.shutdown(task)
        :timeout
    end
    
    # We only verify it doesn't crash, not the actual output
    assert result == :ok
  end
  
  test "format_timestamp formats timestamps correctly" do
    # This is a private function, but we can test it indirectly
    # by ensuring the other functions that use it don't crash
    
    # Perform some counter operations to create history
    Counter.increment(5)
    
    # These functions use format_timestamp internally
    assert ElixirScopeDemo.analyze_counter_state_changes() == :ok
    assert ElixirScopeDemo.time_travel_debug() == :ok
  end
end 