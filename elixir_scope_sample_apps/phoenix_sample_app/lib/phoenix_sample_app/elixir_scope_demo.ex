defmodule PhoenixSampleApp.ElixirScopeDemo do
  @moduledoc """
  Demonstrates using ElixirScope to debug and introspect the application.
  
  This module provides examples of how to use the various features of ElixirScope
  to analyze application behavior, trace processes, and debug issues.
  """
  
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
    state_history = ElixirScope.state_timeline(counter_pid)
    
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
  
  @doc """
  Demonstrates how to trace module function calls.
  
  Example usage in IEx:
  
      iex> PhoenixSampleApp.ElixirScopeDemo.trace_counter_module()
      iex> PhoenixSampleApp.Counter.increment(10)
      iex> PhoenixSampleApp.Counter.get()
      iex> PhoenixSampleApp.ElixirScopeDemo.show_counter_function_calls()
  """
  def trace_counter_module do
    # Start tracing the Counter module
    ElixirScope.trace_module(PhoenixSampleApp.Counter)
    
    IO.puts("Now tracing PhoenixSampleApp.Counter module.")
    IO.puts("Execute some Counter functions, then call show_counter_function_calls/0 to see results.")
    
    :ok
  end
  
  @doc """
  Shows the function calls made to the Counter module after tracing.
  """
  def show_counter_function_calls do
    # Query function calls
    function_calls = ElixirScope.QueryEngine.module_function_calls(PhoenixSampleApp.Counter)
    
    IO.puts("Counter Function Calls:")
    IO.puts("---------------------")
    
    Enum.each(function_calls, fn call ->
      formatted_time = format_timestamp(call.timestamp)
      formatted_args = Enum.map_join(call.args, ", ", &inspect/1)
      
      IO.puts("#{formatted_time}: #{call.function}(#{formatted_args})")
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
    state_history = ElixirScope.state_timeline(counter_pid)
    
    if length(state_history) > 0 do
      # Pick a point in time (the timestamp of a state change)
      timestamp = state_history |> Enum.at(div(length(state_history), 2)) |> Map.get(:timestamp)
      
      IO.puts("Time-travel debugging to: #{format_timestamp(timestamp)}")
      IO.puts("------------------------------------------------")
      
      # Get the system snapshot at that time
      snapshot = ElixirScope.QueryEngine.system_snapshot_at(timestamp)
      
      IO.puts("Active processes at that time: #{length(snapshot.active_processes)}")
      
      # Show the counter state at that time
      counter_state = Map.get(snapshot.process_states, counter_pid)
      IO.puts("Counter state at that time: #{inspect(counter_state)}")
      
      # Show events around that time
      events_around = ElixirScope.TraceDB.get_events_at(timestamp, 1000) # 1 second window
      IO.puts("\nEvents around that time:")
      
      Enum.each(Enum.take(events_around, 5), fn event -> 
        formatted_time = format_timestamp(event.timestamp)
        IO.puts("#{formatted_time}: #{event.type} event")
      end)
    else
      IO.puts("No state history available. Try operating the counter first.")
    end
    
    :ok
  end
  
  @doc """
  Demonstrates the supervision tree visualization.
  """
  def show_supervision_tree do
    tree = ElixirScope.ProcessObserver.get_supervision_tree()
    
    IO.puts("Application Supervision Tree:")
    IO.puts("---------------------------")
    
    Enum.each(tree, fn {pid, sup_info} ->
      name = sup_info.name || inspect(pid)
      strategy = sup_info.strategy
      
      IO.puts("Supervisor: #{name} (Strategy: #{strategy})")
      Enum.each(sup_info.children, fn {child_pid, child_info} ->
        child_id = child_info.id || "anonymous"
        child_type = child_info.type
        
        IO.puts("  Child: #{child_id} (#{child_type}) - #{inspect(child_pid)}")
        
        if child_type == :supervisor and Map.has_key?(child_info, :children) do
          Enum.each(child_info.children, fn {grandchild_pid, grandchild_info} ->
            grandchild_id = grandchild_info.id || "anonymous"
            IO.puts("    Grandchild: #{grandchild_id} - #{inspect(grandchild_pid)}")
          end)
        end
      end)
    end)
    
    :ok
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