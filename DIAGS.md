# ElixirScope Diagrams

## 1. **System Architecture** 
Shows the high-level component relationships, from the main entry point through data collection, storage, and integration layers. Highlights how ElixirScope coordinates between process observation, message interception, state recording, and external integrations.

```mermaid
graph LR
    subgraph "Main Entry Point"
        ES[ElixirScope]
    end
    
    subgraph "Core Data Collection Layer"
        PO[ProcessObserver]
        MI[MessageInterceptor]
        SR[StateRecorder]
        CT[CodeTracer]
    end
    
    subgraph "Storage & Query Layer"
        TDB[TraceDB]
        QE[QueryEngine]
    end
    
    subgraph "Integration Layer"
        AI[AIIntegration]
        PT[PhoenixTracker]
    end
    
    subgraph "External Systems"
        TW[Tidewave]
        PX[Phoenix App]
        ETS[(ETS Tables)]
    end
    
    %% Main setup connections
    ES -->|setup/1| PO
    ES -->|setup/1| MI
    ES -->|setup/1| SR
    ES -->|setup/1| CT
    ES -->|setup/1| TDB
    ES -->|setup/1| AI
    ES -->|setup/1| PT
    
    %% Data flow to storage
    PO -->|store_event| TDB
    MI -->|store_event| TDB
    SR -->|store_event| TDB
    CT -->|store_event| TDB
    PT -->|store_event| TDB
    
    %% Storage implementation
    TDB -->|stores in| ETS
    
    %% Query layer
    QE -->|queries| TDB
    ES -->|provides queries| QE
    
    %% AI Integration
    AI -->|registers tools| TW
    AI -->|queries via| QE
    AI -->|queries via| TDB
    
    %% Phoenix Integration
    PT -->|instruments| PX
    
    %% User interactions
    ES -.->|trace_module| CT
    ES -.->|trace_genserver| SR
    ES -.->|state_timeline| QE
    ES -.->|message_flow| QE
    
    classDef entry fill:#e1f5fe,color:#000
    classDef collector fill:#f3e5f5,color:#000
    classDef storage fill:#e8f5e8,color:#000
    classDef integration fill:#fff3e0,color:#000
    classDef external fill:#ffebee,color:#000
    
    class ES entry
    class PO,MI,SR,CT collector
    class TDB,QE storage
    class AI,PT integration
    class TW,PX,ETS external
```

## 2. **Data Flow & Event Processing**
Illustrates how events flow from various sources (process spawns, messages, state changes, function calls) through the data collectors, processing pipeline (sampling, formatting), storage layer, and finally to query interfaces and AI integration.

```mermaid
graph TD
    subgraph "Event Sources"
        PS[Process Spawns/Exits]
        MS[Message Send/Receive]
        SC[State Changes]
        FC[Function Calls]
        PE[Phoenix Events]
    end
    
    subgraph "Data Collectors"
        PO[ProcessObserver<br/>- Monitors process lifecycle<br/>- Tracks supervision tree]
        MI[MessageInterceptor<br/>- Captures inter-process msgs<br/>- Uses :dbg tracing]
        SR[StateRecorder<br/>- GenServer state tracking<br/>- Using macro or :sys.trace]
        CT[CodeTracer<br/>- Function call/return<br/>- Module-specific tracing]
        PT[PhoenixTracker<br/>- HTTP requests<br/>- LiveView events]
    end
    
    subgraph "Event Processing"
        SP[Sampling Logic<br/>sample_rate: 0.0-1.0<br/>Always keeps critical events]
        EF[Event Formatting<br/>- Sanitize large data<br/>- Add timestamps & IDs]
    end
    
    subgraph "Storage Layer"
        TDB[TraceDB GenServer]
        ET[ETS Tables<br/>:elixir_scope_events<br/>:elixir_scope_states<br/>:elixir_scope_process_index]
        CL[Cleanup Logic<br/>- Max events pruning<br/>- Oldest events first]
        PS2[Persistence<br/>- Optional disk storage<br/>- Binary format]
    end
    
    subgraph "Query Interface"
        QE[QueryEngine<br/>- High-level queries<br/>- Time-travel debugging]
        QF[Query Filters<br/>- By PID, type, time<br/>- Combined filters]
        QR[Query Results<br/>- Sorted by timestamp<br/>- Enriched with context]
    end
    
    subgraph "AI Integration"
        TT[Tidewave Tools<br/>- 9 registered functions<br/>- Natural language interface]
        AF[AI Functions<br/>- get_state_timeline<br/>- analyze_state_changes<br/>- get_message_flow]
    end
    
    %% Event flow
    PS --> PO
    MS --> MI
    SC --> SR
    FC --> CT
    PE --> PT
    
    %% Processing flow
    PO --> SP
    MI --> SP
    SR --> SP
    CT --> SP
    PT --> SP
    
    SP --> EF
    EF --> TDB
    
    %% Storage flow
    TDB --> ET
    TDB --> CL
    TDB --> PS2
    
    %% Query flow
    ET --> QF
    QF --> QE
    QE --> QR
    
    %% AI flow
    QE --> AF
    QR --> AF
    AF --> TT
    
    %% Feedback loops
    CL -.->|triggers when max_events reached| TDB
    PS2 -.->|periodic backup| TDB
    
    classDef source fill:#e3f2fd,color:#000
    classDef collector fill:#f1f8e9,color:#000
    classDef process fill:#fff8e1,color:#000
    classDef storage fill:#fce4ec,color:#000
    classDef query fill:#e8eaf6,color:#000
    classDef ai fill:#f3e5f5,color:#000
    
    class PS,MS,SC,FC,PE source
    class PO,MI,SR,CT,PT collector
    class SP,EF process
    class TDB,ET,CL,PS2 storage
    class QE,QF,QR query
    class TT,AF ai
```

## 3. **Module Dependencies & Interactions**
Maps the specific dependencies between modules, showing both the logical flow (setup → storage → query) and implementation dependencies (GenServer, :dbg, ETS, etc.). This helps understand the layered architecture.



```mermaid
graph LR
    subgraph "lib/elixir_scope.ex"
        ES[ElixirScope<br/>Main API<br/>- setup/1<br/>- trace_module/1<br/>- trace_genserver/1<br/>- state_timeline/1<br/>- message_flow/2]
    end
    
    subgraph "Core Modules"
        TDB[TraceDB<br/>Storage Layer<br/>- GenServer<br/>- ETS tables<br/>- Event sampling<br/>- Persistence]
        
        QE[QueryEngine<br/>Query Layer<br/>- High-level queries<br/>- Time-travel debugging<br/>- State reconstruction]
        
        PO[ProcessObserver<br/>Process Monitoring<br/>- Lifecycle tracking<br/>- Supervision tree<br/>- Process info collection]
        
        MI[MessageInterceptor<br/>Message Tracing<br/>- :dbg integration<br/>- Send/receive capture<br/>- Configurable levels]
        
        SR[StateRecorder<br/>State Tracking<br/>- GenServer states<br/>- __using__ macro<br/>- :sys.trace integration]
        
        CT[CodeTracer<br/>Function Tracing<br/>- Module instrumentation<br/>- Call/return events<br/>- Source correlation]
    end
    
    subgraph "Integration Modules"
        AI[AIIntegration<br/>Tidewave Integration<br/>- Tool registration<br/>- Natural language interface<br/>- 9 AI functions]
        
        PT[PhoenixTracker<br/>Phoenix Integration<br/>- HTTP requests<br/>- LiveView events<br/>- Channel tracking]
    end
    
    subgraph "Dependencies"
        direction TB
        GS[GenServer<br/>OTP Behavior]
        DBG[:dbg<br/>Erlang Tracer]
        ETS[ETS<br/>In-memory storage]
        SYS[:sys<br/>System debugging]
        TW[Tidewave<br/>External AI system]
        PX[Phoenix<br/>Web framework]
    end
    
    %% Main API relationships
    ES -->|starts & configures| TDB
    ES -->|starts & configures| PO
    ES -->|starts & configures| MI
    ES -->|starts & configures| SR
    ES -->|starts & configures| CT
    ES -->|optionally starts| AI
    ES -->|optionally starts| PT
    ES -->|delegates queries to| QE
    
    %% Core module relationships
    PO -->|stores events in| TDB
    MI -->|stores events in| TDB
    SR -->|stores events in| TDB
    CT -->|stores events in| TDB
    PT -->|stores events in| TDB
    QE -->|queries data from| TDB
    AI -->|queries via| QE
    AI -->|queries via| TDB
    
    %% Implementation dependencies
    TDB -.->|implements| GS
    TDB -.->|uses| ETS
    PO -.->|implements| GS
    MI -.->|implements| GS
    MI -.->|uses| DBG
    SR -.->|uses| SYS
    CT -.->|implements| GS
    CT -.->|uses| DBG
    AI -.->|registers with| TW
    PT -.->|instruments| PX
    
    %% Data flow indicators
    ES ==>|setup flow| TDB
    TDB ==>|storage flow| QE
    QE ==>|query flow| AI
    
    classDef api fill:#e1f5fe,stroke:#0277bd,stroke-width:3px,color:#000
    classDef core fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#000
    classDef integration fill:#fff3e0,stroke:#ef6c00,stroke-width:2px,color:#000
    classDef external fill:#ffebee,stroke:#c62828,stroke-width:1px,color:#000
    
    class ES api
    class TDB,QE,PO,MI,SR,CT core
    class AI,PT integration
    class GS,DBG,ETS,SYS,TW,PX external
```

## 4 - Test Structure & Coverage

```mermaid
graph TB
    subgraph "Test Environment Setup"
        TH[test_helper.exs<br/>- TraceDB initialization<br/>- ETS table setup<br/>- Test mode configuration]
        TD[TraceDBDiagnostic<br/>- Data inspection utilities<br/>- Debug output helpers<br/>- Table analysis tools]
    end
    
    subgraph "Core Module Tests"
        TDB_T[trace_db_test.exs<br/>940 lines<br/>- Initialization tests<br/>- Event storage<br/>- Sampling logic<br/>- Query functionality<br/>- State history<br/>- Management features]
        
        PO_T[process_observer_test.exs<br/>126 lines<br/>- Initialization<br/>- Process lifecycle<br/>- Information collection<br/>- TraceDB integration]
        
        SR_T[state_recorder_test.exs<br/>212 lines<br/>- GenServer integration<br/>- State change tracking<br/>- External process tracing<br/>- Wrapper functions]
        
        MI_T[message_interceptor_test.exs<br/>273 lines<br/>- Initialization<br/>- Tracing control<br/>- Message capture<br/>- Process-specific tracing]
    end
    
    subgraph "Test Modules & Helpers"
        SGS[SimpleGenServer<br/>Test GenServer<br/>- Basic operations<br/>- State management<br/>- Message handling]
        
        TW[TestWrapper<br/>Manual event storage<br/>- store_init_event<br/>- store_call_events<br/>- store_cast_events<br/>- store_info_events]
        
        TS[TestServer<br/>GenServer for testing<br/>- Call/cast handling<br/>- State updates]
    end
    
    subgraph "Test Categories"
        direction TB
        
        subgraph "TraceDB Test Groups"
            INIT[Initialization<br/>- Default options<br/>- Custom options<br/>- ETS table creation]
            
            STOR[Event Storage<br/>- Basic events<br/>- Unique IDs<br/>- PID indexing<br/>- Complex data]
            
            SAMP[Sampling<br/>- 100% sampling<br/>- 0% sampling<br/>- Critical events<br/>- Deterministic behavior]
            
            QUER[Query Tests<br/>- By type<br/>- By PID<br/>- By timestamp<br/>- Combined filters]
            
            HIST[State History<br/>- Timeline retrieval<br/>- Events at time<br/>- State at timestamp<br/>- Adjacent events]
            
            MGMT[Management<br/>- Clear operations<br/>- Event cleanup<br/>- Persistence<br/>- Max events handling]
        end
        
        subgraph "Integration Test Areas"
            PROC[Process Tests<br/>- Lifecycle tracking<br/>- Information collection<br/>- TraceDB registration]
            
            STATE[State Tests<br/>- GenServer tracking<br/>- Call/cast/info handling<br/>- External tracing]
            
            MSG[Message Tests<br/>- Send/receive capture<br/>- Process-specific tracing<br/>- GenServer calls]
        end
    end
    
    %% Test relationships
    TH -->|provides setup for| TDB_T
    TH -->|provides setup for| PO_T
    TH -->|provides setup for| SR_T
    TH -->|provides setup for| MI_T
    
    TD -.->|diagnostic support| TDB_T
    TD -.->|diagnostic support| SR_T
    
    %% Test module usage
    SGS -.->|used by| SR_T
    TW -.->|used by| SR_T
    TS -.->|used by| MI_T
    
    %% Test category relationships
    TDB_T -->|contains| INIT
    TDB_T -->|contains| STOR
    TDB_T -->|contains| SAMP
    TDB_T -->|contains| QUER
    TDB_T -->|contains| HIST
    TDB_T -->|contains| MGMT
    
    PO_T -->|implements| PROC
    SR_T -->|implements| STATE
    MI_T -->|implements| MSG
    
    %% Test coverage flow
    INIT ==>|validates| STOR
    STOR ==>|enables| SAMP
    SAMP ==>|supports| QUER
    QUER ==>|provides| HIST
    HIST ==>|requires| MGMT
    
    classDef setup fill:#e3f2fd,stroke:#1976d2,color:#000
    classDef testfile fill:#e8f5e8,stroke:#388e3c,color:#000
    classDef helper fill:#fff3e0,stroke:#f57c00,color:#000
    classDef category fill:#f3e5f5,stroke:#7b1fa2,color:#000
    classDef integration fill:#ffebee,stroke:#d32f2f,color:#000
    
    class TH,TD setup
    class TDB_T,PO_T,SR_T,MI_T testfile
    class SGS,TW,TS helper
    class INIT,STOR,SAMP,QUER,HIST,MGMT category
    class PROC,STATE,MSG integration
```

## 5. **AI Integration & Tidewave Tools**
Details the comprehensive AI integration, showing all 9 registered Tidewave tools, their implementation functions, helper utilities, and data source connections. This demonstrates the natural language debugging capabilities.


```mermaid
graph LR
    subgraph "AI Integration Module"
        AI[AIIntegration<br/>Main Integration Point]
        SETUP[setup/0<br/>- Check Tidewave availability<br/>- Register tools if available]
        REG[register_tidewave_tools/0<br/>- Verify Tidewave.Plugin<br/>- Register all 9 tools]
    end
    
    subgraph "Registered Tidewave Tools"
        direction TB
        
        GST[elixir_scope_get_state_timeline<br/>Args: pid_string<br/>Returns: State history with timestamps]
        
        GMF[elixir_scope_get_message_flow<br/>Args: from_pid, to_pid<br/>Returns: Message exchanges between processes]
        
        GFC[elixir_scope_get_function_calls<br/>Args: module_name<br/>Returns: Function calls for module]
        
        TM[elixir_scope_trace_module<br/>Args: module_name<br/>Action: Start tracing module]
        
        TP[elixir_scope_trace_process<br/>Args: pid_string<br/>Action: Start tracing process by PID]
        
        TNP[elixir_scope_trace_named_process<br/>Args: process_name<br/>Action: Start tracing by registered name]
        
        GST2[elixir_scope_get_supervision_tree<br/>Args: none<br/>Returns: Current supervision hierarchy]
        
        GEP[elixir_scope_get_execution_path<br/>Args: pid_string<br/>Returns: Process execution sequence]
        
        ASC[elixir_scope_analyze_state_changes<br/>Args: pid_string<br/>Returns: State diffs and analysis]
    end
    
    subgraph "Tool Implementation Functions"
        direction LR
        
        TGST[tidewave_get_state_timeline/1<br/>- Decode PID string<br/>- Query state timeline<br/>- Format & summarize results]
        
        TGMF[tidewave_get_message_flow/1<br/>- Decode from/to PIDs<br/>- Query message flow<br/>- Format messages]
        
        TGFC[tidewave_get_function_calls/1<br/>- Convert module name<br/>- Query function calls<br/>- Handle errors]
        
        TTM[tidewave_trace_module/1<br/>- Convert to atom<br/>- Start module tracing<br/>- Return status]
        
        TTP[tidewave_trace_process/1<br/>- Decode PID<br/>- Start process tracing<br/>- Return status]
        
        TTNP[tidewave_trace_named_process/1<br/>- Find process by name<br/>- Start tracing<br/>- Handle not found]
        
        TGST3[tidewave_get_supervision_tree/1<br/>- Get tree structure<br/>- Return formatted tree]
        
        TGEP[tidewave_get_execution_path/1<br/>- Decode PID<br/>- Get execution path<br/>- Format results]
        
        TASC[tidewave_analyze_state_changes/1<br/>- Get state timeline<br/>- Calculate diffs<br/>- Analyze changes]
    end
    
    subgraph "Data Sources"
        QE[QueryEngine<br/>High-level queries]
        TDB[TraceDB<br/>Raw data storage]
        ES_MAIN[ElixirScope<br/>Main API functions]
        PO[ProcessObserver<br/>Supervision tree data]
    end
    
    subgraph "Helper Functions"
        DP[decode_pid/1<br/>- Handle various PID formats<br/>- Convert string to PID]
        
        PTS[pid_to_string/1<br/>- Convert PID to string<br/>- Use inspect/1]
        
        PNTP[process_name_to_pid/1<br/>- Try registered name<br/>- Try module name<br/>- Return PID or nil]
        
        FM[format_messages/1<br/>format_states/1<br/>format_function_calls/1<br/>- Convert to consistent format]
        
        SED[summarize_event_data/1<br/>- Limit data size<br/>- Prevent verbose responses<br/>- Handle large structures]
    end
    
    subgraph "External Integration"
        TW[Tidewave System<br/>AI-powered debugging<br/>Natural language interface]
        USER[User Queries<br/>Show me state changes for PID X<br/>What messages between A and B?<br/>Analyze process crashes]
    end
    
    %% Setup flow
    AI --> SETUP
    SETUP --> REG
    REG -->|registers| GST
    REG -->|registers| GMF
    REG -->|registers| GFC
    REG -->|registers| TM
    REG -->|registers| TP
    REG -->|registers| TNP
    REG -->|registers| GST2
    REG -->|registers| GEP
    REG -->|registers| ASC
    
    %% Tool implementation mapping
    GST -.->|implemented by| TGST
    GMF -.->|implemented by| TGMF
    GFC -.->|implemented by| TGFC
    TM -.->|implemented by| TTM
    TP -.->|implemented by| TTP
    TNP -.->|implemented by| TTNP
    GST2 -.->|implemented by| TGST3
    GEP -.->|implemented by| TGEP
    ASC -.->|implemented by| TASC
    
    %% Data source connections
    TGST -->|queries| QE
    TGMF -->|queries| QE
    TGFC -->|queries| QE
    TTM -->|calls| ES_MAIN
    TTP -->|calls| ES_MAIN
    TTNP -->|calls| ES_MAIN
    TGST3 -->|queries| PO
    TGEP -->|calls| ES_MAIN
    TASC -->|queries| QE
    
    %% Helper usage
    TGST -->|uses| DP
    TGMF -->|uses| DP
    TTP -->|uses| DP
    TGEP -->|uses| DP
    TASC -->|uses| DP
    TTNP -->|uses| PNTP
    
    TGST -->|uses| FM
    TGMF -->|uses| FM
    TGFC -->|uses| FM
    
    TGST -->|uses| SED
    TGMF -->|uses| SED
    TGFC -->|uses| SED
    TASC -->|uses| SED
    
    %% External flow
    TW -->|calls registered tools| GST
    TW -->|calls registered tools| GMF
    TW -->|calls registered tools| ASC
    USER -->|natural language queries| TW
    
    classDef integration fill:#e1f5fe,stroke:#0277bd,stroke-width:3px,color:#000
    classDef tool fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#000
    classDef implementation fill:#fff3e0,stroke:#ef6c00,stroke-width:2px,color:#000
    classDef data fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    classDef helper fill:#ffebee,stroke:#c62828,stroke-width:1px,color:#000
    classDef external fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
    
    class AI,SETUP,REG integration
    class GST,GMF,GFC,TM,TP,TNP,GST2,GEP,ASC tool
    class TGST,TGMF,TGFC,TTM,TTP,TTNP,TGST3,TGEP,TASC implementation
    class QE,TDB,ES_MAIN,PO data
    class DP,PTS,PNTP,FM,SED helper
    class TW,USER external
```

## 6. **Tracing Levels & Configuration Flow**
Shows how different tracing levels (:full, :messages_only, :states_only, :minimal, :off) affect component behavior, along with sampling configuration and performance implications.


```mermaid
graph LR
    subgraph "Configuration Entry Point"
        SETUP[ElixirScope.setup/1<br/>Configuration Options:<br/>- tracing_level<br/>- sample_rate<br/>- phoenix<br/>- ai_integration<br/>- trace_all]
    end
    
    subgraph "Tracing Level Options"
        direction LR
        FULL[":full<br/>Everything captured:<br/>- Function calls<br/>- Messages<br/>- State changes<br/>- Process lifecycle"]
        
        MSG_ONLY[":messages_only<br/>Messages only:<br/>- Send/receive events<br/>- Inter-process comm<br/>- No function calls<br/>- No state tracking"]
        
        STATE_ONLY[":states_only<br/>States only:<br/>- GenServer states<br/>- State transitions<br/>- No messages<br/>- No function calls"]
        
        MINIMAL[":minimal<br/>Oversight only:<br/>- Process spawn/exit<br/>- Major state changes<br/>- Critical events<br/>- Very low overhead"]
        
        OFF[":off<br/>Infrastructure only:<br/>- Sets up components<br/>- No active tracing<br/>- Can enable later<br/>- Zero overhead"]
    end
    
    subgraph "Sample Rate Configuration"
        SR_100[sample_rate: 1.0<br/>Record all events<br/>Maximum detail<br/>Higher overhead]
        
        SR_50[sample_rate: 0.5<br/>Record ~50% events<br/>Balanced approach<br/>Moderate overhead]
        
        SR_10[sample_rate: 0.1<br/>Record ~10% events<br/>Production safe<br/>Low overhead]
        
        SR_0[sample_rate: 0.0<br/>Critical events only<br/>Spawn/exit/crash<br/>Minimal overhead]
    end
    
    subgraph "Component Configuration Flow"
        direction TB
        
        subgraph "TraceDB Setup"
            TDB_INIT[TraceDB.start_link<br/>- storage: :ets<br/>- sample_rate config<br/>- max_events limit]
            TDB_SAMPLE[Sampling Logic<br/>- Critical events bypass<br/>- Deterministic sampling<br/>- Hash-based selection]
        end
        
        subgraph "ProcessObserver Setup"
            PO_INIT[ProcessObserver.start_link<br/>tracing_level: config]
            PO_ENABLE{Enable Process<br/>Tracking?}
            PO_TRACK[Track Process<br/>Lifecycle Events]
            PO_SKIP[Skip Process<br/>Tracking]
        end
        
        subgraph "MessageInterceptor Setup"
            MI_INIT[MessageInterceptor.start_link<br/>tracing_level: config]
            MI_ENABLE{Enable Message<br/>Tracing?}
            MI_DBG["Start :dbg Tracer<br/>p(:all, [:send, :receive])"]
            MI_SKIP[Skip Message<br/>Tracing]
        end
        
        subgraph "StateRecorder Setup"
            SR_INIT[StateRecorder Ready<br/>Available for tracing]
            SR_ENABLE{Enable State<br/>Tracking?}
            SR_MACRO[__using__ Macro<br/>Instrument GenServers]
            SR_SYS[:sys.trace Integration<br/>External GenServers]
            SR_SKIP[Skip State<br/>Recording]
        end
        
        subgraph "CodeTracer Setup"
            CT_INIT[CodeTracer.start_link<br/>tracing_level: config]
            CT_ENABLE{Enable Function<br/>Tracing?}
            CT_MODULE[Module-specific<br/>:dbg.tpl Setup]
            CT_SKIP[Skip Function<br/>Tracing]
        end
    end
    
    subgraph "Runtime Behavior"
        direction LR
        
        subgraph "Event Capture"
            CAPTURE[Event Captured]
            CRITICAL{Critical Event?<br/>spawn/exit/crash}
            SAMPLE{Passes Sampling?<br/>Based on sample_rate}
            LEVEL{Allowed by<br/>Tracing Level?}
            STORE[Store in TraceDB]
            DROP[Drop Event]
        end
        
        subgraph "Performance Impact"
            PERF_HIGH[High Performance Impact<br/>:full + sample_rate: 1.0<br/>Complete system visibility]
            
            PERF_MED[Medium Performance Impact<br/>:messages_only + sample_rate: 0.5<br/>Balanced monitoring]
            
            PERF_LOW[Low Performance Impact<br/>:minimal + sample_rate: 0.1<br/>Production safe]
            
            PERF_MIN[Minimal Performance Impact<br/>:off or sample_rate: 0.0<br/>Critical events only]
        end
    end
    
    %% Configuration flow
    SETUP --> FULL
    SETUP --> MSG_ONLY
    SETUP --> STATE_ONLY
    SETUP --> MINIMAL
    SETUP --> OFF
    
    SETUP --> SR_100
    SETUP --> SR_50
    SETUP --> SR_10
    SETUP --> SR_0
    
    %% Component initialization
    SETUP --> TDB_INIT
    SETUP --> PO_INIT
    SETUP --> MI_INIT
    SETUP --> SR_INIT
    SETUP --> CT_INIT
    
    TDB_INIT --> TDB_SAMPLE
    
    %% Conditional enablement based on tracing level
    PO_INIT --> PO_ENABLE
    PO_ENABLE -->|level != :off| PO_TRACK
    PO_ENABLE -->|level == :off| PO_SKIP
    
    MI_INIT --> MI_ENABLE
    MI_ENABLE -->|"level in [:full, :messages_only]"| MI_DBG
    MI_ENABLE -->|"level not in [:full, :messages_only]"| MI_SKIP
    
    SR_INIT --> SR_ENABLE
    SR_ENABLE -->|"level in [:full, :states_only]"| SR_MACRO
    SR_ENABLE -->|"level in [:full, :states_only]"| SR_SYS
    SR_ENABLE -->|"level not in [:full, :states_only]"| SR_SKIP
    
    CT_INIT --> CT_ENABLE
    CT_ENABLE -->|level == :full| CT_MODULE
    CT_ENABLE -->|level != :full| CT_SKIP
    
    %% Runtime event flow
    CAPTURE --> CRITICAL
    CRITICAL -->|Yes| STORE
    CRITICAL -->|No| SAMPLE
    SAMPLE -->|Yes| LEVEL
    SAMPLE -->|No| DROP
    LEVEL -->|Yes| STORE
    LEVEL -->|No| DROP
    
    %% Performance mapping
    FULL -.->|+ sample_rate: 1.0| PERF_HIGH
    MSG_ONLY -.->|+ sample_rate: 0.5| PERF_MED
    MINIMAL -.->|+ sample_rate: 0.1| PERF_LOW
    OFF -.->|or sample_rate: 0.0| PERF_MIN
    
    classDef config fill:#e3f2fd,stroke:#1976d2,stroke-width:3px,color:#000
    classDef level fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    classDef sample fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    classDef component fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    classDef runtime fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
    classDef performance fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
    classDef decision fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    
    class SETUP config
    class FULL,MSG_ONLY,STATE_ONLY,MINIMAL,OFF level
    class SR_100,SR_50,SR_10,SR_0 sample
    class TDB_INIT,PO_INIT,MI_INIT,SR_INIT,CT_INIT,TDB_SAMPLE,PO_TRACK,MI_DBG,SR_MACRO,SR_SYS,CT_MODULE component
    class CAPTURE,STORE,DROP runtime
    class PERF_HIGH,PERF_MED,PERF_LOW,PERF_MIN performance
    class PO_ENABLE,MI_ENABLE,SR_ENABLE,CT_ENABLE,CRITICAL,SAMPLE,LEVEL decision
```

## 7. **ETS Storage Structure & Data Organization**
Deep dive into the three ETS tables, their structure, data flow during storage and querying, event types, and management operations like cleanup and persistence.

```mermaid
graph LR
    subgraph "ETS Tables Structure"
        direction TB
        
        subgraph "Events Table (:elixir_scope_events)"
            ET[":elixir_scope_events<br/>Type: :ordered_set<br/>Key: event_id<br/>Stores: process, message, genserver, function events"]
            
            ET_STRUCT["Event Structure:<br/>{event_id, %{<br/>  id: unique_integer,<br/>  type: :process | :message | :genserver | :function,<br/>  pid: process_id,<br/>  timestamp: monotonic_time,<br/>  ...event_specific_data<br/>}}"]
        end
        
        subgraph "States Table (:elixir_scope_states)"
            ST[":elixir_scope_states<br/>Type: :ordered_set<br/>Key: state_id<br/>Stores: GenServer state snapshots"]
            
            ST_STRUCT["State Structure:<br/>{state_id, %{<br/>  id: unique_integer,<br/>  type: :state,<br/>  pid: process_id,<br/>  module: genserver_module,<br/>  state: serialized_state,<br/>  callback: :init | :handle_call | :handle_cast,<br/>  data: callback_context,<br/>  timestamp: monotonic_time<br/>}}"]
        end
        
        subgraph "Process Index (:elixir_scope_process_index)"
            PI[":elixir_scope_process_index<br/>Type: :bag<br/>Key: process_id<br/>Stores: {pid, {event_type, event_id}} mappings"]
            
            PI_STRUCT["Index Structure:<br/>{process_id, {event_type, event_id}}<br/>Where event_type can be:<br/>- :state<br/>- :process<br/>- :message<br/>- :message_sent<br/>- :message_received<br/>- :genserver<br/>- :function"]
        end
    end
    
    subgraph "Data Flow & Operations"
        direction LR
        
        subgraph "Store Event Flow"
            STORE_START["store_event(type, data)"]
            ADD_META[Add metadata:<br/>- unique ID<br/>- timestamp<br/>- type]
            ROUTE{Event Type?}
            STORE_EVENT[Store in events table]
            STORE_STATE[Store in states table]
            UPDATE_INDEX[Update process index]
        end
        
        subgraph "Query Flow"
            QUERY_START["query_events(filters)"]
            SELECT_TABLE{Query Type?}
            SCAN_EVENTS[Scan events table]
            SCAN_STATES[Scan states table]
            APPLY_FILTERS[Apply filters:<br/>- PID<br/>- timestamp range<br/>- event type]
            SORT_RESULTS[Sort by timestamp]
            RETURN_RESULTS[Return filtered results]
        end
        
        subgraph "Process-Specific Queries"
            PID_QUERY[Query by PID]
            LOOKUP_INDEX[Lookup in process index]
            GET_EVENT_IDS[Extract event IDs]
            FETCH_EVENTS[Fetch from events/states tables]
            MERGE_RESULTS[Merge and sort results]
        end
    end
    
    subgraph "Event Type Details"
        direction TB
        
        subgraph "Process Events"
            PROC_EVENT["Process Event<br/>type: :process<br/>Common fields:<br/>- pid<br/>- event: :spawn | :exit | :crash<br/>- info: process_info<br/>- timestamp"]
        end
        
        subgraph "Message Events"
            MSG_EVENT["Message Event<br/>type: :message<br/>Fields:<br/>- from_pid<br/>- to_pid (or just pid for receive)<br/>- message: sanitized_content<br/>- type: :send | :receive<br/>- timestamp"]
        end
        
        subgraph "State Events"
            STATE_EVENT[State Event<br/>type: :state<br/>Fields:<br/>- pid<br/>- module<br/>- state: sanitized_state<br/>- callback: triggering_callback<br/>- data: callback_context<br/>- timestamp]
        end
        
        subgraph "GenServer Events"
            GS_EVENT["GenServer Event<br/>type: :genserver<br/>Fields:<br/>- pid<br/>- module<br/>- callback: :init | :handle_*<br/>- message/args: sanitized<br/>- state_before: previous_state<br/>- timestamp"]
        end
        
        subgraph "Function Events"
            FUNC_EVENT["Function Event<br/>type: :function<br/>Fields:<br/>- pid<br/>- module<br/>- function<br/>- args: sanitized_args<br/>- type: :function_call | :function_return<br/>- result: return_value (for returns)<br/>- timestamp"]
        end
    end
    
    subgraph "Data Management"
        direction LR
        
        subgraph "Cleanup Operations"
            CLEANUP[Cleanup Process]
            CHECK_COUNT[Check event count vs max_events]
            FIND_OLDEST[Find oldest events by timestamp]
            DELETE_EVENTS[Delete from events table]
            DELETE_STATES[Delete from states table]
            UPDATE_INDEX_DEL[Remove from process index]
        end
        
        subgraph "Sampling Logic"
            SAMPLING[Sampling Decision]
            CRITICAL_CHECK{Critical Event?<br/>spawn/exit/crash/error}
            SAMPLE_RATE[Apply sample_rate]
            HASH_BASED[Hash-based selection<br/>using PID + timestamp]
            RECORD[Record Event]
            SKIP[Skip Event]
        end
        
        subgraph "Persistence"
            PERSIST[Persistence Process]
            EXPORT_DATA[Export ETS tables]
            BINARY_FORMAT[Convert to binary]
            WRITE_FILE[Write to disk]
            TIMESTAMP_NAME[Timestamp-based filename]
        end
    end
    
    %% Storage flow connections
    STORE_START --> ADD_META
    ADD_META --> ROUTE
    ROUTE -->|:state| STORE_STATE
    ROUTE -->|others| STORE_EVENT
    STORE_EVENT --> UPDATE_INDEX
    STORE_STATE --> UPDATE_INDEX
    
    %% Query flow connections
    QUERY_START --> SELECT_TABLE
    SELECT_TABLE -->|events| SCAN_EVENTS
    SELECT_TABLE -->|states| SCAN_STATES
    SELECT_TABLE -->|both| SCAN_EVENTS
    SELECT_TABLE -->|both| SCAN_STATES
    SCAN_EVENTS --> APPLY_FILTERS
    SCAN_STATES --> APPLY_FILTERS
    APPLY_FILTERS --> SORT_RESULTS
    SORT_RESULTS --> RETURN_RESULTS
    
    %% PID query connections
    PID_QUERY --> LOOKUP_INDEX
    LOOKUP_INDEX --> GET_EVENT_IDS
    GET_EVENT_IDS --> FETCH_EVENTS
    FETCH_EVENTS --> MERGE_RESULTS
    
    %% Table relationships
    ET -.->|indexed by| PI
    ST -.->|indexed by| PI
    
    %% Management connections
    CLEANUP --> CHECK_COUNT
    CHECK_COUNT --> FIND_OLDEST
    FIND_OLDEST --> DELETE_EVENTS
    FIND_OLDEST --> DELETE_STATES
    DELETE_EVENTS --> UPDATE_INDEX_DEL
    DELETE_STATES --> UPDATE_INDEX_DEL
    
    SAMPLING --> CRITICAL_CHECK
    CRITICAL_CHECK -->|Yes| RECORD
    CRITICAL_CHECK -->|No| SAMPLE_RATE
    SAMPLE_RATE --> HASH_BASED
    HASH_BASED --> RECORD
    HASH_BASED --> SKIP
    
    PERSIST --> EXPORT_DATA
    EXPORT_DATA --> BINARY_FORMAT
    BINARY_FORMAT --> WRITE_FILE
    WRITE_FILE --> TIMESTAMP_NAME
    
    classDef table fill:#e3f2fd,stroke:#1976d2,stroke-width:3px,color:#000
    classDef structure fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    classDef flow fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    classDef event fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    classDef management fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
    classDef decision fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    
    class ET,ST,PI table
    class ET_STRUCT,ST_STRUCT,PI_STRUCT structure
    class STORE_START,ADD_META,STORE_EVENT,STORE_STATE,UPDATE_INDEX,QUERY_START,SCAN_EVENTS,SCAN_STATES,APPLY_FILTERS,SORT_RESULTS,RETURN_RESULTS,PID_QUERY,LOOKUP_INDEX,GET_EVENT_IDS,FETCH_EVENTS,MERGE_RESULTS flow
    class PROC_EVENT,MSG_EVENT,STATE_EVENT,GS_EVENT,FUNC_EVENT event
    class CLEANUP,CHECK_COUNT,FIND_OLDEST,DELETE_EVENTS,DELETE_STATES,UPDATE_INDEX_DEL,SAMPLING,HASH_BASED,RECORD,SKIP,PERSIST,EXPORT_DATA,BINARY_FORMAT,WRITE_FILE,TIMESTAMP_NAME management
    class ROUTE,SELECT_TABLE,CRITICAL_CHECK,SAMPLE_RATE decision
```

## 8. **QueryEngine Capabilities & Time-Travel Debugging**
Comprehensive view of the QueryEngine's API, from basic queries to advanced time-travel debugging features like system snapshots and state evolution analysis.

```mermaid
graph LR
    subgraph "QueryEngine API"
        QE[QueryEngine<br/>High-level Query Interface<br/>Built on TraceDB]
    end
    
    subgraph "Basic Query Functions"
        direction TB
        
        MF[message_flow/2<br/>Get messages between<br/>two processes<br/>Args: from_pid, to_pid]
        
        MF_FROM[messages_from/1<br/>All messages sent<br/>from a process<br/>Args: pid]
        
        MF_TO[messages_to/1<br/>All messages received<br/>by a process<br/>Args: pid]
        
        ST[state_timeline/1<br/>State changes for<br/>a process over time<br/>Args: pid]
        
        EP[execution_path/1<br/>Function calls and<br/>returns for process<br/>Args: pid]
        
        PE[process_events/1<br/>All events for<br/>a specific process<br/>Args: pid]
    end
    
    subgraph "Advanced Query Functions"
        direction TB
        
        SC_WIN[state_changes_in_window/2<br/>State changes in<br/>time window<br/>Args: start_time, end_time]
        
        MFC[module_function_calls/1<br/>Function calls for<br/>specific module<br/>Args: module]
        
        FC[function_calls/2<br/>Calls to specific<br/>function in module<br/>Args: module, function]
        
        GS_EVT[genserver_events/2<br/>GenServer operations<br/>Optional operation filter<br/>Args: pid, operation?]
        
        EVT_AROUND[events_around_event/2<br/>Events near specific<br/>event in time<br/>Args: event_id, window_ms]
        
        ACTIVE_PROC[active_processes_at/1<br/>Processes alive at<br/>specific timestamp<br/>Args: timestamp]
    end
    
    subgraph "Time-Travel Debugging"
        direction TB
        
        GET_STATE_AT["get_state_at/2<br/>Process state at<br/>specific timestamp<br/>Args: pid, timestamp<br/>Returns: {:ok, state} | {:error, reason}"]
        
        SYSTEM_SNAP[system_snapshot_at/1<br/>Complete system state<br/>at point in time<br/>Args: timestamp<br/>Returns: comprehensive snapshot]
        
        EXEC_TIMELINE[execution_timeline/3<br/>All events between<br/>two timestamps<br/>Args: start, end, filter_types?<br/>Returns: chronological sequence]
        
        STATE_EVOLUTION[state_evolution/3<br/>State changes with<br/>context and causes<br/>Args: pid, start_time, end_time<br/>Returns: enriched state history]
    end
    
    subgraph "Utility Functions"
        direction TB
        
        COMPARE_STATES[compare_states/2<br/>Diff two states<br/>showing changes<br/>Args: state1, state2<br/>Returns: diff analysis]
        
        PROC_SPAWNS[process_spawns/0<br/>All process spawn<br/>events in system<br/>Returns: spawn event list]
        
        PROC_EXITS[process_exits/0<br/>All process exit<br/>events in system<br/>Returns: exit event list]
    end
    
    subgraph "System Snapshot Details"
        direction LR
        
        SNAP_ACTIVE[Active Processes<br/>List of live PIDs<br/>at timestamp]
        
        SNAP_STATES[Process States<br/>State of each process<br/>at timestamp]
        
        SNAP_PENDING[Pending Messages<br/>Sent but not received<br/>messages at timestamp]
        
        SNAP_SUP[Supervision Tree<br/>Supervisor hierarchy<br/>at timestamp]
    end
    
    subgraph "State Evolution Analysis"
        direction LR
        
        EVOL_CHANGES[State Changes<br/>Actual state transitions<br/>with timestamps]
        
        EVOL_CAUSES[Potential Causes<br/>Events that triggered<br/>each state change]
        
        EVOL_DIFFS[State Diffs<br/>What changed between<br/>consecutive states]
        
        EVOL_CONTEXT[Contextual Info<br/>Messages, function calls<br/>around state changes]
    end
    
    subgraph "Helper Functions"
        direction TB
        
        FIND_EVENT[find_event_by_id/1<br/>Locate event by ID<br/>in ETS tables]
        
        PENDING_MSGS[get_pending_messages_at/1<br/>Calculate pending<br/>messages at timestamp]
        
        RECONSTRUCT_SUP[reconstruct_supervision_tree_at/1<br/>Build supervision tree<br/>from historical data]
    end
    
    subgraph "Data Sources Integration"
        direction LR
        
        TDB_QUERY[TraceDB Queries<br/>- query_events/1<br/>- get_state_history/1<br/>- get_events_at/2<br/>- get_state_at/2]
        
        ETS_DIRECT[Direct ETS Access<br/>- :elixir_scope_events<br/>- :elixir_scope_states<br/>- :elixir_scope_process_index]
        
        PROCESS_INFO[Process Information<br/>- Process.info/1<br/>- :sys.get_state/1<br/>- Runtime introspection]
    end
    
    %% API connections
    QE --> MF
    QE --> MF_FROM
    QE --> MF_TO
    QE --> ST
    QE --> EP
    QE --> PE
    QE --> SC_WIN
    QE --> MFC
    QE --> FC
    QE --> GS_EVT
    QE --> EVT_AROUND
    QE --> ACTIVE_PROC
    QE --> GET_STATE_AT
    QE --> SYSTEM_SNAP
    QE --> EXEC_TIMELINE
    QE --> STATE_EVOLUTION
    QE --> COMPARE_STATES
    QE --> PROC_SPAWNS
    QE --> PROC_EXITS
    
    %% System snapshot composition
    SYSTEM_SNAP --> SNAP_ACTIVE
    SYSTEM_SNAP --> SNAP_STATES
    SYSTEM_SNAP --> SNAP_PENDING
    SYSTEM_SNAP --> SNAP_SUP
    
    %% State evolution composition
    STATE_EVOLUTION --> EVOL_CHANGES
    STATE_EVOLUTION --> EVOL_CAUSES
    STATE_EVOLUTION --> EVOL_DIFFS
    STATE_EVOLUTION --> EVOL_CONTEXT
    
    %% Helper function usage
    EVT_AROUND --> FIND_EVENT
    SYSTEM_SNAP --> PENDING_MSGS
    SYSTEM_SNAP --> RECONSTRUCT_SUP
    STATE_EVOLUTION --> COMPARE_STATES
    
    %% Data source connections
    MF --> TDB_QUERY
    ST --> TDB_QUERY
    EP --> TDB_QUERY
    GET_STATE_AT --> TDB_QUERY
    SYSTEM_SNAP --> TDB_QUERY
    EXEC_TIMELINE --> TDB_QUERY
    STATE_EVOLUTION --> TDB_QUERY
    
    FIND_EVENT --> ETS_DIRECT
    PENDING_MSGS --> TDB_QUERY
    RECONSTRUCT_SUP --> TDB_QUERY
    
    SNAP_STATES --> PROCESS_INFO
    
    %% Query complexity indicators
    MF -.->|Simple| TDB_QUERY
    SYSTEM_SNAP -.->|Complex| TDB_QUERY
    STATE_EVOLUTION -.->|Complex| TDB_QUERY
    EXEC_TIMELINE -.->|Medium| TDB_QUERY
    
    classDef api fill:#e1f5fe,stroke:#0277bd,stroke-width:3px,color:#000
    classDef basic fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#000
    classDef advanced fill:#fff3e0,stroke:#ef6c00,stroke-width:2px,color:#000
    classDef timetravel fill:#f3e5f5,stroke:#7b1fa2,stroke-width:3px,color:#000
    classDef utility fill:#ffebee,stroke:#c62828,stroke-width:2px,color:#000
    classDef component fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
    classDef helper fill:#fce4ec,stroke:#c2185b,stroke-width:1px,color:#000
    classDef datasource fill:#e8eaf6,stroke:#3f51b5,stroke-width:2px,color:#000
    
    class QE api
    class MF,MF_FROM,MF_TO,ST,EP,PE basic
    class SC_WIN,MFC,FC,GS_EVT,EVT_AROUND,ACTIVE_PROC advanced
    class GET_STATE_AT,SYSTEM_SNAP,EXEC_TIMELINE,STATE_EVOLUTION timetravel
    class COMPARE_STATES,PROC_SPAWNS,PROC_EXITS utility
    class SNAP_ACTIVE,SNAP_STATES,SNAP_PENDING,SNAP_SUP,EVOL_CHANGES,EVOL_CAUSES,EVOL_DIFFS,EVOL_CONTEXT component
    class FIND_EVENT,PENDING_MSGS,RECONSTRUCT_SUP helper
    class TDB_QUERY,ETS_DIRECT,PROCESS_INFO datasource
```


## 9. **Test Coverage Matrix & Testing Strategy**
Detailed breakdown of the test structure, showing implemented tests (✅), partially implemented (⏳), and missing tests (❌), along with test utilities and coverage gaps.

```mermaid
graph LR
    subgraph "Test Infrastructure"
        direction LR
        
        TH[test_helper.exs<br/>Global Test Setup<br/>- TraceDB initialization<br/>- ETS table creation<br/>- Test mode configuration]
        
        DIAG[TraceDBDiagnostic<br/>Debug Utilities<br/>- print_all_data/0<br/>- print_process_events/1<br/>- tables_exist?/0]
        
        TEST_MODE[Test Mode Features<br/>- Suppressed console output<br/>- StringIO black holes<br/>- Synchronous operations<br/>- Deterministic behavior]
    end
    
    subgraph "Core Module Test Coverage"
        direction TB
        
        subgraph "TraceDB Tests (940 lines)"
            TDB_INIT[Initialization Tests ✅<br/>- Default options<br/>- Custom options<br/>- ETS table creation<br/>- GenServer lifecycle]
            
            TDB_STORAGE[Event Storage Tests ✅<br/>- Basic events<br/>- Unique ID assignment<br/>- PID indexing<br/>- Complex data structures<br/>- Timestamp handling]
            
            TDB_SAMPLING["Sampling Tests ✅<br/>- 100% sampling (1.0)<br/>- 0% sampling (0.0)<br/>- Critical event bypass<br/>- Deterministic sampling<br/>- Hash-based selection"]
            
            TDB_QUERY[Query Tests ✅<br/>- Query by type<br/>- Query by PID<br/>- Query by timestamp<br/>- Combined filters<br/>- Result ordering]
            
            TDB_HISTORY[State History Tests ✅<br/>- Process state timeline<br/>- Events at timestamp<br/>- State at timestamp<br/>- Adjacent event finding<br/>- Active processes query]
            
            TDB_MGMT["Management Tests ✅<br/>- Clear operations<br/>- Event cleanup (max_events)<br/>- Persistence to disk<br/>- Oldest event removal"]
        end
        
        subgraph "ProcessObserver Tests (126 lines)"
            PO_INIT[Initialization Tests ✅<br/>- Default startup<br/>- TraceDB registration]
            
            PO_LIFECYCLE[Lifecycle Tests ✅<br/>- Process event tracking<br/>- Event storage verification]
            
            PO_INFO[Info Collection Tests ✅<br/>- Process.info/1 data<br/>- Basic process metadata]
            
            PO_SUPERVISION[Supervision Tests ⏳<br/>- Tree structure building<br/>- Supervisor nesting<br/>- Strategy identification]
        end
        
        subgraph "StateRecorder Tests (212 lines)"
            SR_WRAPPER[Wrapper Tests ✅<br/>- Manual event storage<br/>- TestWrapper functions<br/>- store_init_event<br/>- store_call_events<br/>- store_cast_events<br/>- store_info_events]
            
            SR_GENSERVER[GenServer Tests ✅<br/>- Initialization tracking<br/>- handle_call state changes<br/>- handle_cast state changes<br/>- handle_info state changes]
            
            SR_EXTERNAL[External Tracing ✅<br/>- trace_genserver/1<br/>- :sys.trace integration<br/>- External process monitoring]
            
            SR_COMPLEX[Complex State Tests ⏳<br/>- Large state structures<br/>- State diff analysis<br/>- Nested state changes]
        end
        
        subgraph "MessageInterceptor Tests (273 lines)"
            MI_INIT[Initialization Tests ✅<br/>- Default startup options<br/>- Tracing level changes<br/>- Enable/disable tracing]
            
            MI_BASIC[Basic Operations ✅<br/>- Start/stop tracing<br/>- Tracing level changes<br/>- Status queries]
            
            MI_CAPTURE[Message Capture ✅<br/>- Send message detection<br/>- Process-specific tracing<br/>- GenServer call capture<br/>- store_event_sync usage]
            
            MI_FILTERING[Message Filtering ✅<br/>- Garbage message detection<br/>- Test mode behavior<br/>- Quiet logging mode]
        end
    end
    
    subgraph "Test Categories & Patterns"
        direction LR
        
        subgraph "Unit Tests"
            UNIT_ISOLATED[Isolated Function Tests<br/>- Individual method testing<br/>- Mock dependencies<br/>- Deterministic inputs]
            
            UNIT_STATE[State Management Tests<br/>- GenServer state tracking<br/>- State transition validation<br/>- Error condition handling]
        end
        
        subgraph "Integration Tests"
            INTEG_COMPONENTS[Component Integration<br/>- TraceDB ↔ Collectors<br/>- QueryEngine ↔ TraceDB<br/>- AI ↔ QueryEngine]
            
            INTEG_FLOW[End-to-End Flow<br/>- Event capture → Storage<br/>- Storage → Query → Results<br/>- Configuration → Behavior]
        end
        
        subgraph "Performance Tests"
            PERF_SAMPLING[Sampling Performance<br/>- Different sample rates<br/>- Event throughput<br/>- Memory usage patterns]
            
            PERF_CLEANUP[Cleanup Performance<br/>- max_events behavior<br/>- ETS table pruning<br/>- Memory management]
        end
    end
    
    subgraph "Test Utilities & Helpers"
        direction TB
        
        subgraph "Mock Objects"
            SIMPLE_GS[SimpleGenServer<br/>Test GenServer<br/>- Basic state operations<br/>- Call/cast/info handlers<br/>- Predictable behavior]
            
            TEST_SERVER[TestServer<br/>Specialized GenServer<br/>- Increment operations<br/>- State validation<br/>- Error scenarios]
        end
        
        subgraph "Test Helpers"
            SYNC_STORAGE[Synchronous Storage<br/>- store_event_sync/2<br/>- Immediate ETS writes<br/>- Test-friendly timing<br/>- Assertion compatibility]
            
            CLEANUP_HELPERS[Cleanup Helpers<br/>- setup/teardown blocks<br/>- ETS table clearing<br/>- Process termination<br/>- State reset]
        end
        
        subgraph "Diagnostic Tools"
            EVENT_INSPECTION[Event Inspection<br/>- print_all_data/0<br/>- Event counting<br/>- Type distribution<br/>- Timestamp analysis]
            
            PROCESS_DEBUGGING[Process Debugging<br/>- print_process_events/1<br/>- PID-specific events<br/>- State change tracking<br/>- Message flow analysis]
        end
    end
    
    subgraph "Coverage Gaps & Future Tests"
        direction TB
        
        subgraph "Missing Core Tests"
            CODE_TRACER[CodeTracer Tests ❌<br/>- Function call tracing<br/>- Module instrumentation<br/>- :dbg.tpl integration<br/>- Source correlation]
            
            QUERY_ENGINE[QueryEngine Tests ❌<br/>- High-level queries<br/>- Time-travel debugging<br/>- State reconstruction<br/>- Complex analysis]
            
            AI_INTEGRATION[AI Integration Tests ❌<br/>- Tidewave tool registration<br/>- Function implementations<br/>- Error handling<br/>- Response formatting]
        end
        
        subgraph "Missing Integration Tests"
            PHOENIX_TESTS[Phoenix Integration ❌<br/>- HTTP request tracing<br/>- LiveView event capture<br/>- Channel monitoring<br/>- PubSub integration]
            
            END_TO_END[End-to-End Scenarios ❌<br/>- Complete workflows<br/>- Multi-component interaction<br/>- Performance under load<br/>- Error recovery]
        end
        
        subgraph "Advanced Scenarios"
            STRESS_TESTS[Stress Testing ❌<br/>- High message volume<br/>- Many concurrent processes<br/>- Memory pressure<br/>- Long-running scenarios]
            
            ERROR_SCENARIOS[Error Scenarios ❌<br/>- Process crashes<br/>- ETS table corruption<br/>- Disk full conditions<br/>- Network failures]
        end
    end
    
    %% Test infrastructure relationships
    TH --> TDB_INIT
    TH --> PO_INIT
    TH --> SR_WRAPPER
    TH --> MI_INIT
    
    DIAG -.->|supports| TDB_STORAGE
    DIAG -.->|supports| SR_GENSERVER
    TEST_MODE -.->|enables| MI_CAPTURE
    
    %% Test helper relationships
    SIMPLE_GS -.->|used by| SR_GENSERVER
    TEST_SERVER -.->|used by| MI_CAPTURE
    SYNC_STORAGE -.->|used by| SR_WRAPPER
    SYNC_STORAGE -.->|used by| MI_CAPTURE
    
    %% Coverage flow
    TDB_INIT ==> TDB_STORAGE
    TDB_STORAGE ==> TDB_SAMPLING
    TDB_SAMPLING ==> TDB_QUERY
    TDB_QUERY ==> TDB_HISTORY
    TDB_HISTORY ==> TDB_MGMT
    
    %% Integration patterns
    UNIT_ISOLATED --> INTEG_COMPONENTS
    UNIT_STATE --> INTEG_FLOW
    INTEG_COMPONENTS --> PERF_SAMPLING
    INTEG_FLOW --> PERF_CLEANUP
    
    %% Coverage gaps flow
    TDB_MGMT -.->|needs| CODE_TRACER
    SR_EXTERNAL -.->|needs| QUERY_ENGINE
    MI_FILTERING -.->|needs| AI_INTEGRATION
    
    CODE_TRACER -.->|enables| PHOENIX_TESTS
    QUERY_ENGINE -.->|enables| END_TO_END
    AI_INTEGRATION -.->|enables| STRESS_TESTS
    
    classDef infrastructure fill:#e3f2fd,stroke:#1976d2,stroke-width:3px,color:#000
    classDef implemented fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#000
    classDef partial fill:#fff3e0,stroke:#ef6c00,stroke-width:2px,color:#000
    classDef missing fill:#ffebee,stroke:#d32f2f,stroke-width:2px,color:#000
    classDef helper fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    classDef category fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000
    classDef future fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    
    class TH,DIAG,TEST_MODE infrastructure
    class TDB_INIT,TDB_STORAGE,TDB_SAMPLING,TDB_QUERY,TDB_HISTORY,TDB_MGMT,PO_INIT,PO_LIFECYCLE,PO_INFO,SR_WRAPPER,SR_GENSERVER,SR_EXTERNAL,MI_INIT,MI_BASIC,MI_CAPTURE,MI_FILTERING implemented
    class PO_SUPERVISION,SR_COMPLEX partial
    class CODE_TRACER,QUERY_ENGINE,AI_INTEGRATION,PHOENIX_TESTS,END_TO_END missing
    class SIMPLE_GS,TEST_SERVER,SYNC_STORAGE,CLEANUP_HELPERS,EVENT_INSPECTION,PROCESS_DEBUGGING helper
    class UNIT_ISOLATED,UNIT_STATE,INTEG_COMPONENTS,INTEG_FLOW,PERF_SAMPLING,PERF_CLEANUP category
    class STRESS_TESTS,ERROR_SCENARIOS future
```
