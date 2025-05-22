## Layered Test-Driven Strategy for Debugging ElixirScope

To develop a **layered test-driven strategy** for debugging the ElixirScope codebase and ensure it works with real-life examples, we need to start by analyzing the codebase, identifying foundational components, and building a dependency graph. Since there are currently no tests, we'll establish a testing framework from scratch, focusing on isolating and testing the most independent layers first. Below, I'll outline the analysis, dependency graph, and a detailed testing strategy.

### Analysis of the Codebase

ElixirScope is a **modular debugging and introspection system** for Elixir applications, particularly Phoenix-based ones. The codebase is organized into several key components across layers:

* **Data Collection Layer**: Includes `ProcessObserver`, `MessageInterceptor`, `StateRecorder`, `PhoenixTracker`, and `CodeTracer`. These components capture runtime events like process lifecycles, messages, and state changes.
* **Storage and Query Layer**: Consists of `TraceDB` (storage) and `QueryEngine` (querying). `TraceDB` is the central storage for all trace data, while `QueryEngine` provides high-level access to it.
* **Visualization and Analysis Layer**: Features `TimeTravel` (part of `QueryEngine`), with `InteractiveVisualization` and `Analyzer` planned but not fully implemented.
* **AI Integration Layer**: Includes `AIIntegration`, which connects to external AI systems like Tidewave.
* **Main Module**: `ElixirScope` orchestrates the setup and interaction with all components.

The goal is to isolate foundational files that can be tested independently. **TraceDB** stands out as a critical component because it has no dependencies on other ElixirScope modules and is relied upon by most data collection and query components. Testing it first will establish a solid base for higher layers.

---

### Dependency Graph

Here’s the dependency graph based on the source code files provided:

* **TraceDB** (`lib/elixir_scope/trace_db.ex`):
    * **Dependencies**: None within ElixirScope (uses only Elixir/OTP libraries like ETS).
    * **Dependents**: `ProcessObserver`, `MessageInterceptor`, `StateRecorder`, `PhoenixTracker`, `CodeTracer`, `QueryEngine`.
* **Data Collection Components**:
    * **ProcessObserver** (`lib/elixir_scope/process_observer.ex`):
        * **Dependencies**: `TraceDB`.
        * **Dependents**: `ElixirScope` (for setup).
    * **MessageInterceptor** (`lib/elixir_scope/message_interceptor.ex`):
        * **Dependencies**: `TraceDB`.
        * **Dependents**: `ElixirScope`.
    * **StateRecorder** (`lib/elixir_scope/state_recorder.ex`):
        * **Dependencies**: `TraceDB`.
        * **Dependents**: `ElixirScope`.
    * **PhoenixTracker** (`lib/elixir_scope/phoenix_tracker.ex`):
        * **Dependencies**: `TraceDB`.
        * **Dependents**: `ElixirScope`.
    * **CodeTracer** (`lib/elixir_scope/code_tracer.ex`):
        * **Dependencies**: `TraceDB`.
        * **Dependents**: `ElixirScope`.
* **QueryEngine** (`lib/elixir_scope/query_engine.ex`):
    * **Dependencies**: `TraceDB`.
    * **Dependents**: `ElixirScope`, `AIIntegration`.
* **AIIntegration** (`lib/elixir_scope/ai_integration.ex`):
    * **Dependencies**: `TraceDB`, `QueryEngine`, `CodeTracer`, `ElixirScope`.
    * **Dependents**: None (top layer).
* **ElixirScope** (`lib/elixir_scope.ex`):
    * **Dependencies**: All components (`ProcessObserver`, `MessageInterceptor`, `StateRecorder`, `PhoenixTracker`, `CodeTracer`, `TraceDB`, `QueryEngine`, `AIIntegration`).
    * **Dependents**: None (entry point).

**Graph Visualization (simplified)**:

```
ElixirScope
  ├── ProcessObserver → TraceDB
  ├── MessageInterceptor → TraceDB
  ├── StateRecorder → TraceDB
  ├── PhoenixTracker → TraceDB
  ├── CodeTracer → TraceDB
  ├── TraceDB
  ├── QueryEngine → TraceDB
  └── AIIntegration → TraceDB, QueryEngine, CodeTracer, ElixirScope
```

**Lowest Independent Layer**: `TraceDB` is the foundational layer with no internal dependencies, making it the ideal starting point for testing.

---

### Layered Test-Driven Strategy

Given the dependency graph, we’ll adopt a **bottom-up approach**, starting with `TraceDB` and progressively testing dependent layers. Here’s the detailed strategy:

#### 1. Test TraceDB (Foundational Layer)

**Why Start Here**: As the independent storage layer, `TraceDB` underpins all data collection and querying. Ensuring its reliability is critical before testing components that rely on it.

**Modifications for Testability**:

* **Configurable ETS Tables**: Modify `TraceDB` to accept custom table names via options (e.g., `events_table`, `states_table`) instead of hardcoding `:elixir_scope_events`, etc. This prevents test interference due to shared ETS tables.

    ```elixir
    def init(opts) do
      events_table = Keyword.get(opts, :events_table, :elixir_scope_events)
      states_table = Keyword.get(opts, :states_table, :elixir_scope_states)
      process_index = Keyword.get(opts, :process_index, :elixir_scope_process_index)
      :ets.new(events_table, [:named_table, :ordered_set, :public])
      :ets.new(states_table, [:named_table, :ordered_set, :public])
      :ets.new(process_index, [:named_table, :bag, :public])
      {:ok, %{events_table: events_table, states_table: states_table, process_index: process_index, ...}}
    end
    ```

* **Pass GenServer Reference**: Update API functions (e.g., `store_event/2`) to accept the `TraceDB` PID or name, allowing tests to target specific instances.

    ```elixir
    def store_event(tracedb, type, event_data) do
      GenServer.cast(tracedb, {:store_event, type, event_data})
    end
    ```

**Test Setup**:

```elixir
defmodule ElixirScope.TraceDBTest do
  use ExUnit.Case

  setup do
    events_table = :"events_#{System.unique_integer()}"
    states_table = :"states_#{System.unique_integer()}"
    process_index = :"process_index_#{System.unique_integer()}"
    opts = [events_table: events_table, states_table: states_table, process_index: process_index]
    {:ok, pid} = TraceDB.start_link(opts)
    on_exit(fn -> GenServer.stop(pid) end)
    {:ok, tracedb_pid: pid, events_table: events_table, states_table: states_table, process_index: process_index}
  end
end
```

**Test Cases**:

* **Initialization**: Verify that `TraceDB` starts and creates ETS tables.

    ```elixir
    test "starts and creates ETS tables", %{tracedb_pid: pid, events_table: events_table} do
      assert Process.alive?(pid)
      assert :ets.info(events_table) != :undefined
    end
    ```

* **Store Events**: Test storing different event types (e.g., `:process`, `:state`) and verify ETS contents.

    ```elixir
    test "stores a process event", %{tracedb_pid: tracedb, events_table: events_table} do
      event_data = %{type: :process, pid: self(), event: :spawn, timestamp: System.monotonic_time()}
      TraceDB.store_event(tracedb, :process, event_data)
      Process.sleep(10) # Wait for cast
      assert :ets.lookup(events_table, event_data.id) == [{event_data.id, event_data}]
    end
    ```

* **Query Events**: Test `query_events/1` with filters (e.g., type, PID, timestamp).
* **State History**: Test `get_state_history/1` for a process.
* **Sampling**: Test that `sample_rate` correctly filters non-critical events.
* **Cleanup**: Verify that exceeding `max_events` removes old events.

---

#### 2. Test Data Collection Components

**Components**: `ProcessObserver`, `MessageInterceptor`, `StateRecorder`, `PhoenixTracker`, `CodeTracer`.

**Approach**: Test each in isolation, using a test-specific `TraceDB` instance.

**Modifications**:

* Pass the `TraceDB` PID to each component’s `start_link/1` and use it for storing events.

    ```elixir
    def start_link(tracedb, opts \\ []) do
      GenServer.start_link(__MODULE__, {tracedb, opts}, name: __MODULE__)
    end
    ```

**Test Examples**:

* **ProcessObserver**:
    * Test process spawn/exit logging.
    * Test supervision tree construction with nested supervisors (leverage existing `process_observer_test.exs`).
* **MessageInterceptor**:
    * Test message send/receive capture using `:dbg`.
    * Verify tracing level affects event logging.
* **StateRecorder**:
    * Test macro instrumentation by defining a sample `GenServer`.
    * Test external tracing with `:sys.trace`.

---

#### 3. Test QueryEngine

**Approach**: Populate a `TraceDB` with test data and verify query results.

**Test Cases**:

* Test `state_timeline/1`, `message_flow/2`, and `system_snapshot_at/1`.
* Verify time-travel debugging reconstructs accurate states.

---

#### 4. Test Higher-Level Components

**Components**: `AIIntegration`, integration with sample apps.

**Approach**: Use integration tests with mocked Tidewave interactions and sample apps (plain Elixir and Phoenix).

**Test Cases**:

* Test AI tool registration and data summarization.
* Use sample app scenarios (e.g., counter state changes) to verify end-to-end functionality.

---

### Using Real-Life Examples

* **Sample Apps**: Leverage the provided plain Elixir and Phoenix sample apps to create integration tests. For example, test `analyze_counter_state_changes/0` in the Phoenix app to ensure correct state tracking.
* **Smoke Tests**: Run ElixirScope in these apps and assert expected outputs (e.g., state changes, supervision trees).

---

### Conclusion

This layered strategy starts with `TraceDB`, builds confidence in data collection, and progresses to querying and integration. By focusing on testability modifications and leveraging real-life examples, we can debug and enhance ElixirScope effectively, ensuring it works reliably in practical scenarios.
