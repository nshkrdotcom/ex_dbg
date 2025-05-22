defmodule ElixirScope.TraceDBDiagnostic do
  @moduledoc """
  Helper module for diagnosing TraceDB issues during tests.
  
  This provides direct inspection of the ETS tables to help debug 
  issues with event storage and retrieval.
  """
  
  @events_table :elixir_scope_events
  @states_table :elixir_scope_states
  @process_index :elixir_scope_process_index
  
  @doc """
  Prints a summary of all data stored in the TraceDB tables.
  """
  def print_all_data do
    IO.puts("\n==== TraceDB Data Summary ====")
    
    # Check if tables exist
    if tables_exist?() do
      events_count = :ets.info(@events_table, :size)
      states_count = :ets.info(@states_table, :size)
      process_index_count = :ets.info(@process_index, :size)
      
      IO.puts("Events table has #{events_count} records")
      IO.puts("States table has #{states_count} records")
      IO.puts("Process index has #{process_index_count} records")
      
      IO.puts("\n== All Events ==")
      :ets.tab2list(@events_table)
      |> Enum.map(fn {_, event} -> event end)
      |> Enum.each(fn event -> 
        IO.puts("ID: #{event.id}, Type: #{event.type}, PID: #{inspect(event.pid)}, TS: #{event.timestamp}")
      end)
      
      IO.puts("\n== All States ==")
      :ets.tab2list(@states_table)
      |> Enum.map(fn {_, event} -> event end)
      |> Enum.each(fn event -> 
        callback = Map.get(event, :callback, "unknown")
        IO.puts("ID: #{event.id}, Type: #{event.type}, PID: #{inspect(event.pid)}, Callback: #{callback}, TS: #{event.timestamp}")
      end)
    else
      IO.puts("ETS tables do not exist yet. Is TraceDB started?")
    end
    
    IO.puts("================================\n")
  end
  
  @doc """
  Prints details of events for a specific process.
  """
  def print_process_events(pid) do
    IO.puts("\n==== Process Events for #{inspect(pid)} ====")
    
    if tables_exist?() do
      # Get all events for the process from the index
      process_events = :ets.lookup(@process_index, pid)
      IO.puts("Found #{length(process_events)} index entries for process")
      
      # Get state events
      state_events = process_events
      |> Enum.filter(fn {_, {type, _}} -> type == :state end)
      |> Enum.map(fn {_, {_, id}} -> 
        case :ets.lookup(@states_table, id) do
          [{^id, event}] -> event
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      
      IO.puts("\n== State Events (#{length(state_events)}) ==")
      Enum.each(state_events, fn event -> 
        callback = Map.get(event, :callback, "unknown")
        data = Map.get(event, :data, %{})
        IO.puts("ID: #{event.id}, Type: #{event.type}, Callback: #{callback}, Data: #{inspect(data)}")
      end)
      
      # Get other events
      other_events = process_events
      |> Enum.filter(fn {_, {type, _}} -> type != :state end)
      |> Enum.map(fn {_, {_, id}} -> 
        case :ets.lookup(@events_table, id) do
          [{^id, event}] -> event
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      
      IO.puts("\n== Other Events (#{length(other_events)}) ==")
      Enum.each(other_events, fn event -> 
        IO.puts("ID: #{event.id}, Type: #{event.type}, Callback: #{Map.get(event, :callback, "unknown")}")
      end)
    else
      IO.puts("ETS tables do not exist yet. Is TraceDB started?")
    end
    
    IO.puts("================================\n")
  end
  
  @doc """
  Check if all needed ETS tables exist.
  """
  def tables_exist? do
    :ets.info(@events_table) != :undefined && 
    :ets.info(@states_table) != :undefined && 
    :ets.info(@process_index) != :undefined
  end
end 