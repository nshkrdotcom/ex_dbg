# ElixirScope Phoenix Sample App

This is a sample Phoenix application that demonstrates the usage of ElixirScope for application introspection and debugging.

## Features

- Demonstrates ElixirScope integration with Phoenix
- Shows state tracking of a simple counter GenServer
- Provides examples of time-travel debugging
- Shows how to observe and analyze process behavior

## Getting Started

1. Make sure you have ElixirScope in your mix.exs dependencies
2. Run `mix deps.get` to fetch dependencies
3. Start the server with `mix phx.server` or IEx with `iex -S mix phx.server`

## How ElixirScope is Used in This App

This application demonstrates several key features of ElixirScope:

### Initialization

In `application.ex`, we initialize ElixirScope with:

```elixir
ElixirScope.setup(
  phoenix: true,
  storage: :ets,
  tracing_level: :full,
  sample_rate: 1.0
)
```

### State Recording

The `Counter` module uses `ElixirScope.StateRecorder` to automatically track all state changes:

```elixir
defmodule PhoenixSampleApp.Counter do
  use GenServer
  use ElixirScope.StateRecorder

  # ... rest of the module ...
end
```

### Usage Examples

The `ElixirScopeDemo` module provides examples of how to use ElixirScope:

- `analyze_counter_state_changes/0` - Shows how to retrieve and analyze state changes
- `trace_counter_module/0` - Demonstrates function call tracing
- `show_counter_function_calls/0` - Shows how to query function calls
- `time_travel_debug/0` - Demonstrates time-travel debugging features
- `show_supervision_tree/0` - Shows how to visualize the application's supervision tree

## Try It Out

From an IEx session:

```elixir
# Perform some counter operations
PhoenixSampleApp.Counter.reset()
PhoenixSampleApp.Counter.increment(5)
PhoenixSampleApp.Counter.decrement(2)

# Analyze state changes
PhoenixSampleApp.ElixirScopeDemo.analyze_counter_state_changes()

# Trace function calls
PhoenixSampleApp.ElixirScopeDemo.trace_counter_module()
PhoenixSampleApp.Counter.increment(10)
PhoenixSampleApp.Counter.get()
PhoenixSampleApp.ElixirScopeDemo.show_counter_function_calls()

# Try time-travel debugging
PhoenixSampleApp.ElixirScopeDemo.time_travel_debug()

# View the supervision tree
PhoenixSampleApp.ElixirScopeDemo.show_supervision_tree()
``` 