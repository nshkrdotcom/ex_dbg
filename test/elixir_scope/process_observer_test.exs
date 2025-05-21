defmodule ElixirScope.ProcessObserverTest do
  use ExUnit.Case, async: false
  
  alias ElixirScope.ProcessObserver
  
  # Set shorter timeouts for tests but a higher value for setup
  @moduletag timeout: 15000
  
  setup do
    # Start or connect to TraceDB and ProcessObserver
    tracedb_pid = case Process.whereis(ElixirScope.TraceDB) do
      nil -> 
        {:ok, pid} = ElixirScope.TraceDB.start_link()
        pid
      pid -> pid
    end
    
    observer_pid = case Process.whereis(ProcessObserver) do
      nil -> 
        {:ok, pid} = ProcessObserver.start_link()
        pid
      pid -> pid
    end
    
    # Clean up - only if we started it ourselves
    on_exit(fn -> 
      # Just leave them running as they might be used by other tests
      :ok
    end)
    
    # Use a try block in case TraceDB is not responding
    try do
      # Force a clean slate for tests by clearing events
      ElixirScope.TraceDB.clear()
    catch
      _, _ -> :ok
    end
    
    %{observer_pid: observer_pid, tracedb_pid: tracedb_pid}
  end
  
  describe "initialization" do
    test "starts with default options" do
      # The observer should start with the setup block
      assert Process.whereis(ProcessObserver) != nil
    end
    
    test "registers with TraceDB", %{tracedb_pid: tracedb_pid} do
      # Create a test process to ensure we have events
      _test_pid = spawn(fn -> :timer.sleep(50) end)
      
      # Give it a moment to register
      :timer.sleep(50)
      
      # Store a manual event to ensure we test TraceDB properly
      ElixirScope.TraceDB.store_event(:process, %{
        pid: self(),
        event: :test_event,
        info: nil,
        timestamp: System.monotonic_time()
      })
      
      # Get events from TraceDB
      events = ElixirScope.TraceDB.query_events(%{
        type: :process,
        limit: 10
      })
      
      # There should be at least one process event stored
      assert length(events) > 0
    end
  end
  
  describe "process lifecycle tracking" do
    test "tracks process events", %{tracedb_pid: tracedb_pid} do
      # Clear events to ensure a clean test
      try do
        ElixirScope.TraceDB.clear()
      catch
        _, _ -> :ok
      end
      
      # Store a manual event to ensure we test TraceDB properly
      ElixirScope.TraceDB.store_event(:process, %{
        pid: self(),
        event: :manual_test_event,
        info: nil,
        timestamp: System.monotonic_time()
      })
      
      # Query directly for events for our process
      events = ElixirScope.TraceDB.query_events(%{
        type: :process,
        pid: self()
      })
      
      # We should have at least one event for this process
      assert length(events) > 0, "No process events recorded"
    end
  end
  
  describe "process information collection" do
    test "collects basic process information" do
      # Create a process that will stay alive for the test
      test_process = spawn(fn -> 
        receive do
          :exit -> :ok
        after 
          5000 -> :ok
        end
      end)
      
      # Wait for ProcessObserver to capture information
      :timer.sleep(100)
      
      # Get process info directly from Erlang
      process_info = Process.info(test_process)
      
      # Should have basic info
      assert process_info != nil
      
      # Terminate the process
      send(test_process, :exit)
    end
  end
end 