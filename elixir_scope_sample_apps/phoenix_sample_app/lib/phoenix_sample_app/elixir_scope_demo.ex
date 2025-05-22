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
    
    # Define process names that are known to not be supervisors
    known_non_supervisors = [
      :logger, :kernel_sup_safe, :application_controller, 
      :erts_trace_cleaner, :socket_registry, :kernel_safe_sup, 
      :standard_error, :standard_error_sup, :file_server_2,
      :code_server, :erl_prim_loader, :user, :global_name_server,
      :inet_db, :pg, :timer_server, :elixir_config, :elixir_sup,
      :global_group, :init
    ]
    
    IO.puts("Application Supervision Tree:")
    IO.puts("---------------------------")
    
    # Find and print top-level supervisors first
    top_supervisors = Enum.filter(processes, fn pid ->
      is_likely_supervisor?(pid, known_non_supervisors)
    end)
    
    Enum.each(top_supervisors, fn pid ->
      print_supervisor_tree(pid, "", known_non_supervisors)
    end)
    
    :ok
  end
  
  # Determine if a process is likely a supervisor
  defp is_likely_supervisor?(pid, known_non_supervisors) do
    # Skip if process no longer exists
    if !Process.alive?(pid), do: return(false)
    
    # Skip if process is in the known non-supervisors list
    case Process.info(pid, :registered_name) do
      {:registered_name, name} when name in known_non_supervisors -> 
        false
      _ ->
        # Check for supervisor indicators in process dictionary
        case Process.info(pid, [:dictionary]) do
          [{:dictionary, dictionary}] when is_list(dictionary) ->
            # Look for specific supervisor indicators
            initial_call = Keyword.get(dictionary, :"$initial_call")
            behaviour_modules = Keyword.get(dictionary, :behaviour_modules, [])
            
            supervisor_initial_calls = [
              {:supervisor, :supervisor, 1},
              {:supervisor, Supervisor, 1},
              {:supervisor3, :init, 1}
            ]
            
            cond do
              initial_call in supervisor_initial_calls -> true
              Supervisor in behaviour_modules -> true
              true ->
                # Try a safer approach to check if it's a supervisor
                try_supervisor_check(pid)
            end
          _ -> 
            false
        end
    end
  rescue
    # Handle any errors during inspection
    _ -> false
  catch
    # Handle any throws during inspection
    _, _ -> false
  end
  
  # Try to safely check if a process is a supervisor without crashing
  defp try_supervisor_check(pid) do
    # Use a combination of checks that won't crash for non-supervisors
    try do
      # Use Task with timeout to avoid hanging
      task = Task.async(fn -> 
        # Try to get supervisor flags - only works for supervisors
        # This is safer than which_children for detection
        case :sys.get_state(pid) do
          %{flags: _} -> true
          {_, %{flags: _}} -> true
          {:state, _, _, %{flags: _}, _} -> true
          _ -> 
            # If we can get children without error, it's a supervisor
            case Supervisor.count_children(pid) do
              %{} -> true
              _ -> false
            end
        end
      end)
      
      case Task.yield(task, 100) do
        {:ok, result} -> result
        _ -> 
          Task.shutdown(task)
          false
      end
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end
  
  # Print a supervisor and its children with indentation
  defp print_supervisor_tree(pid, indent, known_non_supervisors) do
    # Skip if process no longer exists
    if !Process.alive?(pid), do: return(nil)
    
    name = case Process.info(pid, :registered_name) do
      {:registered_name, registered_name} -> registered_name
      _ -> inspect(pid)
    end
    
    IO.puts("#{indent}Supervisor: #{name}")
    
    # Safely get children with a timeout to avoid hangs
    children = safe_get_children(pid)
    
    Enum.each(children, fn 
      {child_id, child_pid, child_type, _modules} when is_pid(child_pid) and Process.alive?(child_pid) ->
        child_name = case Process.info(child_pid, :registered_name) do
          {:registered_name, registered_name} -> registered_name
          _ -> inspect(child_pid)
        end
        
        IO.puts("#{indent}  Child: #{child_id} (#{child_type}) - #{child_name}")
        
        # Recursively print child supervisors
        if child_type == :supervisor and is_likely_supervisor?(child_pid, known_non_supervisors) do
          print_supervisor_tree(child_pid, "#{indent}    ", known_non_supervisors)
        end
      _ ->
        # Skip children that are no longer alive or invalid
        nil
    end)
  rescue
    e -> IO.puts("#{indent}  Error inspecting supervisor #{inspect(pid)}: #{inspect(e)}")
  catch
    kind, reason -> IO.puts("#{indent}  Error #{kind} inspecting supervisor #{inspect(pid)}: #{inspect(reason)}")
  end
  
  # Get children of a supervisor with a timeout to avoid hanging
  defp safe_get_children(supervisor_pid) do
    try do
      # Use Task.yield with a shorter timeout to avoid hangs
      task = Task.async(fn -> Supervisor.which_children(supervisor_pid) end)
      case Task.yield(task, 300) do
        {:ok, result} -> result
        nil -> 
          Task.shutdown(task)
          []
      end
    rescue
      e -> 
        IO.puts("  Error getting children for #{inspect(supervisor_pid)}: #{inspect(e)}")
        []
    catch
      kind, reason -> 
        IO.puts("  Error #{kind} getting children for #{inspect(supervisor_pid)}: #{inspect(reason)}")
        []
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