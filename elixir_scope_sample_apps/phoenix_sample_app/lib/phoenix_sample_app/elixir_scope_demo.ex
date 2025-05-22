defmodule PhoenixSampleApp.ElixirScopeDemo do
  @moduledoc """
  Demonstrates using ElixirScope to debug and introspect the application.
  
  This module provides examples of how to use the various features of ElixirScope
  to analyze application behavior, trace processes, and debug issues.
  """
  
  alias ElixirScope.TraceDB
  
  @doc """
  Demonstrates how to analyze the Counter module's state changes.
  
  Example usage in IEx:
  
      iex> PhoenixSampleApp.Counter.reset()
      iex> PhoenixSampleApp.Counter.increment(5)
      iex> PhoenixSampleApp.Counter.decrement(2)
      iex> PhoenixSampleApp.ElixirScopeDemo.analyze_counter_state_changes()
  """
  def analyze_counter_state_changes do
    # Get the PID of the Counter process
    counter_pid = Process.whereis(PhoenixSampleApp.Counter)
    
    # Get the timeline of state changes
    state_history = get_state_timeline(counter_pid)
    
    # Print out state history
    IO.puts("Counter State History:")
    IO.puts("---------------------")
    
    Enum.each(state_history, fn event ->
      formatted_time = format_timestamp(event.timestamp)
      IO.puts("#{formatted_time}: State = #{inspect(event.state)}")
    end)
    
    # Calculate differences between states
    if length(state_history) > 1 do
      IO.puts("\nState Changes:")
      IO.puts("-------------")
      
      state_history
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.each(fn [state1, state2] ->
        change = state2.state - state1.state
        direction = if change >= 0, do: "increased by", else: "decreased by"
        
        formatted_time1 = format_timestamp(state1.timestamp)
        formatted_time2 = format_timestamp(state2.timestamp)
        
        IO.puts("From #{formatted_time1} to #{formatted_time2}: #{direction} #{abs(change)}")
      end)
    end
    
    :ok
  end
  
  # Gets the state timeline for a process from TraceDB
  defp get_state_timeline(pid) do
    TraceDB.get_state_history(pid)
  end
  
  @doc """
  Demonstrates how to trace module function calls.
  
  Example usage in IEx:
  
      iex> PhoenixSampleApp.ElixirScopeDemo.trace_counter_module()
      iex> PhoenixSampleApp.Counter.increment(10)
      iex> PhoenixSampleApp.Counter.get()
      iex> PhoenixSampleApp.ElixirScopeDemo.show_counter_function_calls()
  """
  def trace_counter_module do
    # Start the MessageInterceptor if it's not running
    case Process.whereis(ElixirScope.MessageInterceptor) do
      nil -> 
        {:ok, _pid} = ElixirScope.MessageInterceptor.start_link(tracing_level: :full)
      _ -> 
        :ok
    end
    
    # Enable message tracing
    ElixirScope.MessageInterceptor.enable_tracing()
    
    # Trace the Counter process
    counter_pid = Process.whereis(PhoenixSampleApp.Counter)
    ElixirScope.MessageInterceptor.trace_process(counter_pid)
    
    # Start tracing state changes with StateRecorder
    ElixirScope.StateRecorder.trace_genserver(counter_pid)
    
    IO.puts("Now tracing PhoenixSampleApp.Counter module.")
    IO.puts("Execute some Counter functions, then call show_counter_function_calls/0 to see results.")
    
    :ok
  end
  
  @doc """
  Shows the function calls made to the Counter module after tracing.
  """
  def show_counter_function_calls do
    # Get the PID of the Counter process
    counter_pid = Process.whereis(PhoenixSampleApp.Counter)
    
    # Query for message events
    events = TraceDB.query_events(%{
      type: :message,
      pid: counter_pid
    })
    
    IO.puts("Counter Function Calls:")
    IO.puts("---------------------")
    
    Enum.each(events, fn event ->
      formatted_time = format_timestamp(event.timestamp)
      
      # Attempt to extract function name from message
      function_info = case event.message do
        {:'$gen_call', _, {:set, value}} ->
          "set(#{inspect(value)})"
        {:'$gen_call', _, :get} ->
          "get()"
        {:'$gen_cast', _, {:increment, amount}} ->
          "increment(#{inspect(amount)})"
        {:'$gen_cast', _, {:decrement, amount}} ->
          "decrement(#{inspect(amount)})"
        {:'$gen_cast', _, {:reset, value}} ->
          "reset(#{inspect(value)})"
        _ ->
          "unknown(#{inspect(event.message)})"
      end
      
      IO.puts("#{formatted_time}: #{function_info}")
    end)
    
    :ok
  end
  
  @doc """
  Demonstrates time-travel debugging features.
  
  Example usage in IEx (after making some counter operations):
  
      iex> PhoenixSampleApp.ElixirScopeDemo.time_travel_debug()
  """
  def time_travel_debug do
    # Get the PID of the Counter process
    counter_pid = Process.whereis(PhoenixSampleApp.Counter)
    
    # Get the timeline of state changes
    state_history = get_state_timeline(counter_pid)
    
    if length(state_history) > 0 do
      # Pick a point in time (the timestamp of a state change)
      timestamp = state_history |> Enum.at(div(length(state_history), 2)) |> Map.get(:timestamp)
      
      IO.puts("Time-travel debugging to: #{format_timestamp(timestamp)}")
      IO.puts("------------------------------------------------")
      
      # Get events around that time
      events_around = TraceDB.get_events_at(timestamp, 1000) # 1 second window
      
      # Show events around that time
      IO.puts("\nEvents around that time:")
      
      Enum.each(Enum.take(events_around, 5), fn event -> 
        formatted_time = format_timestamp(event.timestamp)
        IO.puts("#{formatted_time}: #{event.type} event")
      end)
      
      # Get the state at that time
      state_at_time = case TraceDB.get_state_at(counter_pid, timestamp) do
        {:ok, state} -> state
        {:error, _} -> "Unknown"
      end
      
      IO.puts("\nCounter state at that time: #{inspect(state_at_time)}")
    else
      IO.puts("No state history available. Try operating the counter first.")
    end
    
    :ok
  end
  
  @doc """
  Demonstrates the supervision tree visualization.
  """
  def show_supervision_tree do
    # Get all processes
    processes = Process.list()
    
    # Filter to find supervisors - use a more careful approach to identify actual supervisors
    # Avoid known non-supervisor processes
    known_non_supervisors = [:logger, :kernel_sup_safe, :application_controller, :erts_trace_cleaner, :socket_registry]
    
    supervisors = Enum.filter(processes, fn pid ->
      # Skip if the process is in the known non-supervisors list
      case Process.info(pid, :registered_name) do
        {:registered_name, name} when name in known_non_supervisors -> 
          false
        _ ->
          # Check if it looks like a supervisor
          case Process.info(pid, [:dictionary]) do
            [{:dictionary, dictionary}] ->
              # Check for supervisor module in initial call or behavior
              is_supervisor =
                (Keyword.get(dictionary, :"$initial_call") in [
                  {:supervisor, :supervisor, 1},
                  {:supervisor, Supervisor, 1}
                ]) or
                Enum.any?(dictionary, fn
                  {:behaviour_modules, modules} -> Supervisor in modules
                  _ -> false
                end)
                
              if is_supervisor do
                # Verify it responds to which_children as a final check
                try do
                  Supervisor.count_children(pid)
                  true
                rescue
                  _ -> false
                catch
                  _, _ -> false
                end
              else
                false
              end
            _ -> 
              false
          end
      end
    end)
    
    IO.puts("Application Supervision Tree:")
    IO.puts("---------------------------")
    
    Enum.each(supervisors, fn pid ->
      name = case Process.info(pid, :registered_name) do
        {:registered_name, registered_name} -> registered_name
        _ -> nil
      end
      
      # Safely get children with a timeout to avoid hangs
      children = safe_get_children(pid)
      
      supervisor_name = if name, do: name, else: inspect(pid)
      
      IO.puts("Supervisor: #{supervisor_name}")
      
      Enum.each(children, fn {child_id, child_pid, child_type, _modules} ->
        child_name = case Process.info(child_pid, :registered_name) do
          {:registered_name, registered_name} -> registered_name
          _ -> inspect(child_pid)
        end
        
        IO.puts("  Child: #{child_id} (#{child_type}) - #{child_name}")
        
        # Check if this child is also a supervisor
        if child_type == :supervisor do
          # Get grandchildren
          grandchildren = safe_get_children(child_pid)
          Enum.each(grandchildren, fn {grandchild_id, grandchild_pid, gc_type, _} ->
            grandchild_name = case Process.info(grandchild_pid, :registered_name) do
              {:registered_name, registered_name} -> registered_name
              _ -> inspect(grandchild_pid)
            end
            
            IO.puts("    Grandchild: #{grandchild_id} (#{gc_type}) - #{grandchild_name}")
          end)
        end
      end)
    end)
    
    :ok
  end
  
  # Get children of a supervisor with a timeout to avoid hanging
  defp safe_get_children(supervisor_pid) do
    try do
      # Use Task.yield_many with a timeout to avoid hangs
      task = Task.async(fn -> Supervisor.which_children(supervisor_pid) end)
      case Task.yield(task, 500) do
        {:ok, result} -> result
        nil -> 
          Task.shutdown(task)
          []
      end
    rescue
      _ -> []
    catch
      _, _ -> []
    end
  end
  
  # Helper functions
  
  defp format_timestamp(timestamp) do
    # Convert ElixirVM monotonic time to DateTime
    system_time = System.convert_time_unit(timestamp, :native, :microsecond)
    {date, {hour, minute, second}} = :calendar.system_time_to_universal_time(system_time, :microsecond)
    {microsecond, _} = system_time |> rem(1_000_000) |> Integer.digits(10) |> List.to_string() |> Float.parse
    
    "#{hour}:#{minute}:#{second}.#{microsecond}"
  end
end 