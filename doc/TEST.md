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
- ✅ Initialization
  - ✅ Starts with default options
  - ✅ Can enable and disable tracing
  - ✅ Can set different tracing levels
- ✅ Basic Operations  
  - ✅ Can be enabled and disabled
  - ✅ Can change tracing level
- ✅ Message Interception
  - ✅ Captures sent messages
  - ✅ Traces messages for a specific process
  - ✅ Captures GenServer call messages

### CodeTracer Tests
(To be implemented)

### PhoenixTracker Tests
(To be implemented)

## Query Layer Tests

(To be implemented)

## Integration Tests

(To be implemented)

## Test Files Overview

The ElixirScope test suite includes the following test files:

1. `test/elixir_scope/trace_db_test.exs` - Tests for the core TraceDB module (940 lines)
2. `test/elixir_scope/process_observer_test.exs` - Tests for the ProcessObserver module (126 lines)
3. `test/elixir_scope/state_recorder_test.exs` - Tests for the StateRecorder module (212 lines)
4. `test/elixir_scope/message_interceptor_test.exs` - Tests for the MessageInterceptor module (273 lines)

## Running Tests

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

# Run ProcessObserver tests
mix test test/elixir_scope/process_observer_test.exs

# Run StateRecorder tests
mix test test/elixir_scope/state_recorder_test.exs

# Run MessageInterceptor tests
mix test test/elixir_scope/message_interceptor_test.exs
```

### Running Specific Test Cases

To run a specific test or test group:

```bash
# Run a specific test case (using line number)
mix test test/elixir_scope/trace_db_test.exs:42

# Run a specific test group (using the describe string)
mix test --only describe:"initialization"
```

### Test Options

Common test options:

```bash
# Run tests with extended timeout (for slower tests)
mix test --timeout 60000

# Get detailed information about each test
mix test --trace

# Run tests matching a specific pattern
mix test --only tag_name
mix test --exclude tag_name
```

### Test Environment

The tests are configured to run in isolation, with several optimizations:

- Test mode is enabled for most modules to reduce console output
- StringIO is used to suppress unwanted logging
- Sampling rates are adjusted for predictable test behavior
- Tests that interact with tracing are marked as async: false to prevent interference 