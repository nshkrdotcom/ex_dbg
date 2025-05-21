# ElixirScope Data Collection Layer Testing Plan

## Overview

This document outlines the approach for testing the data collection layer of ElixirScope. With the foundational `TraceDB` component thoroughly tested, we can now move on to testing the components that directly depend on it. These components are responsible for collecting different types of data from the Erlang VM and storing them in the `TraceDB`.

## Dependency Analysis

Based on the codebase structure, the data collection layer consists of:

```
ElixirScope (Main API)
├── TraceDB (Core Storage) - TESTED ✅
├── ProcessObserver → TraceDB - TESTED ✅
├── StateRecorder → TraceDB - TESTED ✅
├── MessageInterceptor → TraceDB
├── CodeTracer → TraceDB
├── PhoenixTracker → TraceDB
└── QueryEngine → TraceDB
```

We'll focus on testing these components in the following order, based on their complexity and interdependencies:

1. ProcessObserver
2. StateRecorder
3. MessageInterceptor
4. CodeTracer
5. PhoenixTracker

## Test Plan

### 1. ProcessObserver Tests

The `ProcessObserver` monitors process lifecycle events (spawn, exit, link, monitor) and stores them in `TraceDB`. Tests will ensure it properly captures and records these events.

#### Test Files:
- `test/elixir_scope/process_observer_test.exs`

#### Test Cases:

1. **Initialization Tests**
   - Test initialization with default options
   - Test initialization with custom options
   - Verify it registers with TraceDB

2. **Process Lifecycle Tracking**
   - Test tracking of process spawns
   - Test tracking of process exits
   - Test tracking of process crashes
   - Test tracking of links between processes
   - Test tracking of monitors

3. **Supervision Tree Building**
   - Test identification of top-level supervisors
   - Test building simple supervision trees with workers
   - Test handling nested supervisors
   - Test different supervisor strategies (one_for_one, one_for_all, etc.)
   - Test dynamic supervisor child changes
   - Test supervisor restarts

4. **Process Information Collection**
   - Test collection of process information (memory usage, message queue length, etc.)
   - Test process state dumps
   - Test registration of named processes

5. **OTP Behavior Recognition**
   - Test identification of GenServer processes
   - Test identification of Supervisor processes
   - Test identification of other OTP behaviors

### 2. StateRecorder Tests

The `StateRecorder` captures state changes in processes, especially GenServers. Tests will ensure it correctly records state transitions.

#### Test Files:
- `test/elixir_scope/state_recorder_test.exs`

#### Test Cases:

1. **Initialization Tests**
   - Test initialization with default options
   - Test target process tracking

2. **GenServer State Tracking**
   - Test capturing initial state
   - Test capturing state changes after handle_call
   - Test capturing state changes after handle_cast
   - Test capturing state changes after handle_info
   - Test state capture timing

3. **State Diffing**
   - Test identifying changes between states
   - Test handling complex state structures
   - Test performance with large states

4. **Different Process Types**
   - Test with regular GenServers
   - Test with Supervisors
   - Test with GenEvent handlers
   - Test with Agents

### 3. MessageInterceptor Tests

The `MessageInterceptor` captures inter-process message passing. Tests will ensure it properly captures messages between processes.

#### Test Files:
- `test/elixir_scope/message_interceptor_test.exs`

#### Test Cases:

1. **Initialization Tests**
   - Test initialization with default options
   - Test selective process tracing

2. **Message Capture**
   - Test capturing sent messages
   - Test capturing received messages
   - Test message content capturing
   - Test message timing accuracy

3. **GenServer Message Interception**
   - Test capturing calls
   - Test capturing casts
   - Test capturing replies
   - Test capturing info messages

4. **Specialized Message Types**
   - Test EXIT messages
   - Test monitoring messages
   - Test system messages

### 4. CodeTracer Tests

The `CodeTracer` traces execution of functions in modules. Tests will ensure it properly captures function calls and returns.

#### Test Files:
- `test/elixir_scope/code_tracer_test.exs`

#### Test Cases:

1. **Initialization Tests**
   - Test initialization with default options
   - Test module selection for tracing

2. **Function Call Tracing**
   - Test capturing function calls
   - Test capturing function arguments
   - Test capturing function returns
   - Test capturing function exceptions

3. **Module Coverage**
   - Test tracing multiple modules
   - Test exclusion patterns
   - Test performance impact

4. **Source Code Integration**
   - Test source code location identification
   - Test line number accuracy

### 5. PhoenixTracker Tests

The `PhoenixTracker` captures Phoenix-specific events. Tests will ensure it properly captures web framework events.

#### Test Files:
- `test/elixir_scope/phoenix_tracker_test.exs`

#### Test Cases:

1. **Initialization Tests**
   - Test initialization with a Phoenix endpoint
   - Test initialization without Phoenix

2. **Request Lifecycle Tracking**
   - Test capturing HTTP requests
   - Test capturing controller actions
   - Test capturing view renders
   - Test capturing redirects

3. **Channel Event Tracking**
   - Test capturing channel joins
   - Test capturing channel leaves
   - Test capturing channel messages

4. **PubSub Tracking**
   - Test capturing publications
   - Test capturing subscriptions

## Implementation Strategy

We'll follow these principles for implementing the tests:

1. Focus on isolated testing of each component
2. Use mocks or stubs to isolate from TraceDB when necessary
3. Verify both the component behavior and its interaction with TraceDB
4. Test real-world scenarios that combine multiple aspects of each component

## Progress Checklist

### ProcessObserver

- [x] **Fix existing test failures**
  - [x] Fix BadMapError in build_supervision_tree function
  - [x] Fix process monitoring timeout issues
  - [x] Improve error handling in process trace event tracking
  
- [x] **Initialization Tests**
  - [x] Initialization with default options
  - [x] Registration with TraceDB

- [x] **Process Lifecycle Tracking**
  - [x] Process event tracking
  - [x] Basic process tracing
  - [x] Event storage in TraceDB

- [x] **Process Information Collection**
  - [x] Basic process information collection

- [ ] **Supervision Tree Building (Deferred due to complexity)**
  - [ ] Top-level supervisor identification 
  - [ ] Simple supervision tree building
  - [ ] Nested supervisor handling
  - [ ] Supervisor strategy recognition
  - [ ] Dynamic supervisor child changes
  - [ ] Supervisor restart handling

- [ ] **OTP Behavior Recognition (Deferred due to complexity)**
  - [ ] GenServer identification
  - [ ] Supervisor identification
  - [ ] Other OTP behavior identification

### StateRecorder

- [x] **Initialization Tests**
  - [x] Initialization with default options
  - [x] Target process tracking

- [x] **GenServer State Tracking**
  - [x] Initial state capture
  - [x] State changes after handle_call
  - [x] State changes after handle_cast
  - [x] State changes after handle_info

- [x] **External Process Tracing**
  - [x] Trace external GenServer processes
  - [x] Capture state changes in external processes

- [ ] **Different Process Types (Deferred)**
  - [ ] Regular GenServer testing
  - [ ] Supervisor testing
  - [ ] GenEvent handler testing
  - [ ] Agent testing

### MessageInterceptor

- [ ] **Initialization Tests**
  - [ ] Initialization with default options
  - [ ] Selective process tracing

- [ ] **Message Capture**
  - [ ] Sent message capture
  - [ ] Received message capture
  - [ ] Message content accuracy
  - [ ] Message timing accuracy

- [ ] **GenServer Message Interception**
  - [ ] Call interception
  - [ ] Cast interception
  - [ ] Reply interception
  - [ ] Info message interception

- [ ] **Specialized Message Types**
  - [ ] EXIT message handling
  - [ ] Monitor message handling
  - [ ] System message handling

### CodeTracer

- [ ] **Initialization Tests**
  - [ ] Initialization with default options
  - [ ] Module selection for tracing

- [ ] **Function Call Tracing**
  - [ ] Function call capture
  - [ ] Function argument capture
  - [ ] Function return capture
  - [ ] Function exception capture

- [ ] **Module Coverage**
  - [ ] Multiple module tracing
  - [ ] Exclusion pattern testing
  - [ ] Performance impact assessment

- [ ] **Source Code Integration**
  - [ ] Source code location identification
  - [ ] Line number accuracy verification

### PhoenixTracker

- [ ] **Initialization Tests**
  - [ ] Initialization with Phoenix endpoint
  - [ ] Initialization without Phoenix

- [ ] **Request Lifecycle Tracking**
  - [ ] HTTP request capture
  - [ ] Controller action capture
  - [ ] View render capture
  - [ ] Redirect capture

- [ ] **Channel Event Tracking**
  - [ ] Channel join capture
  - [ ] Channel leave capture
  - [ ] Channel message capture

- [ ] **PubSub Tracking**
  - [ ] Publication capture
  - [ ] Subscription capture

## Next Steps (After Data Collection Layer)

Once the data collection layer is thoroughly tested, we will move on to:

1. The QueryEngine layer which builds on TraceDB to provide more advanced query capabilities
2. The AIIntegration layer which depends on QueryEngine and CodeTracer
3. Full system integration tests

Each layer will build upon the well-tested foundation established so far. 