# ElixirScope: Future Directions & Potential Enhancements (DIRECTION.md)

## 1. Introduction

This document outlines potential future directions and enhancements for the ElixirScope project. While the current implementation provides a robust foundation for Elixir application introspection and debugging, these ideas aim to further expand its capabilities, improve user experience, and address more advanced debugging scenarios.

## 2. Core Functionality Enhancements

### 2.1. Advanced Time-Travel Debugging UX

*   **Interactive Replay UI**:
    *   Develop a web-based UI component (potentially integrated with Phoenix LiveView for the ElixirScope dashboard itself, or as a standalone tool) that allows users to visually step forward/backward through the `execution_timeline`.
    *   Display the state of relevant processes, pending messages, and the call stack at each step.
    *   Visualize message flows and state changes dynamically as the user "travels" through time.
*   **"What-If" Scenarios (Speculative Execution)**:
    *   Allow users to select an event in the timeline (e.g., a message receive or function call).
    *   Provide an interface to modify the incoming message/arguments or even temporarily patch the code.
    *   Re-simulate (in a sandboxed/isolated manner if possible, or by guiding the user to re-run with modifications) the subsequent events to see how behavior would change. This is a highly ambitious feature.

### 2.2. Granular Line-by-Line Variable Tracking (Opt-in)

*   **AST Transformation**: Explore opt-in AST transformation during compilation (e.g., via a compiler pass or macros) to inject `ElixirScope.TraceDB.log_variable_change(var_name, new_value, __ENV__)` calls after assignments within specific, user-annotated functions or blocks.
    *   This would provide true line-by-line variable state, but with significant performance implications, hence strict opt-in.
*   **Correlation with Source**: Enhance the `QueryEngine` and potential UI to precisely map these variable changes to source code lines.

### 2.3. Persistent Storage Options

*   **Mature File/Database Persistence**:
    *   Fully implement and test Mnesia or a more robust file-based persistence (e.g., using DETS or a custom binary format with indexing) for `TraceDB`.
    *   Provide clear strategies for data rotation, archival, and loading persisted traces.
*   **External Database Connectors**: Offer connectors for popular time-series databases (e.g., InfluxDB, Prometheus) or log management systems (e.g., Elasticsearch) for long-term storage and advanced querying of trace data in production environments.

### 2.4. Distributed Tracing

*   **Cross-Node Event Correlation**:
    *   Implement mechanisms to correlate trace events across multiple BEAM nodes in a distributed Elixir application. This would involve standardizing trace IDs and timestamps (considering clock drift) and potentially a central aggregator or distributed query mechanism.
    *   Integrate with established distributed tracing standards like OpenTelemetry if applicable, or provide ElixirScope-specific propagation.
*   **Visualization for Distributed Systems**: Extend UI capabilities to visualize message flows and process interactions across nodes.

## 3. AI Integration and Assisted Debugging

### 3.1. Proactive Anomaly Detection

*   **Baseline Profiling**: Allow ElixirScope to run in a "learning mode" to establish baseline behavior patterns (e.g., typical message frequencies, state transition probabilities, function call latencies).
*   **AI-Driven Anomaly Alerts**: Integrate with `AIIntegration` so Tidewave (or other AI) can be alerted or query for deviations from these baselines. For example, "Process X is suddenly receiving 10x more messages than usual."
*   **Root Cause Suggestion**: Enhance AI tools to suggest potential root causes for anomalies based on correlated trace data.

### 3.2. Natural Language Trace Summarization

*   Develop more sophisticated summarization for AI tools, going beyond simple `inspect` limits.
*   For example, "Process Foo.Bar had 5 state changes. The `:count` key increased from 0 to 10. It received 3 messages of type `{:increment, _}` and 2 messages of type `{:status_update, _}`."

### 3.3. Automated Test Case Generation from Traces

*   Based on a captured execution path, especially one leading to an error or an unexpected state, allow the AI (via a Tidewave tool) to attempt to generate an ExUnit test case skeleton that reproduces the scenario.
    *   This would involve identifying initial process states, message sequences, and function calls.

## 4. Performance and Usability

### 4.1. Dynamic Tracing Adjustments

*   Implement a mechanism where ElixirScope can dynamically adjust `tracing_level` or `sample_rate` based on observed system load (e.g., CPU utilization, memory pressure, message queue lengths reported by `ProcessObserver`).
*   Allow users to define "triggers" (e.g., when a specific error occurs) to automatically increase tracing detail for a short period.

### 4.2. Enhanced Filtering and Search in Queries

*   **TraceDB Indexing**: Improve `TraceDB` indexing for more complex queries (e.g., indexing by message content patterns, specific state values).
*   **Query Language**: Consider a simple DSL or more expressive filter map for `QueryEngine` to allow more complex ad-hoc queries without modifying the engine itself.

### 4.3. Configuration Profiles

*   Allow users to define and save ElixirScope configuration profiles (e.g., "lightweight_production", "deep_dive_dev", "phoenix_focus") that preset various options like `tracing_level`, `sample_rate`, and which tracers are active.

### 4.4. Live Dashboard / UI

*   **Real-time Visualization**: Develop a dedicated web dashboard (possibly using Phoenix LiveView) for ElixirScope that provides:
    *   Live supervision tree views.
    *   Real-time message flow diagrams.
    *   Graphs of process state changes over time.
    *   A query interface for `QueryEngine`.
*   **Integration with `dbg` Frontends**: Explore integration with existing graphical frontends for `:dbg` or a custom one.

## 5. Developer Experience and Ecosystem

### 5.1. ExDoc and Guides

*   **Comprehensive ExDoc**: Ensure all public modules and functions have thorough ExDoc documentation with examples.
*   **Advanced Usage Guides**: Create more guides (similar to `ai-integration-guide.md`) for topics like:
    *   Performance Tuning ElixirScope.
    *   Advanced Querying Techniques.
    *   Debugging Common Elixir/OTP Concurrency Issues with ElixirScope.
    *   Extending ElixirScope (e.g., custom tracers).

### 5.2. IDE Integration

*   Explore creating extensions for popular Elixir IDEs (like VS Code with ElixirLS) to:
    *   Allow starting/stopping tracing for modules/functions directly from the editor.
    *   Display basic trace information (e.g., last few messages, current state) in tooltips or side panels.
    *   Navigate from trace events to source code.

### 5.3. Community Contributions

*   Clearly document extension points for custom tracers or data analysis plugins.
*   Foster a community around sharing common debugging patterns and ElixirScope configurations.

## 6. Refinement of Existing Features

### 6.1. Supervision Tree Accuracy in `system_snapshot_at`

*   The current `reconstruct_supervision_tree_at` in `QueryEngine` is noted as simplified. Enhance this by:
    *   Ensuring `ProcessObserver` logs specific events when supervisors start/stop children or when children are restarted.
    *   Using these historical supervisor action events to more accurately reconstruct the tree at a specific past timestamp.

### 6.2. Message Matching in `get_pending_messages_at`

*   The current pending message detection is an approximation. If `:dbg` or Telemetry can provide unique message identifiers that are consistent across send and receive events (e.g., using message `ref`s more explicitly), this could improve accuracy.

## 7. Conclusion

ElixirScope has a strong foundation. The future direction focuses on deepening its analytical capabilities, making it more accessible and powerful through better UIs and AI integration, ensuring its usability in diverse environments (from development to controlled production debugging), and empowering developers with even more granular control and insight into their Elixir applications. Prioritization of these features will depend on user feedback and evolving needs of the Elixir community.
