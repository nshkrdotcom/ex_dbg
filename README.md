# ElixirScope

A state-of-the-art introspection and debugging system for Elixir applications, with special focus on Phoenix web applications. It enables comprehensive tracking of processes, message passing, state changes, and function calls, with AI-assisted analysis capabilities.

## Features

- **Process Monitoring**: Track process lifecycles (spawn, exit), supervision relationships, and inter-process messages.
- **State Inspection**: Capture and visualize state changes in GenServers and other processes over time.
- **Function Tracing**: Record function calls and returns for specific modules, including arguments and results.
- **Phoenix Integration**: Optional tooling to trace Phoenix channels, LiveView, and HTTP requests (requires `PhoenixTracker` component).
- **AI-Assisted Debugging**: Natural language interface for exploring system behavior through Tidewave integration, leveraging powerful AI for analysis.
- **Time-Travel Debugging**: Reconstruct application state and execution flow at any point in time using rich query capabilities.
- **Configurable Tracing**: Fine-tune the level of detail captured, from full tracing to minimal oversight, to balance insight with performance.
- **Event Sampling**: Reduce performance overhead by recording only a percentage of non-critical events.
- **Data Persistence**: Optionally persist trace data to disk for later analysis.

## Installation

Add `elixir_scope` to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:elixir_scope, "~> 0.1.0"}
    # Ensure :telemetry is also listed if not already present for other libraries
    # {:telemetry, "~> 1.0"}
  ]
end
```

Then, fetch the dependencies:

```bash
mix deps.get
```

## Basic Usage

```elixir
# In your application.ex or IEx session

# Start ElixirScope with default settings
ElixirScope.setup()

# Example: Start with Phoenix and AI integration enabled
# ElixirScope.setup(phoenix: true, ai_integration: true)

# Trace a specific module
ElixirScope.trace_module(MyApp.MyModule)

# Trace a specific GenServer process by PID
case Process.whereis(MyApp.MyWorker) do
  pid when is_pid(pid) -> ElixirScope.trace_genserver(pid)
  nil -> IO.puts("MyApp.MyWorker not found or not a GenServer")
end

# --- Query trace data ---

# Get message flow between two processes
# pid1 = Process.whereis(MyApp.WorkerA)
# pid2 = Process.whereis(MyApp.WorkerB)
# messages = ElixirScope.message_flow(pid1, pid2)

# Get state changes for a process
# states = ElixirScope.state_timeline(pid1)

# Get execution path (function calls) for a process
# execution = ElixirScope.execution_path(pid1)

# Stop tracing and clean up resources
# ElixirScope.stop()
```

## Configuration

ElixirScope is configured via the `ElixirScope.setup/1` function.

```elixir
ElixirScope.setup(
  # :storage - The storage backend for trace data. Currently defaults to :ets internally for TraceDB.
  #   ElixirScope.setup passes this to TraceDB. Default: :ets
  storage: :ets,

  # :phoenix - Boolean indicating whether to enable Phoenix-specific tracking.
  #   Requires the ElixirScope.PhoenixTracker module to be fully implemented and configured.
  #   Default: false
  phoenix: false,

  # :trace_all - Boolean indicating whether to start tracing all processes.
  #   Warning: This can generate a lot of data and impact performance.
  #   Default: false
  trace_all: false,

  # :ai_integration - Boolean indicating whether to enable AI integration (e.g., with Tidewave).
  #   Default: false
  ai_integration: false,

  # :tracing_level - Controls the level of tracing detail.
  #   Default: :full
  tracing_level: :full, # Or :messages_only, :states_only, :minimal, :off

  # :sample_rate - Controls what percentage of non-critical events are captured (float between 0.0 and 1.0).
  #   Default: 1.0 (all events)
  sample_rate: 1.0
)
```

### Tracing Levels

- `:full`: Captures all events: function calls, messages, state changes, and process lifecycle.
- `:messages_only`: Only captures message passing between processes.
- `:states_only`: Only captures GenServer state changes.
- `:minimal`: Captures a minimal set of events, primarily for oversight (process creation/termination and major state changes).
- `:off`: Disables all tracing (still sets up the infrastructure but doesn't start any tracers).

### Sample Rate

The sample rate allows you to reduce the performance impact by only recording a percentage of non-critical events. A value of `1.0` records all events, `0.5` records approximately half, etc. Critical events (like process spawns, exits, crashes) are always recorded regardless of the sample rate.

### TraceDB Configuration Defaults

The underlying `ElixirScope.TraceDB` module has additional configurations that currently use defaults when started via `ElixirScope.setup/1`:
- `max_events`: Maximum number of events to store (Default: 10,000). Older events are pruned.
- `persist`: Whether to persist events to disk (Default: `false`).
- `persist_path`: Path for storing persisted data if `persist` is true (Default: `"./trace_data"`).

To customize these, you would need to start `ElixirScope.TraceDB` manually before `ElixirScope.setup/1` or modify `ElixirScope.setup/1` to pass these options through.

## Phoenix Integration

ElixirScope can provide specialized instrumentation for Phoenix applications.

To enable Phoenix integration, start ElixirScope with the `:phoenix` option:

```elixir
# In your application.ex's start/2 function
def start(_type, _args) do
  children = [
    # ... your other children
  ]

  # Start ElixirScope with Phoenix integration
  ElixirScope.setup(phoenix: true, ai_integration: true) # Example

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

When enabled (and with the `ElixirScope.PhoenixTracker` component fully integrated), this can automatically instrument:
- HTTP request/response cycles
- LiveView mounts, updates, and events
- Channel joins and messages
- PubSub broadcasts

## AI Integration with Tidewave

ElixirScope provides a comprehensive integration with Tidewave, allowing natural language debugging and inspection of your Elixir application. This brings powerful AI-assisted debugging right into your development workflow.

### Available Tidewave Tools

When AI integration is enabled, ElixirScope registers the following tools with Tidewave:

1. **Get State Timeline** (`elixir_scope_get_state_timeline`):
   - Description: "Retrieves the history of state changes for a given process."
   - Args: `pid_string` (e.g., `"#PID<0.123.0>"`)
   - Tracks how process state evolved over time with timestamps.

2. **Get Message Flow** (`elixir_scope_get_message_flow`):
   - Description: "Retrieves the message flow between two processes."
   - Args: `from_pid` (sender PID string), `to_pid` (receiver PID string)
   - Analyzes message exchanges, showing content, timing, and direction.

3. **Get Function Calls** (`elixir_scope_get_function_calls`):
   - Description: "Retrieves the function calls for a given module."
   - Args: `module_name` (e.g., `"MyApp.User"`)
   - Gets a chronological list of function calls, including arguments.

4. **Trace Module** (`elixir_scope_trace_module`):
   - Description: "Starts tracing a specific module."
   - Args: `module_name` (e.g., `"MyApp.User"`)
   - Dynamically captures all function calls and returns for the module.

5. **Trace Process (by PID)** (`elixir_scope_trace_process`):
   - Description: "Starts tracing a specific process."
   - Args: `pid_string` (e.g., `"#PID<0.123.0>"`)
   - Captures messages, state changes, and function calls for the process.

6. **Trace Named Process** (`elixir_scope_trace_named_process`):
   - Description: "Starts tracing a process by its registered name."
   - Args: `process_name` (The registered name of the process)
   - Similar to tracing by PID, but uses the registered name.

7. **Get Supervision Tree** (`elixir_scope_get_supervision_tree`):
   - Description: "Retrieves the current supervision tree."
   - Args: None
   - Visualizes the complete supervision hierarchy, supervisor strategies, and child specs.

8. **Get Execution Path** (`elixir_scope_get_execution_path`):
   - Description: "Retrieves the execution path of a specific process."
   - Args: `pid_string` (e.g., `"#PID<0.123.0>"`)
   - Follows the sequence of operations for a process.

9. **Analyze State Changes** (`elixir_scope_analyze_state_changes`):
   - Description: "Analyzes state changes for a process, including diffs between consecutive states."
   - Args: `pid_string` (e.g., `"#PID<0.123.0>"`)
   - Provides detailed analysis of state transitions and what triggered them.

### Setup for AI Integration

Enable Tidewave integration by starting ElixirScope with the `:ai_integration` option set to `true`:

```elixir
# In your application.ex or IEx
ElixirScope.setup(
  ai_integration: true,
  storage: :ets,        # Recommended for performance with AI tools
  tracing_level: :full # Or another level based on your needs
)
```
ElixirScope will attempt to register its tools if `Tidewave` and `Tidewave.Plugin` are available in your project.

### Performance Considerations for AI Integration

When using AI integration, you can control the tracing level to balance between detail and performance:

```elixir
# Full tracing - captures everything but higher overhead
ElixirScope.setup(ai_integration: true, tracing_level: :full)

# Messages only - lower overhead, focuses on inter-process communication
ElixirScope.setup(ai_integration: true, tracing_level: :messages_only)

# States only - only tracks GenServer state changes
ElixirScope.setup(ai_integration: true, tracing_level: :states_only)

# Minimal - very low overhead, captures only essential events
ElixirScope.setup(ai_integration: true, tracing_level: :minimal)
```

You can also use sampling to reduce the amount of data collected:

```elixir
# Capture only 20% of non-critical events (randomly sampled)
ElixirScope.setup(ai_integration: true, sample_rate: 0.2)
```

### Example Queries for Tidewave

With this integration, you can ask Tidewave questions like:

- "Show me the state changes for the Counter process (PID '#PID<0.250.0>') over the last 5 minutes."
- "What messages were exchanged between the UserController (PID '#PID<0.300.0>') and the AuthService (PID '#PID<0.310.0>')?"
- "When did the AccountManager process (PID '#PID<0.400.0>') crash and what was its state before crashing?"
- "What function calls were made to the `MyApp.PaymentProcessor` module during the failed transaction?"
- "Show me the supervision tree for this application."
- "Analyze state changes for process `MyNamedProcess`."

### Extending the AI Integration

You can extend the Tidewave integration by adding your own custom tools. This typically involves creating a module that defines functions Tidewave can call and registering them using `Tidewave.Plugin.register_tool/1`. Refer to the `ElixirScope.AIIntegration` module for examples.

## Advanced Usage

### Time-Travel Debugging

```elixir
# Get state at a specific timestamp
{:ok, state} = ElixirScope.get_state_at(pid, timestamp)

# Get all events in a time window
events = ElixirScope.get_events_between(start_time, end_time)

# Reconstruct system state at any point
snapshot = ElixirScope.system_snapshot_at(timestamp)

# Find events that led to a specific state change
causes = ElixirScope.analyze_state_change(pid, before_state, after_state)
```

### Performance Analysis

```elixir
# Analyze function performance
hotspots = ElixirScope.performance_analysis(MyApp.SlowModule)

# Message queue analysis
bottlenecks = ElixirScope.message_queue_analysis()

# Find the slowest operations
slow_calls = ElixirScope.slowest_function_calls(limit: 10)
```

### Process Investigation

```elixir
# Get complete process information
info = ElixirScope.process_info(pid)

# Find all processes of a specific module
workers = ElixirScope.find_processes(module: MyApp.Worker)

# Analyze process relationships
relationships = ElixirScope.process_relationships(pid)
```

## Running Tests

ElixirScope includes a comprehensive test suite to ensure its components function correctly.

### Test Files Overview

The main test files include:
- `test/elixir_scope/trace_db_test.exs`: Core storage and querying.
- `test/elixir_scope/process_observer_test.exs`: Process lifecycle tracking.
- `test/elixir_scope/state_recorder_test.exs`: GenServer state recording.
- `test/elixir_scope/message_interceptor_test.exs`: Inter-process message capture.
- *(Tests for `CodeTracer`, `PhoenixTracker`, `QueryEngine`, and `AIIntegration` would also be part of a complete suite).*

### Running All Tests

To run the entire test suite:

```bash
mix test
```

### Running Specific Test Files

To run tests for a specific module:

```bash
# Run TraceDB tests
mix test test/elixir_scope/trace_db_test.exs

# Run MessageInterceptor tests
mix test test/elixir_scope/message_interceptor_test.exs

# And so on for other test files...
```

### Running Specific Test Cases

To run a specific test or test group by line number or describe/test name:

```bash
# Run a specific test case (using line number)
mix test test/elixir_scope/trace_db_test.exs:42

# Run tests within a specific describe block (using the describe string)
mix test --only describe:"event storage"

# Run a specific test by name (requires Elixir 1.13+)
# mix test --only test:"stores basic events"
```

### Common Test Options

```bash
# Run tests with an extended timeout (e.g., 60 seconds)
mix test --timeout 60000

# Get detailed information about each test (trace execution)
mix test --trace

# Run tests matching a specific tag
# mix test --only smoke
# mix test --exclude integration
```

### Test Environment

- The test suite is configured to use `ElixirScope.TraceDB` in `:test_mode` to ensure consistent behavior and avoid issues with ETS table creation/cleanup.
- Many tests that involve inter-process communication or system-level tracing are marked with `async: false` to prevent interference between tests.
- Console output from tracing mechanisms is generally suppressed during tests using `StringIO` or test-specific configurations to keep test output clean.

## Production Considerations

### Performance Impact

ElixirScope is designed to be production-safe when configured appropriately:

```elixir
# Recommended production settings
ElixirScope.setup(
  tracing_level: :minimal,    # Only critical events
  sample_rate: 0.01,          # 1% sampling
  storage: :ets,              # Fast in-memory storage
  max_events: 5_000,          # Limited memory usage
  persist: false              # No disk I/O overhead
)
```

### Memory Management

- **Automatic Pruning**: Oldest events are automatically removed when `max_events` is reached
- **Sampling**: Non-critical events can be sampled to reduce memory usage
- **Critical Events**: Process crashes, spawns, and exits are always captured regardless of sampling
- **Configurable Retention**: Set different retention policies for different event types

### Security Considerations

- **Sensitive Data**: ElixirScope captures actual process state and messages - ensure sensitive data is handled appropriately
- **Access Control**: Limit access to ElixirScope data in production environments
- **Data Persistence**: Consider encryption if persisting trace data to disk

## Architecture

### Core Components

- **TraceDB**: ETS-based storage with sophisticated querying capabilities
- **ProcessObserver**: Monitors process lifecycle and supervision relationships  
- **MessageInterceptor**: Captures inter-process communication using `:dbg`
- **StateRecorder**: Tracks GenServer state changes via `__using__` macro or `:sys.trace`
- **CodeTracer**: Function call tracing with arguments and return values
- **QueryEngine**: High-level interface for time-travel debugging and analysis
- **AIIntegration**: Tidewave integration for natural language debugging

### Data Flow

```
Events → Sampling → Formatting → TraceDB → QueryEngine → AI Analysis
```

### ETS Storage Structure

ElixirScope uses three main ETS tables:
- `:elixir_scope_events` - All non-state events (process, message, function)
- `:elixir_scope_states` - GenServer state snapshots  
- `:elixir_scope_process_index` - Fast process-based lookups

## Documentation

For more detailed API documentation, generate the docs locally:
```bash
mix docs
```
Then open `doc/index.html`. Online documentation can be found at [https://hexdocs.pm/elixir_scope](https://hexdocs.pm/elixir_scope).

## License

This project is licensed under the MIT License - see the `LICENSE` file for details.
