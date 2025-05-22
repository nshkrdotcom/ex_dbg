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

## AI Integration with Tidewave

ElixirScope provides a comprehensive integration with Tidewave, allowing natural language debugging and inspection of your Elixir application. This brings powerful AI-assisted debugging right into your development workflow.

For a complete guide on AI integration capabilities, see the [AI Integration Guide](docs/ai-integration-guide.md).

### Available Tidewave Tools

When AI integration is enabled, ElixirScope registers the following tools with Tidewave:

1. **State Timeline Retrieval** (`elixir_scope_get_state_timeline`):
   - Retrieve the complete history of state changes for any GenServer process
   - Track how process state evolved over time with timestamps

2. **Message Flow Analysis** (`elixir_scope_get_message_flow`):
   - Analyze message exchanges between any two processes
   - See message content, timing, and direction

3. **Function Call Tracing** (`elixir_scope_get_function_calls`):
   - Get a chronological list of function calls for any module
   - See arguments passed to each function

4. **Module Tracing** (`elixir_scope_trace_module`):
   - Start tracing a specific module dynamically
   - Capture all function calls and returns

5. **Process Tracing** (`elixir_scope_trace_process`, `elixir_scope_trace_named_process`):
   - Begin tracing a process by PID or registered name
   - Capture messages, state changes, and function calls

6. **Supervision Tree Inspection** (`elixir_scope_get_supervision_tree`):
   - Visualize the complete supervision hierarchy
   - See supervisor strategies and child specifications

7. **Execution Path Analysis** (`elixir_scope_get_execution_path`):
   - Follow the execution path of any process
   - See a chronological sequence of operations

8. **State Change Analysis** (`elixir_scope_analyze_state_changes`):
   - Get detailed analysis of state changes with diffs
   - See what triggered each state change

### Setup

Enable Tidewave integration by starting ElixirScope with AI integration enabled:

```elixir
# In your application.ex
def start(_type, _args) do
  ElixirScope.setup(
    ai_integration: true,
    storage: :ets,
    tracing_level: :full
  )
  
  # Rest of your application startup
  # ...
end
```

### Performance Considerations

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
# Capture only 20% of events (randomly sampled)
ElixirScope.setup(ai_integration: true, sample_rate: 0.2)
```

### Example Queries for Tidewave

With this integration, you can ask Tidewave questions like:

- "Show me the state changes for the Counter process over the last 5 minutes"
- "What messages were exchanged between the UserController and the AuthService?"
- "When did the AccountManager process crash and what was its state before crashing?"
- "What function calls were made to the PaymentProcessor module during the failed transaction?"
- "Show me the supervision tree for this application"
- "What was the state of the GameServer process at 2:45 PM?"

### Extending the Integration

You can extend the Tidewave integration by adding custom tools to the AIIntegration module:

```elixir
defmodule MyApp.CustomAITools do
  def setup do
    # Register a custom tool with Tidewave
    Tidewave.Plugin.register_tool(%{
      name: "my_app_custom_analysis",
      description: "Performs custom analysis of application behavior",
      module: __MODULE__,
      function: :custom_analysis,
      args: %{
        # Define your arguments here
      }
    })
  end
  
  def custom_analysis(args) do
    # Implement your custom analysis logic
    # ...
  end
end
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