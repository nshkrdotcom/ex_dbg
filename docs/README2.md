# elixir_scope

A comprehensive debugging and observability framework for Elixir applications, providing deep runtime introspection, time-travel debugging, and intelligent analysis of BEAM processes.

## What is elixir_scope?

elixir_scope is designed to solve the hardest debugging challenges in Elixir/Erlang systems:

- **Why did my GenServer crash?** - Reconstruct the exact state and message sequence leading to failure
- **What's causing this performance bottleneck?** - Trace function calls and message flows with minimal overhead
- **How did my application state get corrupted?** - Time-travel through state changes to identify the root cause
- **What's happening in this distributed system?** - Comprehensive process and supervision tree analysis

## Key Features

### 🔍 **Deep BEAM Introspection**
- **Process Lifecycle Tracking**: Monitor spawns, exits, crashes, and supervision relationships
- **Message Flow Analysis**: Capture and analyze inter-process communication patterns
- **Function Call Tracing**: Record function calls with arguments and return values
- **State History**: Complete GenServer state evolution with timestamps

### ⏰ **Time-Travel Debugging**
- **State Reconstruction**: View any process state at any point in time
- **Event Replay**: Step through system execution forward and backward
- **Timeline Analysis**: Correlate events across multiple processes
- **Failure Investigation**: Examine system state leading up to crashes

### 🚀 **Production-Ready Performance**
- **Configurable Sampling**: Balance detail vs. performance impact
- **Intelligent Filtering**: Focus on relevant events, ignore noise
- **Memory Management**: Automatic cleanup and data retention policies
- **Low Overhead**: Minimal impact on application performance

### 📊 **Advanced Analytics**
- **Pattern Recognition**: Identify common failure modes and bottlenecks
- **State Diff Analysis**: See exactly what changed between state transitions
- **Process Relationship Mapping**: Visualize supervision trees and dependencies
- **Performance Metrics**: Track function execution times and message latency

## Quick Start

### Installation

Add elixir_scope to your `mix.exs`:

```elixir
def deps do
  [
    {:elixir_scope, "~> 0.1.0"}
  ]
end
```

### Basic Usage

```elixir
# Start elixir_scope with default settings
ElixirScope.start()

# Trace a specific GenServer
{:ok, pid} = MyApp.Worker.start_link()
ElixirScope.trace_genserver(pid)

# Trace function calls in a module
ElixirScope.trace_module(MyApp.PaymentProcessor)

# Start comprehensive tracing (be careful in production!)
ElixirScope.trace_all_processes()

# Query the data
timeline = ElixirScope.state_timeline(pid)
messages = ElixirScope.message_flow(pid1, pid2)
calls = ElixirScope.function_calls(MyApp.PaymentProcessor)

# Time-travel debugging
state_at_crash = ElixirScope.get_state_at(pid, crash_timestamp)
events_before_crash = ElixirScope.get_events_before(crash_timestamp, seconds: 30)

# Stop tracing
ElixirScope.stop()
```

## Configuration

```elixir
# Basic configuration
ElixirScope.start(
  # Storage backend - :ets for speed, :mnesia for persistence
  storage: :ets,
  
  # Maximum events to store (older events are pruned)
  max_events: 100_000,
  
  # Sample rate (0.0 - 1.0) to control performance impact
  sample_rate: 1.0,
  
  # Tracing detail level
  tracing_level: :full  # :full | :messages_only | :states_only | :minimal | :off
)

# Production-safe configuration
ElixirScope.start(
  storage: :ets,
  max_events: 10_000,
  sample_rate: 0.1,  # Only 10% of non-critical events
  tracing_level: :minimal,
  persist_to_disk: false
)

# Development configuration with full detail
ElixirScope.start(
  storage: :ets,
  max_events: 1_000_000,
  sample_rate: 1.0,
  tracing_level: :full,
  persist_to_disk: true,
  persist_path: "./debug_traces"
)
```

## Tracing Levels

- **`:full`** - Everything: function calls, messages, state changes, process lifecycle
- **`:messages_only`** - Only inter-process message passing
- **`:states_only`** - Only GenServer state changes
- **`:minimal`** - Process spawns/exits and major state changes only
- **`:off`** - No active tracing (infrastructure remains available)

## Advanced Usage

### Time-Travel Debugging

```elixir
# Get all events in a time window
events = ElixirScope.events_between(start_time, end_time)

# Reconstruct system state at a specific time
snapshot = ElixirScope.system_snapshot_at(timestamp)

# Find the cause of a state change
state_diff = ElixirScope.analyze_state_change(pid, before_time, after_time)

# Track down a race condition
race_analysis = ElixirScope.analyze_race_condition(pid1, pid2, event_window)
```

### Process Analysis

```elixir
# Current supervision tree
tree = ElixirScope.supervision_tree()

# Process relationship analysis
relationships = ElixirScope.process_relationships(pid)

# Find all processes of a specific type
workers = ElixirScope.find_processes(type: :worker)
supervisors = ElixirScope.find_processes(type: :supervisor)
```

### Performance Investigation

```elixir
# Function call performance analysis
hotspots = ElixirScope.performance_hotspots(module: MyApp.SlowModule)

# Message queue analysis
bottlenecks = ElixirScope.message_queue_analysis()

# Memory usage patterns
memory_trends = ElixirScope.memory_analysis(pid, duration: :timer.hours(1))
```

## Real-World Examples

### Debugging a GenServer Crash

```elixir
# 1. Start tracing the problematic GenServer
{:ok, pid} = MyApp.PaymentProcessor.start_link()
ElixirScope.trace_genserver(pid)

# 2. Reproduce the crash
MyApp.PaymentProcessor.process_payment(pid, invalid_data)

# 3. Investigate what happened
crash_events = ElixirScope.get_crash_events(pid)
state_before_crash = ElixirScope.get_state_at(pid, crash_events.timestamp - 1000)
message_sequence = ElixirScope.get_messages_to(pid, before: crash_events.timestamp)

# 4. Analyze the failure
ElixirScope.analyze_crash(pid, crash_events.timestamp)
```

### Finding a Performance Bottleneck

```elixir
# 1. Start performance tracing
ElixirScope.start(tracing_level: :full, sample_rate: 0.5)
ElixirScope.trace_module(MyApp.ExpensiveOperation)

# 2. Run the slow operation
MyApp.ExpensiveOperation.do_work()

# 3. Analyze performance
hotspots = ElixirScope.performance_analysis(MyApp.ExpensiveOperation)
call_tree = ElixirScope.call_tree_analysis(MyApp.ExpensiveOperation)
timing_breakdown = ElixirScope.timing_analysis(MyApp.ExpensiveOperation)
```

### Investigating a Race Condition

```elixir
# 1. Trace all involved processes
ElixirScope.trace_genserver(process_a)
ElixirScope.trace_genserver(process_b)
ElixirScope.trace_genserver(shared_resource)

# 2. Reproduce the race condition
spawn(fn -> ProcessA.update_resource() end)
spawn(fn -> ProcessB.update_resource() end)

# 3. Analyze the race
message_timeline = ElixirScope.interleaved_timeline([process_a, process_b, shared_resource])
race_analysis = ElixirScope.detect_race_conditions(message_timeline)
```

## Production Considerations

### Performance Impact

elixir_scope is designed to be production-safe when configured appropriately:

```elixir
# Recommended production settings
ElixirScope.start(
  tracing_level: :minimal,    # Only critical events
  sample_rate: 0.01,          # 1% sampling
  max_events: 5_000,          # Limited memory usage
  auto_cleanup: true          # Automatic cleanup
)
```

### Memory Management

- **Automatic Pruning**: Oldest events are automatically removed when `max_events` is reached
- **Sampling**: Non-critical events can be sampled to reduce memory usage
- **Critical Events**: Process crashes, spawns, and exits are always captured regardless of sampling
- **Configurable Retention**: Set different retention policies for different event types

### Security Considerations

- **Sensitive Data**: elixir_scope captures actual process state and messages - ensure sensitive data is handled appropriately
- **Access Control**: Limit access to elixir_scope data in production environments
- **Data Persistence**: Consider encryption if persisting trace data to disk

## Architecture

### Core Components

- **TraceDB**: ETS-based storage with sophisticated querying capabilities
- **ProcessObserver**: Monitors process lifecycle and supervision relationships
- **MessageInterceptor**: Captures inter-process communication using `:dbg`
- **StateRecorder**: Tracks GenServer state changes via `__using__` macro or `:sys.trace`
- **CodeTracer**: Function call tracing with arguments and return values
- **QueryEngine**: High-level interface for time-travel debugging and analysis

### Data Flow

```
Events → Sampling → Formatting → TraceDB → QueryEngine → Analysis
```

### Storage Schema

elixir_scope uses three main ETS tables:
- `:elixir_scope_events` - All non-state events (process, message, function)
- `:elixir_scope_states` - GenServer state snapshots
- `:elixir_scope_process_index` - Fast process-based lookups

## API Reference

### Core Functions

- `ElixirScope.start/1` - Initialize elixir_scope with configuration
- `ElixirScope.stop/0` - Stop all tracing and cleanup
- `ElixirScope.trace_genserver/1` - Start tracing a GenServer process
- `ElixirScope.trace_module/1` - Start tracing all functions in a module
- `ElixirScope.trace_process/1` - Start comprehensive process tracing

### Query Functions

- `ElixirScope.state_timeline/1` - Get state change history for a process
- `ElixirScope.message_flow/2` - Get messages between two processes
- `ElixirScope.function_calls/1` - Get function call history for a module
- `ElixirScope.get_state_at/2` - Get process state at specific timestamp
- `ElixirScope.events_between/2` - Get all events in time range

### Analysis Functions

- `ElixirScope.analyze_crash/2` - Comprehensive crash analysis
- `ElixirScope.performance_analysis/1` - Function performance breakdown
- `ElixirScope.detect_race_conditions/1` - Race condition detection
- `ElixirScope.supervision_tree/0` - Current supervision hierarchy

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Running Tests

```bash
mix test
```

### Development Setup

```bash
git clone https://github.com/your-org/elixir_scope.git
cd elixir_scope
mix deps.get
mix test
```

## License

Copyright 2024 - Licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

elixir_scope builds upon the powerful debugging and tracing primitives provided by the Erlang VM, including `:dbg`, `:sys`, and `:observer`. Special thanks to the Erlang/OTP team for creating such a robust foundation for runtime introspection.
