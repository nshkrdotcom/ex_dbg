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
  
  ## Example
  
      ElixirScope.setup(phoenix: true)
  """
  def setup(opts \\ []) do
    # Start the TraceDB first
    storage_type = Keyword.get(opts, :storage, :ets)
    {:ok, _pid} = TraceDB.start_link(storage: storage_type)
    
    # Start core components
    {:ok, _pid} = ProcessObserver.start_link()
    {:ok, _pid} = MessageInterceptor.start_link()
    {:ok, _pid} = CodeTracer.start_link()
    
    # Optional Phoenix tracking
    if Keyword.get(opts, :phoenix, false) do
      PhoenixTracker.setup_phoenix_tracing()
    end
    
    # Optional AI integration
    if Keyword.get(opts, :ai_integration, false) do
      AIIntegration.setup()
    end
    
    # Optional trace all processes
    if Keyword.get(opts, :trace_all, false) do
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
end 