# ElixirScope - Refactoring and Enhancement Log

This document tracks all the refactoring and enhancements made to the ElixirScope library.

## Task 1: Refine ElixirScope.AIIntegration ✅

- Replaced single `Tidewave.register_tool` with multiple explicit `Tidewave.Plugin.register_tool` calls
- Created individual wrapper functions for each distinct functionality:
  - `tidewave_get_state_timeline`: Retrieves state history for a process
  - `tidewave_get_message_flow`: Retrieves message exchanges between processes
  - `tidewave_get_function_calls`: Retrieves function calls for a module
  - `tidewave_trace_module`: Starts tracing a specific module
  - `tidewave_trace_process`: Starts tracing a process by PID
  - `tidewave_trace_named_process`: Starts tracing a process by name
  - `tidewave_get_supervision_tree`: Retrieves the supervision tree
  - `tidewave_get_execution_path`: Retrieves process execution path
  - `tidewave_analyze_state_changes`: Analyzes state changes with diffs
- Added proper function documentation and argument validation
- Created `summarize_event_data` helper (replacing `간단하게_요약` with an Anglicized name)
- Improved error handling with descriptive error messages

## Task 2: Create Sample Applications

- Create sample Phoenix application demonstrating ElixirScope usage
- Create sample plain Elixir application demonstrating ElixirScope usage

## Task 3: Improve Performance Configuration ✅

- Added new configuration options to `ElixirScope.setup/1`:
  - `:tracing_level` - Added five levels to control detail (`:full`, `:messages_only`, `:states_only`, `:minimal`, `:off`)
  - `:sample_rate` - Added float value (0.0-1.0) to control event sampling percentage
- Updated `TraceDB` to respect the `:sample_rate` option:
  - Added the `should_record_event?/3` function to determine which events to keep
  - Modified the event storage to skip events based on sampling
  - Ensured critical events are always recorded regardless of sample rate
- Updated `MessageInterceptor` to respect the `:tracing_level` option:
  - Added conditional tracing activation based on tracing level
  - Added ability to change tracing level at runtime via `set_tracing_level/1`
  - Optimized message storage based on tracing level

## Task 4: Enhance Time-Travel Debugging ✅

- Improved `QueryEngine` to better support time-travel debugging:
  - Enhanced `get_state_at/2` function to more reliably reconstruct state for any point in time
  - Added `system_snapshot_at/1` for comprehensive view of system at any timestamp
  - Added `execution_timeline/3` to "step through" execution history 
  - Added `state_evolution/3` with contextual information about state changes and their causes
- Added helper functions for reconstructing historical system state:
  - `get_pending_messages_at/1` to find messages in transit
  - `reconstruct_supervision_tree_at/1` to approximate supervision hierarchy

## Task 5: Test ProcessObserver Supervision Tree Logic ✅

- Added comprehensive tests for supervision tree building and updating
- Created `process_observer_test.exs` with thorough test cases:
  - Identification of top-level supervisors
  - Simple supervision trees with workers
  - Nested supervisor hierarchies
  - Different supervisor strategies (one_for_one, one_for_all, rest_for_one)
  - Dynamic supervisor child addition and removal
  - Supervisor restart behavior testing

## Task 6: Expand Documentation

- Update README.md with clearer examples
  - Add code examples for common use cases
  - Add step-by-step guides for setting up with Phoenix and plain Elixir
  - Include diagrams for supervision tree and message flow visualization
- Add documentation for advanced use cases and configurations
  - Add detailed guide on performance tuning
  - Add troubleshooting section
  - Add examples for distributed Erlang tracing
- Document Tidewave integration and AI capabilities ✅ 