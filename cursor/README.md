# ElixirScope

ElixirScope is a state-of-the-art introspection and debugging system for Elixir applications, with special focus on Phoenix web applications.

## Features

- **Process Monitoring**: Track process lifecycles, supervision relationships, and inter-process messages
- **State Inspection**: Capture and visualize state changes in GenServers and other processes
- **Function Tracing**: Record function calls and returns with arguments and results
- **Phoenix Integration**: Special tooling for Phoenix channels, LiveView, and HTTP requests
- **AI-Assisted Debugging**: Natural language interface for exploring system behavior (via Tidewave integration)
- **Time-Travel Debugging**: Reconstruct application state at any point in time
- **Low Performance Impact**: Configurable tracing levels to minimize overhead

## Installation

Add `elixir_scope` to your mix.exs dependencies:

```elixir
def deps do
  [
    {:elixir_scope, "~> 0.1.0"}
  ]
end
```

## Basic Usage

```elixir
# Start ElixirScope
ElixirScope.setup()

# Trace a specific module
ElixirScope.trace_module(MyApp.User)

# Trace a specific GenServer process
pid = Process.whereis(MyApp.Worker)
ElixirScope.trace_genserver(pid)

# Enable Phoenix-specific tracing
ElixirScope.PhoenixTracker.setup_phoenix_tracing(MyAppWeb.Endpoint)

# Query trace data
# Get message flow between two processes
pid1 = Process.whereis(MyApp.WorkerA)
pid2 = Process.whereis(MyApp.WorkerB)
messages = ElixirScope.message_flow(pid1, pid2)

# Get state changes for a process
states = ElixirScope.state_timeline(pid1)

# Get execution path for a process
execution = ElixirScope.execution_path(pid1)

# Stop tracing
ElixirScope.stop()
```

## Phoenix Integration

ElixirScope includes special instrumentation for Phoenix applications:

```elixir
# In your application startup code
ElixirScope.setup(phoenix: true)

# This will automatically instrument:
# - HTTP request/response cycles
# - LiveView mounts, updates, and events
# - Channel joins and messages
# - PubSub broadcasts (requires additional setup)
```

## AI Integration

ElixirScope can integrate with AI systems like Tidewave for natural language debugging:

```elixir
# Enable AI integration
ElixirScope.setup(ai_integration: true)

# Now you can ask questions like:
# "Why didn't the counter update when I clicked increment?"
# "What happens to the state when a user logs in?"
# "Show me the message flow between the authentication service and the user controller"
```

## Advanced Configuration

```elixir
# Full configuration
ElixirScope.setup(
  # Storage backend (:ets, :mnesia, or :file)
  storage: :ets,
  
  # Maximum number of events to store
  max_events: 10_000,
  
  # Whether to persist events to disk
  persist: false,
  
  # Path for persisted data
  persist_path: "./trace_data",
  
  # Enable Phoenix-specific tracking
  phoenix: true,
  
  # Enable AI integration
  ai_integration: false,
  
  # Start tracing all processes (high overhead)
  trace_all: false
)
```

## Documentation

For more detailed documentation, see the [full documentation](https://hexdocs.pm/elixir_scope).

## License

This project is licensed under the MIT License - see the LICENSE file for details. 