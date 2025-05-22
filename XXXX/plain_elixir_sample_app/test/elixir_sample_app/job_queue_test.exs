defmodule ElixirSampleApp.JobQueueTest do
  use ExUnit.Case, async: false
  
  alias ElixirSampleApp.JobQueue
  alias ElixirScope.TraceDB
  
  setup do
    # Make sure JobQueue is running
    # This will also restart it if it was already running
    {:ok, _pid} = JobQueue.start_link([])
    
    # Clear TraceDB before each test
    TraceDB.clear()
    
    :ok
  end
  
  test "adding a job updates the state" do
    # Initial state
    initial_stats = JobQueue.stats()
    assert initial_stats.pending_jobs == 0
    
    # Add a job
    job = %{id: "test-job-1", type: :test, data: "test data"}
    JobQueue.add_job(job)
    
    # Wait a moment for the state to update
    :timer.sleep(100)
    
    # Check updated state
    updated_stats = JobQueue.stats()
    assert updated_stats.pending_jobs == 1
    
    # Query ElixirScope for state changes
    events = TraceDB.query_events(%{
      type: :state
    })
    
    # Verify ElixirScope captured state changes
    assert length(events) >= 1
    
    # The state should contain our job
    assert Enum.any?(events, fn event ->
      event.type == :state && 
      is_map(event.state) && 
      is_list(event.state[:pending_jobs]) && 
      Enum.any?(event.state[:pending_jobs], fn pending_job -> 
        pending_job[:id] == "test-job-1"
      end)
    end)
  end
  
  test "adding multiple jobs updates the state" do
    # Initial state
    initial_stats = JobQueue.stats()
    assert initial_stats.pending_jobs == 0
    
    # Add multiple jobs
    jobs = [
      %{id: "test-job-1", type: :test, data: "test data 1"},
      %{id: "test-job-2", type: :test, data: "test data 2"}
    ]
    JobQueue.add_jobs(jobs)
    
    # Wait a moment for the state to update
    :timer.sleep(100)
    
    # Check updated state
    updated_stats = JobQueue.stats()
    assert updated_stats.pending_jobs == 2
    
    # Query ElixirScope for state changes
    events = TraceDB.query_events(%{
      type: :state
    })
    
    # Verify ElixirScope captured state changes
    assert length(events) >= 1
    
    # The state should contain our jobs
    latest_state_event = Enum.find(events, fn event -> 
      event.type == :state && 
      is_map(event.state) && 
      is_list(event.state[:pending_jobs]) && 
      length(event.state[:pending_jobs]) == 2
    end)
    
    assert latest_state_event != nil
  end
  
  test "stats returns the correct values" do
    # Get initial stats
    stats = JobQueue.stats()
    
    # Stats should include expected keys
    assert is_map(stats)
    assert Map.has_key?(stats, :pending_jobs)
    assert Map.has_key?(stats, :processed_jobs)
    assert Map.has_key?(stats, :failed_jobs)
    assert Map.has_key?(stats, :uptime_seconds)
    
    # Add a job to see stats change
    job = %{id: "test-job-1", type: :test, data: "test data"}
    JobQueue.add_job(job)
    
    # Wait a moment for the state to update
    :timer.sleep(100)
    
    # Check updated stats
    updated_stats = JobQueue.stats()
    assert updated_stats.pending_jobs > stats.pending_jobs
  end
end 