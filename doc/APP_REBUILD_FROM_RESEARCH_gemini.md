Okay, I've reviewed all the provided documents and the existing ElixirScope codebase. Here's a new code roadmap from scratch, focusing on describing dependencies and elucidating a new code structure and functionality that covers the original vision and more.

## ElixirScope: Enhanced Roadmap for Comprehensive Elixir Observability

This roadmap outlines the evolution of ElixirScope into a full-fledged observability and diagnostics platform for Elixir applications. It builds upon the solid foundation of the current implementation, expanding its capabilities to offer deeper insights, better developer experience, and production-ready features.

### 1. Dependencies (`mix.exs`)

The current `mix.exs` includes:
```elixir
defp deps do
  [
    {:telemetry, "~> 1.0"},               # Used by PhoenixTracker for Phoenix events
    {:ex_doc, "~> 0.27", only: :dev, runtime: false}, # For documentation
    {:phoenix, "~> 1.6", optional: true},  # For Phoenix-specific tracing
    {:phoenix_live_view, "~> 0.17", optional: true} # For LiveView-specific tracing
  ]
end

def application do
  [
    extra_applications: [:logger, :runtime_tools] # :runtime_tools for :dbg, :sys access
  ]
end
```

**Roadmap for Dependencies (Categorized by Feature Area):**

As ElixirScope evolves, the following dependencies may be introduced. They will be added as optional or direct dependencies based on the feature's nature and integration depth.

*   **Core & Storage:**
    *   No immediate new external dependencies for core ETS/Mnesia.
    *   **(Potential)** `:redix` (for Redis-based caching/event bus if needed for distributed coordination).
    *   **(Potential)** `:postgrex`, `:ecto_sql` (if a robust SQL-based persistent storage backend is added).
    *   **(Potential)** Client libraries for time-series DBs (e.g., InfluxDB, TimescaleDB) if direct integration is chosen for persistence.
*   **Observability Ecosystem Integration:**
    *   `Opentelemetry`: `:opentelemetry_api`, `:opentelemetry`.
    *   `Opentelemetry Exporters`: `:opentelemetry_exporter` (for OTLP).
    *   `Opentelemetry Instrumentation`: (Could leverage existing like `:opentelemetry_phoenix`, `:opentelemetry_ecto` or provide ElixirScope-specific versions).
    *   `Prometheus`: `:prom_ex` or a similar library for exposing metrics.
*   **Domain-Specific Analyzers:**
    *   `Ecto`: `:ecto` (likely already present in projects using this analyzer).
    *   `Plug`: `:plug` (likely already present).
    *   `Broadway`, `GenStage`, `Flow`: The libraries themselves, if deep integration for their specific analyzers is built.
*   **AI/ML Features:**
    *   `Nx ecosystem`: `:nx`, `:axon`, `:explorer` (if ML models are built and run within ElixirScope).
    *   `HTTPoison` or `Tesla`: For interacting with external AI/LLM APIs.
*   **Web UI (If a standalone dashboard is developed):**
    *   More Phoenix stack dependencies if it's a full Phoenix app (e.g., `:phoenix_pubsub` for real-time UI updates).
    *   `Matplotex` or similar for server-side chart generation if preferred over JS libraries.
*   **Collaborative Features:**
    *   Dependencies related to real-time communication if not built purely on existing Phoenix channels (e.g., WebSocket libraries).
*   **Developer Experience & Testing:**
    *   `:mox`: For mocking external dependencies during testing.

The strategy will be to keep the core library lean and make integrations optional where possible (e.g., users install `:opentelemetry_exporter` themselves if they want that feature).

### 2. New Code Structure and Functionality

The new structure aims to be highly modular, allowing features to be developed and optionally included. It builds upon the existing strengths while paving the way for advanced capabilities.

```
elixir_scope/
├── elixir_scope.ex                # Facade: Main API, setup, configuration management.
│
├── common/                        # Shared utilities and definitions
│   ├── event.ex                   # Defines canonical ElixirScope.Event struct.
│   ├── config.ex                  # Manages global and tracer-specific configurations, profiles.
│   └── utils.ex                   # General helper functions (term sanitization, PID utils, etc.).
│
├── core/                          # Core data handling and processing
│   ├── trace_db.ex                # Interface for trace data storage.
│   ├── storage_backends/          # Pluggable storage implementations.
│   │   ├── ets_backend.ex         # (Current)
│   │   ├── mnesia_backend.ex      # (New) For persistent, distributed BEAM storage.
│   │   └── file_backend.ex        # (New/Improved) For simple file-based persistence.
│   │   └── external_ts_backend.ex # (New) Interface for Time-Series DBs (e.g., InfluxDB).
│   └── query_engine.ex            # (Enhanced) Advanced querying, aggregation, correlation logic.
│
├── collectors/                    # Modules responsible for gathering trace data.
│   ├── process_collector.ex       # (Evolved from ProcessObserver) Lifecycle, supervision, runtime stats.
│   ├── message_collector.ex       # (Evolved from MessageInterceptor) Inter-process messages.
│   ├── function_collector.ex      # (Evolved from CodeTracer) Function calls/returns. AST-based coming later.
│   ├── state_collector.ex         # (Evolved from StateRecorder) GenServer state, generic process state.
│   │
│   ├── domain_collectors/         # (New) For framework/library-specific data.
│   │   ├── phoenix_collector.ex   # (Evolved from PhoenixTracker) Phoenix telemetry.
│   │   ├── ecto_collector.ex      # (New) Ecto queries, changesets, transactions.
│   │   ├── plug_collector.ex      # (New) Plug pipeline execution, timings.
│   │   ├── broadway_collector.ex  # (New) Broadway pipeline events.
│   │   └── behaviour.ex           # (New) Defines a behaviour for custom collectors.
│   │
│   └── runtime_metrics_collector.ex # (New) BEAM-wide metrics (schedulers, memory, etc.).
│
├── analysis/                      # Modules for deriving insights from collected data.
│   ├── time_traveler.ex           # (Enhanced from QueryEngine) State reconstruction at T.
│   ├── performance_profiler.ex    # (New) Bottleneck ID, flame graphs, resource usage analysis.
│   ├── anomaly_detector.ex        # (New) Statistical and ML-based anomaly detection.
│   ├── root_cause_analyzer.ex     # (New) Heuristic/AI-based root cause suggestions.
│   ├── state_differ.ex            # (Enhanced from QueryEngine) Advanced state comparison.
│   └── pattern_recognizer.ex      # (New) For learning typical execution patterns.
│
├── presentation/                  # How data is exposed and interacted with.
│   ├── ui/                        # (New - Optional) Web-based UI.
│   │   ├── live/                  # LiveView components for dashboard, trace explorer.
│   │   ├── assets/                # Static assets for UI.
│   │   └── router.ex              # If UI is a full mini-Phoenix app.
│   ├── formatters/                # (New) For various output formats.
│   │   ├── text_formatter.ex      # For console, human-readable output.
│   │   ├── json_formatter.ex      # For machine-readable export.
│   │   └── otel_formatter.ex      # (New) OpenTelemetry trace format.
│   ├── ai_bridge.ex               # (Enhanced AIIntegration) Interface for AI tools (Tidewave, etc.).
│   └── session_manager.ex         # (New) For collaborative debugging sessions, annotations.
│
├── integrations/                  # Connecting ElixirScope to external systems.
│   ├── open_telemetry_exporter.ex # (New) Exports data to OpenTelemetry.
│   ├── prometheus_exporter.ex     # (New) Exposes metrics for Prometheus.
│   ├── alert_manager_bridge.ex    # (New) Sends alerts to systems like PagerDuty, Slack.
│   └── issue_tracker_bridge.ex    # (New) Links to Jira, GitHub Issues.
│
└── developer_tools/               # Features enhancing the development workflow.
    ├── test_case_generator.ex     # (New) Generates ExUnit tests from traces.
    ├── config_impact_analyzer.ex  # (New) Shows impact of config changes.
    └── hot_swap_tracker.ex        # (New) Tracks effects of code hot-swapping.
```

**Elucidation of New Structure and Functionality (Covering Original Vision and More):**

**Phase 0: Current State & Refinements (Already Partially Done as per `CURSOR-REFACTOR.md`)**
*   **Current Functionality:** Process, message, function, state, and Phoenix tracing. ETS storage. Basic querying. Tidewave integration.
*   **Refinements:**
    *   Formalize `ElixirScope.Common.Event` struct.
    *   Solidify `ElixirScope.Common.Config` for robust configuration management (including profiles).
    *   Enhance `ElixirScope.Core.QueryEngine` with more versatile filtering and aggregation.
    *   Rename existing tracers to `_collector.ex` for consistency (e.g., `ElixirScope.Collectors.ProcessCollector`).

**Phase 1: Foundational Enhancements & Production Readiness**
*   **`ElixirScope.Core.StorageBackends` (New):**
    *   `MnesiaBackend`: For persistent, distributed BEAM storage. Useful for retaining traces across restarts or in clustered environments.
    *   `FileBackend`: Improved file-based persistence with rotation and indexing.
    *   **Vision:** Provide robust storage options beyond ephemeral ETS, crucial for production debugging and long-term analysis.
*   **`ElixirScope.Collectors.RuntimeMetricsCollector` (New):**
    *   **Functionality:** Collects key BEAM VM metrics (scheduler utilization, memory usage, process counts, run queue lengths, I/O stats) and selected process-specific metrics (memory, message queue).
    *   **Vision:** Correlate application-level traces with system health, aiding in performance analysis and resource bottleneck identification.
*   **Production-Safe Runtime Inspection (from `APP_DIRECTION_claude.md` #5):**
    *   Implement strict resource governance for all collectors (CPU/memory limits).
    *   Automatic circuit breakers in `ElixirScope.Common.Config` to disable/reduce tracing if system load exceeds thresholds.
    *   Secure remote access (if applicable, likely via host app's security).
    *   PII redaction hooks/configuration in collectors and `ElixirScope.Common.Utils`.
    *   **Vision:** Enable safe use of ElixirScope in production for critical issue diagnosis.

**Phase 2: Ecosystem Integration & Domain-Specific Analysis**
*   **`ElixirScope.Integrations.OpenTelemetryExporter` & `ElixirScope.Presentation.Formatters.OtelFormatter` (New):**
    *   **Functionality:** Transform and export ElixirScope's detailed traces into OpenTelemetry format. Send to an OpenTelemetry collector.
    *   **Vision:** Position ElixirScope within the broader observability ecosystem, allowing its data to be viewed alongside traces from other services. (Covers `APP_DIRECTION_claude.md` #7)
*   **`ElixirScope.Integrations.PrometheusExporter` (New):**
    *   **Functionality:** Expose key metrics (e.g., number of anomalies detected, trace volume, performance bottlenecks identified) for Prometheus scraping.
    *   **Vision:** Integrate with popular monitoring and alerting setups.
*   **`ElixirScope.Collectors.DomainCollectors` (New):**
    *   `EctoCollector`: Track Ecto queries (raw SQL, params, timings), changeset processing, transaction lifecycles.
    *   `PlugCollector`: Visualize Plug pipeline execution, timing for each plug, `Plug.Conn` transformations.
    *   **(Future)** `BroadwayCollector`, `GenStageCollector`, etc.
    *   **Vision:** Provide deep, context-specific insights for common Elixir frameworks and patterns. (Covers `APP_DIRECTION_claude.md` #2)

**Phase 3: Advanced Analysis & Intelligent Debugging**
*   **`ElixirScope.Analysis.PerformanceProfiler` (New):**
    *   **Functionality:** Identify performance bottlenecks (e.g., frequently slow functions, high resource-consuming processes). Generate flame graphs (potentially by integrating with external tools via exported data). Analyze resource usage patterns.
    *   **Vision:** Shift ElixirScope from a debugging tool to a performance optimization advisor. (Covers `APP_DIRECTION_claude.md` #6)
*   **`ElixirScope.Analysis.AnomalyDetector` (New):**
    *   **Functionality:**
        *   **Statistical Anomaly Detection:** Establish baselines for metrics (e.g., message rates, function call frequencies, state transition probabilities) and flag significant deviations.
        *   **(Advanced)** **ML-driven Anomaly Detection:** Train models on "normal" behavior to detect complex anomalies and predict potential failures. (Covers `APP_DIRECTION_claude.md` #3)
    *   **Vision:** Enable proactive problem identification and move towards predictive debugging.
*   **`ElixirScope.Analysis.RootCauseAnalyzer` (New):**
    *   **Functionality:** When an error or anomaly is detected, analyze correlated trace events, state changes, and metrics to suggest potential root causes. Leverage AI/heuristics.
    *   **Vision:** Speed up debugging by guiding developers to the source of issues.
*   **Context-Aware Debugging (`ElixirScope.Common.Config` & Collectors - Enhanced):**
    *   **Functionality:** Implement adaptive tracing. Hotspot detection (increase detail in anomalous areas), pattern recognition (learn from past sessions), feedback loop (developer marks "interesting" events).
    *   **Vision:** Optimize trace data capture, focusing on relevant information while minimizing overhead. (Covers `APP_DIRECTION_claude.md` #1)

**Phase 4: Enhanced Developer Experience & Collaboration**
*   **`ElixirScope.Presentation.UI` (New - Optional):**
    *   **Functionality:** A web-based dashboard (likely Phoenix LiveView) for interactive trace exploration, real-time visualization of process trees, message flows, state timelines, performance metrics. Includes interactive time-travel controls.
    *   **Vision:** Provide a powerful and intuitive visual interface for ElixirScope data. (Covers `APP_DIRECTION.md` #4.4 & `APP_DIRECTION_claude.md` #8 ideas)
*   **`ElixirScope.DeveloperTools.TestCaseGenerator` (New):**
    *   **Functionality:** Analyze trace paths, especially those leading to errors or specific states, and generate ExUnit test case skeletons to reproduce the scenario.
    *   **Vision:** Improve test coverage and streamline bug reproduction. (Covers `APP_DIRECTION_claude.md` #9)
*   **`ElixirScope.Presentation.SessionManager` (New):**
    *   **Functionality:** Allow saving, sharing, and annotating debugging sessions. Support for collaborative trace analysis (e.g., multiple users viewing and commenting on the same trace data in the UI).
    *   **Vision:** Enhance team-based problem-solving and knowledge sharing. (Covers `APP_DIRECTION_claude.md` #4)
*   **Time-Synchronized Logging (Integration with Logger):**
    *   Correlate ElixirScope events with standard application logs by enriching ElixirScope events with Logger metadata or vice-versa.
    *   **Vision:** Provide a unified view of all diagnostic information. (Covers `APP_DIRECTION_claude.md` #9)

**Phase 5: Advanced & Future-Looking Features**
*   **Granular Line-by-Line Variable Tracking (`ElixirScope.Collectors.FunctionCollector` - Advanced):**
    *   Explore opt-in AST transformation for injecting variable state capture at specific lines/blocks. High overhead, for deep-dive debugging.
    *   **Vision:** Offer the ultimate level of execution detail when required.
*   **Distributed Tracing (Core Enhancement):**
    *   Implement mechanisms for trace context propagation across BEAM nodes and potentially other services (via OpenTelemetry integration). Correlate events across a distributed system.
    *   **Vision:** Debug complex distributed Elixir applications.
*   **Edge Computing Support (`ElixirScope.Collectors` & `ElixirScope.Core.StorageBackends` adaptations):**
    *   Develop lightweight collectors with minimal overhead.
    *   Support for hierarchical trace aggregation and offline storage/sync.
    *   **Vision:** Extend ElixirScope's utility to IoT and edge devices. (Covers `APP_DIRECTION_claude.md` #10)
*   **Voice-Controlled Debugging (`ElixirScope.Presentation.AIBridge` - Experimental):**
    *   Integrate with speech-to-text and NLP to allow voice commands for controlling tracing and querying data.
    *   **Vision:** Explore novel interaction paradigms for debugging.
*   **Self-Healing Integrations (`ElixirScope.Integrations.AlertManagerBridge` enhanced):**
    *   Allow ElixirScope's AnomalyDetector to trigger predefined recovery actions or alert systems that can initiate healing.
    *   **Vision:** Move towards more autonomous system resilience.

This roadmap provides a comprehensive evolution path for ElixirScope, transforming it from an already capable debugging library into a central observability platform for the Elixir ecosystem. Each phase builds upon the previous, allowing for incremental development and value delivery. The modular structure ensures that different components can be developed in parallel and that users can opt-in to features as needed.
