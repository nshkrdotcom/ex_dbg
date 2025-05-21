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
  
  ## Options
  
  * `:tracing_level` - Controls the level of tracing detail (`:full`, `:messages_only`, `:states_only`, `:minimal`, or `:off`). Default: `:full`
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Initializes the MessageInterceptor with tracing enabled based on configuration.
  """
  def init(opts) do
    tracing_level = Keyword.get(opts, :tracing_level, :full)
    
    # Make sure to stop any existing trace
    try do
      :dbg.stop()
    catch
      _, _ -> :ok
    end
    
    # Set up message tracing using :dbg
    try do
      :dbg.tracer(:process, {fn msg, _ -> send(self(), {:trace_msg, msg}) end, []})
    catch
      _, _ -> :ok
    end
    
    # Determine if tracing should be enabled based on tracing_level
    enabled = tracing_level in [:full, :messages_only]
    
    # Enable tracing if needed
    if enabled do
      try do
        :dbg.p(:all, [:send, :receive])
      catch
        _, _ -> :ok
      end
    end
    
    # Make this process trap exits so it can cleanup properly
    Process.flag(:trap_exit, true)
    
    {:ok, %{
      enabled: enabled,
      message_count: 0,
      tracing_level: tracing_level
    }}
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
  
  @doc """
  Changes the current tracing level.
  
  ## Parameters
  
  * `level` - New tracing level: `:full`, `:messages_only`, `:states_only`, `:minimal`, or `:off`
  """
  def set_tracing_level(level) when level in [:full, :messages_only, :states_only, :minimal, :off] do
    GenServer.call(__MODULE__, {:set_tracing_level, level})
  end
  def set_tracing_level(level) do
    {:error, "Invalid tracing level: #{inspect(level)}"}
  end
  
  # GenServer callbacks
  
  def handle_call(:enable_tracing, _from, state) do
    if not state.enabled do
      try do
        # Set up the tracer first
        :dbg.tracer(:process, {fn msg, _ -> send(self(), {:trace_msg, msg}) end, []})
        # Then start tracing processes
        :dbg.p(:all, [:send, :receive])
      catch
        kind, error ->
          IO.puts("Failed to enable tracing: #{inspect({kind, error})}")
      end
    end
    
    {:reply, :ok, %{state | enabled: true}}
  end
  
  def handle_call(:disable_tracing, _from, state) do
    if state.enabled do
      try do
        # Stop tracing properly
        :dbg.stop()
      catch
        kind, error ->
          IO.puts("Failed to disable tracing: #{inspect({kind, error})}")
      end
    end
    
    {:reply, :ok, %{state | enabled: false}}
  end
  
  def handle_call(:status, _from, state) do
    {:reply, %{
      enabled: state.enabled,
      message_count: state.message_count,
      tracing_level: state.tracing_level
    }, state}
  end
  
  def handle_call({:trace_process, pid}, _from, state) do
    # Enable tracing for a specific process
    try do
      # Stop any existing tracing first
      :dbg.stop()
      # Set up new tracer
      :dbg.tracer(:process, {fn msg, _ -> send(self(), {:trace_msg, msg}) end, []})
      # Trace only this specific process with both send and receive operations
      # Ensure we're capturing both send and receive
      :dbg.p(pid, [:send, :receive])
      
      # Log that we're tracing this process to aid debugging
      IO.puts("Started tracing process #{inspect(pid)}")
    catch
      kind, error ->
        IO.puts("Failed to trace process #{inspect(pid)}: #{inspect({kind, error})}")
    end
    
    {:reply, :ok, %{state | enabled: true}}
  end
  
  def handle_call({:set_tracing_level, level}, _from, state) do
    # Update tracing based on new level
    should_be_enabled = level in [:full, :messages_only]
    new_state = %{state | tracing_level: level}
    
    cond do
      # Need to enable
      should_be_enabled and not state.enabled ->
        try do
          :dbg.tracer(:process, {fn msg, _ -> send(self(), {:trace_msg, msg}) end, []})
          :dbg.p(:all, [:send, :receive])
        catch
          kind, error ->
            IO.puts("Failed to set tracing level: #{inspect({kind, error})}")
        end
        {:reply, :ok, %{new_state | enabled: true}}
        
      # Need to disable
      not should_be_enabled and state.enabled ->
        try do
          :dbg.stop()
        catch
          kind, error ->
            IO.puts("Failed to disable tracing: #{inspect({kind, error})}")
        end
        {:reply, :ok, %{new_state | enabled: false}}
        
      # No change needed
      true ->
        {:reply, :ok, new_state}
    end
  end
  
  def handle_info({:trace_msg, {:trace, from_pid, :send, msg, to_pid}}, state) do
    # Skip this message if tracing level is not appropriate
    if state.tracing_level in [:full, :messages_only] do
      # Record send message events
      try do
        TraceDB.store_event(:message, %{
          id: System.unique_integer([:positive, :monotonic]),
          timestamp: System.monotonic_time(),
          from_pid: from_pid,
          to_pid: to_pid,
          message: maybe_sanitize_message(msg, state.tracing_level),
          type: :send
        })
        
        {:noreply, %{state | message_count: state.message_count + 1}}
      catch
        _, _ ->
          # If we fail to store, just continue
          {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end
  
  def handle_info({:trace_msg, {:trace, pid, :receive, msg}}, state) do
    # Skip this message if tracing level is not appropriate
    if state.tracing_level in [:full, :messages_only] do
      # Record receive message events
      try do
        TraceDB.store_event(:message, %{
          id: System.unique_integer([:positive, :monotonic]),
          timestamp: System.monotonic_time(),
          pid: pid,
          message: maybe_sanitize_message(msg, state.tracing_level),
          type: :receive
        })
        
        {:noreply, %{state | message_count: state.message_count + 1}}
      catch
        _, _ ->
          # If we fail to store, just continue
          {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end
  
  def handle_info({:trace_msg, _other_trace}, state) do
    # Ignore other trace messages
    {:noreply, state}
  end
  
  def handle_info({:EXIT, _pid, _reason}, state) do
    # Handle exit messages gracefully to avoid crashing
    {:noreply, state}
  end
  
  def terminate(_reason, state) do
    # Clean up when the process is terminated
    if state.enabled do
      try do
        :dbg.stop()
      catch
        _, _ -> :ok
      end
    end
    :ok
  end
  
  # Private functions
  
  # Conditionally sanitize message based on tracing level
  defp maybe_sanitize_message(msg, :minimal) do
    # For minimal tracing, just store the type/shape, not the content
    type = cond do
      is_pid(msg) -> "pid"
      is_function(msg) -> "function"
      is_port(msg) -> "port"
      is_reference(msg) -> "reference"
      is_tuple(msg) -> "tuple with #{tuple_size(msg)} elements"
      is_list(msg) -> "list with #{length(msg)} elements"
      is_map(msg) -> "map with #{map_size(msg)} elements"
      is_binary(msg) -> "binary with #{byte_size(msg)} bytes"
      true -> "term"
    end
    "{#{type}}"
  end
  
  defp maybe_sanitize_message(msg, _tracing_level) do
    sanitize_message(msg)
  end
  
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