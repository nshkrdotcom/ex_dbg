Comprehensive Plan for an Assisted Debugger for Elixir Applications
This document outlines a detailed, cohesive plan to design an assisted debugger for Elixir applications running on the BEAM/OTP platform. The debugger focuses on tracking processes, message passing, and state changes at a granular level, enabling developers to introspect application execution and compare expected versus actual behavior line-by-line, variable-by-variable, and GenServer-by-GenServer. The plan leverages existing Elixir and BEAM/OTP debugging tools, builds custom components, and integrates with Tidewave for AI-assisted debugging, using a simple supervision tree with two GenServers as an illustrative example.
Overview
The goal is to create a debugger that provides automated tooling to log and analyze execution details and state transitions comprehensively. For a "hello world" Elixir application with a supervision tree containing two GenServers (e.g., WorkerA and WorkerB), the system will:
Track Processes: Monitor process lifecycles and supervision relationships.
Capture Message Passing: Record messages sent and received between processes.
Monitor State Changes: Log state at key execution points, approximating line-by-line granularity.
Facilitate Debugging: Compare actual execution against expected behavior using logs and AI analysis.
The system, named "ElixirScope", combines existing BEAM tools with custom instrumentation and integrates Tidewave for enhanced usability.
System Architecture
ElixirScope is structured into modular components that work together to collect, store, analyze, and present debugging data:
┌───────────────────────────────────────────────────────┐
│                    ElixirScope                        │
├─────────────┬──────────────┬──────────────┬───────────┤
│ Process     │ Message      │ State        │ Analysis &│
│ Tracker     │ Logger       │ Inspector    │ Visualizer│
├─────────────┴──────────────┴──────────────┴───────────┤
│                TraceStore & Query Engine              │
├───────────────────────────────────────────────────────┤
│                Tidewave Integration                   │
└───────────────────────────────────────────────────────┘
Leveraging Existing Tools
ElixirScope builds on the following BEAM/OTP and Elixir tools:
:sys Module: Traces GenServer processes, logging state changes and message events.
:dbg Module: Traces function calls and message passing across processes.
:observer: Provides a high-level view of the supervision tree (optional integration).
Logger: Records custom state and event logs.
Tidewave: Enhances debugging with AI-assisted querying and analysis (Phoenix-specific but adaptable).
These tools provide a foundation, but custom enhancements are required for granular state tracking and automated analysis.
Detailed Components
1. Process Tracker
Purpose: Monitors process lifecycles and supervision tree structure.
Implementation:
Uses :sys.trace/2 to log process events (e.g., spawning, termination).
Recursively builds the supervision tree using :supervisor.which_children/1.
Code Example:
elixir
defmodule ElixirScope.ProcessTracker do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, %{tree: build_supervision_tree()}}
  end

  def handle_info({:trace, pid, event, data}, state) do
    ElixirScope.TraceStore.store_event(pid, event, data)
    {:noreply, state}
  end

  def get_supervision_tree, do: GenServer.call(__MODULE__, :get_tree)

  defp build_supervision_tree do
    # Recursive logic to map supervision tree
  end
end
2. Message Logger
Purpose: Captures all messages between processes with timestamps and content.
Implementation:
Uses :dbg to trace :send and :receive events for all processes.
Logs message details to TraceStore.
Code Example:
elixir
defmodule ElixirScope.MessageLogger do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    :dbg.tracer(:process, {fn msg, _ -> send(__MODULE__, msg) end, nil})
    :dbg.p(:all, [:send, :receive])
    {:ok, %{}}
  end

  def handle_info({:trace, from_pid, :send, msg, to_pid}, state) do
    ElixirScope.TraceStore.store_event(from_pid, :message_send, %{to: to_pid, content: msg})
    {:noreply, state}
  end

  def handle_info({:trace, pid, :receive, msg}, state) do
    ElixirScope.TraceStore.store_event(pid, :message_receive, %{content: msg})
    {:noreply, state}
  end
end
3. State Inspector
Purpose: Tracks state changes in GenServers, approximating line-by-line granularity.
Implementation:
Uses :sys.trace/2 to log state before and after GenServer callbacks (handle_call/3, handle_cast/2, etc.).
Optionally uses :dbg to trace specific function calls within callbacks for finer granularity.
Avoids full line-by-line tracing (performance-intensive) by focusing on callback boundaries.
Code Example:
elixir
defmodule ElixirScope.StateInspector do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, %{}}
  end

  def trace_genserver(pid) do
    :sys.trace(pid, true)
  end

  def handle_info({:trace, pid, :state, state}, state) do
    ElixirScope.TraceStore.store_event(pid, :state_change, state)
    {:noreply, state}
  end
end
4. TraceStore & Query Engine
Purpose: Stores and manages trace data for querying and analysis.
Implementation:
Uses ETS for in-memory storage of trace events.
Provides query functions (e.g., state changes for a PID, messages between processes).
Code Example:
elixir
defmodule ElixirScope.TraceStore do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    :ets.new(__MODULE__, [:named_table, :public])
    {:ok, %{}}
  end

  def store_event(pid, event_type, data) do
    event = %{
      timestamp: System.monotonic_time(),
      pid: pid,
      type: event_type,
      data: data
    }
    :ets.insert(__MODULE__, {System.unique_integer(), event})
  end

  def get_state_changes(pid) do
    :ets.match_object(__MODULE__, {:"$1", %{pid: pid, type: :state_change, data: :"$2"}})
  end

  def get_messages_between(pid1, pid2) do
    :ets.match_object(__MODULE__, {:"$1", %{pid: pid1, type: :message_send, data: %{to: pid2}}})
  end
end
5. Analysis & Visualizer
Purpose: Analyzes trace data and visualizes execution for debugging.
Implementation:
Builds a timeline of events (process spawns, messages, state changes).
Compares actual execution against expected behavior (defined as invariants).
Provides a web interface (Phoenix-based) for visualization.
Code Example:
elixir
defmodule ElixirScope.Analyzer do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, %{expectations: [], timeline: []}}
  end

  def register_expectation(expectation) do
    GenServer.cast(__MODULE__, {:expectation, expectation})
  end

  def compare_execution do
    GenServer.call(__MODULE__, :compare)
  end

  def handle_cast({:expectation, exp}, state) do
    {:noreply, %{state | expectations: [exp | state.expectations]}}
  end

  def handle_call(:compare, _from, state) do
    diffs = compare_timeline(state.timeline, state.expectations)
    {:reply, diffs, state}
  end

  defp compare_timeline(timeline, expectations) do
    # Logic to identify discrepancies
  end
end
Integration with Tidewave
Utility: Tidewave enhances ElixirScope by providing AI-assisted debugging, particularly for Phoenix applications. Its Model Context Protocol (MCP) allows AI assistants to query trace data and analyze execution.
Implementation:
Register ElixirScope query functions with Tidewave’s MCP.
Enable natural language queries (e.g., "Show me WorkerA’s state changes").
Code Example:
elixir
defmodule ElixirScope.TidewaveIntegration do
  def setup do
    if Code.ensure_loaded?(Tidewave) do
      Tidewave.register_tool("state_changes", &ElixirScope.TraceStore.get_state_changes/1)
      Tidewave.register_tool("messages_between", &ElixirScope.TraceStore.get_messages_between/2)
    end
  end
end
Workflow:
Developer asks, “Why didn’t WorkerA increment its count?”
Tidewave queries TraceStore for state changes and messages.
AI analyzes data and responds, “WorkerA received :increment but crashed due to an unhandled case.”
For non-Phoenix apps, Tidewave’s utility is limited, but ElixirScope operates independently.
Example: Hello World Supervision Tree
Consider this simple Elixir application:
elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {MyApp.WorkerA, []},
      {MyApp.WorkerB, []},
      {ElixirScope.ProcessTracker, []},
      {ElixirScope.MessageLogger, []},
      {ElixirScope.StateInspector, []},
      {ElixirScope.TraceStore, []},
      {ElixirScope.Analyzer, []}
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: MyApp.Supervisor)
  end
end

defmodule MyApp.WorkerA do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, 0, name: __MODULE__)

  def init(count), do: {:ok, count}

  def handle_cast(:increment, count) do
    new_count = count + 1
    MyApp.WorkerB.ping(new_count)
    {:noreply, new_count}
  end
end

defmodule MyApp.WorkerB do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)
  def ping(count), do: GenServer.cast(__MODULE__, {:ping, count})

  def init(state), do: {:ok, state}

  def handle_cast({:ping, count}, state) do
    {:noreply, [count | state]}
  end
end
Debugging Workflow
Start Tracing:
elixir
Enum.each([MyApp.WorkerA, MyApp.WorkerB], &ElixirScope.StateInspector.trace_genserver/1)
Perform Actions:
elixir
GenServer.cast(MyApp.WorkerA, :increment)
Register Expectation:
elixir
ElixirScope.Analyzer.register_expectation(%{
  pid: Process.whereis(MyApp.WorkerA),
  event: :state_change,
  expected: fn state -> state > 0 end
})
Analyze Execution:
Check TraceStore for state changes and messages.
Use Tidewave: “Show me WorkerA’s state after increment.”
View timeline in the web interface (if implemented).
Outcome:
Logs show WorkerA state changing from 0 to 1 and sending :ping to WorkerB.
Diff confirms expectation met or highlights discrepancies.
Challenges and Mitigations
Performance Overhead:
Mitigation: Dynamically adjust tracing levels (e.g., disable :dbg when not needed).
Data Volume:
Mitigation: Use ring buffers in TraceStore or sample events in production.
Granularity Limits:
Mitigation: Focus on callback-level state changes; add optional function tracing for critical sections.
Conclusion
ElixirScope provides a comprehensive debugging solution for Elixir applications by:
Leveraging :sys and :dbg for process and message tracing.
Capturing GenServer state changes at callback boundaries.
Storing and querying trace data efficiently with TraceStore.
Integrating Tidewave for AI-assisted analysis (where applicable).
Enabling comparison of expected versus actual execution.
For the hello world example, it tracks WorkerA and WorkerB interactions, logs state transitions, and facilitates robust debugging, fulfilling the requirements for granular introspection and automated tooling. This plan balances functionality, performance, and usability, making it a powerful tool for Elixir developers.
