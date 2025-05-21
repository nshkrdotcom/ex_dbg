defmodule ElixirScope.StateRecorder do
  @moduledoc """
  Tracks state changes in GenServers.
  
  This module provides two ways to track GenServer state:
  1. A `__using__` macro to instrument GenServer modules
  2. Direct tracing of external GenServers using `:sys.trace/2`
  """
  
  alias ElixirScope.TraceDB
  
  @doc """
  When used, this macro enhances a GenServer to automatically track state changes.
  
  It overrides the GenServer callbacks to record state before and after
  each callback execution.
  
  ## Example
  
      defmodule MyApp.Worker do
        use GenServer
        use ElixirScope.StateRecorder
        
        # Normal GenServer implementation...
      end
  """
  defmacro __using__(_opts) do
    quote do
      # Store original callbacks if they exist
      @before_compile ElixirScope.StateRecorder
      
      # Track if the module has defined each callback
      Module.register_attribute(__MODULE__, :has_init, accumulate: false, persist: false)
      Module.register_attribute(__MODULE__, :has_handle_call, accumulate: false, persist: false)
      Module.register_attribute(__MODULE__, :has_handle_cast, accumulate: false, persist: false)
      Module.register_attribute(__MODULE__, :has_handle_info, accumulate: false, persist: false)
      Module.register_attribute(__MODULE__, :has_terminate, accumulate: false, persist: false)
      
      # Default all to false
      @has_init false
      @has_handle_call false
      @has_handle_cast false
      @has_handle_info false
      @has_terminate false
      
      # Override callbacks to add state logging
      def init(args) do
        ElixirScope.TraceDB.store_event(:genserver, %{
          pid: self(),
          module: __MODULE__,
          callback: :init,
          args: sanitize_state(args),
          timestamp: System.monotonic_time()
        })
        
        result = super(args)
        
        case result do
          {:ok, state} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              callback: :init,
              state: sanitize_state(state),
              timestamp: System.monotonic_time()
            })
          _ -> :ok
        end
        
        result
      end
      
      # Mark that we've defined our own init
      @has_init true
      
      def handle_call(msg, from, state) do
        ElixirScope.TraceDB.store_event(:genserver, %{
          pid: self(),
          module: __MODULE__,
          callback: :handle_call,
          message: sanitize_state(msg),
          from: from,
          state_before: sanitize_state(state),
          timestamp: System.monotonic_time()
        })
        
        result = super(msg, from, state)
        
        case result do
          {:reply, reply, new_state} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              callback: :handle_call,
              message: sanitize_state(msg),
              reply: sanitize_state(reply),
              state: sanitize_state(new_state),
              timestamp: System.monotonic_time()
            })
          {:reply, reply, new_state, _} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              callback: :handle_call,
              message: sanitize_state(msg),
              reply: sanitize_state(reply),
              state: sanitize_state(new_state),
              timestamp: System.monotonic_time()
            })
          {:noreply, new_state} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              callback: :handle_call,
              message: sanitize_state(msg),
              state: sanitize_state(new_state),
              timestamp: System.monotonic_time()
            })
          {:noreply, new_state, _} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              callback: :handle_call,
              message: sanitize_state(msg),
              state: sanitize_state(new_state),
              timestamp: System.monotonic_time()
            })
          _ -> :ok
        end
        
        result
      end
      
      # Mark that we've defined our own handle_call
      @has_handle_call true
      
      def handle_cast(msg, state) do
        ElixirScope.TraceDB.store_event(:genserver, %{
          pid: self(),
          module: __MODULE__,
          callback: :handle_cast,
          message: sanitize_state(msg),
          state_before: sanitize_state(state),
          timestamp: System.monotonic_time()
        })
        
        result = super(msg, state)
        
        case result do
          {:noreply, new_state} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              callback: :handle_cast,
              message: sanitize_state(msg),
              state: sanitize_state(new_state),
              timestamp: System.monotonic_time()
            })
          {:noreply, new_state, _} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              callback: :handle_cast,
              message: sanitize_state(msg),
              state: sanitize_state(new_state),
              timestamp: System.monotonic_time()
            })
          _ -> :ok
        end
        
        result
      end
      
      # Mark that we've defined our own handle_cast
      @has_handle_cast true
      
      def handle_info(msg, state) do
        ElixirScope.TraceDB.store_event(:genserver, %{
          pid: self(),
          module: __MODULE__,
          callback: :handle_info,
          message: sanitize_state(msg),
          state_before: sanitize_state(state),
          timestamp: System.monotonic_time()
        })
        
        result = super(msg, state)
        
        case result do
          {:noreply, new_state} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              callback: :handle_info,
              message: sanitize_state(msg),
              state: sanitize_state(new_state),
              timestamp: System.monotonic_time()
            })
          {:noreply, new_state, _} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              callback: :handle_info,
              message: sanitize_state(msg),
              state: sanitize_state(new_state),
              timestamp: System.monotonic_time()
            })
          _ -> :ok
        end
        
        result
      end
      
      # Mark that we've defined our own handle_info
      @has_handle_info true
      
      def terminate(reason, state) do
        ElixirScope.TraceDB.store_event(:genserver, %{
          pid: self(),
          module: __MODULE__,
          callback: :terminate,
          reason: sanitize_state(reason),
          state: sanitize_state(state),
          timestamp: System.monotonic_time()
        })
        
        super(reason, state)
      end
      
      # Mark that we've defined our own terminate
      @has_terminate true
      
      # Helper to sanitize state for storage
      defp sanitize_state(state) do
        try do
          inspect(state, limit: 50, pretty: false)
        rescue
          _ -> "<<error inspecting state>>"
        end
      end
      
      defoverridable [init: 1, handle_call: 3, handle_cast: 2, handle_info: 2, terminate: 2]
    end
  end
  
  @doc """
  Provides default implementations for callbacks that weren't defined.
  """
  defmacro __before_compile__(_env) do
    quote do
      unless @has_init do
        def init(args) do
          ElixirScope.TraceDB.store_event(:genserver, %{
            pid: self(),
            module: __MODULE__,
            callback: :init,
            args: sanitize_state(args),
            timestamp: System.monotonic_time()
          })
          
          {:ok, args}
        end
      end
      
      unless @has_handle_call do
        def handle_call(msg, _from, state) do
          ElixirScope.TraceDB.store_event(:genserver, %{
            pid: self(),
            module: __MODULE__,
            callback: :handle_call,
            message: sanitize_state(msg),
            state_before: sanitize_state(state),
            timestamp: System.monotonic_time()
          })
          
          {:reply, {:error, :not_implemented}, state}
        end
      end
      
      unless @has_handle_cast do
        def handle_cast(msg, state) do
          ElixirScope.TraceDB.store_event(:genserver, %{
            pid: self(),
            module: __MODULE__,
            callback: :handle_cast,
            message: sanitize_state(msg),
            state_before: sanitize_state(state),
            timestamp: System.monotonic_time()
          })
          
          {:noreply, state}
        end
      end
      
      unless @has_handle_info do
        def handle_info(msg, state) do
          ElixirScope.TraceDB.store_event(:genserver, %{
            pid: self(),
            module: __MODULE__,
            callback: :handle_info,
            message: sanitize_state(msg),
            state_before: sanitize_state(state),
            timestamp: System.monotonic_time()
          })
          
          {:noreply, state}
        end
      end
      
      unless @has_terminate do
        def terminate(reason, state) do
          ElixirScope.TraceDB.store_event(:genserver, %{
            pid: self(),
            module: __MODULE__,
            callback: :terminate,
            reason: sanitize_state(reason),
            state: sanitize_state(state),
            timestamp: System.monotonic_time()
          })
          
          :ok
        end
      end
    end
  end
  
  @doc """
  Starts tracing a specific GenServer process using :sys.trace/2.
  
  This is useful for monitoring GenServers that you can't modify directly.
  
  ## Example
  
      pid = Process.whereis(MyApp.Worker)
      ElixirScope.StateRecorder.trace_genserver(pid)
  """
  def trace_genserver(pid) when is_pid(pid) do
    # Set up tracing handler to intercept GenServer state changes
    Process.monitor(pid)
    setup_trace_handler(pid)
    
    # Enable sys tracing
    :sys.trace(pid, true)
    
    # Log initial state if possible
    try do
      initial_state = :sys.get_state(pid)
      TraceDB.store_event(:state, %{
        pid: pid,
        module: process_name(pid),
        callback: :trace_start,
        state: sanitize_state(initial_state),
        timestamp: System.monotonic_time()
      })
    rescue
      _ -> :ok
    end
    
    :ok
  end
  
  @doc """
  Stops tracing a specific GenServer process.
  """
  def stop_trace_genserver(pid) when is_pid(pid) do
    :sys.trace(pid, false)
    :ok
  end
  
  # Installs a handler for the :sys.trace messages
  defp setup_trace_handler(pid) do
    receiver_pid = spawn_link(fn -> handle_trace_messages(pid) end)
    :sys.install(pid, {receiver_pid, nil}, {fun(:user), fun(:sys)})
  end
  
  # Handles trace messages from the system
  defp handle_trace_messages(traced_pid) do
    receive do
      {:trace, ^traced_pid, :receive, msg} ->
        TraceDB.store_event(:genserver, %{
          pid: traced_pid,
          module: process_name(traced_pid),
          callback: :receive,
          message: sanitize_state(msg),
          timestamp: System.monotonic_time()
        })
        handle_trace_messages(traced_pid)
        
      {:trace, ^traced_pid, :call, {mod, fun, args}} ->
        TraceDB.store_event(:genserver, %{
          pid: traced_pid,
          module: process_name(traced_pid),
          callback: {mod, fun, length(args)},
          args: sanitize_state(args),
          timestamp: System.monotonic_time()
        })
        handle_trace_messages(traced_pid)
        
      {:trace, ^traced_pid, :return_from, {mod, fun, arity}, result} ->
        TraceDB.store_event(:genserver, %{
          pid: traced_pid,
          module: process_name(traced_pid),
          callback: {:return, mod, fun, arity},
          result: sanitize_state(result),
          timestamp: System.monotonic_time()
        })
        handle_trace_messages(traced_pid)
        
      {:trace, ^traced_pid, :send, msg, to_pid} ->
        TraceDB.store_event(:genserver, %{
          pid: traced_pid,
          module: process_name(traced_pid),
          callback: :send,
          message: sanitize_state(msg),
          to: to_pid,
          timestamp: System.monotonic_time()
        })
        handle_trace_messages(traced_pid)
        
      {:trace, ^traced_pid, :state_change, old_state, new_state} ->
        TraceDB.store_event(:state, %{
          pid: traced_pid,
          module: process_name(traced_pid),
          callback: :state_change,
          state_before: sanitize_state(old_state),
          state: sanitize_state(new_state),
          timestamp: System.monotonic_time()
        })
        handle_trace_messages(traced_pid)
        
      {:DOWN, _ref, :process, ^traced_pid, reason} ->
        TraceDB.store_event(:genserver, %{
          pid: traced_pid,
          module: process_name(traced_pid),
          callback: :terminate,
          reason: sanitize_state(reason),
          timestamp: System.monotonic_time()
        })
        
      _ ->
        # Ignore other messages
        handle_trace_messages(traced_pid)
    end
  end
  
  # Helper functions
  
  defp process_name(pid) do
    case Process.info(pid, :registered_name) do
      {:registered_name, name} when is_atom(name) -> name
      _ -> pid
    end
  end
  
  defp sanitize_state(state) do
    try do
      inspect(state, limit: 50, pretty: false)
    rescue
      _ -> "<<error inspecting state>>"
    end
  end
  
  # Helper for sys callbacks
  defp fun(type) do
    fn
      {from, state}, msg ->
        if from != Process.whereis(:sys) do
          send(from, {:trace, self(), :state_change, state, :sys.get_state(self())})
        end
        {:ok, state}
    end
  end
end 