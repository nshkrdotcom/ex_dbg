Okay, let's craft a detailed Product Requirements Document (PRD) for **ElixirScope**, focusing on achieving the "Grand Plan for AI-Powered Execution Cinema Debugger." This PRD will cover the overall vision, target audience, features (phased), and success metrics.

---

**Product Requirements Document: ElixirScope - AI-Powered Execution Cinema Debugger**

**1. Introduction**

*   **1.1. Purpose:** This document outlines the requirements for ElixirScope, a next-generation debugging and observability platform for Elixir applications running on the BEAM/OTP. ElixirScope aims to revolutionize how developers understand, debug, and optimize complex concurrent and distributed Elixir systems by providing an AI-driven, "execution cinema" experience with total behavioral recall and intuitive time-travel debugging capabilities.
*   **1.2. Vision:** To make debugging highly concurrent Elixir applications as intuitive and insightful as watching a perfectly annotated film of their execution, where developers can effortlessly navigate through time, across processes, and zoom from system-wide views down to individual variable changes, all guided by intelligent, AI-powered analysis.
*   **1.3. Target Audience:**
    *   **Primary:** Mid-to-Senior Elixir/Phoenix developers working on complex, concurrent, or distributed applications.
    *   **Secondary:** DevOps engineers managing BEAM-based production systems; Junior Elixir developers needing to quickly understand system behavior; Technical leads and architects designing and troubleshooting OTP systems.
*   **1.4. Goals:**
    *   Dramatically reduce the time and effort required to diagnose and resolve bugs in Elixir systems.
    *   Provide unprecedented visibility into the runtime behavior of concurrent processes and their interactions.
    *   Enable "total recall" of application execution for precise historical analysis and time-travel debugging.
    *   Automate significant parts of the instrumentation and analysis process using AI.
    *   Make advanced BEAM/OTP debugging techniques accessible to a broader range of Elixir developers.
*   **1.5. Non-Goals (for initial major versions):**
    *   Full replacement for traditional APM solutions (though it provides deep observability).
    *   Real-time, active system modification or "self-healing" (this is a very long-term vision).
    *   Debugging for languages other than Elixir (though Erlang interop might be partially covered).
    *   Support for non-BEAM platforms.

**2. Competitive Landscape & ElixirScope's Unique Value Proposition**

*   **2.1. Existing Tools & Limitations:** (As summarized previously: `:observer`, `:dbg`, APMs like Honeybadger/AppSignal, traditional debuggers like ElixirLS, tracing tools like Rexbug, specific tools like LiveDebugger). None offer the combination of AI-driven automatic instrumentation, total recall for concurrent systems, and visual time-travel with deep causal analysis.
*   **2.2. ElixirScope's Differentiators ("Execution Cinema" Advantage):**
    1.  **AI-First Instrumentation & Analysis:** Proactively understands code and guides debugging.
    2.  **Total Behavioral Recall:** Captures comprehensive execution history, avoiding sampling limitations for deep debugging.
    3.  **Multi-Dimensional Execution Model:** Correlates events across temporal, process, state, code, data, performance, and causality dimensions (the 7 DAGs).
    4.  **Visual Time-Travel Interface:** Intuitive "scrubbing" and navigation through complex concurrent executions.
    5.  **BEAM-Native & Concurrency-Aware:** Designed from the ground up for OTP patterns.

**3. Product Features & Phasing**

This PRD outlines a multi-phase approach. Each phase builds upon the last, delivering incremental value. The foundational layers from previous discussions map directly into this.

---

**Phase 1: Intelligent Auto-Instrumentation & Core Capture Foundation (Months 1-6)**

*   **Goal:** Establish AI-driven instrumentation strategy, compile-time AST transformation, and a high-performance, total-recall event capture pipeline. Provide basic data access for developers.
*   **Core Epic:** Build the `Intelligent Capture & Contextualization Foundation` (as detailed in the revised Layer 1 plan).

*   **3.1. Feature: AI-Powered Code Analysis Engine (`ElixirScope.AI.CodeAnalyzer`)**
    *   **3.1.1.** User can point ElixirScope at their project.
    *   **3.1.2.** AI (LLM and/or advanced heuristics) performs static analysis of Elixir source code to identify:
        *   GenServer modules and their callback structures.
        *   Supervisor modules and their child specifications.
        *   Common message passing patterns (e.g., `GenServer.call/cast`, `send/receive`).
        *   Potentially complex or critical functions/modules.
    *   **3.1.3.** Outputs a structured analysis of the codebase.
    *   *(Acceptance Criteria: Successfully analyzes a moderately complex open-source Elixir project and identifies key OTP components.)*

*   **3.2. Feature: AI-Driven Instrumentation Planner (`ElixirScope.AI.InstrumentationPlanner`)**
    *   **3.2.1.** Takes code analysis output and user-configurable "intent" (e.g., "debug performance," "trace state corruption," "full recall dev mode").
    *   **3.2.2.** Generates a declarative instrumentation plan specifying:
        *   Modules, functions, specific lines, or GenServer callbacks to instrument.
        *   Type of instrumentation (e.g., log entry/exit, capture args/return, capture state before/after, trace specific variable assignments).
    *   **3.2.3.** Balances desired detail with estimated performance impact based on AI heuristics.
    *   *(Acceptance Criteria: Generates a coherent instrumentation plan for various intents. Plan clearly specifies what needs to be traced.)*

*   **3.3. Feature: Compile-Time AST Auto-Instrumentation Engine (`ElixirScope.Compiler.MixTask`, `ElixirScope.AST.Transformer`)**
    *   **3.3.1.** Integrates as a custom Mix compiler.
    *   **3.3.2.** Reads the AI-generated instrumentation plan.
    *   **3.3.3.** Transforms the AST of targeted modules to inject calls to `ElixirScope.Capture.InstrumentationRuntime` functions.
    *   **3.3.4.** Preserves original code semantics, line numbers, and debug information.
    *   **3.3.5.** Handles common Elixir constructs, including macros (basic support initially, expanded over time).
    *   *(Acceptance Criteria: Instrumented code compiles and runs correctly. Injected calls are made as per the plan. Performance overhead of the compilation step is acceptable.)*

*   **3.4. Feature: High-Performance Event Capture Pipeline (`ElixirScope.Capture.*` modules)**
    *   **3.4.1. `InstrumentationRuntime`:** Provides lightweight target functions called by instrumented code.
    *   **3.4.2. `VMTracer`:** Captures essential VM-level events (process lifecycle, unhandled errors) missed by AST or for non-instrumented code.
    *   **3.4.3. `Ingestor`:** Receives events, performs minimal serialization, writes to `RingBuffer`.
    *   **3.4.4. `RingBuffer`:** Lock-free, concurrent-safe, persistent-term based buffer for ultra-fast event staging.
    *   *(Acceptance Criteria: Ingestion path (runtime call to ring buffer write) has sub-microsecond overhead per event. Ring buffer handles >100k events/sec. Stable under high load.)*

*   **3.5. Feature: Asynchronous Event Processing & Storage Foundation (`ElixirScope.Storage.*` modules)**
    *   **3.5.1. `AsyncWriterPool`:** Consumes events from `RingBuffer`(s).
    *   **3.5.2. Initial `EventCorrelator`:** Assigns event IDs, parent IDs, and basic causal links (e.g., message send ID -> receive ID, call ID -> return ID).
    *   **3.5.3. `DataAccess` (Basic - "Hot/Warm Store"):**
        *   Stores enriched, correlated events in ETS (for recent "hot" data, ~last 15-60 mins).
        *   Implements basic indexing (PID, timestamp, event type, module/function).
        *   Implements pruning of old ETS data.
        *   (Optional for Phase 1: Initial persistence to disk for "warm" data beyond ETS).
    *   **3.5.4. `QueryCoordinator` (Basic):**
        *   API to retrieve event streams (e.g., all events for a PID, events in a time range).
        *   API to reconstruct state timeline for a GenServer (from captured state_change events).
        *   API to get message flow between PIDs.
    *   *(Acceptance Criteria: Events are reliably processed from ring buffer to ETS. Basic queries are functional and reasonably performant. Pruning works.)*

*   **3.6. User Experience (Phase 1 - CLI/API for developers/early AI):**
    *   **3.6.1.** Simple Mix tasks to trigger `ElixirScope.start/stop` with configurations.
    *   **3.6.2.** Basic CLI or IEx functions to invoke `AI.CodeAnalyzer` and `AI.InstrumentationPlanner` and inspect the plan.
    *   **3.6.3.** Programmatic access to `QueryCoordinator` for retrieving trace data.
    *   **3.6.4.** Initial (experimental) Tidewave integration exposing Phase 1 query capabilities.

---

**Phase 2: Execution Cinema Core - Visualization & Time-Travel (Months 7-12)**

*   **Goal:** Implement the core "Execution Cinema" UI for visualizing traces and enabling time-travel. Materialize key DAGs.
*   **Core Epic:** Build the `Visual Execution Cinema Interface` (basic version) and evolve `Storage` to support the 7 DAGs.

*   **3.7. Feature: Multi-Dimensional Event Correlation & DAG Materialization (`ElixirScope.EventCorrelator` enhanced, `ElixirScope.DAGs.*`)**
    *   **3.7.1.** Real-time (or near real-time) construction and persistence of core DAGs:
        *   Temporal DAG (basic timeline).
        *   Process Interaction DAG (message flows, links, spawn tree).
        *   State Evolution DAG (GenServer state changes linked to causal events).
        *   Code Execution DAG (function call graphs).
    *   **3.7.2.** Storage layer (`DataAccess`) enhanced to store and query these DAG structures efficiently.
    *   *(Acceptance Criteria: Core DAGs are built correctly. Queries across DAGs are possible, e.g., "find all messages that led to this state change.")*

*   **3.8. Feature: Basic "Execution Cinema" Web UI (`ElixirScope.CinemaUI` - Initial Version)**
    *   **3.8.1. Main Timeline View:** Visual representation of events over time (Temporal DAG). Selectable processes/event types.
    *   **3.8.2. Process View:** Visualization of the process tree and message flows between selected processes (Process Interaction DAG).
    *   **3.8.3. State View:** For a selected GenServer, display its state timeline and diffs between states (State Evolution DAG).
    *   **3.8.4. Code View (Basic):** When an event is selected, show the relevant source code line. Display captured arguments/return values/state.
    *   **3.8.5. Timeline Scrubber:** Basic ability to navigate forward/backward through the global timeline or a process-specific timeline.
    *   **3.8.6.** Synchronized selection: Clicking an event in one view highlights related context in others.
    *   *(Acceptance Criteria: Users can load traces and navigate basic views. Time scrubbing is functional. Basic cross-view correlation is evident.)*

*   **3.9. Feature: Perfect State Reconstruction API (`QueryCoordinator` / `ExecutionEngine` conceptual)**
    *   **3.9.1.** Given a timestamp and PID, accurately reconstruct the *full captured state* of that GenServer by applying diffs from the nearest snapshot.
    *   **3.9.2.** API to reconstruct variable values within a function's scope at a specific event point (if traced by AI plan).
    *   *(Acceptance Criteria: State reconstruction is accurate and reasonably fast for recently captured data.)*

*   **3.10. Feature: Initial Causal Exploration**
    *   **3.10.1.** From an event in the UI, allow user to "jump to causing event" (e.g., from state change to incoming message, from message receive to message send).
    *   *(Acceptance Criteria: Basic causal links can be traversed in the UI.)*

---

**Phase 3: Advanced UX, AI Analysis & Phoenix Integration (Months 13-18)**

*   **Goal:** Mature the UI, integrate sophisticated AI-driven analysis and explanations, and provide deep Phoenix-specific tracing.
*   **Core Epic:** Advanced Visualizations, AI Analysis Engine, Deep Framework Integrations.

*   **3.11. Feature: Advanced "Execution Cinema" UI (`ElixirScope.CinemaUI` Enhanced)**
    *   **3.11.1. Multi-Scale Zoom:** Implement zoom levels from System (forest) to Module (tree) to Code (microscope) as per Grand Plan.
    *   **3.11.2. Full DAG Visualizations:** Interactive visualizations for all 7 DAGs.
    *   **3.11.3. Concurrent Path Visualization:** Methods to show interleaved execution paths.
    *   **3.11.4.** Advanced filtering and search across all dimensions.
*   **3.12. Feature: AI-Powered Analysis & Insights Engine (`ElixirScope.AI.AnalysisEngine`)**
    *   **3.12.1.** **Anomaly Detection:** Identifies deviations from normal behavioral models (built by `AI.CodeAnalyzer` or learned over time).
    *   **3.12.2.** **Bottleneck Identification:** Analyzes `Performance DAG` and timing data to highlight slow functions/processes.
    *   **3.12.3.** **Basic Race/Deadlock Hints:** Based on `Causality DAG` and message patterns.
    *   **3.12.4.** **"Explain This Event/Behavior":** Natural language explanations in the UI, using context from all DAGs and AI reasoning (potentially via RAG).
    *   **3.12.5.** (Stretch) Suggests potential bug causes or areas to investigate.
*   **3.13. Feature: Deep Phoenix/LiveView Integration**
    *   **3.13.1.** AI Code Analyzer specifically identifies Phoenix controllers, LiveViews, channels, Ecto repos.
    *   **3.13.2.** Instrumentation Planner creates strategies to trace:
        *   Request lifecycles through plugs and controllers.
        *   LiveView `mount`, `handle_event`, `handle_info` with `assigns` diffing.
        *   Component tree rendering and updates.
        *   Channel message flows and state.
        *   Ecto query execution (possibly via Telemetry integration initially, or AST transformation of Repo calls).
    *   **3.13.3.** Specialized UI views in "Execution Cinema" for Phoenix contexts.
*   **3.14. Feature: Adaptive Detail & Intelligent Filtering in Capture**
    *   Instrumentation Planner can dynamically adjust tracing detail based on AI detecting anomalies or specific user "debug intent".
    *   Event Ingestor or AsyncWriters can intelligently filter "noise" based on context or AI rules, while still enabling "total recall" for periods of interest.

---

**Phase 4 & Beyond (Post 18 Months - Production Readiness & Expansion)**

*   **3.15. Production Mode Enhancements:**
    *   Robust adaptive sampling based on system load and error rates (if "total recall" proves too costly for some prod scenarios).
    *   Hardened security for production data.
    *   Alerting integration with existing monitoring systems.
    *   Performance overhead rigorously profiled and optimized to be <<1% for common production instrumentation strategies.
*   **3.16. Distributed Tracing & Multi-Node Correlation:**
    *   Capture and correlate events across a distributed Elixir cluster.
    *   Global logical clocks / trace IDs for distributed causality.
*   **3.17. Collaborative Debugging:** Sharing "execution cinema" recordings, annotations.
*   **3.18. ElixirLS Orchestration (Claude's vision):** AI using ElixirScope data to actively drive ElixirLS breakpoints and stepping.
*   **3.19. NIF-based VM Hooks (Research):** For ultra-low-level or performance-critical tracing if standard BEAM tracing is insufficient.

**4. Non-Functional Requirements**

*   **4.1. Performance (Capture):**
    *   **P0:** Event capture hot path (instrumented call -> ring buffer write) must average <1µs per event.
    *   **P0:** Impact of base instrumentation (even if AI decides to trace minimally) on a typical Phoenix app request-response time must be <1-2%.
    *   **P1:** AI-driven "full recall" instrumentation impact in development mode should be manageable (e.g., <10-20% slowdown).
*   **4.2. Performance (Storage & Querying):**
    *   **P0:** Basic queries on "hot" ETS data (e.g., state timeline for a PID, last N messages) should return in <50ms.
    *   **P1:** Reconstruction of full GenServer state at a recent timestamp: <100ms.
    *   **P1:** "Execution Cinema" UI scrubbing for recent data should feel responsive.
*   **4.3. Scalability:**
    *   **P0:** Capture pipeline must handle sustained bursts of >100,000 events/second without dropping data (utilizing ring buffers and async processing).
    *   **P1:** System should gracefully handle projects with thousands of modules and tens of thousands of functions for AI analysis and instrumentation planning.
    *   **P2:** Architecture should allow for scaling storage and analysis components independently in the future (e.g., for a SaaS version).
*   **4.4. Reliability & Stability:**
    *   **P0:** ElixirScope itself must not crash the application it's instrumenting. Robust error handling in all tracing components.
    *   **P0:** Instrumentation should be "semantically transparent" – not alter the logical behavior of the instrumented code.
*   **4.5. Usability:**
    *   **P0 (Phase 1):** Easy for developers to integrate into a Mix project (e.g., add dep, modify `compilers`).
    *   **P1 (Phase 2+):** "Execution Cinema" UI must be intuitive for navigating complex concurrent systems.
*   **4.6. Maintainability:**
    *   **P1:** AST transformation logic must be well-tested and adaptable to Elixir language changes.
    *   **P1:** AI models and heuristics should be versionable and configurable.

**5. User Interaction & Design (High-Level for "Execution Cinema")**

*   **5.1. Main Views:**
    *   **System Overview:** Topological graph of processes, real-time message flow visualization.
    *   **Timeline View:** Master timeline with events, filterable by process/type. Scrubbable.
    *   **Process/Module/Code Views:** Hierarchical drill-down from system to code line.
*   **5.2. Key Interactions:**
    *   Global time scrubbing.
    *   Selecting a process filters views to its context.
    *   Clicking an event shows its details and highlights causally related events.
    *   "Explain this" AI interaction for selected events or time ranges.
*   **5.3. Data Display:**
    *   Process states shown as diffs.
    *   Function arguments/return values displayed alongside code.
    *   Messages shown with content and timing.
    *   Concurrency visualized (e.g., swimlanes, sequence diagrams adapted for OTP).

**6. Success Metrics**

*   **Phase 1:**
    *   Number of OTP patterns correctly identified by `AI.CodeAnalyzer`.
    *   Percentage of codebase successfully auto-instrumented based on a simple AI plan.
    *   Event ingestion rate (events/sec into RingBuffer).
    *   Overhead of basic (AI-minimal) instrumentation on standard benchmarks.
*   **Phase 2:**
    *   Time to load and display basic "Execution Cinema" views for a moderately sized trace.
    *   Accuracy of state reconstruction for past events.
    *   User feedback on UI intuitiveness for timeline navigation.
*   **Phase 3:**
    *   Effectiveness of AI anomaly detection (precision/recall).
    *   Time saved by developers diagnosing a set of sample bugs using ElixirScope vs. traditional methods.
    *   Adoption rate within a beta program.
    *   Successful deep tracing and visualization of a complex Phoenix LiveView interaction.

**7. Open Questions & Research Areas**

*   Feasibility and performance of real-time LLM-driven AST transformation versus pre-calculated plans.
*   Optimal data structures and indexing for querying the 7 DAGs simultaneously.
*   Most effective visual metaphors for concurrent execution in the "Cinema UI".
*   Defining "noise" vs. "signal" effectively for intelligent filtering in a "total recall" system.
*   Handling extremely large states or message payloads efficiently.
*   Balancing AI automation with user control in the instrumentation and debugging process.

---

This PRD incorporates the AI-first approach, total recall, and visual execution cinema concepts from the "Grand Plan." It aligns with the need for a robust foundational capture layer first, then builds the advanced AI and UI capabilities on top. The features are phased to deliver value incrementally while tackling significant technical challenges progressively.
