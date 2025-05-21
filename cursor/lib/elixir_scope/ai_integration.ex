defmodule ElixirScope.AIIntegration do
  @moduledoc """
  Provides integration with AI systems for natural language debugging.
  
  This module enables:
  - Natural language queries for debugging data
  - AI-assisted analysis of system behavior
  - Exporting trace data in AI-consumable formats
  """
  
  alias ElixirScope.{TraceDB, QueryEngine}
  
  @doc """
  Sets up AI integration.
  
  Attempts to register tools with Tidewave if it's available.
  """
  def setup do
    if Code.ensure_loaded?(Tidewave) do
      # Register our tools with Tidewave's Model Context Protocol
      Tidewave.register_tool("elixir_scope", &handle_command/1)
      :ok
    else
      {:error, :tidewave_not_available}
    end
  end
  
  @doc """
  Handles commands from the AI system.
  
  This is the entry point for AI tools to interact with ElixirScope.
  """
  def handle_command(%{"action" => action} = args) do
    case action do
      "start_tracing" ->
        start_tracing(args)
      
      "query_execution" ->
        query_execution(args)
      
      "analyze_state" ->
        analyze_state(args)
      
      "explain_behavior" ->
        explain_behavior(args)
        
      "trace_module" ->
        trace_module(args)
        
      "trace_process" ->
        trace_process(args)
        
      _ ->
        %{status: :error, message: "Unknown action: #{action}"}
    end
  end
  
  # Command handlers
  
  defp start_tracing(%{"modules" => modules}) when is_list(modules) do
    results = Enum.map(modules, fn module_name ->
      mod = String.to_existing_atom("Elixir.#{module_name}")
      ElixirScope.trace_module(mod)
    end)
    
    %{
      status: :ok, 
      message: "Started tracing for #{length(modules)} modules",
      modules: modules
    }
  rescue
    e -> %{status: :error, message: "Error starting tracing: #{inspect(e)}"}
  end
  
  defp start_tracing(_) do
    %{status: :error, message: "Missing or invalid 'modules' parameter"}
  end
  
  defp query_execution(%{"query" => query} = args) do
    # Analyze the natural language query to determine what to retrieve
    try do
      cond do
        String.contains?(query, ["message", "flow", "between"]) ->
          # Extract process names/identifiers from the query
          # For simplicity, we'll assume the processes are registered with names
          process_names = extract_process_names(query)
          
          case process_names do
            [from_name, to_name] ->
              from_pid = process_name_to_pid(from_name)
              to_pid = process_name_to_pid(to_name)
              
              if from_pid && to_pid do
                messages = QueryEngine.message_flow(from_pid, to_pid)
                %{
                  status: :ok,
                  result_type: :message_flow,
                  from: from_name,
                  to: to_name,
                  messages: format_messages(messages)
                }
              else
                %{status: :error, message: "Could not find the specified processes"}
              end
              
            _ ->
              %{status: :error, message: "Could not identify two processes in the query"}
          end
          
        String.contains?(query, ["state", "changes", "history"]) ->
          # Extract process name from the query
          process_names = extract_process_names(query)
          
          case process_names do
            [name | _] ->
              pid = process_name_to_pid(name)
              
              if pid do
                states = QueryEngine.state_timeline(pid)
                %{
                  status: :ok,
                  result_type: :state_timeline,
                  process: name,
                  states: format_states(states)
                }
              else
                %{status: :error, message: "Could not find the specified process"}
              end
              
            _ ->
              %{status: :error, message: "Could not identify a process in the query"}
          end
          
        String.contains?(query, ["function", "calls", "execution"]) ->
          # Extract module/function from the query
          module_name = extract_module_name(query)
          
          if module_name do
            module = String.to_existing_atom("Elixir.#{module_name}")
            calls = QueryEngine.module_function_calls(module)
            %{
              status: :ok,
              result_type: :function_calls,
              module: module_name,
              calls: format_function_calls(calls)
            }
          else
            %{status: :error, message: "Could not identify a module in the query"}
          end
          
        true ->
          # Default case - return general info
          %{
            status: :ok,
            result_type: :general_info,
            message: "Your query needs to be more specific about what information you need.",
            examples: [
              "Show message flow between ProcessA and ProcessB",
              "Show state changes for ProcessA",
              "Show function calls for ModuleA"
            ]
          }
      end
    rescue
      e -> %{status: :error, message: "Error processing query: #{inspect(e)}"}
    end
  end
  
  defp query_execution(_) do
    %{status: :error, message: "Missing 'query' parameter"}
  end
  
  defp analyze_state(%{"pid" => pid_string} = args) do
    try do
      pid = decode_pid(pid_string)
      
      history = QueryEngine.state_timeline(pid)
      
      # Calculate differences between consecutive states
      state_diffs = history
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [state1, state2] -> 
          %{
            from_id: state1.id,
            to_id: state2.id,
            from_timestamp: state1.timestamp,
            to_timestamp: state2.timestamp,
            diff: QueryEngine.compare_states(state1.state, state2.state)
          }
        end)
      
      %{
        status: :ok,
        process: pid_to_string(pid),
        state_history: format_states(history),
        state_diffs: state_diffs
      }
    rescue
      e -> %{status: :error, message: "Error analyzing state: #{inspect(e)}"}
    end
  end
  
  defp analyze_state(_) do
    %{status: :error, message: "Missing 'pid' parameter"}
  end
  
  defp explain_behavior(%{"question" => question} = args) do
    # This would typically be handled by the AI system itself,
    # as it requires complex natural language understanding and reasoning
    %{
      status: :ok,
      message: "The AI system will analyze the trace data to answer your question.",
      context: %{
        timestamp: System.os_time(:second),
        event_count: count_events(),
        modules_traced: ElixirScope.CodeTracer.list_traced_modules()
      }
    }
  end
  
  defp explain_behavior(_) do
    %{status: :error, message: "Missing 'question' parameter"}
  end
  
  defp trace_module(%{"module" => module_name}) do
    try do
      mod = String.to_existing_atom("Elixir.#{module_name}")
      ElixirScope.trace_module(mod)
      
      %{
        status: :ok,
        message: "Now tracing module #{module_name}"
      }
    rescue
      e -> %{status: :error, message: "Error tracing module: #{inspect(e)}"}
    end
  end
  
  defp trace_module(_) do
    %{status: :error, message: "Missing 'module' parameter"}
  end
  
  defp trace_process(%{"pid" => pid_string}) do
    try do
      pid = decode_pid(pid_string)
      ElixirScope.trace_genserver(pid)
      
      %{
        status: :ok,
        message: "Now tracing process #{pid_to_string(pid)}"
      }
    rescue
      e -> %{status: :error, message: "Error tracing process: #{inspect(e)}"}
    end
  end
  
  defp trace_process(%{"name" => name}) do
    try do
      pid = process_name_to_pid(name)
      
      if pid do
        ElixirScope.trace_genserver(pid)
        
        %{
          status: :ok,
          message: "Now tracing process #{name} (#{pid_to_string(pid)})"
        }
      else
        %{status: :error, message: "Could not find process named #{name}"}
      end
    rescue
      e -> %{status: :error, message: "Error tracing process: #{inspect(e)}"}
    end
  end
  
  defp trace_process(_) do
    %{status: :error, message: "Missing 'pid' or 'name' parameter"}
  end
  
  # Helper functions
  
  defp extract_process_names(query) do
    # A very simplistic extraction - in a real system, this would use NLP
    # or be handled by the AI system itself
    ~r/\b([A-Z][A-Za-z0-9]*(?:\.[A-Z][A-Za-z0-9]*)*)\b/
    |> Regex.scan(query)
    |> List.flatten()
    |> Enum.uniq()
  end
  
  defp extract_module_name(query) do
    # Extract module name pattern (e.g., "MyApp.SomeModule")
    case Regex.run(~r/\b([A-Z][A-Za-z0-9]*(?:\.[A-Z][A-Za-z0-9]*)*)\b/, query) do
      [_, module_name] -> module_name
      _ -> nil
    end
  end
  
  defp process_name_to_pid(name) do
    try do
      # Try as a registered name atom
      name_atom = String.to_existing_atom(name)
      pid = Process.whereis(name_atom)
      
      # If not found, try as a module name (for named GenServers)
      if is_nil(pid) do
        module = String.to_existing_atom("Elixir.#{name}")
        Process.whereis(module)
      else
        pid
      end
    rescue
      _ -> nil
    end
  end
  
  defp decode_pid(pid_string) do
    try do
      # Handle various PID string formats
      cond do
        String.starts_with?(pid_string, "#PID<") ->
          pid_string
          |> String.replace("#PID<", "")
          |> String.replace(">", "")
          |> :erlang.list_to_pid
          
        String.starts_with?(pid_string, "<") ->
          pid_string
          |> String.replace("<", "")
          |> String.replace(">", "")
          |> :erlang.list_to_pid
          
        true ->
          :erlang.list_to_pid(String.to_charlist(pid_string))
      end
    rescue
      _ -> nil
    end
  end
  
  defp pid_to_string(pid) do
    inspect(pid)
  end
  
  defp format_messages(messages) do
    Enum.map(messages, fn message ->
      %{
        id: message.id,
        from: pid_to_string(message.from_pid),
        to: pid_to_string(message.to_pid),
        message: message.message,
        timestamp: message.timestamp
      }
    end)
  end
  
  defp format_states(states) do
    Enum.map(states, fn state ->
      %{
        id: state.id,
        process: pid_to_string(state.pid),
        state: state.state,
        timestamp: state.timestamp
      }
    end)
  end
  
  defp format_function_calls(calls) do
    Enum.map(calls, fn call ->
      %{
        id: call.id,
        process: pid_to_string(call.pid),
        module: call.module,
        function: call.function,
        args: call.args,
        timestamp: call.timestamp
      }
    end)
  end
  
  defp count_events do
    # Count total number of events
    events_count = :ets.info(:elixir_scope_events, :size) || 0
    states_count = :ets.info(:elixir_scope_states, :size) || 0
    events_count + states_count
  end
end 