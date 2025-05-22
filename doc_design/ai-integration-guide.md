# ElixirScope AI Integration Guide

This document provides a comprehensive guide on integrating ElixirScope with AI systems like Tidewave for natural language debugging and analysis of Elixir applications.

## Introduction

ElixirScope's AI integration allows developers to interact with their application's runtime behavior using natural language. This capability combines the power of AI with ElixirScope's deep introspection features to make debugging and system understanding significantly more accessible.

## Integration with Tidewave

The primary AI integration is with Tidewave, a tool that allows natural language interaction with Elixir applications. ElixirScope exposes its capabilities as Tidewave tools, which can be invoked through natural language queries.

### Enabling the Integration

To enable the integration, start ElixirScope with the `ai_integration` option set to `true`:

```elixir
# Basic integration
ElixirScope.setup(ai_integration: true)

# With additional configuration
ElixirScope.setup(
  ai_integration: true,
  tracing_level: :full,
  sample_rate: 1.0
)
```

### How the Integration Works

1. When ElixirScope starts with AI integration enabled, it checks if Tidewave is available in the application
2. If Tidewave is found, ElixirScope registers a set of specialized tools with Tidewave's plugin system
3. These tools expose ElixirScope's debugging and introspection capabilities via well-defined interfaces
4. The AI can then use these tools to retrieve specific information about your application's behavior

## Available Tools

ElixirScope registers the following tools with Tidewave:

### 1. State Timeline Retrieval

```elixir
# Tool name: elixir_scope_get_state_timeline
# Function: ElixirScope.AIIntegration.tidewave_get_state_timeline/1
```

This tool retrieves the complete history of state changes for a specific process, showing how the process state evolved over time. Each state change is timestamped and includes the full process state.

**Example query:** "Show me the state history for the Counter process"

### 2. Message Flow Analysis

```elixir
# Tool name: elixir_scope_get_message_flow
# Function: ElixirScope.AIIntegration.tidewave_get_message_flow/1
```

This tool analyzes message exchanges between two processes, showing the content, timing, and direction of messages. This is particularly useful for understanding how processes communicate.

**Example query:** "What messages were sent between the UserController and the AuthService?"

### 3. Function Call Tracing

```elixir
# Tool name: elixir_scope_get_function_calls
# Function: ElixirScope.AIIntegration.tidewave_get_function_calls/1
```

This tool provides a chronological list of function calls for a specific module, including arguments passed to each function. This helps understand the usage patterns of a module.

**Example query:** "Show me all calls to the UserRepository module during login"

### 4. Module Tracing

```elixir
# Tool name: elixir_scope_trace_module
# Function: ElixirScope.AIIntegration.tidewave_trace_module/1
```

This tool starts tracing a specific module, capturing all function calls and returns. This is useful for ad-hoc analysis of module behavior.

**Example query:** "Start tracing the PaymentService module"

### 5. Process Tracing

```elixir
# Tool name: elixir_scope_trace_process
# Function: ElixirScope.AIIntegration.tidewave_trace_process/1
```

```elixir
# Tool name: elixir_scope_trace_named_process
# Function: ElixirScope.AIIntegration.tidewave_trace_named_process/1
```

These tools begin tracing a process by PID or registered name, capturing messages, state changes, and function calls related to that process.

**Example queries:** 
- "Trace the process with PID 0.123.0"
- "Start tracing the GameServer process"

### 6. Supervision Tree Inspection

```elixir
# Tool name: elixir_scope_get_supervision_tree
# Function: ElixirScope.AIIntegration.tidewave_get_supervision_tree/0
```

This tool visualizes the complete supervision hierarchy of the application, showing supervisor strategies and child specifications. This helps understand the application's fault tolerance design.

**Example query:** "Show me the application's supervision tree"

### 7. Execution Path Analysis

```elixir
# Tool name: elixir_scope_get_execution_path
# Function: ElixirScope.AIIntegration.tidewave_get_execution_path/1
```

This tool follows the execution path of any process, providing a chronological sequence of operations. This helps understand the control flow through the system.

**Example query:** "What was the execution path of the request that failed?"

### 8. State Change Analysis

```elixir
# Tool name: elixir_scope_analyze_state_changes
# Function: ElixirScope.AIIntegration.tidewave_analyze_state_changes/1
```

This tool provides detailed analysis of state changes with diffs, showing what triggered each state change. This is useful for understanding how and why state changed.

**Example query:** "Analyze the state changes in the ShoppingCart process"

## Configuration Options

### Tracing Levels

ElixirScope offers different tracing levels to balance between detail and performance:

```elixir
# Full tracing - captures everything but higher overhead
ElixirScope.setup(ai_integration: true, tracing_level: :full)

# Messages only - lower overhead, focuses on inter-process communication
ElixirScope.setup(ai_integration: true, tracing_level: :messages_only)

# States only - only tracks GenServer state changes
ElixirScope.setup(ai_integration: true, tracing_level: :states_only)

# Minimal - very low overhead, captures only essential events
ElixirScope.setup(ai_integration: true, tracing_level: :minimal)

# Off - disables tracing completely
ElixirScope.setup(ai_integration: true, tracing_level: :off)
```

### Sampling

For high-throughput systems, you can use sampling to reduce the performance impact:

```elixir
# Capture only 20% of events (randomly sampled)
ElixirScope.setup(ai_integration: true, sample_rate: 0.2)
```

## Example Use Cases

### Debugging Complex State Issues

```
User: "Why did the user's balance change unexpectedly during checkout?"

AI: Let me investigate the state changes in the relevant processes.
    [uses elixir_scope_get_state_timeline for the UserAccount process]
    [uses elixir_scope_get_message_flow to see messages between checkout and payment services]

    I found that the balance was updated twice: once when the payment was authorized
    and again when the order was finalized. There appears to be a race condition where
    both processes updated the balance instead of just one.
```

### Understanding System Behavior

```
User: "What happens when a user sends a chat message?"

AI: Let me trace this flow for you.
    [uses elixir_scope_trace_module on the ChatController module]
    [uses elixir_scope_get_message_flow to follow the message through the system]

    When a user sends a chat message, the following happens:
    1. ChatController receives the message and validates it
    2. Message is stored in the database by MessageRepository
    3. Message is broadcast to ChatPubSub
    4. Online recipients receive the message via their WebSocket connections
    5. Push notifications are sent to offline users
```

### Investigating Performance Issues

```
User: "Why is the product search so slow?"

AI: Let me analyze the execution path for search requests.
    [uses elixir_scope_get_execution_path for the SearchController process]
    [uses elixir_scope_get_function_calls for the SearchRepository]

    The slowdown appears to be caused by:
    1. The search query is accessing 3 different database tables
    2. There are 5 sequential database calls rather than a batched query
    3. The product images are being loaded eagerly instead of lazily
    4. The result caching is not working correctly
```

## Extending the Integration

You can extend the Tidewave integration by adding custom tools to the AIIntegration module. This allows you to expose domain-specific analysis capabilities to the AI.

```elixir
defmodule MyApp.CustomAITools do
  def setup do
    # Register a custom tool with Tidewave
    Tidewave.Plugin.register_tool(%{
      name: "my_app_analyze_user_journey",
      description: "Analyzes a user's complete journey through the application",
      module: __MODULE__,
      function: :analyze_user_journey,
      args: %{
        user_id: %{
          type: "string",
          description: "The ID of the user to analyze"
        }
      }
    })
  end
  
  def analyze_user_journey(%{"user_id" => user_id}) do
    # Implement your custom analysis logic
    # ...
    %{
      user_id: user_id,
      session_count: 5,
      average_session_duration: "24 minutes",
      most_visited_features: ["dashboard", "reports", "settings"],
      common_workflows: [
        "login -> dashboard -> reports -> logout",
        "login -> settings -> profile update -> logout"
      ]
    }
  end
end
```

## Best Practices

1. **Start with minimal tracing**: Begin with `:minimal` tracing level and increase as needed
2. **Use sampling in production**: For production debugging, use sampling (e.g., `sample_rate: 0.1`)
3. **Focus on specific processes**: Trace only the specific processes or modules you're investigating
4. **Clean up regularly**: Call `ElixirScope.TraceDB.clear/0` periodically to free memory
5. **Add context to your queries**: Provide specific process names, time ranges, or event types
6. **Consider privacy**: Be aware of sensitive data that might be captured in state or messages

## Troubleshooting

### Tool Registration Issues

If tools aren't being registered with Tidewave:

1. Ensure Tidewave is included in your dependencies and started before ElixirScope
2. Check that `ai_integration: true` is set in your ElixirScope.setup call
3. Look for any error messages in your application logs

### Performance Issues

If you notice performance degradation:

1. Reduce the tracing level (e.g., `:minimal` instead of `:full`)
2. Enable sampling with a lower rate (e.g., `sample_rate: 0.1`)
3. Trace only specific components rather than the entire application
4. Increase the pruning frequency of old trace data

### Data Quality Issues

If the AI is working with incomplete or incorrect data:

1. Check that the relevant processes or modules are being traced
2. Ensure your tracing level captures the needed information (e.g., `:messages_only` won't capture state changes)
3. Verify that the sampling rate isn't too low for infrequent events
4. Check that ElixirScope was started before the processes you're trying to trace

## Conclusion

ElixirScope's AI integration with Tidewave provides a powerful natural language interface to your Elixir application's runtime behavior. By exposing introspection capabilities through well-defined tools, it allows AI systems to retrieve specific information about your application's state, message flows, function calls, and more.

This makes debugging and system understanding significantly more accessible, allowing developers to focus on solving problems rather than manually piecing together information from various sources. 