defmodule ElixirScope.QueryEngine do
  @moduledoc """
  Provides high-level queries for trace data.
  
  This module provides convenient functions to query trace data,
  built on top of the TraceDB storage layer. It specializes in
  time-travel debugging capabilities, allowing users to inspect
  the system state at any point in time.
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
  Gets all process exits.
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
      _ ->
        %{error: "Could not compare states"}
    end
  end
  
  @doc """
  Gets the state of a process at any point in time.
  
  This enhanced version provides better reconstruction of state by taking
  into account all available state snapshots and transformations.
  
  ## Parameters
  
  * `pid` - The process ID
  * `timestamp` - The point in time to get the state for
  """
  def get_state_at(pid, timestamp) do
    case TraceDB.get_state_at(pid, timestamp) do
      nil -> 
        {:error, :not_found}
      event when is_map(event) -> 
        if Map.has_key?(event, :state) do
          {:ok, event.state}
        else
          {:error, :invalid_state_format}
        end
      {:ok, state} -> 
        {:ok, state}
      {:error, _} = error -> 
        error
    end
  end
  
  @doc """
  Reconstructs an "execution snapshot" of the system at a specific point in time.
  
  This function provides a comprehensive view of the system state at any given moment,
  including:
  - Active processes and their states
  - Pending messages in process mailboxes
  - Links between processes
  - Current supervisors and their children
  
  ## Parameters
  
  * `timestamp` - The point in time for the snapshot
  
  ## Returns
  
  A map containing:
  * `:active_processes` - List of active process PIDs
  * `:process_states` - Map of PID to process state (if available)
  * `:pending_messages` - Map of PID to list of pending messages (if available)
  * `:supervision_tree` - Supervision hierarchy at the time (if available)
  """
  def system_snapshot_at(timestamp) do
    # Get all processes active at this timestamp
    active_pids = active_processes_at(timestamp)
    
    # For each active process, get its state at the timestamp
    process_states = Enum.reduce(active_pids, %{}, fn pid, acc ->
      case get_state_at(pid, timestamp) do
        {:ok, state} -> Map.put(acc, pid, state)
        _ -> acc
      end
    end)
    
    # Find all pending messages (sent but not yet received) at timestamp
    pending_messages = get_pending_messages_at(timestamp)
    
    # Attempt to reconstruct the supervision tree at the timestamp
    supervision_tree = reconstruct_supervision_tree_at(timestamp)
    
    %{
      timestamp: timestamp,
      active_processes: active_pids,
      process_states: process_states,
      pending_messages: pending_messages,
      supervision_tree: supervision_tree
    }
  end
  
  @doc """
  Retrieves a complete execution timeline between two points in time.
  
  This function provides a comprehensive sequence of all events between
  two timestamps, useful for "stepping through" execution history.
  
  ## Parameters
  
  * `start_time` - The start of the time window
  * `end_time` - The end of the time window
  * `filter_types` - Optional list of event types to include (nil includes all)
  
  ## Returns
  
  An ordered list of events with additional context information.
  """
  def execution_timeline(start_time, end_time, filter_types \\ nil) do
    # Get all events in the time window
    all_events = TraceDB.query_events(%{
      timestamp_start: start_time,
      timestamp_end: end_time
    })
    
    # Filter by type if requested
    filtered_events = 
      case filter_types do
        nil -> all_events
        types when is_list(types) -> Enum.filter(all_events, &(&1.type in types))
      end
    
    # Sort by timestamp
    Enum.sort_by(filtered_events, & &1.timestamp)
  end
  
  @doc """
  Gets the state evolution for a process across a time window.
  
  This enhanced version provides a complete view of state changes over time,
  with additional contextual information about what caused each change.
  
  ## Parameters
  
  * `pid` - The process ID
  * `start_time` - Start of the time window
  * `end_time` - End of the time window
  """
  def state_evolution(pid, start_time, end_time) do
    # Get all state changes for the process in the time window
    state_events = TraceDB.query_events(%{
      type: :state,
      pid: pid,
      timestamp_start: start_time,
      timestamp_end: end_time
    })
    
    # Get message events that may have triggered state changes
    message_events = TraceDB.query_events(%{
      type: :message,
      to_pid: pid,
      timestamp_start: start_time,
      timestamp_end: end_time
    })
    
    # Get function call events
    function_events = TraceDB.query_events(%{
      type: :function,
      pid: pid,
      timestamp_start: start_time,
      timestamp_end: end_time
    })
    
    # Combine all events and sort by timestamp
    all_events = state_events ++ message_events ++ function_events
    |> Enum.sort_by(& &1.timestamp)
    
    # Group state changes with their potential causes
    state_changes_with_context = 
      Enum.reduce(state_events, [], fn state_event, acc ->
        # Find potential causes - events right before this state change
        causes = all_events
        |> Enum.filter(fn event -> 
          event.id != state_event.id && 
          event.timestamp <= state_event.timestamp && 
          event.timestamp >= state_event.timestamp - 100_000_000 # 100ms window
        end)
        |> Enum.sort_by(& &1.timestamp, :desc)
        |> Enum.take(5)  # Take the 5 most recent events as potential causes
        
        # Find the previous state (for diffing)
        prev_state = 
          case acc do
            [] -> 
              # No previous state in our window, try to find one before the window
              case get_state_at(pid, start_time - 1) do
                {:ok, state} -> state
                _ -> nil
              end
            [%{state: prev_state} | _] -> prev_state
          end
        
        # Calculate diff if we have a previous state
        diff = 
          if prev_state do
            compare_states(prev_state, state_event.state)
          else
            nil
          end
        
        # Add this state change with its context
        [%{
          timestamp: state_event.timestamp,
          state: state_event.state,
          previous_state: prev_state,
          diff: diff,
          potential_causes: causes
        } | acc]
      end)
      |> Enum.reverse()
    
    state_changes_with_context
  end
  
  # Helper functions
  
  # Find an event by its ID
  defp find_event_by_id(id) do
    case :ets.lookup(:elixir_scope_events, id) do
      [{^id, event}] -> event
      [] -> 
        case :ets.lookup(:elixir_scope_states, id) do
          [{^id, event}] -> event
          [] -> nil
        end
    end
  end
  
  # Gets pending messages at a specific timestamp (sent but not received)
  defp get_pending_messages_at(timestamp) do
    # Get all message send events before or at the timestamp
    sent_events = TraceDB.query_events(%{
      type: :message, 
      timestamp_end: timestamp
    })
    |> Enum.filter(fn event -> event.type == :send end)
    
    # Get all message receive events before or at the timestamp
    received_events = TraceDB.query_events(%{
      type: :message,
      timestamp_end: timestamp
    })
    |> Enum.filter(fn event -> event.type == :receive end)
    
    # Group sent messages by recipient
    sent_by_recipient = Enum.group_by(sent_events, & &1.to_pid)
    
    # Group received messages by recipient
    received_by_recipient = Enum.group_by(received_events, & &1.pid)
    
    # For each recipient, find messages that were sent but not yet received
    Enum.reduce(sent_by_recipient, %{}, fn {pid, sent}, acc ->
      received = Map.get(received_by_recipient, pid, [])
      
      # Find messages that were sent but not in the received list
      # This is an approximation since we can't perfectly match messages
      pending = Enum.filter(sent, fn sent_event ->
        not Enum.any?(received, fn receive_event ->
          # Consider a message received if the content matches and it was received after being sent
          receive_event.message == sent_event.message &&
          receive_event.timestamp > sent_event.timestamp
        end)
      end)
      
      if pending != [] do
        Map.put(acc, pid, pending)
      else
        acc
      end
    end)
  end
  
  # Attempt to reconstruct the supervision tree at a specific point in time
  defp reconstruct_supervision_tree_at(timestamp) do
    # This is a simplified approach - a real implementation would likely need
    # special trace events for supervisor operations
    
    # Find all processes that were spawned before the timestamp
    spawn_events = TraceDB.query_events(%{
      type: :process,
      timestamp_end: timestamp
    })
    |> Enum.filter(fn event -> Map.get(event, :event) == :spawn end)
    
    # Find all processes that exited before the timestamp
    exit_events = TraceDB.query_events(%{
      type: :process,
      timestamp_end: timestamp
    })
    |> Enum.filter(fn event -> Map.get(event, :event) == :exit end)
    
    # Get PIDs of processes that were alive at the timestamp
    alive_pids = 
      spawn_events
      |> Enum.map(& &1.pid)
      |> Enum.reject(fn pid ->
        Enum.any?(exit_events, & &1.pid == pid)
      end)
    
    # Try to infer supervisor relationships from available data
    # This is a simplified approach and might not be fully accurate
    
    # Return the reconstructed tree as a map
    %{
      timestamp: timestamp,
      active_processes: alive_pids,
      # Note: The actual tree structure would need to be inferred from traced supervisor events
      # This is a placeholder for a more complete implementation
      tree_structure: "Supervisor tree reconstruction would require additional tracing data"
    }
  end
end 