defmodule ElixirScope.StateRecorderTest do
  use ExUnit.Case, async: false
  
  alias ElixirScope.StateRecorder
  
  # Set shorter timeouts for tests but a higher value for setup
  @moduletag timeout: 15000
  
  setup do
    # Start or connect to TraceDB
    tracedb_pid = case Process.whereis(ElixirScope.TraceDB) do
      nil -> 
        {:ok, pid} = ElixirScope.TraceDB.start_link()
        pid
      pid -> pid
    end
    
    # Use a try block in case TraceDB is not responding
    try do
      # Force a clean slate for tests by clearing events
      ElixirScope.TraceDB.clear()
    catch
      _, _ -> :ok
    end
    
    %{tracedb_pid: tracedb_pid}
  end
  
  # Define a test GenServer that uses the StateRecorder for testing
  defmodule TestGenServer do
    # Order matters here - use GenServer first, then StateRecorder
    use GenServer
    use ElixirScope.StateRecorder
    
    def start_link(initial_state \\ %{}) do
      GenServer.start_link(__MODULE__, initial_state)
    end
    
    # Implement without using super to avoid issues
    # This replaces the existing init method
    def init(initial_state) do
      # We explicitly return the {:ok, state} tuple
      {:ok, initial_state}
    end
    
    def handle_call(:get_state, _from, state) do
      {:reply, state, state}
    end
    
    def handle_call({:update, key, value}, _from, state) do
      new_state = Map.put(state, key, value)
      {:reply, new_state, new_state}
    end
    
    def handle_cast({:async_update, key, value}, state) do
      new_state = Map.put(state, key, value)
      {:noreply, new_state}
    end
    
    def handle_info({:info_update, key, value}, state) do
      new_state = Map.put(state, key, value)
      {:noreply, new_state}
    end
  end
  
  describe "using macro" do
    test "tracks GenServer initialization" do
      # Start a GenServer that uses StateRecorder
      initial_state = %{name: "test"}
      {:ok, server_pid} = TestGenServer.start_link(initial_state)
      
      # Give it a moment to register the event
      :timer.sleep(50)
      
      # Query for state events for this process
      events = ElixirScope.TraceDB.query_events(%{
        type: :state,
        pid: server_pid
      })
      
      # Should have at least one state event (the initial state)
      assert length(events) > 0
      
      # Check that the initial state is recorded
      init_event = Enum.find(events, fn e -> e.data[:callback] == :init end)
      assert init_event != nil
      
      # Clean up
      GenServer.stop(server_pid)
    end
    
    test "tracks handle_call state changes" do
      # Start a GenServer
      {:ok, server_pid} = TestGenServer.start_link(%{count: 0})
      
      # Clear events to ensure a clean test
      ElixirScope.TraceDB.clear()
      
      # Send a call that will update state
      GenServer.call(server_pid, {:update, :count, 1})
      
      # Get events for this process
      events = ElixirScope.TraceDB.query_events(%{
        type: :state,
        pid: server_pid
      })
      
      # Should have state events from the call
      assert length(events) > 0
      
      # Check that the state change is recorded
      call_event = Enum.find(events, fn e -> e.data[:callback] == :handle_call end)
      assert call_event != nil
      
      # Clean up
      GenServer.stop(server_pid)
    end
    
    test "tracks handle_cast state changes" do
      # Start a GenServer
      {:ok, server_pid} = TestGenServer.start_link(%{count: 0})
      
      # Clear events to ensure a clean test
      ElixirScope.TraceDB.clear()
      
      # Send a cast that will update state
      GenServer.cast(server_pid, {:async_update, :count, 1})
      
      # Give it time to process the cast
      :timer.sleep(50)
      
      # Get events for this process
      events = ElixirScope.TraceDB.query_events(%{
        type: :state,
        pid: server_pid
      })
      
      # Should have state events from the cast
      assert length(events) > 0
      
      # Check that the state change is recorded
      cast_event = Enum.find(events, fn e -> e.data[:callback] == :handle_cast end)
      assert cast_event != nil
      
      # Clean up
      GenServer.stop(server_pid)
    end
    
    test "tracks handle_info state changes" do
      # Start a GenServer
      {:ok, server_pid} = TestGenServer.start_link(%{count: 0})
      
      # Clear events to ensure a clean test
      ElixirScope.TraceDB.clear()
      
      # Send an info message that will update state
      send(server_pid, {:info_update, :count, 1})
      
      # Give it time to process the message
      :timer.sleep(50)
      
      # Get events for this process
      events = ElixirScope.TraceDB.query_events(%{
        type: :state,
        pid: server_pid
      })
      
      # Should have state events from the info message
      assert length(events) > 0
      
      # Check that the state change is recorded
      info_event = Enum.find(events, fn e -> e.data[:callback] == :handle_info end)
      assert info_event != nil
      
      # Clean up
      GenServer.stop(server_pid)
    end
  end
  
  describe "trace_genserver" do
    test "traces an external GenServer" do
      # Start a regular GenServer (not using StateRecorder)
      {:ok, server_pid} = GenServer.start_link(TestGenServer, %{count: 0})
      
      # Clear events to ensure a clean test
      ElixirScope.TraceDB.clear()
      
      # Start tracing the GenServer
      StateRecorder.trace_genserver(server_pid)
      
      # Give it time to set up tracing
      :timer.sleep(50)
      
      # Send a call to update state
      GenServer.call(server_pid, {:update, :count, 1})
      
      # Give it time to process and record the event
      :timer.sleep(50)
      
      # Get events for this process
      events = ElixirScope.TraceDB.query_events(%{
        type: :state,
        pid: server_pid
      })
      
      # Should have state events from the tracing
      assert length(events) > 0
      
      # Stop tracing
      StateRecorder.stop_trace_genserver(server_pid)
      
      # Clean up
      GenServer.stop(server_pid)
    end
  end
end 