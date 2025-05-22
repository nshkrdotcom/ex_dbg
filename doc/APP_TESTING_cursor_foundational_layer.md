# ElixirScope Foundational Layer Testing Plan

## Overview

This document outlines the approach for building foundational tests for ElixirScope. The foundational layer focuses on the core storage and retrieval functionality, which is the basis for all other components. Based on the dependency analysis, the `TraceDB` module is the foundation of the entire system, with no internal dependencies while being used by all other components.

## Dependency Analysis

After reviewing the codebase, the module dependency hierarchy is:

```
ElixirScope (Main API)
├── TraceDB (Core Storage)
├── ProcessObserver → TraceDB
├── MessageInterceptor → TraceDB
├── CodeTracer → TraceDB
├── StateRecorder → TraceDB
├── PhoenixTracker → TraceDB
├── QueryEngine → TraceDB
└── AIIntegration → QueryEngine, CodeTracer, TraceDB
```

## Foundational Test Plan

### 1. TraceDB Tests

The `TraceDB` module is responsible for storing and retrieving trace data and forms the foundation of the entire system. The tests will ensure that:

- Events can be stored and retrieved correctly
- State data is properly maintained
- Sampling works as expected
- Cleanup and persistence operate correctly

#### Test Files:

- `test/elixir_scope/trace_db_test.exs`

#### Test Cases:

1. **Initialization Tests**
   - Test initialization with default options
   - Test initialization with custom options (max_events, persist, sample_rate)
   - Verify ETS tables are created correctly

2. **Event Storage Tests**
   - Test storing events of different types
   - Verify events receive a unique ID and timestamp
   - Test event indexing by PID
   - Verify complex data structures can be stored/retrieved

3. **Sampling Tests**
   - Test with different sample rates
   - Verify critical events bypass sampling
   - Test deterministic sampling with fixed inputs

4. **Query Tests**
   - Test querying by type
   - Test querying by PID
   - Test querying by timestamp range
   - Test combinations of filters

5. **State History Tests**
   - Test state retrieval for a specific process
   - Test state retrieval at a specific point in time

6. **Management Tests**
   - Test clearing the database
   - Test event cleanup when max_events is exceeded
   - Test persistence (if enabled)

### 2. Utility Tests

Create utility modules and helpers to simplify testing of higher layers:

- Test helpers for common test setup
- Mock event generators
- Assertion helpers for common validation patterns

## Implementation Strategy

The implementation will follow a strict test-driven development approach:

1. Write a failing test
2. Implement the minimum code to make the test pass
3. Refactor the code while keeping tests green
4. Repeat for each test case

## Progress Checklist

- [x] **Setup test environment**
  - [x] Configure `mix.exs` to properly run tests
  - [x] Create test helper modules

- [x] **TraceDB initialization tests**
  - [x] Test initialization with default options
  - [x] Test initialization with custom options
  - [x] Verify ETS tables are created correctly

- [x] **TraceDB event storage tests**
  - [x] Test storing events of different types
  - [x] Verify events receive a unique ID and timestamp
  - [x] Test event indexing by PID
  - [x] Verify complex data structures can be stored/retrieved

- [x] **TraceDB sampling tests**
  - [x] Test with different sample rates
  - [x] Verify critical events bypass sampling
  - [x] Test deterministic sampling with fixed inputs

- [x] **TraceDB query tests**
  - [x] Test querying by type
  - [x] Test querying by PID
  - [x] Test querying by timestamp range
  - [x] Test combinations of filters

- [x] **TraceDB state history tests**
  - [x] Test state retrieval for a specific process
  - [x] Test state retrieval at a specific point in time

- [x] **TraceDB management tests**
  - [x] Test clearing the database
  - [x] Test event cleanup when max_events is exceeded
  - [x] Test persistence (if enabled)

## Next Steps (After Foundational Layer)

Once the foundational layer is thoroughly tested, we will move on to the next layer:

1. Data collection components (ProcessObserver, MessageInterceptor, etc.)
2. QueryEngine
3. High-level integration tests

Each layer will build upon the solid foundation established in this phase. 