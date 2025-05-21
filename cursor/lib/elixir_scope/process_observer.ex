defmodule ElixirScope.ProcessObserver do
  @moduledoc """
  Monitors process lifecycles and supervision tree relationships.
  
  This module is responsible for tracking:
  - Process spawning and termination
  - Supervision tree structure
  - Process state (memory usage, message queue length)
  """
  use GenServer
  
  alias ElixirScope.TraceDB
  
  @doc """
  Starts the ProcessObserver.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Initializes the ProcessObserver.
  """
  def init(_opts) do
    # Set up system monitoring
    :erlang.system_monitor(self(), [
      :busy_port,
      :busy_dist_port,
      {:long_gc, 100},
      {:long_schedule, 100}
    ])
    
    # Subscribe to process events
    Process.flag(:trap_exit, true)
    
    # Schedule periodic supervision tree updates
    schedule_supervision_tree_update()
    
    {:ok, %{
      processes: %{},
      supervision_tree: build_supervision_tree()
    }}
  end
  
  @doc """
  Gets the current supervision tree.
  """
  def get_supervision_tree do
    GenServer.call(__MODULE__, :get_supervision_tree)
  end
  
  @doc """
  Gets information about a specific process.
  """
  def get_process_info(pid) do
    GenServer.call(__MODULE__, {:get_process_info, pid})
  end
  
  # GenServer callbacks
  
  def handle_call(:get_supervision_tree, _from, state) do
    {:reply, state.supervision_tree, state}
  end
  
  def handle_call({:get_process_info, pid}, _from, state) do
    process_info = Map.get(state.processes, pid, %{})
    {:reply, process_info, state}
  end
  
  def handle_info({:monitor, pid, event, info}, state) do
    # Record process monitoring events
    TraceDB.store_event(:process, %{
      pid: pid,
      event: event,
      info: info,
      timestamp: System.monotonic_time()
    })
    
    # Update process info in state
    updated_processes = Map.update(
      state.processes,
      pid,
      %{events: [{event, info}]},
      fn process -> Map.update(process, :events, [{event, info}], &[{event, info} | &1]) end
    )
    
    {:noreply, %{state | processes: updated_processes}}
  end
  
  def handle_info({:EXIT, pid, reason}, state) do
    # Record process exit events
    TraceDB.store_event(:process, %{
      pid: pid,
      event: :exit,
      info: reason,
      timestamp: System.monotonic_time()
    })
    
    # Update process info in state
    updated_processes = Map.update(
      state.processes,
      pid,
      %{events: [{:exit, reason}]},
      fn process -> Map.update(process, :events, [{:exit, reason}], &[{:exit, reason} | &1]) end
    )
    
    {:noreply, %{state | processes: updated_processes}}
  end
  
  def handle_info(:update_supervision_tree, state) do
    # Update the supervision tree periodically
    updated_tree = build_supervision_tree()
    
    # Schedule the next update
    schedule_supervision_tree_update()
    
    {:noreply, %{state | supervision_tree: updated_tree}}
  end
  
  # Private functions
  
  defp schedule_supervision_tree_update do
    # Update supervision tree every 5 seconds
    Process.send_after(self(), :update_supervision_tree, 5000)
  end
  
  defp build_supervision_tree do
    # Find all supervisors in the system
    supervisors = 
      Process.list()
      |> Enum.filter(fn pid ->
        case Process.info(pid, :dictionary) do
          {:dictionary, dict} -> 
            dict[:$initial_call] == {:supervisor, :Supervisor, :init} ||
            dict["$initial_call"] == {:supervisor, :Supervisor, :init}
          _ -> false
        end
      end)
    
    # Build tree for each top-level supervisor
    Enum.reduce(supervisors, %{}, fn pid, acc ->
      if is_top_level_supervisor?(pid) do
        Map.put(acc, pid, build_supervisor_subtree(pid))
      else
        acc
      end
    end)
  end
  
  defp is_top_level_supervisor?(pid) do
    case Process.info(pid, :links) do
      {:links, links} ->
        # Check if any of the linked processes is a supervisor
        links
        |> Enum.all?(fn linked_pid ->
          case Process.info(linked_pid, :dictionary) do
            {:dictionary, dict} -> 
              dict[:$initial_call] != {:supervisor, :Supervisor, :init} &&
              dict["$initial_call"] != {:supervisor, :Supervisor, :init}
            _ -> true
          end
        end)
      _ -> false
    end
  end
  
  defp build_supervisor_subtree(supervisor_pid) do
    # Get children using :supervisor.which_children
    try do
      children = :supervisor.which_children(supervisor_pid)
      
      children_map = Enum.map(children, fn
        {id, pid, type, modules} when is_pid(pid) ->
          child_info = %{
            id: id,
            type: type,
            modules: modules
          }
          
          # If the child is a supervisor, recursively build its subtree
          child_info = if type == :supervisor do
            Map.put(child_info, :children, build_supervisor_subtree(pid))
          else
            child_info
          end
          
          {pid, child_info}
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)
      |> Map.new()
      
      # Get supervisor information
      case Process.info(supervisor_pid, [:registered_name, :dictionary]) do
        [{:registered_name, name}, {:dictionary, dict}] ->
          %{
            name: name,
            strategy: dict[:"$supervisor_opts"][:strategy],
            children: children_map
          }
        [{:dictionary, dict}] ->
          %{
            name: nil,
            strategy: dict[:"$supervisor_opts"][:strategy],
            children: children_map
          }
        _ ->
          %{
            name: nil,
            strategy: nil,
            children: children_map
          }
      end
    rescue
      _ -> %{error: "Failed to inspect supervisor"}
    end
  end
end 