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
    # The following implementation pattern solves issues with callback overriding
    quote do
      import Kernel, except: [def: 2]
      
      # Keep track of defined callbacks
      Module.register_attribute(__MODULE__, :es_callbacks, accumulate: true)
      
      # Override def to intercept GenServer callbacks
      defmacro def(call, expr) do
        # Extract function name and args
        {name, args} = case call do
          {name, _, args} when is_atom(name) and is_list(args) -> {name, args}
          _ -> {nil, nil}
        end
        
        # List of callbacks we want to instrument
        traceable_callbacks = [:init, :handle_call, :handle_cast, :handle_info, :terminate]
        
        if name in traceable_callbacks do
          # Mark this callback as defined
          Module.put_attribute(__CALLER__.module, :es_callbacks, name)
          
          case name do
            :init ->
              quote do
                def unquote(call) do
                  args = unquote(hd(args))
                  ElixirScope.StateRecorder.store_event_sync(:genserver, %{
                    pid: self(),
                    module: __MODULE__,
                    callback: :init,
                    args: ElixirScope.StateRecorder.sanitize_state(args),
                    timestamp: System.monotonic_time()
                  })
                  
                  # Call original implementation wrapped in the macro
                  result = unquote(expr[:do])
                  
                  case result do
                    {:ok, state} ->
                      ElixirScope.StateRecorder.store_event_sync(:state, %{
                        pid: self(),
                        module: __MODULE__,
                        data: %{callback: :init},
                        state: ElixirScope.StateRecorder.sanitize_state(state),
                        timestamp: System.monotonic_time()
                      })
                    _ -> :ok
                  end
                  
                  result
                end
              end
            
            :handle_call ->
              quote do
                def unquote(call) do
                  # Extract arguments
                  msg = unquote(Enum.at(args, 0))
                  from = unquote(Enum.at(args, 1))
                  state = unquote(Enum.at(args, 2))
                  
                  ElixirScope.StateRecorder.store_event_sync(:genserver, %{
                    pid: self(),
                    module: __MODULE__,
                    callback: :handle_call,
                    message: ElixirScope.StateRecorder.sanitize_state(msg),
                    from: from,
                    state_before: ElixirScope.StateRecorder.sanitize_state(state),
                    timestamp: System.monotonic_time()
                  })
                  
                  # Call original implementation wrapped in the macro
                  result = unquote(expr[:do])
                  
                  case result do
                    {:reply, reply, new_state} ->
                      ElixirScope.StateRecorder.store_event_sync(:state, %{
                        pid: self(),
                        module: __MODULE__,
                        data: %{
                          callback: :handle_call,
                          message: ElixirScope.StateRecorder.sanitize_state(msg),
                          reply: ElixirScope.StateRecorder.sanitize_state(reply)
                        },
                        state: ElixirScope.StateRecorder.sanitize_state(new_state),
                        timestamp: System.monotonic_time()
                      })
                    {:reply, reply, new_state, _} ->
                      ElixirScope.StateRecorder.store_event_sync(:state, %{
                        pid: self(),
                        module: __MODULE__,
                        data: %{
                          callback: :handle_call,
                          message: ElixirScope.StateRecorder.sanitize_state(msg),
                          reply: ElixirScope.StateRecorder.sanitize_state(reply)
                        },
                        state: ElixirScope.StateRecorder.sanitize_state(new_state),
                        timestamp: System.monotonic_time()
                      })
                    {:noreply, new_state} ->
                      ElixirScope.StateRecorder.store_event_sync(:state, %{
                        pid: self(),
                        module: __MODULE__,
                        data: %{
                          callback: :handle_call,
                          message: ElixirScope.StateRecorder.sanitize_state(msg)
                        },
                        state: ElixirScope.StateRecorder.sanitize_state(new_state),
                        timestamp: System.monotonic_time()
                      })
                    {:noreply, new_state, _} ->
                      ElixirScope.StateRecorder.store_event_sync(:state, %{
                        pid: self(),
                        module: __MODULE__,
                        data: %{
                          callback: :handle_call,
                          message: ElixirScope.StateRecorder.sanitize_state(msg)
                        },
                        state: ElixirScope.StateRecorder.sanitize_state(new_state),
                        timestamp: System.monotonic_time()
                      })
                    _ -> :ok
                  end
                  
                  result
                end
              end
            
            :handle_cast ->
              quote do
                def unquote(call) do
                  # Extract arguments
                  msg = unquote(Enum.at(args, 0))
                  state = unquote(Enum.at(args, 1))
                  
                  ElixirScope.StateRecorder.store_event_sync(:genserver, %{
                    pid: self(),
                    module: __MODULE__,
                    callback: :handle_cast,
                    message: ElixirScope.StateRecorder.sanitize_state(msg),
                    state_before: ElixirScope.StateRecorder.sanitize_state(state),
                    timestamp: System.monotonic_time()
                  })
                  
                  # Call original implementation wrapped in the macro
                  result = unquote(expr[:do])
                  
                  case result do
                    {:noreply, new_state} ->
                      ElixirScope.StateRecorder.store_event_sync(:state, %{
                        pid: self(),
                        module: __MODULE__,
                        data: %{
                          callback: :handle_cast,
                          message: ElixirScope.StateRecorder.sanitize_state(msg)
                        },
                        state: ElixirScope.StateRecorder.sanitize_state(new_state),
                        timestamp: System.monotonic_time()
                      })
                    {:noreply, new_state, _} ->
                      ElixirScope.StateRecorder.store_event_sync(:state, %{
                        pid: self(),
                        module: __MODULE__,
                        data: %{
                          callback: :handle_cast,
                          message: ElixirScope.StateRecorder.sanitize_state(msg)
                        },
                        state: ElixirScope.StateRecorder.sanitize_state(new_state),
                        timestamp: System.monotonic_time()
                      })
                    _ -> :ok
                  end
                  
                  result
                end
              end
            
            :handle_info ->
              quote do
                def unquote(call) do
                  # Extract arguments
                  msg = unquote(Enum.at(args, 0))
                  state = unquote(Enum.at(args, 1))
                  
                  ElixirScope.StateRecorder.store_event_sync(:genserver, %{
                    pid: self(),
                    module: __MODULE__,
                    callback: :handle_info,
                    message: ElixirScope.StateRecorder.sanitize_state(msg),
                    state_before: ElixirScope.StateRecorder.sanitize_state(state),
                    timestamp: System.monotonic_time()
                  })
                  
                  # Call original implementation wrapped in the macro
                  result = unquote(expr[:do])
                  
                  case result do
                    {:noreply, new_state} ->
                      ElixirScope.StateRecorder.store_event_sync(:state, %{
                        pid: self(),
                        module: __MODULE__,
                        data: %{
                          callback: :handle_info,
                          message: ElixirScope.StateRecorder.sanitize_state(msg)
                        },
                        state: ElixirScope.StateRecorder.sanitize_state(new_state),
                        timestamp: System.monotonic_time()
                      })
                    {:noreply, new_state, _} ->
                      ElixirScope.StateRecorder.store_event_sync(:state, %{
                        pid: self(),
                        module: __MODULE__,
                        data: %{
                          callback: :handle_info,
                          message: ElixirScope.StateRecorder.sanitize_state(msg)
                        },
                        state: ElixirScope.StateRecorder.sanitize_state(new_state),
                        timestamp: System.monotonic_time()
                      })
                    _ -> :ok
                  end
                  
                  result
                end
              end
            
            :terminate ->
              quote do
                def unquote(call) do
                  # Extract arguments
                  reason = unquote(Enum.at(args, 0))
                  state = unquote(Enum.at(args, 1))
                  
                  ElixirScope.StateRecorder.store_event_sync(:genserver, %{
                    pid: self(),
                    module: __MODULE__,
                    callback: :terminate,
                    reason: ElixirScope.StateRecorder.sanitize_state(reason),
                    state: ElixirScope.StateRecorder.sanitize_state(state),
                    timestamp: System.monotonic_time()
                  })
                  
                  # Call original implementation wrapped in the macro
                  unquote(expr[:do])
                end
              end
          end
        else
          # Pass through all other functions unchanged
          quote do
            def unquote(call), unquote(expr)
          end
        end
      end
      
      # Provide default implementations for callbacks that might not be defined
      @before_compile ElixirScope.StateRecorder
      
      # Re-import Kernel's def after we're done overriding
      import Kernel
    end
  end
  
  # Add default implementations for any missing callbacks
  defmacro __before_compile__(env) do
    defined_callbacks = Module.get_attribute(env.module, :es_callbacks) || []
    
    # Generate default implementations for any undefined callbacks
    callbacks = [
      init: 1,
      handle_call: 3,
      handle_cast: 2,
      handle_info: 2,
      terminate: 2
    ]
    
    # Create default implementations for any callback not already defined
    defaults = Enum.reduce callbacks, [], fn {name, arity}, acc ->
      if name in defined_callbacks do
        acc
      else
        case {name, arity} do
          {:init, 1} ->
            [quote do
               def init(args) do
                 ElixirScope.StateRecorder.store_event_sync(:genserver, %{
                   pid: self(),
                   module: __MODULE__,
                   callback: :init,
                   args: ElixirScope.StateRecorder.sanitize_state(args),
                   timestamp: System.monotonic_time()
                 })
                 
                 # Default implementation
                 {:ok, args}
               end
             end | acc]
             
          {:handle_call, 3} ->
            [quote do
               def handle_call(msg, from, state) do
                 ElixirScope.StateRecorder.store_event_sync(:genserver, %{
                   pid: self(),
                   module: __MODULE__,
                   callback: :handle_call,
                   message: ElixirScope.StateRecorder.sanitize_state(msg),
                   from: from,
                   state_before: ElixirScope.StateRecorder.sanitize_state(state),
                   timestamp: System.monotonic_time()
                 })
                 
                 # Default implementation
                 {:reply, {:error, :not_implemented}, state}
               end
             end | acc]
             
          {:handle_cast, 2} ->
            [quote do
               def handle_cast(msg, state) do
                 ElixirScope.StateRecorder.store_event_sync(:genserver, %{
                   pid: self(),
                   module: __MODULE__,
                   callback: :handle_cast,
                   message: ElixirScope.StateRecorder.sanitize_state(msg),
                   state_before: ElixirScope.StateRecorder.sanitize_state(state),
                   timestamp: System.monotonic_time()
                 })
                 
                 # Default implementation
                 {:noreply, state}
               end
             end | acc]
             
          {:handle_info, 2} ->
            [quote do
               def handle_info(msg, state) do
                 ElixirScope.StateRecorder.store_event_sync(:genserver, %{
                   pid: self(),
                   module: __MODULE__,
                   callback: :handle_info,
                   message: ElixirScope.StateRecorder.sanitize_state(msg),
                   state_before: ElixirScope.StateRecorder.sanitize_state(state),
                   timestamp: System.monotonic_time()
                 })
                 
                 # Default implementation
                 {:noreply, state}
               end
             end | acc]
             
          {:terminate, 2} ->
            [quote do
               def terminate(reason, state) do
                 ElixirScope.StateRecorder.store_event_sync(:genserver, %{
                   pid: self(),
                   module: __MODULE__,
                   callback: :terminate,
                   reason: ElixirScope.StateRecorder.sanitize_state(reason),
                   state: ElixirScope.StateRecorder.sanitize_state(state),
                   timestamp: System.monotonic_time()
                 })
                 
                 # Default implementation
                 :ok
               end
             end | acc]
             
          _ -> acc
        end
      end
    end
    
    quote do
      unquote_splicing(defaults)
    end
  end
  
  @doc """
  Helper function to sanitize state for storage.
  """
  def sanitize_state(state) do
    try do
      inspect(state, limit: 50, pretty: false)
    rescue
      _ -> "<<error inspecting state>>"
    end
  end
  
  @doc """
  Synchronous store_event function for tests - this directly inserts into the ETS tables
  rather than using GenServer.cast which might not complete in time for assertions
  """
  def store_event_sync(type, event_data) do
    case Process.whereis(ElixirScope.TraceDB) do
      nil -> 
        # If TraceDB is not running, this is a no-op
        :ok
      _pid ->
        # Store the event directly using ETS operations similar to TraceDB's handle_cast
        # Ensure timestamp is present
        event_data = Map.put_new(event_data, :timestamp, System.monotonic_time())
        
        # Add event type and id
        event_data = Map.put(event_data, :type, type)
        id = System.unique_integer([:positive, :monotonic])
        event_data = Map.put(event_data, :id, id)
        
        # For state events, ensure callback is properly extracted from data
        event_data = if type == :state and Map.has_key?(event_data, :data) do
          callback = get_in(event_data, [:data, :callback])
          Map.put(event_data, :callback, callback)
        else
          event_data
        end
        
        # Debug output during tests
        if Mix.env() == :test do
          IO.puts("Storing #{type} event with id #{id} for pid #{inspect(event_data[:pid])}")
        end
        
        # Store the event based on its type
        case type do
          :state ->
            # Store in the states table
            :ets.insert(:elixir_scope_states, {id, event_data})
            
            # Add to process index
            if Map.has_key?(event_data, :pid) do
              :ets.insert(:elixir_scope_process_index, {event_data.pid, {:state, id}})
            end
            
          _ ->
            # Store in the events table
            :ets.insert(:elixir_scope_events, {id, event_data})
            
            # Add to process index if a pid is present
            if Map.has_key?(event_data, :pid) do
              :ets.insert(:elixir_scope_process_index, {event_data.pid, {type, id}})
            end
            
            # Add sender to process index for message events
            if type == :message and Map.has_key?(event_data, :from_pid) do
              :ets.insert(:elixir_scope_process_index, {event_data.from_pid, {:message_sent, id}})
            end
            
            # Add receiver to process index for message events
            if type == :message and Map.has_key?(event_data, :to_pid) do
              :ets.insert(:elixir_scope_process_index, {event_data.to_pid, {:message_received, id}})
            end
        end
        
        :ok
    end
  end
  
  @doc """
  Forwards to the TraceDB's store_event function
  """
  def store_event(type, event_data) do
    TraceDB.store_event(type, event_data)
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
      store_event_sync(:state, %{
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
        store_event_sync(:genserver, %{
          pid: traced_pid,
          module: process_name(traced_pid),
          callback: :receive,
          message: sanitize_state(msg),
          timestamp: System.monotonic_time()
        })
        handle_trace_messages(traced_pid)
        
      {:trace, ^traced_pid, :call, {mod, fun, args}} ->
        store_event_sync(:genserver, %{
          pid: traced_pid,
          module: process_name(traced_pid),
          callback: {mod, fun, length(args)},
          args: sanitize_state(args),
          timestamp: System.monotonic_time()
        })
        handle_trace_messages(traced_pid)
        
      {:trace, ^traced_pid, :return_from, {mod, fun, arity}, result} ->
        store_event_sync(:genserver, %{
          pid: traced_pid,
          module: process_name(traced_pid),
          callback: {:return, mod, fun, arity},
          result: sanitize_state(result),
          timestamp: System.monotonic_time()
        })
        handle_trace_messages(traced_pid)
        
      {:trace, ^traced_pid, :send, msg, to_pid} ->
        store_event_sync(:genserver, %{
          pid: traced_pid,
          module: process_name(traced_pid),
          callback: :send,
          message: sanitize_state(msg),
          to: to_pid,
          timestamp: System.monotonic_time()
        })
        handle_trace_messages(traced_pid)
        
      {:trace, ^traced_pid, :state_change, old_state, new_state} ->
        store_event_sync(:state, %{
          pid: traced_pid,
          module: process_name(traced_pid),
          data: %{callback: :state_change, state_before: sanitize_state(old_state)},
          state: sanitize_state(new_state),
          timestamp: System.monotonic_time()
        })
        handle_trace_messages(traced_pid)
        
      {:DOWN, _ref, :process, ^traced_pid, reason} ->
        store_event_sync(:genserver, %{
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
end 