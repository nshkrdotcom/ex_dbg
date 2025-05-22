ExUnit.start()

# Set up ElixirScope.TraceDB for tests
alias ElixirScope.TraceDB

# Start the TraceDB if it's not already running
if Process.whereis(TraceDB) == nil do
  # Start with test_mode enabled
  {:ok, _pid} = TraceDB.start_link(test_mode: true)
  
  # Make sure ETS tables are created
  tables = [:elixir_scope_events, :elixir_scope_states, :elixir_scope_process_index]
  for table <- tables do
    if :ets.info(table) == :undefined do
      :ets.new(table, [:named_table, :public, :set])
    end
  end
  
  # Clear all existing data
  TraceDB.clear()
  
  IO.puts("TraceDB initialized for tests")
end 