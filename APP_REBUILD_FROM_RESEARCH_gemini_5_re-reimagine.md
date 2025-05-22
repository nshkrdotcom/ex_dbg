Okay, this is an excellent foundation for Phase 0 of **ElixirLumin: Sentience Horizon** (I'll use this name consistently now, as it was the proposed final synthesis). Let's dive into the detailed technical specifications for these components.

## ElixirLumin: Sentience Horizon - Phase 0 Deep Dive

**Phase 0 Goal:** Build the foundational data ingestion, storage, and basic analysis capabilities. This phase delivers a production-ready core that can collect traces, metrics, internal logs, and external logs, store them reliably, and allow for basic querying and pattern detection. It also establishes the `EvolutionaryEvent` as the cornerstone for future capability stacking.

---

### 1. `ElixirLumin.Common.EvolutionaryEvent` v1.0 Schema

This is the canonical data structure for all events flowing through ElixirLumin.

```elixir
defmodule ElixirLumin.Common.EvolutionaryEvent do
  @moduledoc """
  The canonical, versioned event structure for ElixirLumin.
  Version 1.0 focuses on essential fields for collection, correlation, and basic analysis.
  """
  use TypedStruct

  # Potential Event Types for v1.0 (extensible via config/EventSchema)
  @type event_type ::
          # OTP & Application Traces
          :process_spawned | :process_exited | :process_linked | :process_unlinked |
          :genserver_init | :genserver_handle_call | :genserver_handle_cast | :genserver_handle_info | :genserver_terminate | :genserver_state_changed |
          :function_called | :function_returned | :function_raised |
          :message_sent | :message_received |
          # Internal & External Logs
          :internal_log_captured | :external_log_ingested |
          # Metrics
          :beam_metric_snapshot | :application_metric_update |
          # Dynamic Probes (basic structure for Phase 0)
          :dynamic_probe_result |
          # ElixirLumin Internal & Analysis Events
          :event_ingestion_error | :detected_pattern_instance |
          # User Defined
          {_custom_app :: atom(), _custom_type :: atom()}

  typedstruct enforce: true do
    # === Core Identity & Timing ===
    field :id, String.t(), default: "" # UUID v4, typically generated at first touch by Nexus ingestor.
    field :type, ElixirLumin.Common.EvolutionaryEvent.event_type(), enforce: true
    field :timestamp, DateTime.t(), enforce: true # High-precision UTC timestamp of the event occurrence.

    # === Event Payload ===
    field :data, map(), default: %{} # The specific data for this event type. Schema defined by type+event_schema_version.

    # === Source Identity (Origin of the event within the monitored system) ===
    field :source_identity, %{
      # Application & Node context
      app_name: String.t() | nil, # Application.get_application(__MODULE__) |> Atom.to_string()
      app_version: String.t() | nil,
      node: String.t(), # Node.self() |> Atom.to_string()

      # Process context (if applicable)
      process_pid_str: String.t() | nil, # inspect(self())
      process_registered_name: String.t() | nil,
      process_initial_call_mfa_str: String.t() | nil, # {Mod, Fun, Arity} |> inspect()

      # Code context (if applicable)
      module_str: String.t() | nil, # Atom.to_string(MyMod)
      function_str: String.t() | nil, # Atom.to_string(:my_fun)
      arity: non_neg_integer() | nil,
      line: non_neg_integer() | nil,
      file_path: String.t() | nil, # Relative to project root if possible

      # For external logs or other non-OTP sources
      component_id: String.t() | nil, # e.g., "nginx_access_log", "vector_source_my_app"
      host_identifier: String.t() | nil # e.g., hostname, container ID
    }, enforce: true

    # === Ingestion & Platform Metadata (Added by ElixirLumin) ===
    field :ingestion_metadata, %{
      received_at: DateTime.t(), # Timestamp when ElixirLumin first received/processed it.
      ingestor_node_str: String.t(), # ElixirLumin node that ingested it.
      event_schema_version: String.t(), # Version of the `data` payload schema (e.g., "genserver_call.v1.1").
      event_envelope_version: String.t() # Version of this `EvolutionaryEvent` struct itself (e.g., "1.0").
    }, enforce: true

    # === Correlation & Context Propagation (Essential for Phase 0) ===
    field :correlation, %{
      trace_id: String.t() | nil,    # W3C Trace ID or similar.
      span_id: String.t() | nil,     # W3C Span ID or similar for this specific event.
      parent_span_id: String.t() | nil, # Parent Span ID.
      session_id: String.t() | nil,  # ElixirLumin debug session ID.
      user_correlation_tags: map()   # Free-form map for user-defined tags like `user_id`, `request_id`.
    }, default: %{user_correlation_tags: %{}}

    # === Fields for Future Phases (Present as nil/empty for v1.0, types defined for forward compatibility) ===
    field :causality_markers, [String.t()], default: [] # IDs of causally preceding events.
    field :pattern_fingerprints, [String.t()], default: [] # Fingerprints of detected patterns this event belongs to.
    field :behavioral_context, map(), default: %{} # Rich context derived by Intelligence Layer.
    field :temporal_dimensions, map(), default: %{} # For QuantumEventStore dimensions.
    field :reality_state, :actual | :predicted | :hypothetical | :simulated, default: :actual
    field :timeline_branch_id, String.t() | nil # If part of a branched/simulated timeline.
  end

  @doc "Creates a new EvolutionaryEvent, populating defaults."
  def new(type, data, source_identity, correlation_tags \\ %{}) do
    # In a real implementation, UUID generation would be robust.
    # Consider https://hex.pm/packages/uuid
    id = безопасный_uuid_v4() # Placeholder for a secure UUID v4 generator
    now = DateTime.utc_now()

    %__MODULE__{
      id: id,
      type: type,
      timestamp: Map.get(data, :timestamp, now), # Allow overriding if source has a more accurate timestamp
      data: data,
      source_identity: source_identity,
      ingestion_metadata: %{
        received_at: now,
        ingestor_node_str: Atom.to_string(Node.self()),
        event_schema_version: infer_schema_version(type, data), # Placeholder
        event_envelope_version: "1.0"
      },
      correlation: %{
        trace_id: ElixirLumin.Common.Context.get_trace_id(), # From propagated context
        span_id: ElixirLumin.Common.Context.get_span_id() || id, # Default to event_id if no span
        parent_span_id: ElixirLumin.Common.Context.get_parent_span_id(),
        session_id: ElixirLumin.Common.Context.get_debug_session_id(),
        user_correlation_tags: correlation_tags
      }
    }
  end

  # Placeholder for schema version inference based on type/data
  defp infer_schema_version(_type, _data), do: "1.0"
  defp безопасный_uuid_v4, do: Ecto.UUID.generate() # Using Ecto.UUID for simplicity here
end
```
**`ElixirLumin.Common.EventSchema` (Phase 0 - Conceptual):**
For Phase 0, schemas will be implicitly defined by the `data` map structure for each `event_type`. Formal JSON Schema validation via this module will be a Phase 1+ enhancement. The `ingestion_metadata.event_schema_version` field allows for this future evolution.

---

### 2. `ElixirLumin.DataFabric.IngestionNode.CollectionOrchestrator` APIs

This GenServer is responsible for managing all collection activities within an ElixirLumin ingestion node (or within the monitored application if collectors are embedded).

```elixir
defmodule ElixirLumin.DataFabric.IngestionNode.CollectionOrchestrator do
  use GenServer

  # --- Client API ---
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Starts or ensures all configured static collectors are running.
  Applies initial configuration from ElixirLumin.Common.Config.
  This is typically called once on ElixirLumin (or monitored app) startup.
  """
  def bootstrap_collections(opts \\ []) do
    GenServer.call(__MODULE__, {:bootstrap_collections, opts}, :infinity)
  end

  @doc """
  Stops all active collections managed by this orchestrator.
  """
  def halt_collections() do
    GenServer.call(__MODULE__, :halt_collections, 30_000)
  end

  @doc """
  Retrieves the status of all collectors and the orchestrator itself.
  Returns a map like:
  %{
    orchestrator_status: :running,
    collectors: %{
      otp_collector: %{status: :running, event_count: 1024, config: %{...}},
      external_log_ingestor: %{status: :running, port: 8088, active_streams: 5}
    },
    dynamic_probes: %{
      probe_id_1: %{status: :active, target: "MyMod.fun/1", collected_count: 50},
      ...
    }
  }
  """
  def get_status() do
    GenServer.call(__MODULE__, :get_status)
  end

  @doc """
  Applies a new configuration profile or updates specific settings.
  Propagates changes to relevant collectors and the ingestion pipeline.
  Example: update_configuration(%{static_collectors: %{otp_collector: %{sample_rate: 0.5}}})
  """
  def update_configuration(config_delta_map) do
    GenServer.cast(__MODULE__, {:update_configuration, config_delta_map})
  end

  @doc """
  Deploys a dynamic introspection probe.
  `probe_spec` includes: target (MFA, PID, pattern), type (:trace_function, :capture_state_on_msg, :custom_assertion),
  config (e.g., sampling, duration_ttl, max_events), and an optional `probe_id`.
  Returns `{:ok, probe_id}` or `{:error, reason}`.
  """
  def deploy_dynamic_probe(probe_spec) do
    GenServer.call(__MODULE__, {:deploy_dynamic_probe, probe_spec}, 30_000)
  end

  @doc """
  Retracts (stops) an active dynamic probe by its ID.
  """
  def retract_dynamic_probe(probe_id) do
    GenServer.call(__MODULE__, {:retract_dynamic_probe, probe_id})
  end

  # --- Server Implementation (Simplified for brevity) ---
  def init(_init_arg) do
    # state: %{static_collector_supervisor: pid, dynamic_probe_manager: pid, config: current_config}
    # Start supervisors for static collectors and the dynamic probe manager
    # Load initial config from ElixirLumin.Common.Config
    {:ok, %{/* initial state */}}
  end

  def handle_call({:bootstrap_collections, _opts}, _from, state) do
    # Ensure static collector supervisor and its children are started.
    # Ensure external_stream_ingestor (HTTP endpoint) is started.
    # Apply initial configuration.
    {:reply, :ok, state}
  end

  def handle_call(:halt_collections, _from, state) do
    # Stop static collectors, retract all dynamic probes, stop log endpoint.
    {:reply, :ok, state}
  end

  def handle_call(:get_status, _from, state) do
    # Aggregate status from child supervisors/managers.
    status = %{orchestrator_status: :running, collectors: %{}, dynamic_probes: %{}}
    # ... logic to get detailed status ...
    {:reply, status, state}
  end

  def handle_call({:deploy_dynamic_probe, probe_spec}, _from, state) do
    # Delegate to DynamicIntrospector.ProbeManager
    # reply = ElixirLumin.DataFabric.IngestionNode.DynamicIntrospector.ProbeManager.deploy(state.dynamic_probe_manager, probe_spec)
    reply = {:ok, "probe-" <> Ecto.UUID.generate()} # Placeholder
    {:reply, reply, state}
  end

  def handle_call({:retract_dynamic_probe, probe_id}, _from, state) do
    # Delegate to DynamicIntrospector.ProbeManager
    # reply = ElixirLumin.DataFabric.IngestionNode.DynamicIntrospector.ProbeManager.retract(state.dynamic_probe_manager, probe_id)
    reply = :ok # Placeholder
    {:reply, reply, state}
  end

  def handle_cast({:update_configuration, config_delta}, state) do
    # Update internal config state.
    # Propagate relevant parts of config_delta to static collectors, dynamic probe manager,
    # and also to the IngestionPipeline's IntelligentSamplerFilter.
    new_config = Map.merge(state.config, config_delta)
    # ... propogate ...
    {:noreply, %{state | config: new_config}}
  end
end
```

---

### 3. `ElixirLumin.DataFabric.IngestionNode.IngestionPipeline` Broadway Topology (Initial)

**Input:** Raw data items from all collection sources (static collectors, dynamic probes, external log ingestor). These are not yet `EvolutionaryEvent`s.
**Output:** Batches of validated, enriched `ElixirLumin.Common.EvolutionaryEvent` v1.0 structs, sent as a command to `EvolutionaryStorage`.

```elixir
defmodule ElixirLumin.DataFabric.IngestionNode.IngestionPipeline do
  use Broadway

  alias ElixirLumin.Common.{EvolutionaryEvent, Context} # Context for correlation
  alias Broadway.Message

  # --- Broadway Callbacks ---
  def start_link(opts) do
    # Configured by CollectionOrchestrator based on global ElixirLumin config
    # Example opts: [producer_stages: N, processor_stages: M, batcher_stages: P]
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {ElixirLumin.DataFabric.IngestionNode.IngestionPipeline.EventProducer, opts},
        concurrency: Keyword.get(opts, :producer_stages, System.schedulers_online())
      ],
      processors: [
        default: [
          concurrency: Keyword.get(opts, :processor_stages, System.schedulers_online() * 2),
          stages: [
            # Stage 1: Normalize diverse raw inputs into a preliminary event map
            {ElixirLumin.DataFabric.IngestionNode.IngestionPipeline.RawEventNormalizer, :normalize, []},
            # Stage 2: Enrich with correlation IDs and ingestion metadata
            {ElixirLumin.DataFabric.IngestionNode.IngestionPipeline.ContextEnricher, :enrich, []},
            # Stage 3: Create the formal EvolutionaryEvent and validate basic structure
            {ElixirLumin.DataFabric.IngestionNode.IngestionPipeline.EventFinalizerAndValidator, :finalize_and_validate, []},
            # Stage 4: (Future Phase 1) PII Redaction
            # Stage 5: Intelligent Sampling & Filtering (basic for Phase 0)
            {ElixirLumin.DataFabric.IngestionNode.IngestionPipeline.BasicSamplerFilter, :sample_or_filter, []}
          ]
        ]
      ],
      batchers: [
        event_store_batcher: [
          concurrency: Keyword.get(opts, :batcher_stages, 2), # Typically fewer batchers
          batch_size: Keyword.get(opts, :batch_size, 100),
          batch_timeout: Keyword.get(opts, :batch_timeout, 1000) # milliseconds
        ]
      ]
    )
  end

  # Producer (fed by collectors/ingestors via GenStage.cast)
  defmodule EventProducer do
    use GenStage
    def init(opts), do: {:producer, opts} # opts might include buffer settings
    def handle_cast(event_batch, state), do: {:noreply, Enum.map(event_batch, fn raw_event -> Message.new(raw_event) end), state}
    def handle_demand(_demand, state), do: {:noreply, [], state} # Demand driven by Broadway
  end

  # Processor Modules (each implements `transform/2`)
  defmodule RawEventNormalizer do
    def normalize(raw_event_data, _message_options) do
      # Logic to transform various inputs (log string, trace tuple, probe map)
      # into a common map structure with at least :type, :raw_timestamp, :raw_data, :raw_source_info.
      # Example: if is_binary(raw_event_data) and looks_like_log(raw_event_data) ->
      #   parse_log_line(raw_event_data)
      # else if is_tuple(raw_event_data) and elem(raw_event_data,0) == :trace ->
      #   parse_dbg_trace(raw_event_data)
      # ...
      %{normalized_data: %{type: :external_log_ingested, raw_timestamp: DateTime.utc_now(), raw_data: raw_event_data, raw_source_info: %{component_id: "unknown"}}} # Placeholder
    end
  end

  defmodule ContextEnricher do
    def enrich(normalized_event_map, _message_options) do
      # Ensure :current_trace_id, :current_span_id, :current_parent_span_id,
      # :current_session_id, :current_user_tags are extracted or generated.
      # Use ElixirLumin.Common.Context helpers if context is propagated from collectors.
      # For new traces (e.g., an uncorrelated external log), generate a new trace_id.
      trace_id = Context.get_trace_id() || безопасный_uuid_v4()
      span_id = Context.get_span_id() || безопасный_uuid_v4()

      Map.merge(normalized_event_map, %{
        ingestion_metadata: %{
          received_at: DateTime.utc_now(),
          ingestor_node_str: Atom.to_string(Node.self())
        },
        correlation_context: %{
          trace_id: trace_id,
          span_id: span_id,
          parent_span_id: Context.get_parent_span_id(),
          session_id: Context.get_debug_session_id(),
          user_correlation_tags: Context.get_user_tags() || %{}
        }
      })
    end
  end

  defmodule EventFinalizerAndValidator do
    def finalize_and_validate(enriched_event_map, _message_options) do
      # Construct the full ElixirLumin.Common.EvolutionaryEvent v1.0 struct
      # from the enriched_event_map.
      # Perform basic validation: required fields present, timestamp is valid DateTime.
      # Placeholder for actual construction:
      event_type = Map.get(enriched_event_map, :normalized_data)[:type]
      data = Map.get(enriched_event_map, :normalized_data)[:raw_data]
      source_id_map = Map.get(enriched_event_map, :normalized_data)[:raw_source_info]
      # ... map all fields correctly ...
      source_identity = %{ # map from source_id_map
        app_name: Map.get(source_id_map, :app_name),
        node: Map.get(source_id_map, :node, Atom.to_string(Node.self())),
        # ... other source_identity fields ...
        component_id: Map.get(source_id_map, :component_id, "default_component") # ensure default
      }
      ingestion_meta = Map.get(enriched_event_map, :ingestion_metadata, %{})
      # Add event_schema_version and event_envelope_version
      ingestion_meta = Map.merge(ingestion_meta, %{event_schema_version: "inferred.v1.0", event_envelope_version: "1.0"})


      correlation_map = Map.get(enriched_event_map, :correlation_context, %{})

      final_event = struct(EvolutionaryEvent,
        id: безопасный_uuid_v4(),
        type: event_type,
        timestamp: Map.get(enriched_event_map, :normalized_data)[:raw_timestamp],
        data: data,
        source_identity: source_identity, # map all fields from raw_source_info
        ingestion_metadata: ingestion_meta,
        correlation: correlation_map
        # Other fields default to nil/empty for v1.0
      )

      # Basic validation
      if is_atom(final_event.type) && is_map(final_event.data) && is_map(final_event.source_identity) do
        {:ok, final_event}
      else
        # If validation fails, transform to an :event_ingestion_error event
        # or mark the message to be acked without batching (and log the error).
        # For simplicity here, let's assume it passes or becomes an error event.
        error_event = struct(EvolutionaryEvent,
            id: безопасный_uuid_v4(),
            type: :event_ingestion_error,
            timestamp: DateTime.utc_now(),
            data: %{original_event_snippet: inspect(enriched_event_map, limit: 100), error: "validation_failed"},
            source_identity: %{node: Atom.to_string(Node.self()), component_id: "IngestionPipeline.EventFinalizer"},
            ingestion_metadata: %{received_at: DateTime.utc_now(), ingestor_node_str: Atom.to_string(Node.self()), event_schema_version: "error.v1.0", event_envelope_version: "1.0"},
            correlation: %{trace_id: Map.get(enriched_event_map.correlation_context, :trace_id)}
        )
        {:error_transformed, error_event} # Custom tuple to signal transformation
      end
    end
  end

  defmodule BasicSamplerFilter do
    def sample_or_filter(event_or_tuple, _message_options) do
        # If it's an error_transformed event, always pass it
        case event_or_tuple do
            {:error_transformed, error_event} ->
                error_event # Pass the error event directly
            final_event when is_struct(final_event, EvolutionaryEvent) ->
                # Apply basic sampling/filtering rules from ConfigManager
                # Rules: pass all :error_log, :process_crashed, :detected_pattern_instance.
                # Sample other types based on config (e.g., 10% of :info_log).
                # For Phase 0, maybe just pass all successfully transformed events.
                if final_event.type in [:event_ingestion_error] or ElixirLumin.Common.Config.should_sample?(final_event.type) do
                    final_event # Pass the event
                else
                    :filter_out # Atom to indicate filtering
                end
            _ ->
                # Should not happen if previous stages are correct
                :filter_out
        end
    end
  end

  # Batcher
  @impl true
  def handle_batch(:event_store_batcher, messages, _batch_info, _context) do
    # Filter out any :filter_out signals from messages
    events_to_store =
      messages
      |> Enum.map(&(&1.data))
      |> Enum.reject(&(&1 == :filter_out))

    if Enum.any?(events_to_store) do
      # Dispatch RecordEventBatchCommand to EvolutionaryStorage (Commanded application)
      # Stream ID could be based on trace_id, or a global stream for Phase 0.
      # For Phase 0, let's use a single global stream ID for simplicity.
      global_stream_id = "elixirlumin_global_event_stream"
      command = %ElixirLumin.DataFabric.ProcessingNode.EventStoreApplication.RecordEventBatchCommand{
        stream_id: global_stream_id,
        events: events_to_store
      }

      case ElixirLumin.DataFabric.ProcessingNode.EventStoreApplication.dispatch(command) do
        :ok ->
          messages # Ack all original messages if dispatch was successful
        {:error, reason} ->
          # Decide on retry strategy or dead-lettering. For Phase 0, fail the batch.
          Logger.error("Failed to dispatch event batch to EventStore: #{inspect(reason)}")
          Enum.map(messages, &Message.failed(&1, "event_store_dispatch_failed"))
      end
    else
      messages # Ack messages if all were filtered out
    end
  end

  defp безопасный_uuid_v4, do: Ecto.UUID.generate()
end
```

---

### 4. `ElixirLumin.DataFabric.ProcessingNode.EventStoreApplication` (Commanded with PostgreSQL)

This is the Commanded application responsible for persisting `EvolutionaryEvent`s.

**Backend Choice for Phase 0: Commanded with PostgreSQL Adapter.**
*   **Reasoning:**
    *   **Robust & Mature:** PostgreSQL is a reliable, feature-rich RDBMS.
    *   **Ecto Integration:** `commanded_ecto_adapter` provides good integration. Ecto is standard in Elixir for DB interaction, making projections easier.
    *   **JSONB Support:** Excellent for storing the flexible `EvolutionaryEvent.data` and other map fields.
    *   **Transactional Guarantees:** Ensures atomicity for event batches.
    *   **Scalability:** PostgreSQL scales well for many workloads.
    *   **Tooling:** Rich ecosystem of tools for PostgreSQL management and querying.

```elixir
defmodule ElixirLumin.DataFabric.ProcessingNode.EventStoreApplication do
  use Commanded.Application, otp_app: :elixirlumin_sentience_horizon # Use your app name

  # --- Commands ---
  defmodule RecordEventBatchCommand do
    @derive {Jason.Encoder, except: [:events_binary]} # For logging, not for event data itself
    defstruct [:stream_id, :events, :expected_version, :metadata]
    # :events will be a list of ElixirLumin.Common.EvolutionaryEvent structs
    # :events_binary would be if we pre-serialized, but Commanded handles serialization
  end

  # --- Events ---
  defmodule EventBatchRecordedEvent do
    @derive Jason.Encoder # This is what gets stored in the event store
    defstruct [:stream_id, :events, :recorded_at, :metadata]
    # :events is a list of ElixirLumin.Common.EvolutionaryEvent structs
  end

  # --- Aggregates (Simple for Phase 0) ---
  defmodule GlobalEventStreamAggregate do
    defstruct [:stream_id, version: 0, last_recorded_at: nil]

    def execute(%GlobalEventStreamAggregate{stream_id: stream_id}, %RecordEventBatchCommand{events: events_list, metadata: cmd_metadata}) do
      # Basic validation: ensure events_list is a list of EvolutionaryEvent structs
      if is_list(events_list) && Enum.all?(events_list, &is_struct(&1, EvolutionaryEvent)) do
        %EventBatchRecordedEvent{
          stream_id: stream_id,
          events: events_list,
          recorded_at: DateTime.utc_now(),
          metadata: cmd_metadata
        }
      else
        # Consider raising an error or returning an error tuple that Commanded can handle
        # For simplicity, assuming valid events for now. Proper validation in Broadway pipeline.
        raise "Invalid event batch format"
      end
    end

    def apply(%GlobalEventStreamAggregate{} = agg, %EventBatchRecordedEvent{recorded_at: ts}) do
      %{agg | version: agg.version + 1, last_recorded_at: ts}
    end
  end

  # --- Router ---
  router do
    # For Phase 0, all events go to a single global stream aggregate.
    # More complex aggregates (per trace_id, per process) can be added in later phases.
    identify GlobalEventStreamAggregate, by: :stream_id

    dispatch RecordEventBatchCommand, to: GlobalEventStreamAggregate
  end

  # --- Projections (Read Models) for Phase 0 ---

  # 1. Simple Timeline Projection (stores key event fields, indexed by timestamp and trace_id)
  defmodule Phase0TimelineProjection do
    use Commanded.Projections.Ecto,
      application: ElixirLumin.DataFabric.ProcessingNode.EventStoreApplication,
      repo: ElixirLumin.Repo, # Define this Ecto Repo module
      name: "phase0_timeline_projection"

    # Ecto Schema for the projection
    defmodule TimelineEntry do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key {:id, :string, autogenerate: false} # Use EvolutionaryEvent.id
      schema "phase0_timeline_entries" do
        field :event_type, Ecto.Enum, values: [:process_spawned, :genserver_state_changed, :external_log_ingested, :error_log_captured, :metric_update, :function_called, :message_sent] # Add more as needed
        field :timestamp, :utc_datetime_usec
        field :trace_id, :string
        field :span_id, :string
        field :source_app_name, :string
        field :source_node_str, :string
        field :source_process_pid_str, :string
        field :source_component_id, :string
        field :data_summary_str, :string # A short summary of event.data
        field :severity_level, :string # e.g., "INFO", "ERROR", "TRACE" from logs/events

        # Store the full event for now for easy retrieval, can optimize later
        field :full_event_json, :map # Store the serialized EvolutionaryEvent

        timestamps(type: :utc_datetime_usec)
      end

      def changeset(entry, attrs) do
        entry
        |> cast(attrs, [:id, :event_type, :timestamp, :trace_id, :span_id, :source_app_name, :source_node_str, :source_process_pid_str, :source_component_id, :data_summary_str, :severity_level, :full_event_json])
        |> validate_required([:id, :event_type, :timestamp])
      end
    end

    # Project EventBatchRecordedEvent
    project %EventBatchRecordedEvent{events: events_list}, fn multi ->
      changesets =
        Enum.map(events_list, fn (event = %EvolutionaryEvent{}) ->
          TimelineEntry.changeset(%TimelineEntry{id: event.id}, %{
            event_type: event.type, # Ensure this is a value defined in Ecto.Enum
            timestamp: event.timestamp,
            trace_id: event.correlation.trace_id,
            span_id: event.correlation.span_id,
            source_app_name: event.source_identity.app_name,
            source_node_str: event.source_identity.node,
            source_process_pid_str: event.source_identity.process_pid_str,
            source_component_id: event.source_identity.component_id,
            data_summary_str: summarize_data(event.data), # Implement summarize_data/1
            severity_level: infer_severity(event), # Implement infer_severity/1
            full_event_json: Jason.encode!(event) # Storing full event for easy query in phase 0
          })
        end)

      Enum.reduce(changesets, multi, fn ch, acc_multi ->
        Ecto.Multi.insert(acc_multi, безопасный_uuid_v4(), ch)
      end)
    end

    defp summarize_data(data_map) when is_map(data_map) do
      # Simple summary, e.g., first few keys or specific fields.
      data_map
      |> Enum.take(3)
      |> Enum.map_join(", ", fn {k, v} -> "#{k}: #{inspect(v, limit: 20)}" end)
      |> String.slice(0, 200) # Limit length
    end
    defp summarize_data(_other), do: ""

    defp infer_severity(%EvolutionaryEvent{type: type, data: data}) do
      case type do
        :external_log_ingested -> Map.get(data, :level, "INFO") # Assuming logs have a level
        :internal_log_captured -> Map.get(data, :level, "INFO")
        :process_exited -> Map.get(data, :reason) != :normal && "ERROR" || "INFO"
        :function_raised -> "ERROR"
        :event_ingestion_error -> "ERROR"
        :detected_pattern_instance -> Map.get(data, :pattern_severity, "WARN")
        _ -> "TRACE"
      end |> to_string()
    end
  end

  # 2. Entity State Projection (Basic for Phase 0 - e.g., latest GenServer state)
  defmodule Phase0EntityStateProjection do
    use Commanded.Projections.Ecto,
      application: ElixirLumin.DataFabric.ProcessingNode.EventStoreApplication,
      repo: ElixirLumin.Repo,
      name: "phase0_entity_state_projection"

    defmodule EntityState do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key {:entity_id_str, :string, autogenerate: false} # e.g., PID string, module string
      schema "phase0_entity_states" do
        field :entity_type, :string # "process", "genserver_module", "function_mfa"
        field :last_known_state_json, :map # Store serialized state
        field :last_event_timestamp, :utc_datetime_usec
        field :event_count, :integer, default: 0

        timestamps(type: :utc_datetime_usec)
      end

      def changeset(entry, attrs) do
        entry
        |> cast(attrs, [:entity_id_str, :entity_type, :last_known_state_json, :last_event_timestamp, :event_count])
        |> validate_required([:entity_id_str, :entity_type])
      end
    end

    project %EventBatchRecordedEvent{events: events_list}, fn multi ->
      Enum.reduce(events_list, multi, fn (event = %EvolutionaryEvent{type: :genserver_state_changed, data: %{new_state: new_state}, source_identity: %{process_pid_str: pid_str}, timestamp: ts}), acc_multi ->
        # Only track :genserver_state_changed for this example
        entity_id = pid_str
        entity_type = "genserver_process"
        state_json = Jason.encode!(new_state)

        upsert_op = Ecto.Multi.insert(acc_multi, "upsert_state_#{entity_id}",
          EntityState.changeset(%EntityState{}, %{
            entity_id_str: entity_id,
            entity_type: entity_type,
            last_known_state_json: state_json,
            last_event_timestamp: ts,
            event_count: 1 # Placeholder, should increment correctly
          }),
          on_conflict: [set: [last_known_state_json: state_json, last_event_timestamp: ts],
                        inc: [event_count: 1]], # Ecto upsert inc needs specific syntax
          conflict_target: :entity_id_str
        )
        # Note: Ecto's `inc` on upsert requires more setup. For simplicity, could be two ops: update or insert.
        # A more robust way is to fetch, update, then upsert, or use raw SQL.
        # For Phase 0, a simpler update logic might be used, e.g., always replacing if timestamp is newer.
        # This is a simplification.

      upsert_op
      # Non-genserver_state_changed events are ignored by this projection
      acc_multi -> acc_multi
      end)
    end
  end
  defp безопасный_uuid_v4, do: Ecto.UUID.generate()
end
```

---

### 5. Basic Pattern Detection Algorithms (Outline for Phase 0)

Operates on data from `Phase0TimelineProjection` or `Phase0EntityStateProjection`. This module will be a GenServer, periodically querying projections and analyzing data.

```elixir
defmodule ElixirLumin.IntelligenceCore.AnalyticalProcessors.BasicPatternDetector do
  use GenServer
  alias ElixirLumin.Repo
  alias ElixirLumin.DataFabric.ProcessingNode.EventStoreApplication.Phase0TimelineProjection.TimelineEntry

  # --- Client API ---
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Triggers an immediate pattern detection run. For scheduled runs, use handle_info."
  def run_detection_now() do
    GenServer.cast(__MODULE__, :run_detection)
  end

  # --- Server Implementation ---
  def init(opts) do
    # Config: detection_interval_ms, thresholds for various patterns.
    config = Keyword.merge([detection_interval_ms: 60_000], opts)
    schedule_detection(config.detection_interval_ms)
    {:ok, %{config: config, last_processed_timestamp: nil}}
  end

  def handle_cast(:run_detection, state) do
    detect_patterns(state)
    {:noreply, state}
  end

  def handle_info(:scheduled_detection_tick, state) do
    new_state = detect_patterns(state)
    schedule_detection(state.config.detection_interval_ms)
    {:noreply, new_state}
  end

  defp schedule_detection(interval_ms) do
    Process.send_after(self(), :scheduled_detection_tick, interval_ms)
  end

  defp detect_patterns(state) do
    # For Phase 0, query the last N minutes of data from projections.
    # More sophisticated state management for `last_processed_timestamp` is needed for continuous processing.
    time_window_start = DateTime.add(DateTime.utc_now(), -5, :minute) # Example: 5 min window

    # 1. Error Rate Spikes
    error_events =
      from(t in TimelineEntry,
        where: t.severity_level == "ERROR" and t.timestamp >= ^time_window_start,
        select: {t.timestamp, t.source_component_id}
      ) |> Repo.all()

    # Group by source_component_id and count per minute/second
    # ... analysis logic ...
    if high_error_rate_detected_for_component(error_events, "some_component", state.config) do
      emit_pattern_event(:error_rate_spike, %{component: "some_component", rate: "X/min"})
    end

    # 2. High-Frequency Function Calls/Messages
    # Example: Count calls to a specific function
    # SELECT count(id), data_summary_str FROM phase0_timeline_entries
    # WHERE event_type = 'function_called' AND data_summary_str LIKE 'MyMod.my_fun/%' AND timestamp >= ...
    # GROUP BY data_summary_str HAVING count(id) > threshold
    # ... analysis logic for function calls and messages ...

    # 3. Unusual State Transitions (Simple - based on EntityStateProjection)
    # Fetch recently updated entity states. If a GenServer's state size changed drastically or
    # a specific known field took an unexpected value.
    # ... analysis logic ...

    # 4. Consecutive Identical Log Messages
    # Query TimelineEntry for external_log_ingested or internal_log_captured
    # Group by source_component_id and data_summary_str, then look for high counts in short time.
    # ... analysis logic ...

    # 5. Basic Correlation (e.g., error log after external API call)
    # Query TimelineEntry for pairs of events with same trace_id, where event A is an API call
    # and event B is an error, and B.timestamp is shortly after A.timestamp.
    # ... analysis logic ...

    %{state | last_processed_timestamp: DateTime.utc_now()} # Update last processed time
  end

  defp emit_pattern_event(pattern_type, pattern_data) do
    # Create an EvolutionaryEvent of type :detected_pattern_instance
    # and dispatch it to the EventStore.
    source_id = %{node: Atom.to_string(Node.self()), component_id: "BasicPatternDetector"}
    event = EvolutionaryEvent.new(:detected_pattern_instance, %{pattern_type: pattern_type, details: pattern_data}, source_id)
    # This should ideally go via the ingestion pipeline for consistency, but for simplicity here:
    ElixirLumin.DataFabric.ProcessingNode.EventStoreApplication.dispatch(%ElixirLumin.DataFabric.ProcessingNode.EventStoreApplication.RecordEventBatchCommand{
        stream_id: "elixirlumin_analysis_events", events: [event]
    })
    Logger.info("Detected pattern: #{pattern_type} - #{inspect(pattern_data)}")
  end

  defp high_error_rate_detected_for_component(_error_events, _component, _config) do
    # Placeholder for actual rate detection logic
    false
  end
end
```

---

This Phase 0 deep dive provides concrete specifications for:
*   The fundamental `EvolutionaryEvent` v1.0.
*   The API and role of the `CollectionOrchestrator`.
*   An initial Broadway topology for the `IngestionPipeline`, detailing key transformation and validation stages.
*   The choice of Commanded with PostgreSQL for `EvolutionaryStorage`, including aggregate, command, event definitions, and basic Ecto projections for timeline and entity state.
*   An outline of "basic" pattern detection algorithms and the GenServer that would execute them.

This sets a strong, buildable foundation that is explicitly designed for the evolutionary capabilities envisioned in ElixirLumin: Sentience Horizon / ElixirScope Nexus. Subsequent phases will build upon these core components, enhancing the `EvolutionaryEvent` schema, adding more sophisticated processors to the Broadway pipeline, developing richer projections, and implementing advanced AI/ML models for pattern detection and insights.
