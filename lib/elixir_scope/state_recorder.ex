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
      
      # Extend GenServer functionality by capturing original functions
      @es_original_init (
        if function_exported?(__MODULE__, :init, 1) do
          &__MODULE__.init/1
        end
      )
      
      @es_original_handle_call (
        if function_exported?(__MODULE__, :handle_call, 3) do
          &__MODULE__.handle_call/3
        end
      )
      
      @es_original_handle_cast (
        if function_exported?(__MODULE__, :handle_cast, 2) do
          &__MODULE__.handle_cast/2
        end
      )
      
      @es_original_handle_info (
        if function_exported?(__MODULE__, :handle_info, 2) do
          &__MODULE__.handle_info/2
        end
      )
      
      @es_original_terminate (
        if function_exported?(__MODULE__, :terminate, 2) do
          &__MODULE__.terminate/2
        end
      )
      
      # Override callbacks to add state logging
      def init(args) do
        ElixirScope.TraceDB.store_event(:genserver, %{
          pid: self(),
          module: __MODULE__,
          callback: :init,
          args: sanitize_state(args),
          timestamp: System.monotonic_time()
        })
        
        # Call original init if it exists, otherwise use default behavior
        result = case @es_original_init do
          nil -> {:ok, args}
          func -> func.(args)
        end
        
        case result do
          {:ok, state} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              data: %{callback: :init},
              state: sanitize_state(state),
              timestamp: System.monotonic_time()
            })
          _ -> :ok
        end
        
        result
      end
      
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
        
        # Call original handle_call if it exists, otherwise use default behavior
        result = case @es_original_handle_call do
          nil -> {:reply, {:error, :not_implemented}, state}
          func -> func.(msg, from, state)
        end
        
        case result do
          {:reply, reply, new_state} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              data: %{
                callback: :handle_call,
                message: sanitize_state(msg),
                reply: sanitize_state(reply)
              },
              state: sanitize_state(new_state),
              timestamp: System.monotonic_time()
            })
          {:reply, reply, new_state, _} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              data: %{
                callback: :handle_call,
                message: sanitize_state(msg),
                reply: sanitize_state(reply)
              },
              state: sanitize_state(new_state),
              timestamp: System.monotonic_time()
            })
          {:noreply, new_state} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              data: %{
                callback: :handle_call,
                message: sanitize_state(msg)
              },
              state: sanitize_state(new_state),
              timestamp: System.monotonic_time()
            })
          {:noreply, new_state, _} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              data: %{
                callback: :handle_call,
                message: sanitize_state(msg)
              },
              state: sanitize_state(new_state),
              timestamp: System.monotonic_time()
            })
          _ -> :ok
        end
        
        result
      end
      
      def handle_cast(msg, state) do
        ElixirScope.TraceDB.store_event(:genserver, %{
          pid: self(),
          module: __MODULE__,
          callback: :handle_cast,
          message: sanitize_state(msg),
          state_before: sanitize_state(state),
          timestamp: System.monotonic_time()
        })
        
        # Call original handle_cast if it exists, otherwise use default behavior
        result = case @es_original_handle_cast do
          nil -> {:noreply, state}
          func -> func.(msg, state)
        end
        
        case result do
          {:noreply, new_state} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              data: %{
                callback: :handle_cast,
                message: sanitize_state(msg)
              },
              state: sanitize_state(new_state),
              timestamp: System.monotonic_time()
            })
          {:noreply, new_state, _} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              data: %{
                callback: :handle_cast,
                message: sanitize_state(msg)
              },
              state: sanitize_state(new_state),
              timestamp: System.monotonic_time()
            })
          _ -> :ok
        end
        
        result
      end
      
      def handle_info(msg, state) do
        ElixirScope.TraceDB.store_event(:genserver, %{
          pid: self(),
          module: __MODULE__,
          callback: :handle_info,
          message: sanitize_state(msg),
          state_before: sanitize_state(state),
          timestamp: System.monotonic_time()
        })
        
        # Call original handle_info if it exists, otherwise use default behavior
        result = case @es_original_handle_info do
          nil -> {:noreply, state}
          func -> func.(msg, state)
        end
        
        case result do
          {:noreply, new_state} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              data: %{
                callback: :handle_info,
                message: sanitize_state(msg)
              },
              state: sanitize_state(new_state),
              timestamp: System.monotonic_time()
            })
          {:noreply, new_state, _} ->
            ElixirScope.TraceDB.store_event(:state, %{
              pid: self(),
              module: __MODULE__,
              data: %{
                callback: :handle_info,
                message: sanitize_state(msg)
              },
              state: sanitize_state(new_state),
              timestamp: System.monotonic_time()
            })
          _ -> :ok
        end
        
        result
      end
      
      def terminate(reason, state) do
        ElixirScope.TraceDB.store_event(:genserver, %{
          pid: self(),
          module: __MODULE__,
          callback: :terminate,
          reason: sanitize_state(reason),
          state: sanitize_state(state),
          timestamp: System.monotonic_time()
        })
        
        # Call original terminate if it exists, otherwise use default behavior
        case @es_original_terminate do
          nil -> :ok
          func -> func.(reason, state)
        end
      end
      
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
  
  # Empty implementation since we don't need the default implementation behavior anymore
  # but we still have the @before_compile reference in the __using__ macro
  defmacro __before_compile__(_env) do
    quote do
      # No additional code needed here
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
        data: %{callback: :trace_start},
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
    try do
      # This is the correct format for sys.install
      :sys.replace_state(pid, fn state ->
        send(receiver_pid, {:trace, pid, :state_change, nil, state})
        state
      end)
    rescue
      _ -> :ok
    end
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
          data: %{callback: :state_change, state_before: sanitize_state(old_state)},
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
  
  # Helper for sys callbacks - simplified to avoid issues
  defp fun(_type) do
    fn {_from, state}, _msg -> {:ok, state} end
  end
end 