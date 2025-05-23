Here is a detailed technical checklist for building the foundational layer of ElixirScope, based on the provided documents (especially `006-g-foundation-responseToClaude.md` and `008-g-prd.md`). It incorporates a layered construction and testing strategy, ensuring each sub-layer is robust before proceeding.

**Methodology:**

*   **Layered Build:** The foundation itself is broken down into sequential layers (0-6).
*   **Layered Testing:** Each layer includes specific Unit, Integration, and Layer-Level Acceptance Tests. All tests for a given layer *must* be passing before development begins on the next layer.
*   **Focus:** This checklist focuses on Phase 1 ("Intelligent Auto-Instrumentation & Core Capture Foundation") of the ElixirScope PRD.

---

## Foundational Layer (Phase 1) - Technical Checklist

### Layer 0: Core Data Structures, Configuration & Utilities

**Goal:** Define the fundamental data types, configuration handling, and basic utilities used across the system.

**Technical Tasks:**

*   `[ ]` **`ElixirScope.Config`:**
    *   `[ ]` Define a module to handle loading configuration from `config.exs`.
    *   `[ ]` Support dynamic configuration (e.g., via Application env or a GenServer).
    *   `[ ]` Define keys for AI settings, instrumentation levels, storage paths, sampling rates, ring buffer sizes, etc.
    *   `[ ]` Implement validation for configuration values.
*   `[ ]` **`ElixirScope.Event` (and related structs):**
    *   `[ ]` Define core event structures (e.g., `FunctionEntry`, `FunctionExit`, `StateChange`, `MessageSend`, `MessageReceive`, `ProcessSpawn`, `ProcessExit`).
    *   `[ ]` Ensure all events include: `event_id` (unique), `timestamp` (high-resolution), `pid`, `node`, `correlation_id` (optional, for linking).
    *   `[ ]` Implement efficient (binary) serialization/deserialization for events.
    *   `[ ]` Define `ElixirScope.InstrumentationPlan` struct (declarative map/struct).
*   `[ ]` **`ElixirScope.Utils`:**
    *   `[ ]` Implement high-resolution timestamp generation.
    *   `[ ]` Implement a unique ID generator (scalable and fast).
    *   `[ ]` Implement helper functions for safe data inspection/truncation (to avoid large terms in events).

**Layer 0 Testing Strategy:**

*   **Unit Tests:**
    *   `[ ]` Test `ElixirScope.Config` loading from files and env.
    *   `[ ]` Test `ElixirScope.Config` validation logic (valid and invalid cases).
    *   `[ ]` Test `ElixirScope.Event` struct creation and default values.
    *   `[ ]` Test event serialization/deserialization for all event types (round-trip).
    *   `[ ]` Test `ElixirScope.Utils` functions (timestamp resolution, ID uniqueness).
*   **Layer-Level Acceptance Tests:**
    *   `[ ]` Test that a minimal ElixirScope application can start and load a default configuration successfully.

---

### Layer 1: High-Performance Ingestion & "Hot Path" Storage

**Goal:** Build the core, non-blocking event capture pipeline, including the ring buffer and immediate ETS storage. *Performance is paramount here*.

**Technical Tasks:**

*   `[ ]` **`ElixirScope.Capture.RingBuffer`:**
    *   `[ ]` Implement a lock-free, concurrent-safe ring buffer using `:persistent_term` and `:atomics`.
    *   `[ ]` Support multiple, configurable buffer instances (sharded or per-scheduler).
    *   `[ ]` Implement `write/2` (non-blocking, fast) and `read/2` (blocking/non-blocking options).
    *   `[ ]` Implement overflow detection and strategy (e.g., drop oldest, signal).
*   `[ ]` **`ElixirScope.Capture.Ingestor`:**
    *   `[ ]` Implement public functions (not a GenServer) for receiving events.
    *   `[ ]` Implement `ingest/1`: assigns timestamp/ID, serializes, writes to `RingBuffer`.
    *   `[ ]` Ensure *minimal* logic and <1µs execution time target.
*   `[ ]` **`ElixirScope.Capture.InstrumentationRuntime` (Initial Stubs):**
    *   `[ ]` Define the public API functions (`enter_function`, `exit_function`, etc.).
    *   `[ ]` Implement *basic* versions that format an event and call `Ingestor.ingest/1`.
*   `[ ]` **`ElixirScope.Storage.DataAccess` (ETS Backend):**
    *   `[ ]` Implement ETS table creation and management for "hot" events (indexed by `event_id`, `timestamp`, `pid`).
    *   `[ ]` Implement `write_event/1` and `write_batch/1` to ETS.
    *   `[ ]` Implement basic `get_event/1`, `get_events_by_pid/2`, `get_events_by_time/2`.
    *   `[ ]` Implement ETS data pruning based on time or count.

**Layer 1 Testing Strategy:**

*   **Unit Tests:**
    *   `[ ]` Test `RingBuffer` `write/2` and `read/2` logic.
    *   `[ ]` Test `RingBuffer` overflow handling.
    *   `[ ]` Test `Ingestor` event formatting and `RingBuffer` interaction.
    *   `[ ]` Test `DataAccess` ETS operations (write, read, index, prune).
*   **Property-Based Tests:**
    *   `[ ]` Test `RingBuffer` under high concurrency (multiple writers, multiple readers) to find race conditions.
*   **Integration Tests:**
    *   `[ ]` Test `InstrumentationRuntime` -> `Ingestor` -> `RingBuffer` flow.
*   **Performance Tests:**
    *   `[ ]` Benchmark `Ingestor.ingest/1` execution time (must be <1µs average).
    *   `[ ]` Benchmark `RingBuffer` throughput (target >100k events/sec).
    *   `[ ]` Benchmark `DataAccess` ETS write/read speeds.
*   **Layer-Level Acceptance Tests:**
    *   `[ ]` Test that events sent via `InstrumentationRuntime` can be written to the `RingBuffer` without blocking or errors under moderate load. (Reading/processing is *not* tested yet).

---

### Layer 2: Asynchronous Processing & Enrichment

**Goal:** Build the "off-ramp" from the ring buffer to process, enrich, and store events asynchronously.

**Technical Tasks:**

*   `[ ]` **`ElixirScope.Capture.PipelineManager`:**
    *   `[ ]` Implement a supervisor to manage `RingBuffer`s and `AsyncWriterPool`.
*   `[ ]` **`ElixirScope.Storage.AsyncWriterPool`:**
    *   `[ ]` Implement a pool of GenServer workers (e.g., using `Poolboy` or custom supervision).
    *   `[ ]` Implement workers that read from `RingBuffer`, deserialize, and handle events.
    *   `[ ]` Implement backpressure handling (if `RingBuffer` reads need to pause).
*   `[ ]` **`ElixirScope.EventCorrelator` (Basic):**
    *   `[ ]` Implement logic (likely within `AsyncWriterPool` workers initially) to:
        *   Assign/manage call IDs for function entry/exit.
        *   Assign/manage message IDs for send/receive (requires state or lookups).
        *   Identify parent/child relationships for process spawns.
    *   `[ ]` Add correlation data to event structs.
*   `[ ]` **`ElixirScope.Storage.DataAccess` (Enhancements):**
    *   `[ ]` Update `write_event` to handle enriched/correlated events.
    *   `[ ]` Add indexes for correlation IDs.
    *   `[ ]` (Optional) Implement initial disk-based storage (e.g., Mnesia or file-based) for "warm" data, and implement tiering (ETS -> Disk).

**Layer 2 Testing Strategy:**

*   **Unit Tests:**
    *   `[ ]` Test `AsyncWriterPool` worker event processing logic (deserialization, enrichment).
    *   `[ ]` Test `EventCorrelator` linking logic for various scenarios (simple calls, messages, spawns).
    *   `[ ]` Test `DataAccess` tiered storage (if implemented).
*   **Integration Tests:**
    *   `[ ]` Test the *full* pipeline: `Runtime` -> `Ingestor` -> `RingBuffer` -> `AsyncWriterPool` -> `EventCorrelator` -> `DataAccess`.
    *   `[ ]` Test backpressure mechanism between `AsyncWriterPool` and `RingBuffer`.
*   **Load Tests:**
    *   `[ ]` Simulate high event rates to ensure the async pool can keep up and `RingBuffer` doesn't permanently overflow.
*   **Layer-Level Acceptance Tests:**
    *   `[ ]` Verify that a sequence of simulated events (e.g., a process spawning another, sending a message, calling a function) is correctly captured, correlated, and stored in ETS/Disk.
    *   `[ ]` Verify that events are pruned correctly from ETS.

---

### Layer 3: AST Transformation & Instrumentation Engine

**Goal:** Build the system that modifies Elixir code at compile time to inject tracing calls.

**Technical Tasks:**

*   `[ ]` **`ElixirScope.AST.InjectorHelpers`:**
    *   `[ ]` Create functions that generate `quote` blocks for:
        *   Wrapping function bodies.
        *   Capturing arguments and return values.
        *   Capturing GenServer state before/after callbacks.
        *   Capturing specific variable assignments (advanced).
*   `[ ]` **`ElixirScope.AST.Transformer`:**
    *   `[ ]` Implement `Macro.traverse/3` based logic.
    *   `[ ]` Implement logic to receive an AST and instrumentation directives (from the future AI planner).
    *   `[ ]` Use `InjectorHelpers` to modify the AST according to directives.
    *   `[ ]` Ensure it handles scopes, variables, and macro expansion contexts correctly.
    *   `[ ]` Implement initial support for `GenServer` callbacks and standard function definitions.
    *   `[ ]` Implement basic macro handling (e.g., ability to *not* instrument inside certain macros, or instrument common ones like `use GenServer`).
*   `[ ]` **`ElixirScope.Capture.InstrumentationRuntime` (Full Implementation):**
    *   `[ ]` Ensure all API functions are implemented efficiently and robustly.

**Layer 3 Testing Strategy:**

*   **Unit Tests:**
    *   `[ ]` Test each `InjectorHelpers` function to ensure it generates correct `quote` blocks.
    *   `[ ]` Test `AST.Transformer` logic for specific transformations (function wrapping, GenServer callbacks).
*   **Integration Tests:**
    *   `[ ]` Test that `AST.Transformer` correctly uses `InjectorHelpers`.
*   **Semantic Equivalence Tests:**
    *   `[ ]` Create a suite of sample Elixir modules (simple functions, GenServers, macros).
    *   `[ ]` Compile them *without* instrumentation and run tests to verify their behavior.
    *   `[ ]` Compile them *with* instrumentation (using a *mock* instrumentation plan) and run the *same* tests to ensure the core logic hasn't changed.
    *   `[ ]` Verify (manually or via other tests) that the instrumented versions *also* call `InstrumentationRuntime` functions as expected.
*   **Layer-Level Acceptance Tests:**
    *   `[ ]` Demonstrate that a small Mix project can be compiled with the `AST.Transformer` (manually invoked for now), and the resulting beam files contain calls to `ElixirScope.Capture.InstrumentationRuntime`.

---

### Layer 4: AI Analysis & Planning Engine

**Goal:** Build the "brain" that analyzes code and decides what to instrument.

**Technical Tasks:**

*   `[ ]` **`ElixirScope.AI.CodeAnalyzer`:**
    *   `[ ]` Implement logic to parse Elixir source code into ASTs (or use compiler hooks).
    *   `[ ]` Implement static analysis rules/heuristics to identify:
        *   GenServer modules and callbacks.
        *   Supervisor trees.
        *   Basic message passing (`call`/`cast`/`send`).
    *   `[ ]` (Optional) Implement an interface for an LLM to receive code/AST and return structured analysis (use a mock LLM initially).
    *   `[ ]` Output a structured representation of the codebase.
*   `[ ]` **`ElixirScope.AI.InstrumentationPlanner`:**
    *   `[ ]` Implement logic to take `CodeAnalyzer` output and `Config`.
    *   `[ ]` Implement *rule-based* plan generation (e.g., "always trace GenServer callbacks," "trace functions > 50 lines").
    *   `[ ]` (Optional) Implement logic to use LLM analysis to generate a plan (use a mock LLM initially).
    *   `[ ]` Output a valid `ElixirScope.InstrumentationPlan`.
*   `[ ]` **`ElixirScope.AI.Orchestrator`:**
    *   `[ ]` Implement a GenServer/Agent to manage the analysis/planning process.
    *   `[ ]` Implement caching for analysis results and plans.
    *   `[ ]` Provide an API to request/retrieve an instrumentation plan.

**Layer 4 Testing Strategy:**

*   **Unit Tests:**
    *   `[ ]` Test `CodeAnalyzer` static analysis rules against various code samples.
    *   `[ ]` Test `InstrumentationPlanner` rule-based plan generation for different configs.
    *   `[ ]` Test `Orchestrator` state management and API calls (using mock analyzers/planners).
*   **Integration Tests:**
    *   `[ ]` Test `Orchestrator` -> `CodeAnalyzer` -> `InstrumentationPlanner` flow.
*   **Accuracy Tests:**
    *   `[ ]` Run `CodeAnalyzer` on several open-source Elixir projects and manually verify its identification of OTP components.
    *   `[ ]` Verify that generated `InstrumentationPlan`s are sensible and correctly formatted.
*   **Layer-Level Acceptance Tests:**
    *   `[ ]` Demonstrate that the `Orchestrator` can receive a request for a project path, run analysis and planning, and return a valid `InstrumentationPlan`.

---

### Layer 5: VM Tracing & Full Integration

**Goal:** Add supplementary VM tracing and integrate all components via the Mix compiler and main supervisor.

**Technical Tasks:**

*   `[ ]` **`ElixirScope.Capture.VMTracer`:**
    *   `[ ]` Implement basic `:erlang.trace` usage for `spawn`, `exit`, `link`/`unlink`.
    *   `[ ]` Implement basic `:sys.trace` for GenServer events (as a fallback or for uninstrumented code).
    *   `[ ]` Ensure it formats events and sends them to `Capture.Ingestor`.
    *   `[ ]` Implement configuration to enable/disable/filter VM tracing.
*   `[ ]` **`ElixirScope.Compiler.MixTask`:**
    *   `[ ]` Implement a custom `Mix.Task.Compiler`.
    *   `[ ]` Ensure it runs *before* the standard Elixir compiler (or correctly integrates).
    *   `[ ]` Implement logic to fetch the plan from `AI.Orchestrator`.
    *   `[ ]` Implement logic to invoke `AST.Transformer` on each module's AST.
    *   `[ ]` Handle code reloading scenarios (triggering re-analysis/re-instrumentation).
*   `[ ]` **`ElixirScope` (Main Application & Supervisor):**
    *   `[ ]` Create the main `ElixirScope` application.
    *   `[ ]` Build the top-level supervisor tree, starting `Config`, `AI.Orchestrator`, `Capture.PipelineManager`, `Storage.DataAccess` (if it has state), etc.
    *   `[ ]` Implement `start/1` and `stop/0` functions.

**Layer 5 Testing Strategy:**

*   **Unit Tests:**
    *   `[ ]` Test `VMTracer` event capture and formatting for specific VM events.
*   **Integration Tests:**
    *   `[ ]` Test `MixTask` integration with `AI.Orchestrator` and `AST.Transformer`.
    *   `[ ]` Test the `ElixirScope` supervisor startup/shutdown sequence.
*   **End-to-End Tests (Foundation E2E):**
    *   `[ ]` Create a sample Mix project.
    *   `[ ]` Configure it to use the `ElixirScope.Compiler.MixTask`.
    *   `[ ]` Compile the project.
    *   `[ ]` Run the project.
    *   `[ ]` Verify that the `MixTask` runs, `AST.Transformer` modifies code, `InstrumentationRuntime` calls are made, `VMTracer` captures events, and events flow through the *entire* pipeline (`Ingestor` -> `RingBuffer` -> `AsyncWriter` -> `DataAccess`).
*   **Layer-Level Acceptance Tests:**
    *   `[ ]` Demonstrate that enabling ElixirScope in a standard Mix project automatically instruments it and captures basic execution events into ETS *without manual intervention* beyond initial setup.

---

### Layer 6: Basic Querying & API

**Goal:** Expose the captured data through a basic API and IEx helpers.

**Technical Tasks:**

*   `[ ]` **`ElixirScope.Storage.QueryCoordinator`:**
    *   `[ ]` Implement APIs (using `DataAccess`) to:
        *   Get events for a PID in a time range.
        *   Get GenServer state timeline for a PID.
        *   Trace a message flow (send -> receive) using correlation IDs.
        *   Get a simple call stack using correlation IDs.
*   `[ ]` **`ElixirScope.IExHelpers`:**
    *   `[ ]` Create a module with helper functions for IEx:
        *   `ElixirScope.status()`
        *   `ElixirScope.trace_pid(pid)` (uses `QueryCoordinator`).
        *   `ElixirScope.state_history(pid)` (uses `QueryCoordinator`).
        *   `ElixirScope.trigger_ai_analysis()`.
*   `[ ]` **(Optional) Tidewave Integration (Basic):**
    *   `[ ]` Register `QueryCoordinator` functions as Tidewave tools.

**Layer 6 Testing Strategy:**

*   **Unit Tests:**
    *   `[ ]` Test each `QueryCoordinator` function against mock `DataAccess` data.
*   **Integration Tests:**
    *   `[ ]` Test `QueryCoordinator` functions against the *real* `DataAccess` (using data generated by E2E tests from Layer 5).
*   **User Acceptance Tests (UAT):**
    *   `[ ]` Use `IExHelpers` in an IEx session on a running, instrumented application and verify the output is correct and useful.
    *   `[ ]` If Tidewave is integrated, test basic natural language queries.
*   **Layer-Level Acceptance Tests:**
    *   `[ ]` Demonstrate that a developer can, using only IEx, inspect the basic execution history (processes, states, messages) of an ElixirScope-instrumented application.

---

This detailed checklist provides a structured path to building a robust foundation for ElixirScope. By ensuring each layer is thoroughly tested before moving to the next, you increase the likelihood of a stable, high-performance core system upon which the advanced "Execution Cinema" features can be built.
