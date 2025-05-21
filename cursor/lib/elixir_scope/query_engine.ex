defmodule ElixirScope.QueryEngine do
  @moduledoc """
  Provides high-level queries for trace data.
  
  This module provides convenient functions to query trace data,
  built on top of the TraceDB storage layer.
  """
  
  alias ElixirScope.TraceDB
  
  @doc """
  Gets the message flow between two processes.
  
  ## Example
  
      pid1 = Process.whereis(MyApp.WorkerA)
      pid2 = Process.whereis(MyApp.WorkerB)
      ElixirScope.QueryEngine.message_flow(pid1, pid2)
  """
  def message_flow(from_pid, to_pid) do
    TraceDB.query_events(%{
      type: :message,
      from_pid: from_pid,
      to_pid: to_pid
    })
  end
  
  @doc """
  Gets all messages sent from a process.
  """
  def messages_from(pid) do
    TraceDB.query_events(%{
      type: :message,
      from_pid: pid
    })
  end
  
  @doc """
  Gets all messages received by a process.
  """
  def messages_to(pid) do
    TraceDB.query_events(%{
      type: :message,
      to_pid: pid
    })
  end
  
  @doc """
  Gets a timeline of state changes for a process.
  """
  def state_timeline(pid) do
    TraceDB.get_state_history(pid)
  end
  
  @doc """
  Gets the execution path of a process.
  
  Returns all function calls and returns for the specified process.
  """
  def execution_path(pid) do
    TraceDB.query_events(%{
      type: :function,
      pid: pid
    })
  end
  
  @doc """
  Gets all events for a process.
  """
  def process_events(pid) do
    TraceDB.query_events(%{
      pid: pid
    })
  end
  
  @doc """
  Gets all state changes in a specific time window.
  
  ## Parameters
  
  * `start_time` - Start of the time window in monotonic time
  * `end_time` - End of the time window in monotonic time
  """
  def state_changes_in_window(start_time, end_time) do
    TraceDB.query_events(%{
      type: :state,
      timestamp_start: start_time,
      timestamp_end: end_time
    })
  end
  
  @doc """
  Gets all function calls for a specific module.
  """
  def module_function_calls(module) do
    # We need to filter post-query since module is part of the event data
    TraceDB.query_events(%{type: :function})
    |> Enum.filter(fn event -> 
      event.module == module && event.type == :function_call
    end)
  end
  
  @doc """
  Gets all function calls for a specific function in a module.
  """
  def function_calls(module, function) do
    # We need to filter post-query since module and function are part of the event data
    TraceDB.query_events(%{type: :function})
    |> Enum.filter(fn event -> 
      event.module == module && 
      event.function == function &&
      event.type == :function_call
    end)
  end
  
  @doc """
  Gets all events related to a specific GenServer operation.
  """
  def genserver_events(pid, operation \\ nil) do
    events = TraceDB.query_events(%{
      type: :genserver,
      pid: pid
    })
    
    case operation do
      nil -> events
      op -> Enum.filter(events, fn event -> event.callback == op end)
    end
  end
  
  @doc """
  Gets all events that occurred around a specific event.
  
  ## Parameters
  
  * `event_id` - The ID of the event to center the window around
  * `window_ms` - Size of the time window in milliseconds
  """
  def events_around_event(event_id, window_ms \\ 100) do
    # First find the specified event
    event = find_event_by_id(event_id)
    
    case event do
      nil -> []
      event -> TraceDB.get_events_at(event.timestamp, window_ms)
    end
  end
  
  @doc """
  Gets all processes active at a specific time.
  """
  def active_processes_at(timestamp) do
    TraceDB.get_processes_at(timestamp)
  end
  
  @doc """
  Gets all process spawn events.
  """
  def process_spawns do
    TraceDB.query_events(%{type: :process})
    |> Enum.filter(fn event -> Map.get(event, :event) == :spawn end)
  end
  
  @doc """
  Gets all process exit events.
  """
  def process_exits do
    TraceDB.query_events(%{type: :process})
    |> Enum.filter(fn event -> Map.get(event, :event) == :exit end)
  end
  
  @doc """
  Compares two states and returns the differences.
  """
  def compare_states(state1, state2) do
    # This is a simple implementation - could be enhanced for nested structures
    try do
      s1 = if is_binary(state1), do: Code.eval_string(state1) |> elem(0), else: state1
      s2 = if is_binary(state2), do: Code.eval_string(state2) |> elem(0), else: state2
      
      if is_map(s1) and is_map(s2) do
        # For maps, show added, removed, and changed keys
        all_keys = Map.keys(s1) ++ Map.keys(s2) |> Enum.uniq()
        
        Enum.reduce(all_keys, %{added: [], removed: [], changed: []}, fn key, acc ->
          cond do
            not Map.has_key?(s1, key) -> 
              Map.update!(acc, :added, &[{key, s2[key]} | &1])
            not Map.has_key?(s2, key) -> 
              Map.update!(acc, :removed, &[{key, s1[key]} | &1])
            s1[key] != s2[key] -> 
              Map.update!(acc, :changed, &[{key, {s1[key], s2[key]}} | &1])
            true -> 
              acc
          end
        end)
      else
        # For non-maps, just return a simple comparison
        %{
          equal: s1 == s2,
          before: s1,
          after: s2
        }
      end
    rescue
      _ -> %{error: :invalid_state_format}
    end
  end
  
  @doc """
  Finds an event by its ID.
  """
  def find_event_by_id(event_id) do
    # Query for the event in both tables
    case :ets.lookup(:elixir_scope_events, event_id) do
      [{^event_id, event}] -> event
      [] ->
        case :ets.lookup(:elixir_scope_states, event_id) do
          [{^event_id, event}] -> event
          [] -> nil
        end
    end
  end
  
  @doc """
  Gets the call stack of a process at a specific point in time.
  
  This is an approximation based on function calls and returns.
  """
  def call_stack_at(pid, timestamp) do
    # Get all function calls and returns for the process up to the timestamp
    events = TraceDB.query_events(%{
      type: :function,
      pid: pid,
      timestamp_end: timestamp
    })
    
    # Build a call stack by tracking calls and returns
    events
    |> Enum.sort_by(& &1.timestamp)
    |> Enum.reduce([], fn event, stack ->
      case Map.get(event, :type) do
        :function_call ->
          # Push function onto stack
          [{event.module, event.function, event.args} | stack]
          
        :function_return ->
          # Pop function from stack on return
          case stack do
            [{m, f, _} | rest] when m == event.module and f == event.function ->
              rest
            _ ->
              # If the stack doesn't match, something's wrong - don't modify it
              stack
          end
            
        _ -> stack
      end
    end)
    |> Enum.reverse()  # reverse to get root at the top
  end
  
  @doc """
  Analyzes function call patterns, looking for repeated sequences.
  """
  def analyze_call_patterns(pid, min_pattern_length \\ 2, max_pattern_length \\ 10) do
    # Get all function calls for the process
    calls = TraceDB.query_events(%{
      type: :function,
      pid: pid
    })
    |> Enum.filter(fn event -> Map.get(event, :type) == :function_call end)
    |> Enum.map(fn event -> {event.module, event.function} end)
    
    # Find repeated patterns with lengths between min and max
    patterns = Enum.flat_map(min_pattern_length..max_pattern_length, fn length ->
      find_repeated_patterns(calls, length)
    end)
    
    # Group and count by pattern
    patterns
    |> Enum.group_by(& &1)
    |> Enum.map(fn {pattern, occurrences} ->
      {pattern, length(occurrences)}
    end)
    |> Enum.sort_by(fn {_, count} -> -count end)  # sort by count descending
  end
  
  # Helper to find repeated patterns in a list
  defp find_repeated_patterns(list, pattern_length) do
    if length(list) < pattern_length * 2 do
      []
    else
      0..(length(list) - pattern_length)
      |> Enum.map(fn i ->
        Enum.slice(list, i, pattern_length)
      end)
      |> Enum.filter(fn pattern ->
        # Count occurrences of the pattern
        count = count_pattern(list, pattern)
        count > 1
      end)
    end
  end
  
  # Count occurrences of a pattern in a list
  defp count_pattern(list, pattern) do
    pattern_length = length(pattern)
    
    0..(length(list) - pattern_length)
    |> Enum.count(fn i ->
      Enum.slice(list, i, pattern_length) == pattern
    end)
  end
end 