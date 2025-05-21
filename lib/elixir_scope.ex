defmodule ElixirScope do
  @moduledoc """
  ElixirScope: Advanced Introspection and Debugging for Phoenix Applications
  
  This module provides the main entry point for using ElixirScope, a state-of-the-art
  Elixir introspection and debugging system focused on Phoenix applications.
  """
  
  alias ElixirScope.{
    ProcessObserver,
    MessageInterceptor,
    StateRecorder,
    PhoenixTracker,
    CodeTracer,
    TraceDB,
    QueryEngine,
    AIIntegration
  }
  
  @doc """
  Sets up ElixirScope with the given configuration options.
  
  ## Options
  
  * `:storage` - The storage backend for trace data (`:ets`, `:mnesia`, or `:file`). Default: `:ets`
  * `:phoenix` - Boolean indicating whether to enable Phoenix-specific tracking. Default: `false`
  * `:trace_all` - Boolean indicating whether to start tracing all processes. Default: `false`
  * `:ai_integration` - Boolean indicating whether to enable AI integration. Default: `false`
  * `:tracing_level` - Controls the level of tracing detail (`:full`, `:messages_only`, `:states_only`, `:minimal`, or `:off`). Default: `:full`
  * `:sample_rate` - Controls what percentage of events are captured, as a float between 0.0 and 1.0. Default: `1.0` (all events)
  
  ## Tracing Levels
  
  * `:full` - Captures all events: function calls, messages, state changes, and process lifecycle
  * `:messages_only` - Only captures message passing between processes
  * `:states_only` - Only captures GenServer state changes
  * `:minimal` - Captures a minimal set of events, primarily for oversight (process creation/termination and major state changes)
  * `:off` - Disables all tracing (still sets up the infrastructure but doesn't start any tracers)
  
  ## Sample Rate
  
  The sample rate allows you to reduce the performance impact by only recording a percentage of events.
  A value of `1.0` records all events, `0.5` records approximately half, etc.
  
  ## Example
  
      # Full tracing for Phoenix
      ElixirScope.setup(phoenix: true)
      
      # Lightweight tracing that only records messages with 20% sampling
      ElixirScope.setup(tracing_level: :messages_only, sample_rate: 0.2)
  """
  def setup(opts \\ []) do
    # Start the TraceDB first
    storage_type = Keyword.get(opts, :storage, :ets)
    tracing_level = Keyword.get(opts, :tracing_level, :full)
    sample_rate = Keyword.get(opts, :sample_rate, 1.0)
    
    # Validate configuration
    validate_tracing_level!(tracing_level)
    validate_sample_rate!(sample_rate)
    
    # Setup TraceDB with the sampling rate
    {:ok, _pid} = TraceDB.start_link([
      storage: storage_type,
      sample_rate: sample_rate
    ])
    
    # Start core components with appropriate configuration
    {:ok, _pid} = ProcessObserver.start_link(tracing_level: tracing_level)
    {:ok, _pid} = MessageInterceptor.start_link(tracing_level: tracing_level)
    {:ok, _pid} = CodeTracer.start_link(tracing_level: tracing_level)
    
    # Optional Phoenix tracking
    if Keyword.get(opts, :phoenix, false) do
      PhoenixTracker.setup_phoenix_tracing(tracing_level: tracing_level)
    end
    
    # Optional AI integration
    if Keyword.get(opts, :ai_integration, false) do
      AIIntegration.setup()
    end
    
    # Optional trace all processes - respecting the tracing level
    if Keyword.get(opts, :trace_all, false) && tracing_level != :off do
      trace_all_processes()
    end
    
    :ok
  end
  
  @doc """
  Starts tracing a specific module.
  
  ## Example
  
      ElixirScope.trace_module(MyApp.User)
  """
  def trace_module(module) do
    CodeTracer.trace_module(module)
  end
  
  @doc """
  Starts tracing a specific GenServer process.
  
  ## Example
  
      pid = Process.whereis(MyApp.Worker)
      ElixirScope.trace_genserver(pid)
  """
  def trace_genserver(pid) do
    StateRecorder.trace_genserver(pid)
  end
  
  @doc """
  Starts tracing all registered GenServer processes.
  """
  def trace_all_genservers do
    Process.registered()
    |> Enum.map(&Process.whereis/1)
    |> Enum.filter(&Process.alive?/1)
    |> Enum.each(&trace_genserver/1)
  end
  
  @doc """
  Traces all processes in the system.
  
  Warning: This can generate a lot of data and impact performance.
  Consider using with `tracing_level: :minimal` or `sample_rate: 0.1` for production systems.
  """
  def trace_all_processes do
    Process.list()
    |> Enum.each(&trace_genserver/1)
  end
  
  @doc """
  Gets a timeline of state changes for a process.
  
  ## Example
  
      pid = Process.whereis(MyApp.Worker)
      ElixirScope.state_timeline(pid)
  """
  def state_timeline(pid) do
    QueryEngine.state_timeline(pid)
  end
  
  @doc """
  Gets the message flow between two processes.
  
  ## Example
  
      pid1 = Process.whereis(MyApp.WorkerA)
      pid2 = Process.whereis(MyApp.WorkerB)
      ElixirScope.message_flow(pid1, pid2)
  """
  def message_flow(from_pid, to_pid) do
    QueryEngine.message_flow(from_pid, to_pid)
  end
  
  @doc """
  Gets the execution path of a process.
  
  ## Example
  
      pid = Process.whereis(MyApp.Worker)
      ElixirScope.execution_path(pid)
  """
  def execution_path(pid) do
    QueryEngine.execution_path(pid)
  end
  
  @doc """
  Stops all tracing and cleans up resources.
  """
  def stop do
    :dbg.stop_clear()
    
    # Stop the GenServers
    GenServer.stop(ProcessObserver)
    GenServer.stop(MessageInterceptor)
    GenServer.stop(CodeTracer)
    GenServer.stop(TraceDB)
    
    :ok
  end
  
  # Helper functions for configuration validation
  
  defp validate_tracing_level!(level) when level in [:full, :messages_only, :states_only, :minimal, :off], do: :ok
  defp validate_tracing_level!(level) do
    raise ArgumentError, "Invalid tracing_level: #{inspect(level)}. " <>
      "Expected one of: :full, :messages_only, :states_only, :minimal, :off"
  end
  
  defp validate_sample_rate!(rate) when is_float(rate) and rate >= 0.0 and rate <= 1.0, do: :ok
  defp validate_sample_rate!(rate) when is_integer(rate) and rate >= 0 and rate <= 1, do: :ok
  defp validate_sample_rate!(rate) do
    raise ArgumentError, "Invalid sample_rate: #{inspect(rate)}. " <>
      "Expected a float between 0.0 and 1.0 (inclusive)"
  end
end 