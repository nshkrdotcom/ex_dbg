defmodule ElixirScope.ProcessObserverTest do
  use ExUnit.Case, async: false
  
  alias ElixirScope.ProcessObserver
  
  setup do
    # Start TraceDB before ProcessObserver
    {:ok, tracedb_pid} = ElixirScope.TraceDB.start_link()
    {:ok, observer_pid} = ProcessObserver.start_link()
    
    on_exit(fn -> 
      Process.exit(observer_pid, :normal)
      Process.exit(tracedb_pid, :normal)
    end)
    
    %{observer_pid: observer_pid}
  end
  
  describe "supervision tree building" do
    test "can identify top-level supervisors" do
      # Create a test supervision tree
      {:ok, sup1} = Supervisor.start_link([], strategy: :one_for_one)
      
      # Wait for ProcessObserver to update the supervision tree
      :timer.sleep(100)
      
      # Get the supervision tree
      supervision_tree = ProcessObserver.get_supervision_tree()
      
      # Check that our supervisor is identified
      assert Map.has_key?(supervision_tree, sup1)
      
      # Clean up
      Supervisor.stop(sup1)
    end
    
    test "can build a simple supervision tree with a worker" do
      child_spec = %{
        id: SimpleWorker,
        start: {Task, :start_link, [fn -> Process.sleep(10_000) end]},
        restart: :temporary
      }
      
      {:ok, sup} = Supervisor.start_link([child_spec], strategy: :one_for_one)
      
      # Wait for ProcessObserver to update the supervision tree
      :timer.sleep(100)
      
      # Get the supervision tree
      supervision_tree = ProcessObserver.get_supervision_tree()
      
      # Check the supervisor structure
      assert sup_info = Map.get(supervision_tree, sup)
      assert sup_info.strategy == :one_for_one
      
      # Check that the supervisor has one child
      assert map_size(sup_info.children) == 1
      
      # Find the child pid
      [child_pid] = Supervisor.which_children(sup) |> Enum.map(fn {_, pid, _, _} -> pid end)
      
      # Check that the child is in the supervision tree
      assert Map.has_key?(sup_info.children, child_pid)
      assert Map.get(sup_info.children, child_pid).id == SimpleWorker
      
      # Clean up
      Supervisor.stop(sup)
    end
    
    test "can handle nested supervisors" do
      # Define a worker child spec
      worker_spec = %{
        id: NestedWorker,
        start: {Task, :start_link, [fn -> Process.sleep(10_000) end]},
        restart: :temporary
      }
      
      # Define a nested supervisor child spec
      nested_sup_spec = %{
        id: NestedSupervisor,
        start: {Supervisor, :start_link, [[worker_spec], [strategy: :one_for_one]]},
        type: :supervisor,
        restart: :permanent
      }
      
      # Start the top-level supervisor with the nested supervisor as a child
      {:ok, top_sup} = Supervisor.start_link([nested_sup_spec], strategy: :one_for_all)
      
      # Wait for ProcessObserver to update the supervision tree
      :timer.sleep(100)
      
      # Get the supervision tree
      supervision_tree = ProcessObserver.get_supervision_tree()
      
      # Get the top supervisor info
      assert top_sup_info = Map.get(supervision_tree, top_sup)
      assert top_sup_info.strategy == :one_for_all
      
      # Check that it has one child (the nested supervisor)
      assert map_size(top_sup_info.children) == 1
      
      # Find the nested supervisor pid
      [{_id, nested_sup_pid, :supervisor, _modules}] = Supervisor.which_children(top_sup)
      
      # Check that the nested supervisor is a child
      assert nested_sup_info = Map.get(top_sup_info.children, nested_sup_pid)
      assert nested_sup_info.type == :supervisor
      assert nested_sup_info.id == NestedSupervisor
      
      # Check that the nested supervisor has children information
      assert Map.has_key?(nested_sup_info, :children)
      
      # Clean up
      Supervisor.stop(top_sup)
    end
    
    test "can handle different supervisor strategies" do
      # Define a worker child spec
      worker_spec = %{
        id: TestWorker,
        start: {Task, :start_link, [fn -> Process.sleep(10_000) end]},
        restart: :temporary
      }
      
      # Start supervisors with different strategies
      {:ok, sup_one_for_one} = Supervisor.start_link([worker_spec], strategy: :one_for_one)
      {:ok, sup_one_for_all} = Supervisor.start_link([worker_spec], strategy: :one_for_all)
      {:ok, sup_rest_for_one} = Supervisor.start_link([worker_spec], strategy: :rest_for_one)
      
      # Wait for ProcessObserver to update the supervision tree
      :timer.sleep(200)
      
      # Get the supervision tree
      supervision_tree = ProcessObserver.get_supervision_tree()
      
      # Check that all supervisors have correct strategies
      assert Map.get(supervision_tree, sup_one_for_one).strategy == :one_for_one
      assert Map.get(supervision_tree, sup_one_for_all).strategy == :one_for_all
      assert Map.get(supervision_tree, sup_rest_for_one).strategy == :rest_for_one
      
      # Clean up
      Supervisor.stop(sup_one_for_one)
      Supervisor.stop(sup_one_for_all)
      Supervisor.stop(sup_rest_for_one)
    end
    
    test "can handle dynamic supervisor child changes" do
      # Start a dynamic supervisor
      {:ok, dynamic_sup} = DynamicSupervisor.start_link(strategy: :one_for_one)
      
      # Wait for ProcessObserver to update the supervision tree
      :timer.sleep(100)
      
      # Get the initial supervision tree
      initial_tree = ProcessObserver.get_supervision_tree()
      assert initial_info = Map.get(initial_tree, dynamic_sup)
      assert map_size(initial_info.children) == 0
      
      # Add a child dynamically
      child_spec = %{
        id: DynamicWorker,
        start: {Task, :start_link, [fn -> Process.sleep(10_000) end]},
        restart: :temporary
      }
      {:ok, child_pid} = DynamicSupervisor.start_child(dynamic_sup, child_spec)
      
      # Force an update of the supervision tree (instead of waiting 5 seconds)
      send(Process.whereis(ProcessObserver), :update_supervision_tree)
      :timer.sleep(50)
      
      # Get the updated supervision tree
      updated_tree = ProcessObserver.get_supervision_tree()
      assert updated_info = Map.get(updated_tree, dynamic_sup)
      
      # Check that the dynamic supervisor now has one child
      assert map_size(updated_info.children) == 1
      assert Map.has_key?(updated_info.children, child_pid)
      
      # Terminate the child
      DynamicSupervisor.terminate_child(dynamic_sup, child_pid)
      
      # Force another update
      send(Process.whereis(ProcessObserver), :update_supervision_tree)
      :timer.sleep(50)
      
      # Get the latest supervision tree
      latest_tree = ProcessObserver.get_supervision_tree()
      assert latest_info = Map.get(latest_tree, dynamic_sup)
      
      # Check that the dynamic supervisor has no children again
      assert map_size(latest_info.children) == 0
      
      # Clean up
      DynamicSupervisor.stop(dynamic_sup)
    end
    
    test "can handle supervisor restarts" do
      # Define a worker that will crash
      crash_spec = %{
        id: CrashWorker,
        start: {Task, :start_link, [fn -> 
          # Send a message and then crash
          send(self(), :worker_started)
          Process.sleep(200)
          raise "Deliberate crash for testing"
        end]},
        restart: :permanent  # This will be restarted
      }
      
      # Start a supervisor with a permanent worker that will crash
      {:ok, restart_sup} = Supervisor.start_link([crash_spec], strategy: :one_for_one)
      
      # Wait for the worker to start
      assert_receive :worker_started, 1000
      
      # Wait for ProcessObserver to update the supervision tree
      :timer.sleep(100)
      
      # Get the initial supervision tree
      initial_tree = ProcessObserver.get_supervision_tree()
      assert initial_info = Map.get(initial_tree, restart_sup)
      
      # Verify we have one child
      assert map_size(initial_info.children) == 1
      
      # Record the PID of the initial worker
      initial_pid = Supervisor.which_children(restart_sup) |> hd() |> elem(1)
      
      # Wait for the crash and restart
      :timer.sleep(500)
      
      # Get the updated supervision tree
      send(Process.whereis(ProcessObserver), :update_supervision_tree)
      :timer.sleep(50)
      updated_tree = ProcessObserver.get_supervision_tree()
      
      # The supervisor should still exist
      assert updated_info = Map.get(updated_tree, restart_sup)
      
      # Should still have one child
      assert map_size(updated_info.children) == 1
      
      # But it should be a different PID
      restarted_pid = Supervisor.which_children(restart_sup) |> hd() |> elem(1)
      assert initial_pid != restarted_pid
      
      # Clean up
      Supervisor.stop(restart_sup)
    end
  end
end 