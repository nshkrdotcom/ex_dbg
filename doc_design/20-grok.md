# Assisted Debugger for Elixir Applications

## Key Points

  * Building a detailed assisted debugger for Elixir applications likely involves modifying `GenServer` code to log state changes and using Erlang's `dbg` module for tracing messages.
  * Leveraging existing tools like `iex`, `Observer`, and `Logger` can assist, but custom instrumentation is necessary for line-by-line state tracking.
  * Tidewave appears to be useful primarily for Phoenix applications, not general Elixir applications, due to its design.
  * Automated tooling for comparing expected versus actual execution is feasible with logs and analysis tools, but may require code modifications.

## Overview

Creating a debugger for Elixir applications on the BEAM/OTP platform, particularly for tracking processes, message passing, and state at each line, is a complex yet achievable task. This system aims to help developers debug by comparing expected and actual execution at a granular level (e.g., line-by-line, variable-by-variable, and `GenServer`-by-`GenServer`). This document explores how to design this system, focusing on a simple supervision tree with two `GenServer`s, and discusses leveraging existing tools and the potential role of Tidewave.

## Design Approach

To construct this debugger, we'll need to instrument the `GenServer` code to log state changes at key points, utilize Erlang's tracing capabilities for message passing, and create an analysis tool to visualize and compare execution logs. Here's a breakdown:

  * **State Logging:** Modify `GenServer` callbacks (e.g., `handle_call/3` and `handle_cast/2`) to log the state before and after processing each message. This can be automated using macros to avoid manual changes.
  * **Message Tracing:** Use Erlang's `dbg` module to trace messages sent and received by processes, ensuring that communication between `GenServer`s is captured.
  * **Log Analysis:** Collect logs in a file or database and build a tool (e.g., a web interface) to parse and visualize the execution flow, allowing for comparison with expected behavior.

## Role of Tidewave

Tidewave, an AI-powered tool for Phoenix applications, offers process inspection and tracing, which could be beneficial if your application is built with Phoenix. However, for general Elixir applications, it's not directly applicable; therefore, our focus will be on custom solutions.

-----

## Survey Note: Detailed Design of the Assisted Debugger for Elixir Applications

### Introduction

This survey note outlines the design of a detailed assisted debugger for Elixir applications running on the BEAM/OTP platform, with a focus on tracking processes, message passing, and state at a granular level. The goal is to facilitate robust debugging by enabling the comparison of expected versus actual execution, particularly for a simple supervision tree with two `GenServer`s (e.g., `MyApp.GenServer1` and `MyApp.GenServer2`). We will explore leveraging existing Elixir and BEAM/OTP debugging tools, evaluate the utility of Tidewave, and describe the custom system in detail.

### Background on Elixir and BEAM/OTP Debugging

Elixir, built on the Erlang VM (BEAM), provides several tools for debugging and introspection, which form the foundation of our system:

  * **`iex`:** The interactive shell allows inspecting and interacting with running processes, useful for manual debugging but not automated tracking.
  * **`Observer`:** A graphical tool for monitoring processes, ETS tables, and system metrics, providing real-time process information but lacking line-by-line state tracking.
  * **`dbg` (Debugger):** Enables tracing of function calls, message passing, and process events, which can be used programmatically for automated tracing.
  * **`sys` Module:** Allows getting and setting the state of processes (e.g., `sys:get_state(Pid)` for `GenServer`s), useful for inspecting state but requires processes to be debug-enabled.
  * **`Logger`:** Elixir’s built-in logging mechanism for recording events and errors, which can be extended for custom logging with instrumentation.
  * **`crasher`:** Handles supervised process crashes, not directly relevant for granular debugging.

These tools provide a starting point, but for the level of granularity required (line-by-line state tracking), additional custom instrumentation is necessary.

### Evaluating Tidewave for Debugging

Tidewave, as described in its GitHub repository, is an AI-powered tool designed to enhance development for Phoenix applications. Its key features include:

  * Process inspection and tracing.
  * Runtime intelligence via the Model Context Protocol (MCP).
  * Integration with AI assistants for enhanced debugging workflows.

Installation instructions (e.g., adding Tidewave to `mix.exs` and plugging it into Phoenix endpoints) indicate it is tailored for Phoenix apps. From the Tidewave website, it mentions support for “all supported languages and frameworks,” but current documentation (as of May 21, 2025) focuses on Phoenix. Discussions on platforms like the Elixir Forum and podcasts highlight its utility for Phoenix, with features like process tracing and runtime introspection.

Given this, Tidewave is likely useful only for Phoenix-based Elixir applications, providing process tracing and runtime intelligence that could complement our system. For non-Phoenix Elixir apps, we will rely on custom solutions, as Tidewave’s design is web-framework-specific.

### Designing the Assisted Debugger

To achieve the desired granularity (tracking processes, message passing, and state at each line), we combine existing tools with custom instrumentation. Below is a detailed breakdown:

#### Instrumenting `GenServer`s for State Logging

`GenServer`s maintain their state internally, with changes occurring within callback functions (e.g., `handle_call/3`, `handle_cast/2`, `handle_info/2`). To track state at a granular level:

Modify the `GenServer` code to log its state before and after each callback. For example:

```elixir
defmodule MyApp.GenServer1 do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(state) do
    log_state(:init, state)
    {:ok, state}
  end

  def handle_call(:request, _from, state) do
    log_state(:before_call, :request, state)
    {:reply, :response, new_state} = do_handle_call(:request, _from, state)
    log_state(:after_call, :request, new_state)
    {:reply, :response, new_state}
  end

  defp do_handle_call(:request, _from, state) do
    # Actual logic here
    {:reply, :response, new_state}
  end

  defp log_state(event, state) do
    Logger.info("#{inspect(event)} - State: #{inspect(state)}")
  end
end
```

To automate this and avoid manual changes, use meta-programming (e.g., macros) to generate logging code. For instance:

```elixir
defmacro logging_callback(name, body) do
  quote do
    def unquote(name)(unquote(body)) do
      log_state(:before, unquote(name), state)
      result = do_unquote(name)(unquote(body))
      log_state(:after, unquote(name), elem(result, 1))
      result
    end

    defp do_unquote(name)(unquote(body)) do
      unquote(body)
    end
  end
end
```

This approach ensures state is logged at key points (before and after each callback), providing sufficient granularity for debugging.

#### Tracing Message Passing

To track message passing between processes (e.g., between `MyApp.GenServer1` and `MyApp.GenServer2`), use Erlang’s `dbg` module:

Set up a tracer to log messages to a file:

```erlang
dbg:tracer(file, "debug.log").
```

Trace messages for specific processes:

```erlang
dbg:p(Pid, [m]).
```

Replace `Pid` with the PID of the `GenServer` (e.g., obtained from the supervision tree).

This logs all messages sent to and from the traced process, capturing communication between `GenServer`s.

Automate this by creating a Debugger process that identifies PIDs and sets up tracing for all relevant processes.

#### Collecting and Analyzing Logs

Logs from state instrumentation and message tracing need to be collected and analyzed:

  * Use Elixir’s `Logger` for state logs, which can be configured to output to a file or database.
  * Use `dbg` to collect message traces into a file (e.g., "debug.log").
  * Build an analysis tool (e.g., a web interface or CLI tool) to:
      * Parse logs to extract events (timestamp, process ID, event type, state before/after).
      * Visualize execution flow as a timeline or sequence diagram.
      * Allow users to define expected behavior (e.g., “After receiving `:request`, state should transition to X”) and compare with actual logs.

#### Handling Line-by-Line State Tracking

True line-by-line state tracking is challenging, as state changes occur within callback functions, not at each line. Erlang’s tracing (e.g., `dbg:tpl/3`) can trace specific lines but is impractical for entire applications due to performance overhead. Instead, focus on callback-level state tracking, logging state before and after each message is processed, which aligns with how `GenServer`s operate and provides sufficient granularity for debugging.

#### Implementation Example

For a simple supervision tree with two `GenServer`s:

  * Start the `GenServer`s with logging enabled (as shown above).
  * Set up the Debugger process to trace messages and collect logs.
  * Use the analysis tool to visualize:
      * Message sequence (e.g., `GenServer1` sends `:request` to `GenServer2` at time T1).
      * State changes (e.g., `GenServer1` state before `:request` is X, after is Y).

#### Comparison with Expected vs. Actual Execution

The analysis tool should allow defining expected behavior, such as:

  * Expected state transitions after specific messages.
  * Expected message sequences between processes.

Compare these with actual logs to identify discrepancies, facilitating debugging at a line-by-line, variable-by-variable, and `GenServer`-by-`GenServer` level.

### Table: Summary of Debugging Components

| Component           | Description                                                        | Tool/Method Used                     |
| :------------------ | :----------------------------------------------------------------- | :----------------------------------- |
| State Logging       | Log state before and after each `GenServer` callback               | Custom instrumentation, `Logger`     |
| Message Tracing     | Track messages sent and received between processes                 | Erlang `dbg` module                  |
| Log Collection      | Store logs for analysis                                            | File (e.g., "debug.log"), Database   |
| Analysis Tool       | Visualize and compare execution flow, expected vs. actual behavior | Custom web interface or CLI tool     |
| Tidewave Integration | Process inspection and tracing (if Phoenix app)                    | Tidewave (Phoenix-specific)          |

### Conclusion

This system combines existing Elixir/BEAM/OTP tools (`dbg`, `Logger`, `sys`) with custom instrumentation (logging in `GenServer` callbacks) to achieve granular tracking of processes, message passing, and state. For Phoenix apps, Tidewave can enhance process tracing, but for general Elixir apps, custom solutions are necessary. The automated tooling enables robust debugging by comparing expected versus actual execution, meeting the user’s requirements for line-by-line, variable-by-variable, and `GenServer`-by-`GenServer` introspection.

### Key Citations

  * [Tidewave for Phoenix GitHub Repository](https://www.google.com/search?q=https://github.com/tidewave-io/tidewave)
  * [Tidewave Official Website](https://www.google.com/search?q=https://www.tidewave.io/)
  * [Tidewave Initial Impressions Elixir Forum](https://www.google.com/search?q=https://elixirforum.com/t/tidewave-initial-impressions/64923)
  * [Thinking Elixir Podcast Episode 252](https://www.google.com/search?q=https://thinkingelixir.com/podcast-episodes/252-tidewave-io-with-brian-cardarella/)
  * [Erlang dbg Module Documentation](https://www.erlang.org/doc/man/dbg.html)
  * [Elixir GenServer Documentation](https://hexdocs.pm/elixir/GenServer.html)
