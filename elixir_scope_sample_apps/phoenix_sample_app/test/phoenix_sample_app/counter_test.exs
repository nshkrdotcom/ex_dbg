defmodule PhoenixSampleApp.CounterTest do
  use ExUnit.Case, async: false
  
  alias PhoenixSampleApp.Counter
  alias ElixirScope.TraceDB
  
  setup do
    # Make sure Counter is running
    # This will also restart it if it was already running
    {:ok, _pid} = Counter.start_link([])
    
    # Reset to a known state
    Counter.reset(0)
    
    # Clear TraceDB before each test
    TraceDB.clear()
    
    :ok
  end
  
  test "increment increases the counter" do
    # Initial state
    initial_value = Counter.get()
    assert initial_value == 0
    
    # Increment
    Counter.increment(5)
    
    # Wait a moment for the state to update
    :timer.sleep(100)
    
    # Check updated value
    updated_value = Counter.get()
    assert updated_value == 5
    
    # Query ElixirScope for state changes
    events = TraceDB.query_events(%{
      type: :state
    })
    
    # Verify ElixirScope captured state changes
    assert length(events) >= 1
    
    # Find the state change event after increment
    state_event = Enum.find(events, fn event -> 
      event.type == :state && event.state == 5
    end)
    
    assert state_event != nil
  end
  
  test "decrement decreases the counter" do
    # Set initial state
    Counter.set(10)
    
    # Verify initial state
    initial_value = Counter.get()
    assert initial_value == 10
    
    # Decrement
    Counter.decrement(3)
    
    # Wait a moment for the state to update
    :timer.sleep(100)
    
    # Check updated value
    updated_value = Counter.get()
    assert updated_value == 7
    
    # Query ElixirScope for state changes
    events = TraceDB.query_events(%{
      type: :state
    })
    
    # Verify ElixirScope captured state changes
    assert length(events) >= 1
    
    # Find the state change event after decrement
    state_event = Enum.find(events, fn event -> 
      event.type == :state && event.state == 7
    end)
    
    assert state_event != nil
  end
  
  test "reset sets the counter to the specified value" do
    # Set initial state
    Counter.set(10)
    
    # Verify initial state
    initial_value = Counter.get()
    assert initial_value == 10
    
    # Reset
    Counter.reset(3)
    
    # Wait a moment for the state to update
    :timer.sleep(100)
    
    # Check updated value
    updated_value = Counter.get()
    assert updated_value == 3
    
    # Query ElixirScope for state changes
    events = TraceDB.query_events(%{
      type: :state
    })
    
    # Verify ElixirScope captured state changes
    assert length(events) >= 1
    
    # Find the state change event after reset
    state_event = Enum.find(events, fn event -> 
      event.type == :state && event.state == 3
    end)
    
    assert state_event != nil
  end
  
  test "set updates the counter to the specified value" do
    # Initial state
    initial_value = Counter.get()
    assert initial_value == 0
    
    # Set
    Counter.set(42)
    
    # Wait a moment for the state to update
    :timer.sleep(100)
    
    # Check updated value
    updated_value = Counter.get()
    assert updated_value == 42
    
    # Query ElixirScope for state changes
    events = TraceDB.query_events(%{
      type: :state
    })
    
    # Verify ElixirScope captured state changes
    assert length(events) >= 1
    
    # Find the state change event after set
    state_event = Enum.find(events, fn event -> 
      event.type == :state && event.state == 42
    end)
    
    assert state_event != nil
  end
end 