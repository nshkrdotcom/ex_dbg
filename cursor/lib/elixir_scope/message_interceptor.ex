defmodule ElixirScope.MessageInterceptor do
  @moduledoc """
  Captures all inter-process messages in the Erlang VM.
  
  This module is responsible for:
  - Logging message content and metadata
  - Tracking send/receive events
  - Associating messages with their process context
  """
  use GenServer
  
  alias ElixirScope.TraceDB
  
  @doc """
  Starts the MessageInterceptor.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Initializes the MessageInterceptor with tracing enabled.
  """
  def init(_opts) do
    # Set up message tracing using :dbg
    :dbg.tracer(:process, {fn msg, _ -> send(self(), {:trace_msg, msg}) end, []})
    :dbg.p(:all, [:send, :receive])
    
    # Start with tracing disabled to avoid performance issues
    # We'll enable it explicitly when needed
    :dbg.stop_clear()
    
    {:ok, %{enabled: false, message_count: 0}}
  end
  
  @doc """
  Enables message tracing.
  """
  def enable_tracing do
    GenServer.call(__MODULE__, :enable_tracing)
  end
  
  @doc """
  Disables message tracing.
  """
  def disable_tracing do
    GenServer.call(__MODULE__, :disable_tracing)
  end
  
  @doc """
  Gets current tracing status.
  """
  def tracing_status do
    GenServer.call(__MODULE__, :status)
  end
  
  @doc """
  Starts tracing messages for a specific process.
  """
  def trace_process(pid) do
    GenServer.call(__MODULE__, {:trace_process, pid})
  end
  
  # GenServer callbacks
  
  def handle_call(:enable_tracing, _from, state) do
    if not state.enabled do
      :dbg.tracer(:process, {fn msg, _ -> send(self(), {:trace_msg, msg}) end, []})
      :dbg.p(:all, [:send, :receive])
    end
    
    {:reply, :ok, %{state | enabled: true}}
  end
  
  def handle_call(:disable_tracing, _from, state) do
    if state.enabled do
      :dbg.stop_clear()
    end
    
    {:reply, :ok, %{state | enabled: false}}
  end
  
  def handle_call(:status, _from, state) do
    {:reply, %{enabled: state.enabled, message_count: state.message_count}, state}
  end
  
  def handle_call({:trace_process, pid}, _from, state) do
    # Enable tracing for a specific process
    :dbg.tracer(:process, {fn msg, _ -> send(self(), {:trace_msg, msg}) end, []})
    :dbg.p(pid, [:send, :receive])
    
    {:reply, :ok, %{state | enabled: true}}
  end
  
  def handle_info({:trace_msg, {:trace, from_pid, :send, msg, to_pid}}, state) do
    # Record send message events
    TraceDB.store_event(:message, %{
      id: System.unique_integer([:positive, :monotonic]),
      timestamp: System.monotonic_time(),
      from_pid: from_pid,
      to_pid: to_pid,
      message: sanitize_message(msg),
      type: :send
    })
    
    {:noreply, %{state | message_count: state.message_count + 1}}
  end
  
  def handle_info({:trace_msg, {:trace, pid, :receive, msg}}, state) do
    # Record receive message events
    TraceDB.store_event(:message, %{
      id: System.unique_integer([:positive, :monotonic]),
      timestamp: System.monotonic_time(),
      pid: pid,
      message: sanitize_message(msg),
      type: :receive
    })
    
    {:noreply, %{state | message_count: state.message_count + 1}}
  end
  
  def handle_info({:trace_msg, _other_trace}, state) do
    # Ignore other trace messages
    {:noreply, state}
  end
  
  # Private functions
  
  # Sanitize message to prevent storing very large terms
  defp sanitize_message(msg) do
    try do
      # Attempt to convert the message to a string for storing
      # If it's too large or complex, just store its type information
      inspect_limit = 500
      
      if is_binary(msg) and byte_size(msg) > inspect_limit do
        "<<#{byte_size(msg)} bytes binary>>"
      else
        case inspect(msg, limit: inspect_limit, pretty: false) do
          str when byte_size(str) > inspect_limit * 2 ->
            type = cond do
              is_pid(msg) -> "pid"
              is_function(msg) -> "function"
              is_port(msg) -> "port"
              is_reference(msg) -> "reference"
              is_tuple(msg) -> "tuple with #{tuple_size(msg)} elements"
              is_list(msg) -> "list with #{length(msg)} elements"
              is_map(msg) -> "map with #{map_size(msg)} elements"
              true -> "term"
            end
            "{#{type}, truncated due to size}"
          str -> str
        end
      end
    rescue
      _ -> "<<error inspecting message>>"
    end
  end
end 