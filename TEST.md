# ElixirScope Test Documentation

## Foundational Tests (TraceDB)

The foundational tests cover the `TraceDB` module, which is the core storage and retrieval component that all other modules depend on.

### Initialization Tests
- ✅ Initializes with default options
- ✅ Initializes with custom options (max_events, sample_rate, persistence)
- ✅ Creates ETS tables properly on initialization
- ✅ Properly handles GenServer initialization and shutdown

### Event Storage Tests
- ✅ Stores basic event data
- ✅ Assigns unique IDs to events
- ✅ Indexes events by PID
- ✅ Handles complex data structures (nested maps, tuples, binaries, etc.)
- ✅ Records timestamps on events
- ✅ Manages different event types (process, message, state, etc.)

### Sampling Tests
- ✅ Records all events with sample_rate 1.0
- ✅ Records no non-critical events with sample_rate 0.0
- ✅ Always records critical events (spawn/exit/crash) regardless of sample rate
- ✅ Maintains deterministic sampling with fixed inputs

### Query Tests
- ✅ Queries events by type
- ✅ Queries events by PID
- ✅ Queries events by timestamp range
- ✅ Supports combined filters
- ✅ Returns events in chronological order
- ✅ Handles empty query results

### State History Tests
- ✅ Retrieves state history for a specific process
- ✅ Gets events at a specific point in time with customizable window
- ✅ Gets state of a process at a specific timestamp
- ✅ Finds next event after a specific timestamp
- ✅ Finds previous event before a specific timestamp
- ✅ Identifies active processes at a specific timestamp

### Management Tests
- ✅ Clears all events from the database
- ✅ Performs event cleanup when max_events is exceeded
- ✅ Removes oldest events first during cleanup
- ✅ Persists events to disk when configured

## Data Collection Layer Tests

### ProcessObserver Tests
- ✅ Initialization Tests
  - ✅ Initializes with default options
  - ✅ Registers with TraceDB for event storage
- ✅ Process Lifecycle
  - ✅ Tracks basic process events
  - ✅ Stores events in TraceDB
- ✅ Process Information
  - ✅ Retrieves basic process information
- ⏳ Supervision Tree (Deferred due to complexity)
  - ⏳ Builds supervision tree structure
  - ⏳ Handles supervisor nesting
  - ⏳ Identifies supervisor strategies

### StateRecorder Tests
- ✅ GenServer Integration
  - ✅ Records initial state on process start
  - ✅ Properly records state changes from handle_call
  - ✅ Properly records state changes from handle_cast
  - ✅ Properly records state changes from handle_info
- ✅ External Process Tracing
  - ✅ Traces external GenServer processes
  - ✅ Captures state changes in traced processes
- ⏳ Complex State Structures (Deferred)
  - ⏳ Handles large state maps
  - ⏳ Properly diffs state changes

### MessageInterceptor Tests
(To be implemented)

### CodeTracer Tests
(To be implemented)

### PhoenixTracker Tests
(To be implemented)

## Query Layer Tests

(To be implemented)

## Integration Tests

(To be implemented) 