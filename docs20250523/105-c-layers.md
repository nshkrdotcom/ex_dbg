Looking at the prompt and the comprehensive documentation provided, I'll create a detailed technical checklist for the foundational layer with a layered testing strategy. This builds on the excellent architectural foundation in `006-g-foundation-responseToClaude.md` and the PRD vision.


# ElixirScope Foundation Layer: Technical Implementation Checklist

## Overview & Methodology

This checklist implements the **AI-Powered Execution Cinema Debugger** foundation from the ElixirScope PRD, based on the refined architecture in `006-g-foundation-responseToClaude.md`. 

**Core Principles:**
- **Layered Construction**: Foundation built in 7 sequential layers (0-6)
- **Gated Progression**: All tests for layer N must pass before starting layer N+1
- **Performance First**: Hot path optimization prioritized throughout
- **AI-Driven Design**: Architecture prepared for AI orchestration from Layer 0

---

## Layer 0: Core Data Primitives & Configuration Foundation

**Purpose**: Establish fundamental data structures, configuration management, and utilities that underpin the entire system.

### Technical Implementation Tasks

#### Core Data Structures
- [ ] **Event Schema Design**
  - [ ] Define `ElixirScope.Events.Base` with universal fields:
    - `event_id` (unique, fast generation)
    - `timestamp` (high-resolution monotonic)
    - `pid` (source process)
    - `node` (for future distributed support)
    - `correlation_id` (optional, for causal linking)
  - [ ] Define specialized event types:
    - `FunctionEntry` (module, function, arity, args)
    - `FunctionExit` (return_value or exception)
    - `StateChange` (old_state_ref, new_state_ref, callback)
    - `MessageSend` (to_pid, message_ref)
    - `MessageReceive` (from_pid, message_ref)
    - `ProcessSpawn` (parent_pid, child_pid)
    - `ProcessExit` (reason, linked_pids)
  - [ ] Implement efficient binary serialization/deserialization
  - [ ] Add event size limits to prevent memory issues

#### Configuration Management
- [ ] **`ElixirScope.Config`**
  - [ ] Support config.exs and runtime Application.env
  - [ ] Define configuration schema:
    - AI settings (model preferences, API keys)
    - Instrumentation levels (:minimal, :debug, :full_recall)
    - Storage settings (ETS limits, disk paths)
    - Performance tuning (ring buffer sizes, worker pools)
  - [ ] Implement validation with clear error messages
  - [ ] Support hot configuration updates for non-critical settings

#### Utility Functions
- [ ] **`ElixirScope.Utils`**
  - [ ] High-resolution timestamp generation (nanosecond precision)
  - [ ] Distributed-safe unique ID generation
  - [ ] Safe data inspection (handle large terms, circular refs)
  - [ ] Node identification and metadata capture

### Layer 0 Testing Strategy

#### Unit Tests
- [ ] Config loading from various sources (file, env, defaults)
- [ ] Config validation (valid cases, invalid edge cases)
- [ ] Event struct creation and field validation
- [ ] Event serialization round-trip tests (all event types)
- [ ] Utility function correctness (ID uniqueness, timestamp precision)

#### Performance Tests
- [ ] Event serialization/deserialization speed benchmarks
- [ ] ID generation throughput tests
- [ ] Memory usage tests for event structs

#### Layer Acceptance Criteria
- [ ] ElixirScope application starts with default configuration
- [ ] All event types can be created, serialized, and deserialized
- [ ] Configuration validation prevents startup with invalid settings

---

## Layer 1: Ultra-High-Performance Event Ingestion

**Purpose**: Build the "hot path" - the fastest possible route from instrumented code to temporary storage.

### Technical Implementation Tasks

#### Lock-Free Ring Buffer
- [ ] **`ElixirScope.Capture.RingBuffer`**
  - [ ] Implement using `:persistent_term` for buffer storage
  - [ ] Use `:atomics` for read/write pointers and metadata
  - [ ] Support multiple buffer instances (per-scheduler or sharded)
  - [ ] Implement `write/2` (non-blocking, <100ns target)
  - [ ] Implement `read/1` and `read_batch/2` (blocking/non-blocking)
  - [ ] Overflow detection and configurable strategies (drop_oldest, signal)
  - [ ] Memory-mapped circular buffer design

#### Event Ingestor
- [ ] **`ElixirScope.Capture.Ingestor`**
  - [ ] Stateless function-based API (not GenServer)
  - [ ] `ingest_event/1`: timestamp assignment, ID generation, serialization
  - [ ] `ingest_batch/1`: optimized batch processing
  - [ ] Target <1μs per event processing time
  - [ ] Minimal error handling (fail-fast for performance)

#### Runtime Instrumentation Stubs
- [ ] **`ElixirScope.Capture.InstrumentationRuntime`**
  - [ ] Define complete API surface:
    - `enter_function/4` (module, function, args, metadata)
    - `exit_function/2` (call_id, result)
    - `capture_state_change/5` (pid, callback, old_state, new_state, metadata)
    - `capture_message_send/3` (to_pid, message, metadata)
    - `capture_message_receive/3` (from_pid, message, metadata)
    - `capture_process_spawn/2` (parent_pid, child_pid)
    - `capture_process_exit/2` (pid, reason)
  - [ ] Implement initial versions that forward to `Ingestor`
  - [ ] Add circuit breaker for error conditions

### Layer 1 Testing Strategy

#### Unit Tests
- [ ] RingBuffer write/read operations under normal conditions
- [ ] RingBuffer overflow handling and recovery
- [ ] Ingestor event processing and serialization
- [ ] InstrumentationRuntime API completeness

#### Property-Based Tests
- [ ] RingBuffer concurrent access (multiple writers/readers)
- [ ] Event ordering preservation under high load
- [ ] Memory safety under buffer overflow conditions

#### Performance Tests
- [ ] **Critical**: Ingestor throughput (target: >1M events/sec)
- [ ] **Critical**: Single event latency (target: <1μs average)
- [ ] RingBuffer contention under max scheduler load
- [ ] Memory allocation patterns (should be minimal)

#### Load Tests
- [ ] Sustained high event rates (10 minutes at 500k events/sec)
- [ ] Burst handling (1M events in 1 second)
- [ ] Memory stability during extended operation

#### Layer Acceptance Criteria
- [ ] Events can be pushed through InstrumentationRuntime → Ingestor → RingBuffer
- [ ] Performance targets met under realistic load
- [ ] No memory leaks or buffer corruption after stress testing
- [ ] System remains stable during overflow conditions

---

## Layer 2: Asynchronous Processing & Hot Storage

**Purpose**: Build the "off-ramp" that processes buffered events asynchronously and stores them for querying.

### Technical Implementation Tasks

#### Asynchronous Writer Pool
- [ ] **`ElixirScope.Storage.AsyncWriterPool`**
  - [ ] Implement worker pool (configurable size, 2-8 workers typical)
  - [ ] Workers read from RingBuffer, deserialize events
  - [ ] Batch processing for efficiency (configurable batch sizes)
  - [ ] Backpressure handling (pause consumption if storage saturated)
  - [ ] Worker restart strategy for failure isolation
  - [ ] Metrics collection (processed events, processing time)

#### Event Correlation Engine
- [ ] **`ElixirScope.EventCorrelator`**
  - [ ] Call ID management for function entry/exit pairing
  - [ ] Message ID generation and send/receive linking
  - [ ] Process parent/child relationship tracking
  - [ ] State change causality linking (which event triggered state change)
  - [ ] Prepare correlation metadata for future DAG construction
  - [ ] Handle correlation ID cleanup to prevent memory leaks

#### Hot Storage Layer
- [ ] **`ElixirScope.Storage.DataAccess`**
  - [ ] ETS table management with optimized indexes:
    - Primary: by event_id
    - Secondary: by (pid, timestamp)
    - Tertiary: by correlation_id
    - Quaternary: by event_type
  - [ ] Implement `write_event/1` and `write_batch/1`
  - [ ] Implement basic queries:
    - `get_events_by_pid/3` (pid, start_time, end_time)
    - `get_events_by_correlation/1` (correlation_id)
    - `get_state_timeline/1` (pid)
  - [ ] ETS data pruning based on time windows and memory limits
  - [ ] Optional: Initial disk persistence for warm data

#### Pipeline Management
- [ ] **`ElixirScope.Capture.PipelineManager`**
  - [ ] Supervise RingBuffer instances and AsyncWriterPool
  - [ ] Health monitoring and automatic recovery
  - [ ] Dynamic scaling of workers based on backlog
  - [ ] Pipeline metrics and observability

### Layer 2 Testing Strategy

#### Unit Tests
- [ ] AsyncWriterPool worker event processing logic
- [ ] EventCorrelator linking algorithms for various event sequences
- [ ] DataAccess ETS operations (write, read, index, prune)
- [ ] PipelineManager supervision and scaling logic

#### Integration Tests
- [ ] **Critical**: Full pipeline: RingBuffer → AsyncWriterPool → EventCorrelator → DataAccess
- [ ] Backpressure mechanisms between components
- [ ] Error handling and recovery scenarios
- [ ] Data integrity through the complete pipeline

#### Performance Tests
- [ ] AsyncWriterPool throughput under various worker counts
- [ ] DataAccess query performance on large datasets
- [ ] Memory usage during extended operation
- [ ] ETS pruning efficiency

#### Reliability Tests
- [ ] Worker failure and restart scenarios
- [ ] Pipeline behavior under memory pressure
- [ ] Data consistency during component failures

#### Layer Acceptance Criteria
- [ ] Events flow reliably from RingBuffer to ETS storage
- [ ] Correlation IDs correctly link related events
- [ ] Pipeline handles realistic load without data loss
- [ ] ETS pruning maintains system stability
- [ ] Basic queries return accurate, correlated event data

---

## Layer 3: AST Transformation & Code Instrumentation

**Purpose**: Build the compile-time system that automatically injects tracing calls into Elixir code.

### Technical Implementation Tasks

#### AST Injection Helpers
- [ ] **`ElixirScope.AST.InjectorHelpers`**
  - [ ] Function wrapping patterns:
    - `wrap_function_body/3` (preserve args, return value)
    - `inject_function_entry/3` (capture args, local context)
    - `inject_function_exit/2` (capture return value or exception)
  - [ ] GenServer callback instrumentation:
    - `instrument_handle_call/1` (capture state before/after)
    - `instrument_handle_cast/1`
    - `instrument_handle_info/1`
  - [ ] Variable capture patterns:
    - `capture_assignment/3` (variable name, value, line)
    - `capture_pattern_match/2` (pattern, value)
  - [ ] Safe code generation with proper scoping and hygiene

#### AST Transformer Engine
- [ ] **`ElixirScope.AST.Transformer`**
  - [ ] Core traversal using `Macro.prewalk/2` and `Macro.postwalk/2`
  - [ ] Instrumentation directive processing:
    - Parse instrumentation plans into actionable transformations
    - Apply transformations based on module/function/line targeting
  - [ ] Handle Elixir language constructs:
    - Function definitions (`def`, `defp`)
    - GenServer callbacks (via `use GenServer` detection)
    - Basic macro expansion awareness
    - Pattern matching and guards
  - [ ] Preserve original code semantics:
    - Maintain line numbers for debugging
    - Preserve variable scoping
    - Handle edge cases (anonymous functions, receives, etc.)
  - [ ] Error handling and reporting for invalid transformations

#### Enhanced Runtime Implementation
- [ ] **`ElixirScope.Capture.InstrumentationRuntime` (Complete)**
  - [ ] Optimize all API functions for production use
  - [ ] Add context awareness (call depth, process ancestry)
  - [ ] Implement sampling hooks (AI can decide to sample differently)
  - [ ] Add performance monitoring of instrumentation itself

### Layer 3 Testing Strategy

#### Unit Tests
- [ ] InjectorHelpers quote block generation for all patterns
- [ ] AST.Transformer specific transformation logic
- [ ] Edge case handling (complex patterns, nested functions)

#### Semantic Equivalence Tests (Critical)
- [ ] **Test Suite**: Create diverse Elixir modules:
  - Simple functions with various arities
  - GenServer implementations
  - Modules using common macros (Ecto, Phoenix)
  - Complex pattern matching and guards
- [ ] **Baseline**: Compile and test modules WITHOUT instrumentation
- [ ] **Instrumented**: Apply AST transformation and verify:
  - Identical functional behavior (same test results)
  - Proper InstrumentationRuntime calls are made
  - No performance degradation beyond acceptable limits
- [ ] **Regression Tests**: Ensure transformations don't break on language updates

#### Integration Tests
- [ ] AST.Transformer with various instrumentation plans
- [ ] Interaction between InjectorHelpers and Transformer
- [ ] Complete flow: source code → AST transformation → compilation → execution

#### Compilation Tests
- [ ] Transformed code compiles without warnings
- [ ] Beam file analysis shows expected function calls
- [ ] Hot code reloading works with instrumented modules

#### Layer Acceptance Criteria
- [ ] Sample Mix project can be automatically instrumented
- [ ] Instrumented code maintains semantic equivalence
- [ ] InstrumentationRuntime calls are made as expected
- [ ] No compilation errors or warnings from transformation
- [ ] Performance impact of instrumentation is within acceptable bounds

---

## Layer 4: AI-Driven Instrumentation Strategy

**Purpose**: Build the "brain" that analyzes code and intelligently decides what and how to instrument.

### Technical Implementation Tasks

#### Code Analysis Engine
- [ ] **`ElixirScope.AI.CodeAnalyzer`**
  - [ ] AST parsing and structural analysis:
    - Identify GenServer modules and callback patterns
    - Detect supervision tree structures
    - Find message passing patterns (call/cast/send/receive)
    - Analyze function complexity and call patterns
  - [ ] Static analysis heuristics:
    - Function length and complexity scoring
    - Concurrency pattern detection
    - Error-prone pattern identification
  - [ ] LLM integration interface (initially mock):
    - Prepare code/AST for LLM analysis
    - Parse structured LLM responses
    - Fallback to heuristics if LLM unavailable
  - [ ] Output structured codebase analysis

#### Instrumentation Planning Engine
- [ ] **`ElixirScope.AI.InstrumentationPlanner`**
  - [ ] Rule-based planning strategies:
    - "Debug mode": Instrument all GenServer callbacks
    - "Performance mode": Focus on slow functions and hot paths
    - "Minimal mode": Only critical paths and error conditions
  - [ ] Configuration-driven plan generation:
    - User-specified focus areas (specific modules/functions)
    - Performance budget allocation
    - Sampling strategy decisions
  - [ ] Instrumentation plan output format:
    - Map of `{module, function, arity}` to instrumentation directives
    - Directive types: `:trace_entry_exit`, `:capture_state`, `:trace_variables`
  - [ ] Plan optimization to balance detail vs. performance impact

#### AI Orchestration Layer
- [ ] **`ElixirScope.AI.Orchestrator`**
  - [ ] Analysis and planning lifecycle management
  - [ ] Caching of analysis results and plans
  - [ ] Plan versioning for code changes
  - [ ] API for requesting/retrieving instrumentation plans
  - [ ] Integration hooks for future LLM services
  - [ ] Metrics on analysis accuracy and plan effectiveness

### Layer 4 Testing Strategy

#### Unit Tests
- [ ] CodeAnalyzer pattern recognition on diverse code samples
- [ ] InstrumentationPlanner rule-based logic for different configurations
- [ ] Orchestrator state management and caching behavior

#### Accuracy Tests
- [ ] **Codebase Analysis**: Run CodeAnalyzer on established open-source projects:
  - Phoenix applications
  - OTP applications with complex supervision trees
  - Libraries with heavy GenServer usage
- [ ] **Manual Verification**: Expert review of identified patterns
- [ ] **Plan Quality**: Generated plans should be sensible and targeted

#### Integration Tests
- [ ] Orchestrator → CodeAnalyzer → InstrumentationPlanner workflow
- [ ] Plan caching and invalidation on code changes
- [ ] Error handling for analysis failures

#### Performance Tests
- [ ] Analysis time for large codebases (thousands of modules)
- [ ] Memory usage during analysis
- [ ] Plan generation speed

#### Layer Acceptance Criteria
- [ ] Orchestrator can analyze a moderate Elixir project (50-100 modules)
- [ ] Generated instrumentation plans are structurally valid
- [ ] Analysis correctly identifies major OTP patterns
- [ ] Performance is acceptable for development workflow integration

---

## Layer 5: Build System Integration & VM Tracing

**Purpose**: Integrate all components through the Mix build system and add VM-level event capture.

### Technical Implementation Tasks

#### Mix Compiler Integration
- [ ] **`ElixirScope.Compiler.MixTask`**
  - [ ] Implement `Mix.Task.Compiler` behavior
  - [ ] Integration with Mix compilation pipeline:
    - Run before standard Elixir compiler
    - Handle incremental compilation
    - Manage compilation dependencies
  - [ ] Instrumentation workflow:
    - Fetch plans from AI.Orchestrator
    - Apply AST.Transformer to each module
    - Handle compilation errors gracefully
  - [ ] Code reloading support:
    - Detect changed modules
    - Trigger re-analysis and re-instrumentation
    - Maintain instrumentation across hot reloads

#### VM-Level Event Capture
- [ ] **`ElixirScope.Capture.VMTracer`**
  - [ ] `:erlang.trace` integration:
    - Process lifecycle (spawn, exit, link, unlink)
    - Message passing (for uninstrumented code)
    - Selective tracing based on configuration
  - [ ] `:sys.trace` integration:
    - GenServer events from uninstrumented modules
    - OTP behavior callbacks
  - [ ] Event formatting and forwarding to Capture.Ingestor
  - [ ] Performance impact monitoring and throttling

#### Application Architecture
- [ ] **`ElixirScope` (Main Application)**
  - [ ] Supervisor tree design:
    - Config (startup)
    - AI.Orchestrator (early)
    - Capture.PipelineManager (core)
    - Storage.DataAccess (core)
    - VMTracer (optional)
  - [ ] Graceful startup and shutdown sequences
  - [ ] Public API: `start/1`, `stop/0`, `status/0`, `reconfigure/1`
  - [ ] Error isolation and recovery strategies

### Layer 5 Testing Strategy

#### Unit Tests
- [ ] MixTask compilation pipeline integration
- [ ] VMTracer event capture and formatting
- [ ] Application supervisor tree behavior

#### Integration Tests
- [ ] **Critical**: MixTask with AI.Orchestrator and AST.Transformer
- [ ] VMTracer integration with Capture.Ingestor
- [ ] Application startup/shutdown sequences
- [ ] Code reloading scenarios

#### End-to-End Foundation Tests
- [ ] **Complete Workflow Test**:
  1. Create sample Mix project with ElixirScope dependency
  2. Configure MixTask in `mix.exs`
  3. Run `mix compile`
  4. Verify MixTask executes and instruments code
  5. Run the application
  6. Verify events flow through entire pipeline
  7. Check ETS storage contains expected events
- [ ] **Multi-Module Test**: Complex project with GenServers, supervision trees
- [ ] **Phoenix Integration Test**: Basic Phoenix application instrumentation

#### Performance Tests
- [ ] Compilation time impact measurement
- [ ] Runtime overhead assessment
- [ ] Memory usage monitoring

#### Layer Acceptance Criteria
- [ ] Standard Mix project can be instrumented with minimal configuration
- [ ] Complete event pipeline functions correctly
- [ ] Instrumentation works across module boundaries
- [ ] Code reloading maintains instrumentation
- [ ] Performance impact is within acceptable limits (< 5% dev mode)

---

## Layer 6: Data Querying & Developer Interface

**Purpose**: Provide accessible interfaces for developers to interact with captured execution data.

### Technical Implementation Tasks

#### Query Coordination Layer
- [ ] **`ElixirScope.Storage.QueryCoordinator`**
  - [ ] High-level query APIs:
    - `get_process_timeline/2` (pid, time_range)
    - `get_state_history/1` (genserver_pid)
    - `trace_message_flow/2` (from_pid, to_pid)
    - `get_call_stack/2` (pid, timestamp)
    - `find_correlated_events/1` (correlation_id)
  - [ ] Query optimization and caching
  - [ ] Result formatting and pagination
  - [ ] Permission and access control hooks
  - [ ] Performance monitoring for query patterns

#### Developer Tools Interface
- [ ] **`ElixirScope.IExHelpers`**
  - [ ] Interactive functions for IEx:
    - `ElixirScope.status()` - system status and configuration
    - `ElixirScope.trace_pid(pid)` - recent activity for process
    - `ElixirScope.state_timeline(pid)` - GenServer state evolution
    - `ElixirScope.message_flow(pid1, pid2)` - message exchanges
    - `ElixirScope.analyze_performance()` - slow function identification
  - [ ] Result formatting for terminal display
  - [ ] Help system and documentation

#### Optional AI Integration
- [ ] **Basic Tidewave Integration**
  - [ ] Register QueryCoordinator functions as tools
  - [ ] Natural language query processing
  - [ ] Context-aware result explanation

### Layer 6 Testing Strategy

#### Unit Tests
- [ ] QueryCoordinator API functions with mock DataAccess
- [ ] IExHelpers formatting and error handling
- [ ] Query optimization logic

#### Integration Tests
- [ ] QueryCoordinator with real DataAccess using Layer 5 E2E data
- [ ] Complex queries across multiple event types
- [ ] Performance with large datasets

#### User Acceptance Tests
- [ ] **Manual Testing**: Use IExHelpers in live IEx session
- [ ] **Workflow Tests**: Common debugging scenarios
- [ ] **Documentation**: Verify help system and examples work

#### Performance Tests
- [ ] Query response times for various data sizes
- [ ] Memory usage during complex queries
- [ ] Concurrent query handling

#### Layer Acceptance Criteria
- [ ] Developers can query execution history through IEx
- [ ] Query results are accurate and useful for debugging
- [ ] Performance is acceptable for interactive use
- [ ] Documentation and help system guide effective usage

---

## Foundation Validation & Acceptance

### Final Integration Testing

- [ ] **Complete System Test**: Deploy foundation to real Phoenix application
- [ ] **Load Testing**: Sustained operation under realistic load
- [ ] **Reliability Testing**: 24-hour continuous operation
- [ ] **Performance Validation**: Overhead measurements in production-like environment

### Documentation & Handoff

- [ ] **Architecture Documentation**: Complete system overview
- [ ] **API Documentation**: All public interfaces documented
- [ ] **Performance Characteristics**: Benchmarks and scaling guidance
- [ ] **Known Limitations**: Current constraints and future work
- [ ] **Upgrade Path**: Plans for Phase 2 (Execution Cinema UI)

### Success Criteria for Foundation

The foundation is complete and ready for Phase 2 when:

1. **Automatic Instrumentation**: Any Elixir/Phoenix project can be instrumented with minimal setup
2. **Performance**: < 2% overhead in development, < 0.5% with minimal instrumentation
3. **Reliability**: No data loss under normal development loads
4. **Usability**: Developers can debug using captured data through IEx
5. **Extensibility**: Architecture supports planned Execution Cinema features

This foundation provides the robust, high-performance base required for the advanced AI-powered Execution Cinema features planned in subsequent phases.

Key aspects of my approach:

**1. Progressive Complexity**: I structured the layers to build from simple data primitives up to complex AI-driven instrumentation, ensuring each foundation is solid before adding complexity.

**2. Performance-First Design**: The hot path (Layer 1) is prioritized early and heavily tested, recognizing that the "total recall" vision requires exceptional performance in event capture.

**3. AI-Ready Architecture**: Even though initial implementations may use rules and heuristics, the structure is designed to seamlessly integrate LLM-based analysis when ready.

**4. Testing Rigor**: Each layer has comprehensive testing strategies including unit tests, integration tests, performance benchmarks, and acceptance criteria. This ensures the foundation can support the ambitious features planned for later phases.

**5. Developer Experience**: Layer 6 ensures that even with just the foundation, developers have useful tools for debugging, providing immediate value while building toward the full vision.

The checklist balances the ambitious technical goals (sub-microsecond event capture, AI-driven instrumentation) with practical development needs (reliable testing, incremental delivery, maintainable code). This foundation would provide a solid base for implementing the "Execution Cinema" UI and advanced AI analysis features in subsequent phases.
