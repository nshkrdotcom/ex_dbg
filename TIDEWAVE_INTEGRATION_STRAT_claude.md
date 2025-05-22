# Tidewave + ex_dbg Integration Strategy

## Overview

This document outlines the strategy for integrating Tidewave (MCP server for AI-assisted development) with ex_dbg (comprehensive Elixir debugging framework) to create a powerful AI-assisted debugging experience.

## Current Architecture Analysis

### Tidewave Strengths
- **MCP Protocol**: Well-established interface for AI tools
- **Phoenix Integration**: Deep integration with Phoenix/LiveView
- **Tool Ecosystem**: Rich set of development tools (FS, Eval, Ecto, Process, etc.)
- **AI-Ready**: Designed for natural language interactions
- **Production Ready**: Mature codebase with comprehensive testing

### ex_dbg Strengths  
- **Deep BEAM Introspection**: Comprehensive process, message, and state tracking
- **Time-Travel Debugging**: Historical state reconstruction and analysis
- **Unified Data Store**: TraceDB with ETS-based storage and sophisticated querying
- **Configurable Tracing**: Fine-grained control over performance vs. detail
- **AI Integration Ready**: Already designed with Tidewave-style AI integration

## Integration Strategy: Hybrid Approach

Rather than reimplementing ex_dbg's capabilities in Tidewave, we should integrate them as complementary systems:

### Phase 1: ex_dbg as Tidewave MCP Tools

**Approach**: Add ex_dbg functionality as new MCP tools in Tidewave's existing tool ecosystem.

**Implementation**:
```elixir
# lib/tidewave/mcp/tools/ex_dbg.ex
defmodule Tidewave.MCP.Tools.ExDbg do
  def tools do
    [
      %{
        name: "start_tracing",
        description: "Start ex_dbg tracing with configurable levels",
        callback: &start_tracing/2
      },
      %{
        name: "get_state_timeline", 
        description: "Get GenServer state history for time-travel debugging",
        callback: &get_state_timeline/2
      },
      %{
        name: "get_message_flow",
        description: "Analyze message exchanges between processes", 
        callback: &get_message_flow/2
      },
      %{
        name: "analyze_state_changes",
        description: "AI-powered analysis of state transitions",
        callback: &analyze_state_changes/2
      },
      %{
        name: "get_supervision_tree",
        description: "Get current supervision hierarchy",
        callback: &get_supervision_tree/1
      },
      %{
        name: "trace_process_events", 
        description: "Comprehensive process event tracing",
        callback: &trace_process_events/2
      }
    ]
  end
end
```

**Benefits**:
- ✅ Leverages Tidewave's mature MCP infrastructure
- ✅ No duplication of MCP protocol handling
- ✅ Immediate AI integration through existing Tidewave architecture
- ✅ Easy to implement and test incrementally

### Phase 2: Enhanced Integration Features

**Advanced Tool Integration**:
```elixir
# Enhanced tools that combine Tidewave's existing capabilities with ex_dbg
defmodule Tidewave.MCP.Tools.Enhanced do
  def tools do
    [
      %{
        name: "debug_liveview_issue",
        description: "Combine LiveView introspection with ex_dbg tracing",
        callback: &debug_liveview_issue/2
      },
      %{
        name: "analyze_performance_bottleneck", 
        description: "Use ex_dbg tracing to identify performance issues",
        callback: &analyze_performance_bottleneck/2
      },
      %{
        name: "debug_genserver_crash",
        description: "Time-travel debug GenServer crashes with state history",
        callback: &debug_genserver_crash/2
      }
    ]
  end
  
  # Example: Combine Tidewave's LiveView tools with ex_dbg tracing
  defp debug_liveview_issue(args, assigns) do
    # 1. Use Tidewave's existing LiveView discovery
    {:ok, liveviews} = Tidewave.MCP.Tools.Phoenix.list_liveview_pages(%{}, assigns)
    
    # 2. Start ex_dbg tracing on identified processes
    for lv <- liveviews do
      ExDbg.trace_genserver(lv.pid)
    end
    
    # 3. Capture and analyze state changes
    # ... implementation
  end
end
```

### Phase 3: Unified Configuration

**Shared Configuration System**:
```elixir
# config/config.exs
config :tidewave,
  # Existing Tidewave config
  ecto_repos: [MyApp.Repo],
  
  # New ex_dbg integration config
  ex_dbg: [
    enabled: true,
    tracing_level: :full,
    sample_rate: 1.0,
    max_events: 10_000,
    storage: :ets,
    ai_integration: true
  ]
```

## Technical Implementation Details

### 1. Dependency Management

Add ex_dbg as an optional dependency in Tidewave:

```elixir
# mix.exs
defp deps do
  [
    # ... existing deps
    {:ex_dbg, "~> 0.1.0", optional: true}
  ]
end
```

### 2. Conditional Tool Loading

```elixir
# lib/tidewave/mcp/server.ex
defp raw_tools do
  base_tools = [
    Tools.FS.tools(),
    Tools.Logs.tools(),
    # ... existing tools
  ]
  
  ex_dbg_tools = 
    if Code.ensure_loaded?(ExDbg) do
      [Tools.ExDbg.tools()]
    else
      []
    end
    
  (base_tools ++ ex_dbg_tools) |> List.flatten()
end
```

### 3. State Management Integration

Ex_dbg's state management can integrate with Tidewave's existing state system:

```elixir
# Enhanced state tracking
def trace_genserver_with_ai(args, assigns) do
  case ExDbg.StateRecorder.trace_genserver(pid) do
    {:ok, _} ->
      # Store tracing metadata in Tidewave's assigns
      new_assigns = Map.update(assigns, :traced_processes, [pid], &[pid | &1])
      {:ok, "Started tracing #{inspect(pid)}", new_assigns}
      
    {:error, reason} ->
      {:error, "Failed to start tracing: #{reason}"}
  end
end
```

### 4. Data Format Harmonization

Ensure ex_dbg data formats work well with Tidewave's AI interactions:

```elixir
defp format_for_ai(trace_data) do
  # Convert ex_dbg's detailed trace data into AI-friendly summaries
  %{
    summary: summarize_events(trace_data),
    details: truncate_large_data(trace_data),
    insights: generate_insights(trace_data)
  }
end
```

## Integration Benefits

### For Users
- **Natural Language Debugging**: Ask "Why did my GenServer crash?" and get AI analysis of trace data
- **Comprehensive Coverage**: Tidewave's development tools + ex_dbg's deep runtime insights
- **Seamless Experience**: One interface for all debugging needs
- **Time-Travel Debugging**: AI-assisted analysis of historical states and events

### For Developers  
- **Reduced Complexity**: No need to reimplement MCP protocol in ex_dbg
- **Faster Development**: Leverage Tidewave's existing infrastructure
- **Better Testing**: Use Tidewave's established testing patterns
- **Easier Maintenance**: Single codebase for MCP integration

## Potential Challenges & Solutions

### Challenge 1: Performance Impact
**Issue**: ex_dbg's deep tracing could impact development performance
**Solution**: 
- Use Tidewave's existing sampling mechanisms
- Implement intelligent tracing levels based on user intent
- Add performance monitoring to the tools themselves

### Challenge 2: Data Volume
**Issue**: ex_dbg generates large amounts of trace data
**Solution**:
- Implement data summarization for AI consumption
- Use Tidewave's existing truncation and pagination patterns
- Add configurable data retention policies

### Challenge 3: State Synchronization
**Issue**: Keeping ex_dbg state in sync with Tidewave's session state
**Solution**:
- Use Tidewave's existing state management patterns
- Implement cleanup handlers for trace sessions
- Add session-scoped tracing configurations

## Implementation Roadmap

### Milestone 1: Basic Integration (2-3 weeks)
- [ ] Add ex_dbg as optional dependency
- [ ] Implement basic MCP tools for core ex_dbg functionality
- [ ] Add conditional tool loading
- [ ] Basic testing and documentation

### Milestone 2: Enhanced Tools (2-3 weeks)  
- [ ] Implement advanced debugging scenarios
- [ ] Add AI-powered analysis tools
- [ ] Integrate with existing Tidewave tools (LiveView, Process, etc.)
- [ ] Performance optimization and tuning

### Milestone 3: Production Features (2-3 weeks)
- [ ] Comprehensive error handling
- [ ] Advanced configuration options
- [ ] Performance monitoring and metrics
- [ ] Complete documentation and examples

### Milestone 4: Advanced Features (ongoing)
- [ ] Custom analysis plugins
- [ ] Integration with external APM systems
- [ ] Advanced visualization tools
- [ ] Community tool ecosystem

## Conclusion

Integrating ex_dbg as MCP tools within Tidewave provides the best of both worlds:
- Leverages Tidewave's mature MCP infrastructure and AI integration
- Adds ex_dbg's powerful debugging and observability capabilities  
- Creates a unified, AI-assisted debugging experience
- Minimizes development complexity and duplication

This approach allows both projects to focus on their core strengths while providing users with a comprehensive, intelligent debugging platform for Elixir applications.
