# ElixirScope: Layered Test-Driven Debugging Strategy

## Source Code Dependency Analysis

First, let's analyze the code to understand the dependency relationships between modules, which will help us identify the foundational layers to focus our testing efforts on.

### Dependency Graph Analysis

```
ElixirScope (Main API)
├── TraceDB (Core Storage)
├── ProcessObserver → TraceDB
├── MessageInterceptor → TraceDB
├── CodeTracer → TraceDB
├── StateRecorder → TraceDB
├── PhoenixTracker → TraceDB
├── QueryEngine → TraceDB
└── AIIntegration → QueryEngine, CodeTracer, TraceDB

Dependency Flow Direction: Top → Bottom
```

### Module Dependencies in Detail

1. **ElixirScope.TraceDB**
   - Dependencies: None (except Elixir standard library)
   - Used by: All other modules

2. **ElixirScope.ProcessObserver**
   - Dependencies: TraceDB
   - Used by: ElixirScope (main)

3. **ElixirScope.MessageInterceptor**
   - Dependencies: TraceDB
   - Used by: ElixirScope (main)

4. **ElixirScope.CodeTracer**
   - Dependencies: TraceDB
   - Used by: ElixirScope (main), AIIntegration

5. **ElixirScope.StateRecorder**
   - Dependencies: TraceDB
   - Used by: ElixirScope (main)

6. **ElixirScope.PhoenixTracker**
   - Dependencies: TraceDB, Phoenix (optional)
   - Used by: ElixirScope (main)

7. **ElixirScope.QueryEngine**
   - Dependencies: TraceDB
   - Used by: ElixirScope (main), AIIntegration

8. **ElixirScope.AIIntegration**
   - Dependencies: TraceDB, QueryEngine, CodeTracer
   - Used by: ElixirScope (main)

9. **ElixirScope** (main module)
   - Dependencies: All other modules
   - Used by: Client applications

## Foundational Layer Identification

Based on the dependency analysis, the clear foundational layer is `ElixirScope.TraceDB`. It's the core storage mechanism that everything else depends on but has no internal dependencies itself (except for the Elixir standard library).

The next layer consists of the independent tracer components:
- `ProcessObserver`
- `MessageInterceptor`
- `CodeTracer`
- `StateRecorder`
- `PhoenixTracker`

These all depend only on `TraceDB` but are independent of each other.

Then comes `QueryEngine`, which depends on `TraceDB` but not on the tracers.

Finally, `AIIntegration` depends on `TraceDB`, `QueryEngine`, and `CodeTracer`.

## Layered Test-Driven Debugging Strategy

### Layer 1: TraceDB Testing

Since `TraceDB` is the foundation, we'll focus here first:

```elixir
defmodule ElixirScope.TraceDBTest do
  use ExUnit.Case

  alias ElixirScope.TraceDB

  setup do
    # Start TraceDB for testing
    {:ok, pid} = TraceDB.start_link()
    
    # Clean up after test
    on_exit(fn -> 
      Process.exit(pid, :normal)
    end)
    
    %{trace_db_pid: pid}
  end

  describe "basic storage and retrieval" do
    test "can store and retrieve a simple event" do
      test_event = %{
        pid: self(),
        type: :test,
        message: "test message",
        timestamp: System.monotonic_time()
      }
      
      # Store the event
      TraceDB.store_event(:test, test_event)
      
      # Query it back
      events = TraceDB.query_events(%{type: :test})
      
      assert length(events) == 1
      retrieved_event = hd(events)
      assert retrieved_event.message == "test message"
    end
    
    test "respects sample rate for non-critical events" do
      # Set a low sample rate
      {:ok, pid} = TraceDB.start_link(sample_rate: 0.0)
      
      # Store a non-critical event
      test_event = %{
        pid: self(),
        type: :test,
        message: "should be filtered",
        timestamp: System.monotonic_time()
      }
      
      TraceDB.store_event(:test, test_event)
      
      # Query it back - should not be stored due to 0.0 sample rate
      events = TraceDB.query_events(%{type: :test})
      assert Enum.empty?(events)
      
      # Cleanup
      Process.exit(pid, :normal)
    end
    
    test "always records critical events regardless of sample rate" do
      # Set a zero sample rate
      {:ok, pid} = TraceDB.start_link(sample_rate: 0.0)
      
      # Store a critical process event
      critical_event = %{
        pid: self(),
        event: :spawn,  # This is a critical event type
        timestamp: System.monotonic_time()
      }
      
      TraceDB.store_event(:process, critical_event)
      
      # Query it back - should be stored despite 0.0 sample rate
      events = TraceDB.query_events(%{type: :process})
      assert length(events) == 1
      
      # Cleanup
      Process.exit(pid, :normal)
    end
  end

  describe "query functionality" do
    test "can filter events by timestamp range" do
      # Add setup events with timestamps
      now = System.monotonic_time()
      TraceDB.store_event(:test, %{timestamp: now - 1000, message: "old"})
      TraceDB.store_event(:test, %{timestamp: now, message: "current"})
      TraceDB.store_event(:test, %{timestamp: now + 1000, message: "future"})
      
      # Query with time range
      events = TraceDB.query_events(%{
        timestamp_start: now - 500,
        timestamp_end: now + 500
      })
      
      assert length(events) == 1
      assert hd(events).message == "current"
    end
    
    test "can get state history for a process" do
      pid = self()
      
      # Store some state events for the process
      TraceDB.store_event(:state, %{
        pid: pid,
        state: "state1",
        timestamp: System.monotonic_time()
      })
      
      Process.sleep(10) # Ensure different timestamps
      
      TraceDB.store_event(:state, %{
        pid: pid,
        state: "state2",
        timestamp: System.monotonic_time()
      })
      
      # Get state history
      history = TraceDB.get_state_history(pid)
      
      assert length(history) == 2
      assert Enum.at(history, 0).state == "state1"
      assert Enum.at(history, 1).state == "state2"
    end
    
    test "can get active processes at a timestamp" do
      # Create a test process
      spawn_event = %{
        pid: self(),
        event: :spawn,
        timestamp: System.monotonic_time() - 1000
      }
      
      # Process is spawned but hasn't exited
      TraceDB.store_event(:process, spawn_event)
      
      # Get active processes at current time
      active = TraceDB.get_processes_at(System.monotonic_time())
      
      assert self() in active
      
      # Now add an exit event
      exit_event = %{
        pid: self(),
        event: :exit,
        timestamp: System.monotonic_time() - 500
      }
      
      TraceDB.store_event(:process, exit_event)
      
      # Get active processes after exit
      active = TraceDB.get_processes_at(System.monotonic_time())
      
      assert self() not in active
    end
  end

  describe "data management" do
    test "cleans up old events when max_events is exceeded", %{trace_db_pid: pid} do
      # Send a stop message to TraceDB to avoid automated cleanup during test
      :erlang.trace(pid, true, [:receive])
      
      # Create max_events+10 events
      for i <- 1..110 do
        TraceDB.store_event(:test, %{
          id: i,
          timestamp: System.monotonic_time() + i,
          message: "Event #{i}"
        })
      end
      
      # Check event count before cleanup
      all_events = TraceDB.query_events(%{})
      assert length(all_events) > 100
      
      # Manually trigger cleanup
      send(pid, :cleanup)
      
      # Wait for cleanup to complete
      Process.sleep(50)
      
      # Check event count after cleanup
      all_events_after = TraceDB.query_events(%{})
      assert length(all_events_after) <= 100
      
      # Verify oldest events were removed
      event_ids = Enum.map(all_events_after, & &1.id)
      assert 1 not in event_ids # First event should be gone
    end
  end
end
```

### Layer 2: Basic Tracer Modules

Next, let's test a representative tracer module - `ProcessObserver`:

```elixir
defmodule ElixirScope.ProcessObserverTest do
  use ExUnit.Case, async: false
  
  alias ElixirScope.ProcessObserver
  
  setup do
    # Start TraceDB before ProcessObserver
    {:ok, tracedb_pid} = ElixirScope.TraceDB.start_link()
    {:ok, observer_pid} = ProcessObserver.start_link()
    
    on_exit(fn -> 
      Process.exit(observer_pid, :normal)
      Process.exit(tracedb_pid, :normal)
    end)
    
    %{observer_pid: observer_pid}
  end
  
  describe "basic process tracking" do
    test "detects process spawning" do
      # Start a test process that will live for a short time
      test_pid = spawn(fn -> Process.sleep(100) end)
      
      # Wait for ProcessObserver to detect it
      Process.sleep(50)
      
      # Query events
      spawn_events = ElixirScope.TraceDB.query_events(%{
        type: :process
      })
      |> Enum.filter(fn event -> 
        Map.get(event, :event) == :spawn && Map.get(event, :pid) == test_pid
      end)
      
      # Should have detected the spawned process
      assert length(spawn_events) > 0
    end
    
    test "detects process exit" do
      # Start a test process that will exit quickly
      test_pid = spawn(fn -> :ok end)
      
      # Wait for ProcessObserver to detect spawn and exit
      Process.sleep(50)
      
      # Query events
      exit_events = ElixirScope.TraceDB.query_events(%{
        type: :process
      })
      |> Enum.filter(fn event -> 
        Map.get(event, :event) == :exit && Map.get(event, :pid) == test_pid
      end)
      
      # Should have detected the process exit
      assert length(exit_events) > 0
    end
  end
  
  describe "supervision tree building" do
    test "identifies supervisors and their children" do
      # Create a simple supervisor
      child_spec = %{
        id: TestChild,
        start: {Task, :start_link, [fn -> Process.sleep(5000) end]}
      }
      
      {:ok, sup_pid} = Supervisor.start_link([child_spec], strategy: :one_for_one)
      
      # Wait for ProcessObserver to detect and build the tree
      Process.sleep(100)
      
      # Get the supervision tree
      tree = ProcessObserver.get_supervision_tree()
      
      # The supervisor should be in the tree
      assert Map.has_key?(tree, sup_pid)
      
      # The supervisor should have the correct strategy
      assert tree[sup_pid].strategy == :one_for_one
      
      # The supervisor should have one child
      assert map_size(tree[sup_pid].children) == 1
      
      # Clean up
      Supervisor.stop(sup_pid)
    end
  end
end
```

### Layer 3: QueryEngine Testing

Once the core storage and tracers are working, we can test the `QueryEngine`:

```elixir
defmodule ElixirScope.QueryEngineTest do
  use ExUnit.Case
  
  alias ElixirScope.{TraceDB, QueryEngine}
  
  setup do
    # Start TraceDB
    {:ok, pid} = TraceDB.start_link()
    
    on_exit(fn -> 
      Process.exit(pid, :normal)
    end)
    
    %{trace_db_pid: pid}
  end
  
  describe "basic queries" do
    test "message_flow finds messages between processes" do
      # Create test PIDs
      pid1 = spawn(fn -> Process.sleep(1000) end)
      pid2 = spawn(fn -> Process.sleep(1000) end)
      
      # Manually add trace events
      TraceDB.store_event(:message, %{
        from_pid: pid1,
        to_pid: pid2,
        message: "test message",
        type: :send,
        timestamp: System.monotonic_time()
      })
      
      # Query message flow
      flow = QueryEngine.message_flow(pid1, pid2)
      
      assert length(flow) == 1
      assert hd(flow).message == "test message"
    end
    
    test "state_timeline retrieves state history" do
      # Create a test PID
      pid = spawn(fn -> Process.sleep(1000) end)
      
      # Add state events
      TraceDB.store_event(:state, %{
        pid: pid,
        state: "state1",
        timestamp: System.monotonic_time()
      })
      
      Process.sleep(10) # Ensure different timestamps
      
      TraceDB.store_event(:state, %{
        pid: pid,
        state: "state2",
        timestamp: System.monotonic_time()
      })
      
      # Get state timeline
      timeline = QueryEngine.state_timeline(pid)
      
      assert length(timeline) == 2
      assert Enum.at(timeline, 0).state == "state1"
      assert Enum.at(timeline, 1).state == "state2"
    end
  end
  
  describe "time travel debugging" do
    test "get_state_at retrieves state at a specific time" do
      # Create a test PID
      pid = spawn(fn -> Process.sleep(1000) end)
      
      # Record initial state
      time1 = System.monotonic_time()
      TraceDB.store_event(:state, %{
        pid: pid,
        state: "initial",
        timestamp: time1
      })
      
      Process.sleep(10) # Ensure different timestamps
      
      # Record updated state
      time2 = System.monotonic_time()
      TraceDB.store_event(:state, %{
        pid: pid,
        state: "updated",
        timestamp: time2
      })
      
      # Get state at different times
      state_at_time1 = QueryEngine.get_state_at(pid, time1)
      state_at_middle = QueryEngine.get_state_at(pid, time1 + div(time2 - time1, 2))
      state_at_time2 = QueryEngine.get_state_at(pid, time2)
      
      assert {:ok, "initial"} = state_at_time1
      assert {:ok, "initial"} = state_at_middle # Should get most recent state before timestamp
      assert {:ok, "updated"} = state_at_time2
    end
    
    test "system_snapshot_at captures process states at a timestamp" do
      # Create test PIDs
      pid1 = spawn(fn -> Process.sleep(1000) end)
      pid2 = spawn(fn -> Process.sleep(1000) end)
      
      # Record process spawn events
      now = System.monotonic_time()
      TraceDB.store_event(:process, %{
        pid: pid1,
        event: :spawn,
        timestamp: now - 1000
      })
      
      TraceDB.store_event(:process, %{
        pid: pid2,
        event: :spawn,
        timestamp: now - 1000
      })
      
      # Record states
      TraceDB.store_event(:state, %{
        pid: pid1,
        state: "state1",
        timestamp: now - 500
      })
      
      TraceDB.store_event(:state, %{
        pid: pid2,
        state: "state2",
        timestamp: now - 500
      })
      
      # Get system snapshot
      snapshot = QueryEngine.system_snapshot_at(now)
      
      # Both PIDs should be active
      assert pid1 in snapshot.active_processes
      assert pid2 in snapshot.active_processes
      
      # Both states should be captured
      assert snapshot.process_states[pid1] == "state1"
      assert snapshot.process_states[pid2] == "state2"
    end
  end
  
  describe "state comparison" do
    test "compare_states detects differences between maps" do
      state1 = %{a: 1, b: 2, c: 3}
      state2 = %{a: 1, b: 5, d: 4}
      
      diff = QueryEngine.compare_states(state1, state2)
      
      assert %{b: {2, 5}} in diff.changed
      assert %{c: 3} in diff.removed
      assert %{d: 4} in diff.added
    end
  end
end
```

### Layer 4: StateRecorder Testing

Since `StateRecorder` uses macros for instrumentation, we need special testing:

```elixir
defmodule ElixirScope.StateRecorderTest do
  use ExUnit.Case
  
  alias ElixirScope.{TraceDB, StateRecorder}
  
  defmodule TestServer do
    use GenServer
    use ElixirScope.StateRecorder
    
    def start_link do
      GenServer.start_link(__MODULE__, %{count: 0})
    end
    
    def increment(server) do
      GenServer.cast(server, :increment)
    end
    
    def get_count(server) do
      GenServer.call(server, :get_count)
    end
    
    def init(state) do
      {:ok, state}
    end
    
    def handle_cast(:increment, state) do
      {:noreply, %{state | count: state.count + 1}}
    end
    
    def handle_call(:get_count, _from, state) do
      {:reply, state.count, state}
    end
  end
  
  setup do
    # Start TraceDB
    {:ok, trace_pid} = TraceDB.start_link()
    
    on_exit(fn ->
      Process.exit(trace_pid, :normal)
    end)
    
    %{trace_db_pid: trace_pid}
  end
  
  describe "compile-time instrumentation" do
    test "records state changes from init" do
      # Start the test server
      {:ok, server} = TestServer.start_link()
      
      # Get state events
      events = TraceDB.query_events(%{
        type: :state,
        pid: server
      })
      
      # Should have recorded initial state
      assert length(events) == 1
      assert hd(events).callback == :init
      assert String.contains?(hd(events).state, "count: 0")
      
      # Cleanup
      GenServer.stop(server)
    end
    
    test "records state changes from handle_cast" do
      # Start the test server
      {:ok, server} = TestServer.start_link()
      
      # Clear any previous events
      TraceDB.clear()
      
      # Send a cast message
      TestServer.increment(server)
      Process.sleep(10) # Give it time to process
      
      # Get state events
      events = TraceDB.query_events(%{
        type: :state,
        pid: server
      })
      
      # Should have recorded state change
      assert length(events) == 1
      assert hd(events).callback == :handle_cast
      assert String.contains?(hd(events).state, "count: 1")
      
      # Cleanup
      GenServer.stop(server)
    end
    
    test "records state changes from handle_call" do
      # Start the test server
      {:ok, server} = TestServer.start_link()
      
      # Increment to change state
      TestServer.increment(server)
      Process.sleep(10)
      
      # Clear previous events
      TraceDB.clear()
      
      # Send a call message
      count = TestServer.get_count(server)
      assert count == 1
      
      # Get state events
      events = TraceDB.query_events(%{
        type: :state,
        pid: server
      })
      
      # Should have recorded state (unchanged in this case)
      assert length(events) == 1
      assert hd(events).callback == :handle_call
      assert String.contains?(hd(events).state, "count: 1")
      
      # Cleanup
      GenServer.stop(server)
    end
  end
  
  describe "runtime tracing" do
    test "can trace external GenServer" do
      # Start a regular GenServer without ElixirScope.StateRecorder
      {:ok, server} = :gen_server.start_link(
        fn -> {:ok, %{count: 0}} end,
        %{count: 0}
      )
      
      # Start tracing it at runtime
      StateRecorder.trace_genserver(server)
      
      # Send a :sys call to change state
      :sys.replace_state(server, fn state -> %{count: state.count + 1} end)
      Process.sleep(10)
      
      # Get state events
      events = TraceDB.query_events(%{
        type: :state,
        pid: server
      })
      
      # Should have recorded state changes
      assert length(events) > 0
      
      # At least one event should show the updated state
      has_updated_state = Enum.any?(events, fn event ->
        String.contains?(event.state, "count: 1")
      end)
      
      assert has_updated_state
      
      # Cleanup
      GenServer.stop(server)
    end
  end
end
```

### Layer 5: Main ElixirScope Module Testing

Finally, test the main module which orchestrates everything:

```elixir
defmodule ElixirScopeTest do
  use ExUnit.Case
  
  describe "setup and configuration" do
    test "validates tracing level" do
      assert_raise ArgumentError, fn ->
        ElixirScope.setup(tracing_level: :invalid_level)
      end
      
      # Valid levels should not raise
      ElixirScope.setup(tracing_level: :full)
      ElixirScope.setup(tracing_level: :messages_only)
      ElixirScope.setup(tracing_level: :states_only)
      ElixirScope.setup(tracing_level: :minimal)
      ElixirScope.setup(tracing_level: :off)
      
      # Cleanup
      ElixirScope.stop()
    end
    
    test "validates sample rate" do
      assert_raise ArgumentError, fn ->
        ElixirScope.setup(sample_rate: 2.0)
      end
      
      assert_raise ArgumentError, fn ->
        ElixirScope.setup(sample_rate: -0.5)
      end
      
      # Valid rates should not raise
      ElixirScope.setup(sample_rate: 0.0)
      ElixirScope.setup(sample_rate: 0.5)
      ElixirScope.setup(sample_rate: 1.0)
      
      # Cleanup
      ElixirScope.stop()
    end
    
    test "starts all core components" do
      ElixirScope.setup()
      
      # Check that core processes are running
      assert Process.whereis(ElixirScope.TraceDB) != nil
      assert Process.whereis(ElixirScope.ProcessObserver) != nil
      assert Process.whereis(ElixirScope.MessageInterceptor) != nil
      assert Process.whereis(ElixirScope.CodeTracer) != nil
      
      # Cleanup
      ElixirScope.stop()
    end
  end
  
  describe "core functionality" do
    setup do
      ElixirScope.setup()
      
      on_exit(fn ->
        ElixirScope.stop()
      end)
      
      :ok
    end
    
    test "trace_module starts function tracing" do
      # Create a test module to trace
      defmodule TestModule do
        def test_function(x), do: x * 2
      end
      
      # Start tracing it
      ElixirScope.trace_module(TestModule)
      
      # Clear any existing events
      ElixirScope.TraceDB.clear()
      
      # Call the function
      TestModule.test_function(42)
      
      # Check for function call events
      events = ElixirScope.TraceDB.query_events(%{type: :function})
      
      assert length(events) >= 2  # Should have call and return events
    end
    
    test "trace_genserver tracks state changes" do
      # Start a test GenServer
      {:ok, pid} = GenServer.start_link(
        fn -> {:ok, %{value: 0}} end,
        %{value: 0}
      )
      
      # Start tracing it
      ElixirScope.trace_genserver(pid)
      
      # Modify its state
      :sys.replace_state(pid, fn state -> %{value: 42} end)
      Process.sleep(10)
      
      # Check for state events
      state_timeline = ElixirScope.state_timeline(pid)
      
      assert length(state_timeline) > 0
      
      # Verify state was captured
      final_state = List.last(state_timeline)
      assert String.contains?(final_state.state, "value: 42")
      
      # Cleanup
      GenServer.stop(pid)
    end
    
    test "message_flow tracks messages between processes" do
      # Create two test processes
      pid1 = spawn(fn ->
        receive do
          _ -> :ok
        end
      end)
      
      pid2 = spawn(fn ->
        receive do
          _ -> :ok
        end
      end)
      
      # Send a message between them
      send(pid1, {:message_to, pid2, "hello"})
      send(pid2, {:reply_to, pid1, "world"})
      
      # Should have captured the messages
      messages = ElixirScope.message_flow(pid1, pid2)
      
      assert length(messages) > 0
    end
  end
end
```

## Debugging Strategy with Real-Life Examples

Now that we've built a solid test foundation for each layer, let's tackle real-life debugging using increasingly complex scenarios.

### 1. Basic ETS Storage Validation

First, ensure TraceDB can actually store and retrieve data in ETS:

```elixir
# Debug script - run in IEx
{:ok, _} = ElixirScope.TraceDB.start_link()

# Store a test event
test_event = %{
  pid: self(),
  message: "test",
  timestamp: System.monotonic_time()
}

ElixirScope.TraceDB.store_event(:test, test_event)

# Check that it's in the ETS table
:ets.tab2list(:elixir_scope_events)

# Try querying it
ElixirScope.TraceDB.query_events(%{})
```

Common issues at this layer might be:
- ETS tables not created correctly
- Access rights issues (e.g., missing `:public` option)
- Query filtering not working as expected

### 2. Process Observer Tracking

Next, verify the ProcessObserver can detect process lifecycles:

```elixir
# Debug script - run in IEx
ElixirScope.TraceDB.clear()
{:ok, _} = ElixirScope.ProcessObserver.start_link()

# Create a test process that will exit
pid = spawn(fn -> Process.sleep(100) end)
Process.sleep(200)  # Let it spawn and exit

# Check for spawn/exit events
ElixirScope.TraceDB.query_events(%{type: :process})

# Check the supervision tree building
sup_pid = spawn(fn ->
  Supervisor.start_link([
    %{id: :test, start: {Task, :start_link, [fn -> Process.sleep(10000) end]}}
  ], strategy: :one_for_one)
  Process.sleep(10000)
end)

Process.sleep(200)  # Give time for supervisor to start
ElixirScope.ProcessObserver.get_supervision_tree()
```

Issues at this layer often relate to:
- Process monitoring not being set up correctly
- `:trap_exit` not enabled
- Supervision tree building logic errors

### 3. GenServer State Recording

Test the StateRecorder with a simple GenServer:

```elixir
# Debug script - run in IEx
defmodule TestServer do
  use GenServer
  use ElixirScope.StateRecorder
  
  def start_link, do: GenServer.start_link(__MODULE__, %{count: 0}, name: __MODULE__)
  def increment, do: GenServer.cast(__MODULE__, :increment)
  def get, do: GenServer.call(__MODULE__, :get)
  
  def init(state), do: {:ok, state}
  def handle_cast(:increment, state), do: {:noreply, %{state | count: state.count + 1}}
  def handle_call(:get, _from, state), do: {:reply, state.count, state}
end

ElixirScope.TraceDB.clear()
{:ok, _} = ElixirScope.TraceDB.start_link()
{:ok, pid} = TestServer.start_link()

# Perform some operations
TestServer.increment()
TestServer.increment()
TestServer.get()

# Check if state changes were captured
ElixirScope.TraceDB.query_events(%{type: :state, pid: pid})

# Test external GenServer tracing
{:ok, ext_pid} = GenServer.start_link(fn -> {:ok, %{value: 0}} end, %{value: 0})
ElixirScope.StateRecorder.trace_genserver(ext_pid)
:sys.replace_state(ext_pid, fn _ -> %{value: 42} end)
ElixirScope.TraceDB.query_events(%{type: :state, pid: ext_pid})
```

Issues here might include:
- Macro transformation not working correctly
- Callback overrides not preserving original behavior
- External GenServer tracing system handler issues

### 4. Complete System Integration Test

Finally, verify the entire system works together:

```elixir
# Debug script - run in IEx
# Start ElixirScope
ElixirScope.setup()

# Define a test application structure
defmodule TestApp do
  defmodule Worker do
    use GenServer
    use ElixirScope.StateRecorder
    
    def start_link(name, initial), do: GenServer.start_link(__MODULE__, initial, name: name)
    def increment(pid), do: GenServer.cast(pid, :increment)
    def get(pid), do: GenServer.call(pid, :get)
    
    def init(state), do: {:ok, state}
    def handle_cast(:increment, count), do: {:noreply, count + 1}
    def handle_call(:get, _from, count), do: {:reply, count, count}
  end
  
  defmodule Coordinator do
    use GenServer
    use ElixirScope.StateRecorder
    
    def start_link, do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    def add_worker(name), do: GenServer.call(__MODULE__, {:add_worker, name})
    def increment_all, do: GenServer.cast(__MODULE__, :increment_all)
    
    def init(_), do: {:ok, %{workers: %{}}}
    
    def handle_call({:add_worker, name}, _from, state) do
      {:ok, pid} = Worker.start_link(name, 0)
      {:reply, pid, put_in(state.workers[name], pid)}
    end
    
    def handle_cast(:increment_all, state) do
      Enum.each(state.workers, fn {_name, pid} -> Worker.increment(pid) end)
      {:noreply, state}
    end
  end
end

# Start the test application
{:ok, _} = TestApp.Coordinator.start_link()
worker1 = TestApp.Coordinator.add_worker(:worker1)
worker2 = TestApp.Coordinator.add_worker(:worker2)

# Trace the Coordinator module to see function calls
ElixirScope.trace_module(TestApp.Coordinator)

# Perform operations
TestApp.Coordinator.increment_all()
TestApp.Worker.get(worker1)
TestApp.Worker.get(worker2)

# Check various traces
# 1. Message flow between Coordinator and Worker1
messages = ElixirScope.message_flow(Process.whereis(TestApp.Coordinator), worker1)
IO.inspect(messages, label: "Messages between Coordinator and Worker1")

# 2. State timeline for Worker1
states = ElixirScope.state_timeline(worker1)
IO.inspect(states, label: "Worker1 state timeline")

# 3. Function calls to Coordinator
functions = ElixirScope.QueryEngine.module_function_calls(TestApp.Coordinator)
IO.inspect(functions, label: "Coordinator function calls")

# 4. Try time travel debugging
coordinator_pid = Process.whereis(TestApp.Coordinator)
# Get state at different points in time
if length(states) >= 2 do
  timestamp1 = Enum.at(states, 0).timestamp
  timestamp2 = Enum.at(states, -1).timestamp
  
  # State before increment
  before_state = ElixirScope.QueryEngine.get_state_at(worker1, timestamp1)
  IO.inspect(before_state, label: "Worker1 state before increment")
  
  # State after increment
  after_state = ElixirScope.QueryEngine.get_state_at(worker1, timestamp2)
  IO.inspect(after_state, label: "Worker1 state after increment")
  
  # System snapshot
  snapshot = ElixirScope.QueryEngine.system_snapshot_at(timestamp2)
  IO.inspect(snapshot.process_states, label: "System process states at timestamp2")
end
```

## Progressive Real-Life Debugging Scenarios

Let's now build some more complex real-life debugging scenarios, progressively tackling more intricate aspects of ElixirScope.

### 5. Message Interception and Sampling

In real-world applications, message volume can be significant. Let's verify the performance settings work:

```elixir
# Debug script - run in IEx
# Restart ElixirScope with sampling
ElixirScope.stop()
ElixirScope.setup(sample_rate: 0.1, tracing_level: :messages_only)

# Create a high-volume message test
sender = spawn(fn ->
  receiver = spawn(fn ->
    # Receiver just collects messages
    messages = for _ <- 1..1000 do
      receive do
        msg -> msg
      after
        5000 -> :timeout
      end
    end
    IO.puts("Receiver got #{length(messages)} messages")
  end)
  
  # Send a burst of messages
  for i <- 1..1000 do
    send(receiver, {:test, i})
    Process.sleep(1) # Tiny delay to avoid overwhelming the system
  end
end)

# Wait for messages to be processed
Process.sleep(3000)

# Check message events - should be roughly 10% of the 1000 messages
messages = ElixirScope.TraceDB.query_events(%{type: :message})
IO.puts("Captured #{length(messages)} of 1000 messages with 0.1 sample rate")
```

Issues at this layer might include:
- Sampling logic not being applied correctly
- Message sanitization causing problems with large payloads
- Trace event buildup causing memory pressure

### 6. Phoenix Integration Testing

For applications using Phoenix, let's verify the Phoenix-specific tracing:

```elixir
# This would typically be run in a Phoenix application
# You can adapt this to your sample Phoenix app

# 1. First, ensure Phoenix app is running with ElixirScope
# In your Phoenix application.ex:
#
# def start(_type, _args) do
#   ElixirScope.setup(phoenix: true)
#   # rest of your startup code
# end

# 2. Clear existing trace data
ElixirScope.TraceDB.clear()

# 3. Make an HTTP request to a Phoenix endpoint
# You can do this manually in a browser or with HTTPoison in IEx
# For example: visit http://localhost:4000/

# 4. Examine the Phoenix trace events
phoenix_events = ElixirScope.TraceDB.query_events(%{type: :phoenix})
IO.inspect(phoenix_events, label: "Phoenix events")

# 5. Look for specific event types
http_requests = Enum.filter(phoenix_events, &(&1.type == :http_request))
IO.inspect(http_requests, label: "HTTP Requests")

router_dispatches = Enum.filter(phoenix_events, &(&1.type == :router_dispatch))
IO.inspect(router_dispatches, label: "Router Dispatches")

# 6. If using LiveView, trigger a LiveView event and check for those events
liveview_events = Enum.filter(phoenix_events, &String.starts_with?(to_string(&1.type), "live_view_"))
IO.inspect(liveview_events, label: "LiveView Events")
```

Common issues with Phoenix integration:
- Telemetry handlers not attaching properly
- Event data structures not matching what Phoenix emits
- LiveView event handling mismatches

### 7. QueryEngine Advanced Features

Test the more advanced features of the QueryEngine:

```elixir
# Debug script - run in IEx
ElixirScope.setup()

# Setup a test GenServer that will go through multiple state changes
defmodule ComplexStateServer do
  use GenServer
  use ElixirScope.StateRecorder
  
  def start_link do
    GenServer.start_link(__MODULE__, %{
      counter: 0,
      items: [],
      metadata: %{created_at: DateTime.utc_now()}
    })
  end
  
  def increment(pid), do: GenServer.cast(pid, :increment)
  def add_item(pid, item), do: GenServer.cast(pid, {:add_item, item})
  def update_metadata(pid, key, value), do: GenServer.cast(pid, {:update_metadata, key, value})
  def get_state(pid), do: GenServer.call(pid, :get_state)
  
  def init(state), do: {:ok, state}
  
  def handle_cast(:increment, state) do
    {:noreply, %{state | counter: state.counter + 1}}
  end
  
  def handle_cast({:add_item, item}, state) do
    {:noreply, %{state | items: [item | state.items]}}
  end
  
  def handle_cast({:update_metadata, key, value}, state) do
    {:noreply, put_in(state.metadata[key], value)}
  end
  
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end

# Start the server and perform various operations
{:ok, pid} = ComplexStateServer.start_link()
ComplexStateServer.increment(pid)
ComplexStateServer.add_item(pid, "item1")
ComplexStateServer.update_metadata(pid, :status, :active)
ComplexStateServer.increment(pid)
ComplexStateServer.add_item(pid, "item2")

# Now test the advanced query features

# 1. Get the complete state timeline
states = ElixirScope.state_timeline(pid)
IO.inspect(states, label: "State Timeline")

# 2. Test state evolution with context
if length(states) >= 3 do
  start_time = Enum.at(states, 0).timestamp
  end_time = Enum.at(states, -1).timestamp
  
  evolution = ElixirScope.QueryEngine.state_evolution(pid, start_time, end_time)
  IO.inspect(evolution, label: "State Evolution")
  
  # Examine the state diffs to see what changed between states
  if length(evolution) >= 2 do
    first_change = Enum.at(evolution, 0)
    IO.inspect(first_change.diff, label: "First state change diff")
  end
end

# 3. Test execution timeline
start_time = System.monotonic_time() - 60_000_000_000 # 1 minute ago
end_time = System.monotonic_time()
timeline = ElixirScope.QueryEngine.execution_timeline(start_time, end_time)
IO.inspect(timeline, label: "Execution Timeline")

# 4. Test compare_states function directly
state1 = %{a: 1, b: 2, nested: %{x: 10}}
state2 = %{a: 1, b: 3, c: 4, nested: %{x: 20, y: 30}}
diff = ElixirScope.QueryEngine.compare_states(state1, state2)
IO.inspect(diff, label: "State Comparison Result")
```

Issues at this layer often involve:
- State serialization and deserialization
- Timestamp handling and time window calculations
- Complex state diff logic failing on nested structures

### 8. AI Integration Testing (if Tidewave available)

If the Tidewave dependency is available, test the AI integration:

```elixir
# This assumes Tidewave is available and loaded
# You may need to adjust this based on your Tidewave implementation

# 1. Setup ElixirScope with AI integration
ElixirScope.setup(ai_integration: true)

# 2. Create a test GenServer to analyze
defmodule AITestServer do
  use GenServer
  use ElixirScope.StateRecorder
  
  def start_link, do: GenServer.start_link(__MODULE__, %{value: 0}, name: __MODULE__)
  def increment(amount \\ 1), do: GenServer.cast(__MODULE__, {:increment, amount})
  def reset, do: GenServer.cast(__MODULE__, :reset)
  
  def init(state), do: {:ok, state}
  def handle_cast({:increment, amount}, state), do: {:noreply, %{state | value: state.value + amount}}
  def handle_cast(:reset, _state), do: {:noreply, %{value: 0}}
end

{:ok, _pid} = AITestServer.start_link()
AITestServer.increment(5)
AITestServer.increment(10)
AITestServer.reset()
AITestServer.increment(3)

# 3. Test each AI tool function directly
server_pid = Process.whereis(AITestServer)
pid_string = inspect(server_pid)

# Test state timeline tool
state_timeline_result = ElixirScope.AIIntegration.tidewave_get_state_timeline(%{"pid_string" => pid_string})
IO.inspect(state_timeline_result, label: "AI Tool: State Timeline")

# Test module tracing tool
module_trace_result = ElixirScope.AIIntegration.tidewave_trace_module(%{"module_name" => "AITestServer"})
IO.inspect(module_trace_result, label: "AI Tool: Module Tracing")

# Test state changes analysis
state_analysis_result = ElixirScope.AIIntegration.tidewave_analyze_state_changes(%{"pid_string" => pid_string})
IO.inspect(state_analysis_result, label: "AI Tool: State Analysis")

# 4. Test AI integration through Tidewave (if available)
# This assumes Tidewave has a function to execute a tool - adjust as needed
if function_exported?(Tidewave, :execute_tool, 2) do
  tidewave_result = Tidewave.execute_tool("elixir_scope_get_state_timeline", %{"pid_string" => pid_string})
  IO.inspect(tidewave_result, label: "Tidewave Tool Execution")
end
```

Common issues with AI integration:
- PID serialization/deserialization errors
- Data formatting problems for AI consumption
- Missing or incorrect tool registrations

## Final System-Level Test: Real Application Debugging

For the most realistic test, use ElixirScope to debug a real issue in one of the sample applications:

```elixir
# This would typically be run in a real application context
# Here's a scenario you might set up in the sample Phoenix app

# 1. Setup ElixirScope
ElixirScope.setup(phoenix: true)

# 2. Create a scenario with a deliberate issue
# For example, in the Phoenix sample, modify Counter to sometimes fail:
defmodule BuggyCounter do
  use GenServer
  use ElixirScope.StateRecorder
  
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end
  
  def increment(amount \\ 1) do
    GenServer.cast(__MODULE__, {:increment, amount})
  end
  
  def get do
    GenServer.call(__MODULE__, :get)
  end
  
  def init(initial) do
    {:ok, %{value: initial, error_count: 0}}
  end
  
  def handle_cast({:increment, amount}, state) do
    # Introduce a bug - fail after 3 increments
    if state.error_count >= 3 do
      # Simulate a crash
      {:stop, :crash_after_three_increments, state}
    else
      new_state = %{
        value: state.value + amount,
        error_count: state.error_count + 1
      }
      {:noreply, new_state}
    end
  end
  
  def handle_call(:get, _from, state) do
    {:reply, state.value, state}
  end
end

# 3. Start the buggy counter
{:ok, _pid} = BuggyCounter.start_link([])

# 4. Trace the module
ElixirScope.trace_module(BuggyCounter)

# 5. Trigger the issue
BuggyCounter.increment(1)
BuggyCounter.increment(2)
BuggyCounter.increment(3) # This should trigger the crash
Process.sleep(100) # Give time for the crash to be logged

# 6. Use ElixirScope to investigate the issue

# Check process events to see if there was a crash
process_events = ElixirScope.TraceDB.query_events(%{type: :process})
crash_events = Enum.filter(process_events, &(&1.event == :exit))
IO.inspect(crash_events, label: "Process exit events")

# Check the state timeline leading up to the crash
counter_pid = Process.whereis(BuggyCounter)
state_history = ElixirScope.state_timeline(counter_pid)
IO.inspect(state_history, label: "Counter state history")

# Use time travel debugging to see the state just before the crash
if length(state_history) > 0 do
  last_state_time = List.last(state_history).timestamp
  
  # Get system snapshot just before crash
  snapshot = ElixirScope.QueryEngine.system_snapshot_at(last_state_time)
  IO.inspect(snapshot.process_states[counter_pid], label: "State just before crash")
  
  # Look at the surrounding events
  surrounding_events = ElixirScope.TraceDB.get_events_at(last_state_time, 1000)
  IO.inspect(surrounding_events, label: "Events around crash time")
end
```

## Comprehensive Debugging Plan for ElixirScope

Based on our layered testing and debugging approach, here's a comprehensive plan to get ElixirScope fully working:

1. **Start with the Core Storage Layer**
   - Implement and test `TraceDB` thoroughly
   - Verify ETS tables are created and functioning
   - Test event storage, querying, and management
   - Validate sampling and cleanup mechanisms

2. **Build and Test Each Tracer Component**
   - ProcessObserver: Test supervision tree building, process monitoring
   - MessageInterceptor: Test message capturing with different tracing levels
   - StateRecorder: Test both compile-time and runtime tracing approaches
   - CodeTracer: Test function call tracing and source mapping
   - PhoenixTracker: Test Phoenix-specific event capturing (if Phoenix available)

3. **Validate Query Engine Functionality**
   - Test basic querying (message flows, state timelines)
   - Test time travel debugging features
   - Test state comparison and diff generation
   - Test execution path reconstruction

4. **Test Main API and Configuration**
   - Verify setup process with different configuration options
   - Test validation of configuration parameters
   - Ensure proper component initialization based on settings
   - Test graceful shutdown and cleanup

5. **Add Integration Tests**
   - Test across multiple components (e.g., message flow + state changes)
   - Test with realistic application scenarios
   - Verify AI integration if available

6. **Performance Testing**
   - Test with high message volumes to validate sampling
   - Test memory usage over time to verify cleanup
   - Verify tracing level impacts on performance

7. **Real-World Application Testing**
   - Deploy in sample applications
   - Trace real application behaviors
   - Set up and resolve debugging scenarios

By following this layered approach from foundational components to full system integration, you'll be able to methodically debug and validate ElixirScope, addressing issues at each level before moving to more complex scenarios.

This test-driven strategy ensures the core functionality is solid before tackling the more advanced features, making the debugging process more efficient and systematic.
