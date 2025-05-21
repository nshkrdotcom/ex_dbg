# ElixirScope: Technical State Document (as of Current Implementation)

## 1. Overview

ElixirScope is an introspection and debugging library for Elixir applications, designed to provide granular insights into process behavior, message passing, state changes, and function execution. It integrates with AI tools like Tidewave for enhanced debugging and features configurable performance options. The project is functional, with core tracing capabilities, data storage, querying, and AI integration implemented. It also includes two sample applications (plain Elixir and Phoenix) demonstrating its usage.

## 2. ElixirScope Core Library (`cursor/`)

### 2.1. Architecture and Key Components

The library is modular, with distinct components responsible for different aspects of tracing, data storage, and querying:

*   **Main API (`ElixirScope`)**: The primary entry point for setting up and interacting with the library.
*   **Tracers**:
    *   `ProcessObserver`: Monitors process lifecycles and supervision trees.
    *   `MessageInterceptor`: Captures inter-process messages.
    *   `CodeTracer`: Traces function calls and returns.
    *   `StateRecorder`: Tracks GenServer state changes.
    *   `PhoenixTracker`: Instruments Phoenix applications using Telemetry.
*   **Data Storage (`TraceDB`)**: A GenServer managing in-memory storage (primarily ETS) of trace events.
*   **Querying (`QueryEngine`)**: Provides a high-level API to retrieve and analyze stored trace data, including time-travel debugging features.
*   **AI Integration (`AIIntegration`)**: Exposes ElixirScope's capabilities as tools for AI systems like Tidewave.

### 2.2. Detailed Component Breakdown

#### 2.2.1. `lib/elixir_scope.ex` (Main API)

*   **Purpose**: Orchestrates the setup and provides top-level user-facing functions.
*   **Key Implementation Details**:
    *   `setup(opts \\ [])`:
        *   Initializes `TraceDB` first.
        *   Starts `ProcessObserver`, `MessageInterceptor`, and `CodeTracer` GenServers, passing relevant configuration.
        *   Optionally initializes `PhoenixTracker` if `phoenix: true`.
        *   Optionally initializes `AIIntegration` if `ai_integration: true`.
        *   Supports `:storage` (defaults to `:ets`), `:tracing_level` (defaults to `:full`), `:sample_rate` (defaults to `1.0`), `:phoenix`, `:ai_integration`, `:trace_all`.
        *   Validates `tracing_level` and `sample_rate` inputs.
    *   Provides public functions like `trace_module/1`, `trace_genserver/1`, `state_timeline/1`, `message_flow/2`, `execution_path/1` which mostly delegate to specialized modules.
    *   `stop/0`: Clears `:dbg` tracers and stops the core GenServer components.
*   **Dependencies**: All core ElixirScope GenServer modules.

#### 2.2.2. `lib/elixir_scope/trace_db.ex` (Trace Data Storage)

*   **Purpose**: Centralized storage and management of all trace events.
*   **Key Implementation Details**:
    *   Uses three named ETS tables:
        *   `:elixir_scope_events` (ordered_set): For general events (process, message, function).
        *   `:elixir_scope_states` (ordered_set): For GenServer state snapshots.
        *   `:elixir_scope_process_index` (bag): For indexing events by PID.
    *   `init/1`: Sets up ETS tables. Supports options for `:max_events`, `:persist`, `:persist_path`, `:sample_rate`. Schedules periodic cleanup and persistence if configured (persistence currently writes `:erlang.term_to_binary` to a timestamped file).
    *   `store_event/2 (handle_cast)`:
        *   Applies sampling via `should_record_event?/3`. Critical events (process spawn/exit, crashes) bypass sampling. Non-critical events are sampled based on `sample_rate` using a hash of PID and timestamp for consistency, or `:rand.uniform()` as a fallback.
        *   Assigns a unique monotonic integer ID to each event.
        *   Stores events in appropriate ETS tables and updates the process index.
    *   Query functions (`query_events/1`, `get_state_history/1`, `get_events_at/2`, etc.) are implemented as GenServer calls that filter and sort data directly from ETS tables.
    *   `get_state_at(pid, timestamp)`: Finds the most recent state for `pid` at or before `timestamp`.
    *   `get_processes_at(timestamp)`: Determines active PIDs by comparing spawn and exit events up to `timestamp`.
    *   `handle_info(:cleanup, ...)`: Implements logic to remove the oldest events if `max_events` is exceeded.
*   **Dependencies**: None external to Elixir. Relied upon by all tracer modules and `QueryEngine`.

#### 2.2.3. `lib/elixir_scope/process_observer.ex` (Process & Supervision Monitor)

*   **Purpose**: Tracks process lifecycle events and supervision tree structure.
*   **Key Implementation Details**:
    *   `init/1`:
        *   Sets up `:erlang.system_monitor/2` for system events like `:busy_port`, `:long_gc`, `:long_schedule`.
        *   Sets `Process.flag(:trap_exit, true)` to receive `:EXIT` messages.
        *   Periodically calls `build_supervision_tree/0` via `Process.send_after`.
    *   `handle_info({:monitor, ...})` and `handle_info({:EXIT, ...})`: Record respective events to `TraceDB`.
    *   `build_supervision_tree/0`:
        *   Identifies all potential supervisors by checking the `:$initial_call` key in their process dictionary for `{:supervisor, :Supervisor, :init}`.
        *   Uses `is_top_level_supervisor?/1` to filter.
        *   Recursively calls `build_supervisor_subtree/1` which uses `:supervisor.which_children/1` to get child specs.
        *   Stores supervisor strategy from `:$supervisor_opts` in the process dictionary.
    *   `get_supervision_tree/0`: Returns the cached supervision tree.
*   **Dependencies**: `TraceDB`.

#### 2.2.4. `lib/elixir_scope/message_interceptor.ex` (Message Tracer)

*   **Purpose**: Captures inter-process messages.
*   **Key Implementation Details**:
    *   `init/1`: Sets up `:dbg.tracer/2` to send trace messages to itself. Based on `tracing_level` (if `:full` or `:messages_only`), it calls `:dbg.p(:all, [:send, :receive])`.
    *   `handle_info({:trace_msg, {:trace, from_pid, :send, msg, to_pid}}, ...)` and `handle_info({:trace_msg, {:trace, pid, :receive, msg}}, ...)`:
        *   If `tracing_level` permits, records send/receive events to `TraceDB`.
        *   Uses `maybe_sanitize_message/2` to either store a summary (for `:minimal` tracing level, e.g., "tuple with 3 elements") or a sanitized (inspected with limit) version of the message.
    *   Supports dynamic enabling/disabling and changing of `tracing_level` via GenServer calls.
*   **Dependencies**: `TraceDB`.

#### 2.2.5. `lib/elixir_scope/code_tracer.ex` (Function Call Tracer)

*   **Purpose**: Traces function calls and returns for specified modules.
*   **Key Implementation Details**:
    *   `handle_call({:trace_module, module}, ...)`:
        *   Sets up `:dbg.tracer/2` if not already enabled.
        *   Uses `:dbg.tpl(module, :_, [{'_', [], [{:return_trace}]}])` to trace all functions in the module and their return values.
        *   Attempts to get module source info via `module.__info__` and `Code.fetch_docs`.
    *   `handle_trace_msg({:trace, pid, :call, {module, function, args}})` and `handle_trace_msg({:trace, pid, :return_from, {module, function, arity}, result}})`:
        *   Record function call/return events to `TraceDB`.
        *   Arguments and results are sanitized using `inspect(term, limit: 50)`.
*   **Dependencies**: `TraceDB`.

#### 2.2.6. `lib/elixir_scope/state_recorder.ex` (GenServer State Tracer)

*   **Purpose**: Tracks state changes within GenServer processes.
*   **Key Implementation Details**:
    *   **Macro Instrumentation (`__using__` and `__before_compile__`)**:
        *   When `use ElixirScope.StateRecorder` is added to a GenServer:
            *   It overrides `init/1`, `handle_call/3`, `handle_cast/2`, `handle_info/2`, and `terminate/2`.
            *   The overridden callbacks log GenServer operation details (callback type, message, args) and state snapshots (before/after for handlers, after for init) to `TraceDB`.
            *   Uses `super(...)` to call the original user-defined callbacks.
            *   `@before_compile` ensures default implementations are provided if the user doesn't define a callback, allowing tracing to still function.
            *   State is sanitized via `inspect(state, limit: 50)`.
    *   **External Tracing (`trace_genserver/1`)**:
        *   For GenServers that cannot be modified with `use ElixirScope.StateRecorder`.
        *   Uses `:sys.trace(pid, true)` to enable system-level tracing for the GenServer.
        *   Uses `:sys.install(pid, {receiver_pid, nil}, {fun(:user), fun(:sys)})` to install a custom trace message handler (`handle_trace_messages/1` running in a spawned process).
        *   `handle_trace_messages/1` receives various trace tuples (e.g., `:receive`, `:call`, `:return_from`, `:state_change`, `:DOWN`) and records them to `TraceDB`.
        *   Attempts to log initial state using `:sys.get_state(pid)`.
*   **Dependencies**: `TraceDB`.

#### 2.2.7. `lib/elixir_scope/phoenix_tracker.ex` (Phoenix Application Tracer)

*   **Purpose**: Provides specialized tracing for Phoenix framework events.
*   **Key Implementation Details**:
    *   `setup_phoenix_tracing(endpoint \\ nil)`:
        *   Attaches telemetry handlers to various Phoenix events:
            *   `[:phoenix, :endpoint, :stop]`
            *   `[:phoenix, :router_dispatch, :stop]`
            *   `[:phoenix, :channel_join, :stop]`
            *   `[:phoenix, :socket_connected]`
            *   LiveView events (e.g., `[:phoenix, :live_view, :mount, :stop]`) if `Phoenix.LiveView` is loaded.
    *   Event handler functions (e.g., `handle_endpoint_event/4`):
        *   Extract relevant data from telemetry `measurements` and `metadata`.
        *   Record these Phoenix-specific events to `TraceDB`.
        *   Uses `sanitize_conn/1` and `sanitize_value/1` to limit data stored from complex objects like `Plug.Conn`.
*   **Dependencies**: `TraceDB`, `telemetry` (library).

#### 2.2.8. `lib/elixir_scope/query_engine.ex` (Data Querying & Analysis)

*   **Purpose**: Offers a high-level API for querying and analyzing trace data, enabling time-travel debugging.
*   **Key Implementation Details**:
    *   Most functions are wrappers around `TraceDB.query_events/1` or other `TraceDB` calls, adding filtering or specific logic.
    *   `get_state_at(pid, timestamp)`: Retrieves the state by calling `TraceDB.get_state_at/2`.
    *   `system_snapshot_at(timestamp)`:
        *   Calls `TraceDB.get_processes_at(timestamp)`.
        *   For each active PID, calls `get_state_at(pid, timestamp)`.
        *   Calls internal `get_pending_messages_at(timestamp)` which compares sent vs. received messages.
        *   Calls internal `reconstruct_supervision_tree_at(timestamp)` (currently a simplified version based on active PIDs, acknowledging more detailed tracing would be needed for full accuracy).
    *   `execution_timeline(start_time, end_time, filter_types \\ nil)`: Retrieves and sorts all events within a time window.
    *   `state_evolution(pid, start_time, end_time)`: Combines state, message, and function events for a PID to provide context for state changes, including potential causes (recent events) and diffs.
    *   `compare_states(state1, state2)`: Provides a basic diff for map states (added, removed, changed keys) or simple equality for others.
*   **Dependencies**: `TraceDB`.

#### 2.2.9. `lib/elixir_scope/ai_integration.ex` (AI Integration Layer)

*   **Purpose**: Integrates ElixirScope with AI systems, primarily Tidewave.
*   **Key Implementation Details**:
    *   `setup/0`: Checks if `Tidewave` is loaded and calls `register_tidewave_tools/0`.
    *   `register_tidewave_tools/0`:
        *   Uses `Tidewave.Plugin.register_tool/1` to register multiple specific tools (e.g., `elixir_scope_get_state_timeline`, `elixir_scope_get_message_flow`, `elixir_scope_trace_module`, `elixir_scope_get_supervision_tree`, `elixir_scope_analyze_state_changes`).
        *   Each tool definition includes a name, description, and specifies the implementing module/function within `AIIntegration` and its arguments.
    *   Tool implementation functions (`tidewave_get_state_timeline/1`, etc.):
        *   Decode input arguments (e.g., PID strings to PIDs using `decode_pid/1`, module names to atoms).
        *   Call appropriate `ElixirScope.QueryEngine` or `ElixirScope` API functions.
        *   Format the results for AI consumption, often using `summarize_event_data/1` to `inspect` complex terms with a limit, reducing verbosity.
*   **Dependencies**: `TraceDB`, `QueryEngine`, `CodeTracer`, `ElixirScope` (main module), `Tidewave` (library).

### 2.3. Build and Configuration

*   **`mix.exs`**:
    *   Elixir `~> 1.12`.
    *   Dependencies: `telemetry` (core), `ex_doc` (dev), optional `phoenix` and `phoenix_live_view`.
    *   Extra applications: `:logger`, `:runtime_tools`.
*   **`.gitignore`**: Standard Elixir/Erlang ignores.

### 2.4. Testing

*   `test/elixir_scope/process_observer_test.exs`: Contains thorough tests for `ProcessObserver`'s supervision tree logic, covering various scenarios like nested supervisors, dynamic children, and restarts. `TraceDB` is explicitly started in the test setup.

## 3. Sample Applications (`elixir_scope_sample_apps/`)

### 3.1. Plain Elixir Sample App

*   **Purpose**: Demonstrates ElixirScope usage in a non-Phoenix Elixir application.
*   **Structure**:
    *   `mix.exs`: Depends on ElixirScope via path (`../cursor`).
    *   `lib/elixir_sample_app/application.ex`:
        *   Initializes ElixirScope: `ElixirScope.setup(storage: :ets, trace_all: false, tracing_level: :full, sample_rate: 1.0)`.
        *   Supervises `Task.Supervisor`, `Registry`, `ElixirSampleApp.WorkerSupervisor`, and `ElixirSampleApp.JobQueue`.
    *   `lib/elixir_sample_app/worker.ex`: A GenServer that uses `use ElixirScope.StateRecorder` for automatic state tracking.
    *   `lib/elixir_sample_app/job_queue.ex`: Another GenServer using `use ElixirScope.StateRecorder`.
    *   `lib/elixir_sample_app/worker_supervisor.ex`: A `Supervisor` for managing worker processes dynamically, showcasing supervision tree tracking.
*   **Key Demonstrations**:
    *   ElixirScope setup in `application.ex`.
    *   Automatic state recording in GenServers via `use ElixirScope.StateRecorder`.
    *   Supervision tree construction and observation.

### 3.2. Phoenix Sample App

*   **Purpose**: Demonstrates ElixirScope integration with a Phoenix application.
*   **Structure**:
    *   `mix.exs`: Standard Phoenix setup, depends on ElixirScope via path (`../cursor`).
    *   `lib/phoenix_sample_app/application.ex`:
        *   Initializes ElixirScope: `ElixirScope.setup(phoenix: true, storage: :ets, tracing_level: :full, sample_rate: 1.0)`.
        *   Standard Phoenix application startup.
    *   `lib/phoenix_sample_app/counter.ex`: A simple GenServer using `use ElixirScope.StateRecorder`.
    *   `lib/phoenix_sample_app/elixir_scope_demo.ex`: A module with IEx-runnable functions to demonstrate:
        *   Analyzing state changes (`ElixirScope.state_timeline`).
        *   Module function call tracing (`ElixirScope.trace_module`, `QueryEngine.module_function_calls`).
        *   Time-travel debugging (`QueryEngine.system_snapshot_at`, `TraceDB.get_events_at`).
        *   Supervision tree visualization (`ProcessObserver.get_supervision_tree`).
*   **Key Demonstrations**:
    *   ElixirScope setup with `phoenix: true`.
    *   State recording in a GenServer within a Phoenix app.
    *   Practical examples of querying various trace data.
    *   Phoenix-specific tracing (implicitly enabled by `phoenix: true`).

## 4. Key Technical Aspects & Patterns Implemented

*   **Tracing Mechanisms**:
    *   **`:dbg`**: Heavily used by `MessageInterceptor` and `CodeTracer` for message and function call tracing.
    *   **`:sys.trace`**: Used by `StateRecorder` for tracing external GenServers and by `ProcessObserver` for some system events.
    *   **Telemetry**: Used by `PhoenixTracker` for Phoenix-specific events.
    *   **Process Monitoring**: `Process.flag(:trap_exit, true)` and `:erlang.system_monitor`.
*   **Data Storage**:
    *   **ETS**: The primary active storage mechanism for all trace data due to its performance characteristics for concurrent read/writes. Data is structured across multiple tables for events, states, and process indexing.
*   **Configuration**:
    *   Centralized setup via `ElixirScope.setup/1`.
    *   Fine-grained control through `:tracing_level` (e.g., `:full`, `:messages_only`, `:minimal`) and `:sample_rate` to manage performance overhead. These settings propagate to tracer modules.
*   **AI Integration (Tidewave)**:
    *   Robust integration via `Tidewave.Plugin.register_tool`, providing specific, well-described tools rather than a generic command handler.
    *   Data passed to AI is summarized/inspected with limits to avoid overwhelming the AI context.
*   **Modularity**: Clear separation of concerns between tracing components, storage, querying, and the main API.
*   **GenServer Usage**: Core components are GenServers, managing their own state and processes.
*   **Macro Metaprogramming**: `StateRecorder.__using__/1` effectively injects tracing code into user GenServers non-intrusively.
*   **Data Sanitization/Summarization**: Implemented in various places (`CodeTracer`, `MessageInterceptor`, `StateRecorder`, `PhoenixTracker`, `AIIntegration`) to manage the volume and complexity of stored/displayed data (e.g., `inspect` with limits).

## 5. Summary of Current State

ElixirScope is a well-developed library with a comprehensive feature set for debugging Elixir applications. Its core functionalities for tracing processes, messages, function calls, and GenServer states are implemented and configurable. The data storage in ETS is functional, and the query engine provides powerful ways to inspect this data, including time-travel capabilities. The AI integration with Tidewave is mature, offering a range of specific tools. The sample applications effectively demonstrate how to integrate and use the library in both plain Elixir and Phoenix contexts. The project shows evidence of careful design regarding performance and usability.
