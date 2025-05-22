## ElixirLumin: A Unified Observability and Diagnostics Platform for Elixir

**Vision:** ElixirLumin aims to be the definitive platform for understanding, debugging, and optimizing Elixir applications, from local development to large-scale distributed production systems. It integrates deep, dynamic introspection with intelligent analysis and a rich, collaborative user experience, fostering observability-driven development and operational excellence.

This plan synthesizes insights from all provided ElixirScope documents, aiming to build upon and enhance the best ideas, particularly those in "ElixirScope 2.0" (`APP_REBUILD_FROM_RESEARCH_claude.md`).

### 1. Dependencies (`mix.exs`)

ElixirLumin will have a core set of dependencies and a larger set of optional dependencies based on features enabled. This promotes a lean core while allowing for rich feature extensions.

**Core Dependencies (Always Included):**
```elixir
defp deps do
  [
    # For Event Sourcing & CQRS backbone
    {:commanded, "~> 1.4"},
    # Default to Ecto/PostgreSQL for Event Store, but allow adapters
    {:commanded_ecto_adapter, "~> 1.2", optional: true},
    {:ecto_sql, "~> 3.9", optional: true}, # Make Ecto optional if no default store
    {:postgrex, "~> 0.17", optional: true}, # Or another Ecto adapter

    # For high-throughput event ingestion
    {:broadway, "~> 1.0"},

    # For distributed process group management and coordination
    {:horde, "~> 0.9"}, # For dynamic supervision and registry across nodes

    # For configuration and utilities
    {:jason, "~> 1.4"},
    {:typed_struct, "~> 0.3.0"}, # For well-defined event/data structures

    # For self-monitoring & basic metrics emission/collection
    {:telemetry, "~> 1.2"},
    {:telemetry_metrics, "~> 0.6"},
    {:telemetry_poller, "~> 1.0"}, # For polling BEAM and OS metrics

    # Development & Testing
    {:ex_doc, "~> 0.30", only: :dev, runtime: false},
    {:mox, "~> 1.0", only: :test},
    {:stream_data, "~> 0.6", only: :test} # For property-based testing
  ]
end

def application do
  [
    extra_applications: [
      :logger,
      :runtime_tools, # For :dbg, :sys, etc.
      :crypto # For UUIDs, hashing
    ],
    mod: {ElixirLumin.Application, []} # ElixirLumin itself is an OTP app
  ]
end
```

**Optional & Plugin Dependencies (Enabled via Configuration/Separate Packages):**

*   **AI & Machine Learning:**
    *   `{:nx, "~> 0.7", optional: true}`, `{:axon, "~> 0.6", optional: true}` (for onboard ML models)
    *   `{:bumblebee, "~> 0.5", optional: true}` (for interfacing with HuggingFace models)
    *   `{:tesla, "~> 1.7", optional: true}` (for external AI API calls)
    *   `{:tidewave_client, "...", optional: true}` (hypothetical client library for Tidewave)
*   **Observability Ecosystem Integration:**
    *   `{:opentelemetry_api, "~> 1.3", optional: true}`, `{:opentelemetry, "~> 1.3", optional: true}`
    *   `{:opentelemetry_exporter, "~> 1.3", optional: true}`
    *   `{:prom_ex, "~> 1.9", optional: true}` (for Prometheus metrics)
*   **Domain-Specific Collector Plugins (as separate hex packages or internal optional modules):**
    *   `elixirlumin_phoenix_collector` (depends on `:phoenix`)
    *   `elixirlumin_ecto_collector` (depends on `:ecto`)
    *   `elixirlumin_broadway_collector` (depends on `:broadway`)
*   **Web UI & Visualization:**
    *   `{:phoenix, "~> 1.7", optional: true}`, `{:phoenix_live_view, "~> 0.20", optional: true}` (if ElixirLumin hosts its own UI)
    *   `{:matplotex, "~> 0.2", optional: true}`
*   **Alternative Event Store Backends (as separate adapter packages):**
    *   `elixirlumin_commanded_eventstoredb_adapter` (depends on `{:commanded_eventstore_adapter, "~> 1.1"}`)
    *   `elixirlumin_commanded_mnesia_adapter` (custom adapter for Mnesia)

This structure allows users to install only the ElixirLumin core and add features/integrations as needed, reducing overall application footprint if only a subset of ElixirLumin's capabilities are required.

### 2. New Code Structure and Functionality: ElixirLumin

This architecture is designed for modularity, extensibility, production-readiness, and a rich developer experience. It integrates the event-driven CQRS/ES model proposed by Claude with more dynamic introspection capabilities and an enhanced focus on actionable insights.

```
elixirlumin/
├── application.ex                # Main OTP application for ElixirLumin.
│
├── common/
│   ├── event.ex                  # Defines `ElixirLumin.Common.Event` (versioned, typed, rich metadata).
│   ├── event_schema.ex           # `ElixirLumin.Common.EventSchema` (validation, evolution).
│   ├── config.ex                 # `ElixirLumin.Common.Config` (hierarchical, profiles, runtime updates via ConfigManager).
│   ├── context.ex                # `ElixirLumin.Common.Context` (trace/span correlation, distributed context).
│   └── utils.ex                  # Shared utilities (sanitization, PII redaction helpers, etc.).
│
├── core_system/                  # Foundational infrastructure for ElixirLumin itself.
│   ├── config_manager.ex         # GenServer managing dynamic configuration of ElixirLumin.
│   ├── resource_governor.ex      # Circuit breakers, rate limiting for ElixirLumin's operations.
│   ├── self_monitor.ex           # Internal metrics, health checks for ElixirLumin (uses Telemetry).
│   └── security_manager.ex       # Handles RBAC, API keys for ElixirLumin access, PII policy enforcement.
│
├── data_ingestion/               # Collection, dynamic instrumentation, and initial processing.
│   ├── collectors/               # Static collectors gathering data from various sources.
│   │   ├── behaviour.ex          # `ElixirLumin.DataIngestion.Collector` behaviour.
│   │   ├── otp_collector.ex      # Process lifecycle, base GenServer state, messages (via :sys, :dbg).
│   │   ├── beam_metrics_collector.ex # BEAM VM & OS metrics.
│   │   ├── log_collector.ex      # Subscribes to `Logger` backend, converts logs to Events.
│   │   └── plugin_supervisor.ex  # Supervisor for optional collector plugins.
│   │
│   ├── dynamic_introspector/     # Engine for on-demand, deep instrumentation.
│   │   ├── probe_manager.ex      # Manages dynamic probes (function tracing, var capture, custom assertions).
│   │   ├── probe_runner.ex       # Executes probes safely within the target application context.
│   │   ├── ast_instrumentor.ex   # (Advanced Opt-in) For AST-based code injection for line-level detail.
│   │   └── probe_library.ex      # Pre-defined common probes (e.g., GenServer state diff on call).
│   │
│   └── ingestion_pipeline/       # Broadway-based: Receives events from collectors & probes.
│       ├── gateway.ex            # Validates, enriches (context, schema), redacts PII, samples.
│       └── batch_persister.ex    # Batches events and sends commands to EventStore.
│
├── event_processing/             # CQRS/Event Sourcing core.
│   ├── event_store_app.ex        # Commanded Application: Defines aggregates, commands, events.
│   │   ├── commands.ex           # e.g., `RecordIngestedEventBatch`, `StartDebugSession`.
│   │   ├── aggregates/           # e.g., `DebugSessionAggregate`, `TracedProcessAggregate`.
│   │   └── events.ex             # Domain events for storage.
│   │
│   └── read_models/              # Projections for building queryable views.
│       ├── projection_supervisor.ex # Manages all Ecto (or other) projections.
│       ├── process_timeline_projection.ex
│       ├── message_flow_projection.ex
│       ├── state_history_projection.ex
│       ├── performance_metrics_projection.ex
│       └── anomaly_log_projection.ex
│
├── analysis_and_insights/        # Deriving meaning from the data.
│   ├── query_service.ex          # API to query read models (projections_repo).
│   ├── live_query_service.ex     # Supports streaming queries/subscriptions (e.g., for live UI updates).
│   │
│   ├── analysis_engine/
│   │   ├── correlator.ex         # Links disparate events (traces, logs, metrics) by context.
│   │   ├── pattern_detector.ex   # Statistical pattern detection (e.g., frequent call sequences).
│   │   ├── anomaly_detector.ex   # Detects deviations from baselines or learned patterns.
│   │   └── root_cause_engine.ex  # Heuristic & ML-based root cause suggestion.
│   │
│   └── insight_engine/
│       ├── knowledge_base_builder.ex # Builds a graph or structured representation of system behavior.
│       └── recommendation_provider.ex # Generates actionable advice, optimization tips.
│
├── user_interaction/             # How users and other systems interact with ElixirLumin.
│   ├── web_interface/            # (Optional) Phoenix LiveView based UI.
│   │   ├── live/                 # TraceExplorer, TimeTraveler, SystemDashboard, AnomalyDashboard.
│   │   ├── components/           # Shared UI elements.
│   │   └── endpoint.ex
│   │
│   ├── api_interface/            # Programmatic access.
│   │   ├── rest_controller.ex
│   │   └── graphql_handler.ex
│   │
│   └── ai_interface/             # Integration with AI assistants.
│       ├── tool_definitions.ex   # Describes ElixirLumin tools for AI.
│       └── tidewave_adapter.ex   # (Example) Adapter for Tidewave.
│
├── ecosystem_integrations/       # Connecting to external observability tools.
│   ├── open_telemetry_bridge.ex  # Exports ElixirLumin data to OTel, can also ingest OTel data.
│   ├── prometheus_bridge.ex      # Exposes metrics for Prometheus.
│   └── alerting_bridge.ex        # Sends alerts to PagerDuty, Slack, etc.
│
└── developer_workflow/           # Tools directly aiding the developer lifecycle.
    ├── interactive_console.ex    # IEx helpers for controlling ElixirLumin.
    ├── test_utilities.ex         # Helpers for using ElixirLumin in tests, test data generation.
    ├── learning_module.ex        # Uses ElixirLumin to explain OTP/Elixir concepts interactively.
    └── session_recorder.ex       # For saving/sharing/annotating ElixirLumin debugging sessions.
```

**Elucidation of Structure and Functionality (Highlighting Improvements & New Ideas):**

*   **`common/`**:
    *   `Event`: Central, versioned struct with rich metadata including `correlation_id`, `causation_id`, `schema_version`. This standardizes all internal data flow.
    *   `EventSchema`: Manages validation rules for different event types and versions, ensuring data integrity.
*   **`core_system/`**:
    *   This new top-level component houses the infrastructure that makes ElixirLumin itself robust and manageable, addressing Claude's "Observable Debugger" and "Production-Safe" principles directly.
    *   `ConfigManager`: Allows runtime updates to ElixirLumin's behavior (e.g., changing sampling rates globally or for specific collectors/probes without restart).
    *   `SecurityManager`: Centralizes crucial security aspects: Role-Based Access Control for ElixirLumin's API/UI, PII redaction policy management (policies can be applied by collectors or the `IngestionPipeline`).
*   **`data_ingestion/`**:
    *   **`collectors/`**: Standardized set of base collectors. `LogCollector` is a key addition, transforming `Logger` messages into structured `ElixirLumin.Common.Event`s, allowing logs to be correlated seamlessly with traces and metrics. Plugin architecture allows easy extension.
    *   **`dynamic_introspector/`**: A significant enhancement for achieving granular, on-demand detail.
        *   `ProbeManager`: The control point for users/AI to say "start detailed tracing for `MyModule.my_func/2` for the next 5 minutes, capturing all variable changes". Probes can be time-limited, count-limited, or condition-triggered.
        *   `ProbeRunner`: Executes these probes. This could range from simple `:dbg.tpl` setup to more complex AST instrumentation injection if enabled.
        *   `ASTInstrumentor`: An advanced, opt-in feature for true line-by-line variable state capture. It would rewrite function ASTs (perhaps in memory or a temporary compiled version) to inject `ElixirLumin.capture_binding(__ENV__, binding())` calls. This directly addresses the "state as each line executes" part of the original prompt.
        *   `ProbeLibrary`: Offers predefined probes for common scenarios (e.g., "trace all state changes in this GenServer and the messages that triggered them").
    *   **`ingestion_pipeline/`**: Broadway ensures backpressure and resilience. `Gateway` performs validation against `EventSchema` and initial enrichment. `Preprocessor` handles PII redaction based on `SecurityManager` policies and applies sampling.
*   **`event_processing/`**:
    *   `event_store_app/`: Uses Commanded. Aggregates could be more granular, e.g., a `DebugSessionAggregate` to manage the lifecycle of a specific debugging investigation, or `TracedProcessAggregate` to hold overarching metadata about a process's entire traced history.
    *   `read_models/`: Projections create denormalized views for fast querying. For instance, `PerformanceMetricsProjection` could aggregate raw timing events into min/max/avg/p95/p99 latencies.
*   **`analysis_and_insights/`**:
    *   `QueryService` & `LiveQueryService`: Provide access to the read models. `LiveQueryService` uses Phoenix PubSub or similar to push real-time updates to the UI or other subscribers.
    *   `AnalysisEngine`:
        *   `Correlator`: Key for building context. E.g., links a log error message to the trace ID active at that time, and to the BEAM metrics state.
        *   `RootCauseEngine`: More advanced than "suggester". Could use Bayesian networks or other probabilistic models informed by the `KnowledgeBaseBuilder`.
    *   `InsightEngine`:
        *   `KnowledgeBaseBuilder`: This is a new concept. It continuously processes events from the `EventStore` (or specific projections) to build a structured knowledge base about the application's entities (processes, modules, functions, data types) and their interactions, common call paths, state transition frequencies, etc. This could be a graph database or a set of relational tables.
        *   `RecommendationProvider`: Uses this knowledge base plus `AnalysisEngine` outputs to offer proactive advice (e.g., "Function X is frequently called with large lists, consider streaming"; "Process Y often becomes a bottleneck under load pattern Z").
*   **`user_interaction/`**:
    *   `WebInterface`: Focus on highly interactive components:
        *   **TraceExplorer:** Advanced filtering (by event type, PID, module, function, context fields), chronological and causal chain views, source code linking.
        *   **TimeTraveler:** UI to scrub through the event stream, reconstructing and visualizing state at any point. "What-if" scenario simulation (as described in `docs/02-gemini.md`) can be initiated here, triggering `DynamicIntrospector` probes with modified inputs.
        *   **SystemDashboard:** Real-time overview of BEAM metrics, top N busy processes, recent anomalies.
        *   **AnomalyDashboard:** Drill-down into detected anomalies, showing correlated events and root cause suggestions.
    *   `AIInterface`: `ToolDefinitions` uses a structured format (like OpenAPI schemas for functions) that AI agents can understand. This makes ElixirLumin's capabilities (querying, triggering dynamic probes, asking for analysis) available to various AI platforms.
*   **`ecosystem_integrations/`**:
    *   `OpenTelemetryBridge`: Bi-directional. Exports ElixirLumin's rich internal traces to OTel. *Also, can ingest OTel traces* from other services, allowing correlation of ElixirLumin data with traces from a broader microservices ecosystem.
*   **`developer_workflow/`**:
    *   `InteractiveConsole`: `IEx` helpers like `ElixirLumin.trace(MyMod.fun/1)`, `ElixirLumin.history(pid)`, `ElixirLumin.explain_anomaly(id)`.
    *   `TestUtilities`: Functions to assert specific trace patterns occurred during tests, or to feed recorded scenarios into property-based tests.
    *   `LearningModule`: Provides guided tours through common Elixir/OTP scenarios (e.g., a GenServer call/cast flow, a supervision restart) by running a small sample app and using ElixirLumin to visualize exactly what happens at each step. Excellent for onboarding.
    *   `SessionRecorder`: Captures not just the trace data but also the user's interactions with the ElixirLumin UI (queries made, views explored) for a particular debugging session. This can be saved, annotated, and shared. This is crucial for collaborative debugging and knowledge transfer. (Covers `APP_DIRECTION_claude.md` #4).

**Meeting and Exceeding the Vision:**

*   **Granular Tracking:** Achieved via `OTCollector` for general tracing, and the `DynamicIntrospector` (especially with `ASTInstrumentor`) for deep, on-demand, line-by-line state and variable capture. Event Sourcing preserves all history.
*   **Juxtaposing Expected vs. Actual:** The `WebInterface` will offer rich diffing views. The `AnalysisEngine` can automate this comparison based on user-defined invariants or learned patterns. AI can explain discrepancies.
*   **Leveraging Existing Tools:** `:dbg`, `:sys`, `Logger`, `Telemetry` are foundational for collectors. `Commanded`, `Broadway`, `Horde` provide core infrastructure.
*   **Tidewave (and AI):** The `AIInterface` provides a sophisticated bridge. AI can query analysis results, trigger dynamic probes, ask for data from the `KnowledgeBaseBuilder`, and help narrate causal chains.

**Creative Enhancements Integrated:**

*   **Causal Chain Forensics:** Implemented by `AnalysisEngine.Correlator` and visualized in `TraceExplorer`. AI can narrate this.
*   **State Drift Anomaly Detection:** Handled by `AnalysisEngine.AnomalyDetector` using baselines from `PatternDetector`.
*   **What-If Scenarios:** Possible via `WebInterface.TimeTraveler` initiating `DynamicIntrospector` probes with modified inputs.
*   **Visual Message Flow Cartography:** A key feature of `WebInterface.TraceExplorer` and `SystemDashboard`.
*   **Line-Level Relevance Highlighting:** The `ASTInstrumentor` enables this. Even without it, `Correlator` + AI can infer active code paths.
*   **Automated Test Case Suggestion:** A core feature of `DeveloperWorkflow.TestUtilities`.
*   **Production Safety & Performance:** Central to `CoreSystem` (ResourceGovernor, SelfMonitor) and `DataIngestion` (sampling, redaction).
*   **Collaborative Debugging:** Implemented by `DeveloperWorkflow.SessionRecorder`.

This ElixirLumin plan creates a powerful, scalable, and intelligent observability platform. Its event-sourced architecture, dynamic introspection capabilities, and deep AI integration provide a foundation for revolutionizing how Elixir applications are understood and debugged.
