# Deep Research: Code Property Graphs and Static Analysis in Elixir/Erlang Ecosystem

**Research Date:** January 2025
**Status:** Comprehensive landscape analysis

## Executive Summary

**Key Finding: NO native Code Property Graph (CPG) implementation exists for Elixir/Erlang.** The BEAM ecosystem has developed alternative approaches to static analysis that leverage success typing, gradual typing, and semantic program graphs rather than traditional CPG representations used in imperative languages.

---

## 1. Code Property Graph (CPG) - Industry Standard

### What is CPG?

Code Property Graph is a language-agnostic graph representation of source code that **unites multiple graph types** into a single supergraph:

- **Abstract Syntax Tree (AST)** - Code structure
- **Control Flow Graph (CFG)** - Execution paths
- **Data Flow Graph (DFG)** - Data dependencies
- **Evaluation Order Graph (EOG)** - Statement execution order
- **Call Graph** - Function call relationships
- **Control Dependence Graph (CDG)** - Control dependencies

### Major CPG Implementations

#### Joern (ShiftLeft/Qwiet AI)
- **Languages**: C/C++, Java, Java bytecode, Kotlin, Python, JavaScript, TypeScript, LLVM bitcode, x86 binaries
- **Status**: Production-ready, widely used in security analysis
- **Elixir Support**: ❌ None

#### Fraunhofer AISEC CPG
- **Languages**: C/C++, Java, Golang, Python, TypeScript
- **Status**: Open-source, academic/research focus
- **Elixir Support**: ❌ None

### Why CPG Doesn't Exist for Elixir

1. **Functional paradigm mismatch**: CPG was designed for imperative/OO languages
2. **BEAM runtime complexity**: Dynamic code loading, hot code swapping
3. **Metaprogramming**: AST manipulation at compile-time makes static analysis harder
4. **Small community**: Limited resources compared to Java/JavaScript ecosystems
5. **Alternative solutions**: Success typing (Dialyzer) provides adequate bug detection

---

## 2. Elixir/Erlang Static Analysis Ecosystem (2024-2025)

### 2.1 Production-Ready Type Checkers

#### Dialyzer - Success Typing (Industry Standard ✅)
- **Approach**: Success typing with constraint-based dataflow analysis
- **Philosophy**: Reports only **provable errors** (no false positives)
- **Strength**: Can find bugs across modules without requiring type specs
- **Limitation**: May miss issues it cannot prove
- **Status**: Mature, shipped with Erlang/OTP, universal adoption
- **Integration**: Available via Dialyxir for Elixir projects

**How it works:**
```
BEAM bytecode → Abstract Format → Success Type Inference → Constraint Solving → Report Definite Errors
```

#### eqWAlizer - WhatsApp's Type Checker (2022+) ✅
- **Developer**: WhatsApp (Meta)
- **Approach**: Static type checking (similar to Flow/Pyre/Hack for JavaScript/Python)
- **Philosophy**: Reports cases where it **cannot prove correctness** (guarantees absence of certain bugs)
- **Key Difference from Dialyzer**: Stricter, provides guarantees but requires more annotations
- **Status**: Production at WhatsApp, open-sourced
- **Integration**: Part of ELP (Erlang Language Platform)
- **Requirements**: OTP 26+

**Architecture:**
```elixir
Erlang Source → ELP Parser → AST → Type Inference → Type Checking → IDE Integration
```

#### Gradualizer - Gradual Typing (Research → Beta) 🟡
- **Developer**: Academic (Josef Svenningsson)
- **Approach**: Gradual typing (mix static and dynamic typing)
- **Philosophy**: Start dynamic, gradually add type specs for static checking
- **Key Feature**: `any()` type for dynamic typing
- **Status**: Near beta release, works on most Erlang constructs
- **Elixir Integration**: Via **Gradient** frontend
- **Requirements**: OTP 21+

**Gradual Typing Model:**
```
No specs → Dynamic typing (runtime checks)
Add specs → Static typing (compile-time checks)
More specs → More static guarantees
```

#### Etylizer - Set-Theoretic Types (Academic) 🟡
- **Developer**: Academic (Albert Schimpf, University of Kaiserslautern)
- **Approach**: Set-theoretic types (first for dynamically typed language)
- **Philosophy**: Type check programs "written with types in mind"
- **Key Feature**: Guard refinement - statically decide branch well-typedness
- **Status**: Research/experimental
- **Paper**: "Set-theoretic Types for Erlang" (2023)

### 2.2 Advanced Static Analysis Tools

#### InfERL - WhatsApp/Meta (2022+) ✅
- **Developer**: WhatsApp/Meta
- **Based on**: Meta's Infer (used for Java, C++, Objective-C)
- **Approach**: Scalable, extensible static analysis using separation logic
- **Scale**: Scans WhatsApp server codebase (2+ billion users)
- **Purpose**: Detect reliability issues, check user-defined properties
- **Status**: Production at WhatsApp, open-source
- **Presented**: ACM SIGPLAN Erlang Workshop 2022 (ICFP)

**Technical Stack:**
- Written in OCaml
- Analyzes Erlang Abstract Format
- Incremental analysis for large codebases
- Customizable analysis rules

#### RefactorErl - Semantic Program Graph (Academic) 🟡
- **Developer**: Eötvös Loránd University, Budapest
- **Approach**: **Semantic Program Graph (SPG)** - closest to CPG concept!
- **Purpose**: Code comprehension, refactoring, visualization
- **Scale**: Successfully applied to 1.5M+ LOC codebases

**Graph Representation:**
- Data-flow analysis
- Control-flow analysis
- Behavior-flow analysis (OTP behaviors)
- Dependency analysis (sequential + parallel constructs)
- **Query Language**: Custom DSL for SPG queries
- **Visualization**: Interactive graph traversal with detail levels

**This is the closest thing to a CPG for Erlang!**

#### Credo - Pattern-Based Analysis (Elixir Standard) ✅
- **Purpose**: Code consistency, style, best practices
- **Approach**: AST pattern matching via `Macro.prewalk/postwalk`
- **Philosophy**: Teaching tool + linter
- **Extensibility**: Custom checks via AST traversal
- **Status**: De facto standard for Elixir projects

**Analysis Categories:**
- Design patterns detection
- Refactoring opportunities
- Common mistakes
- Code consistency
- Complexity metrics

### 2.3 Concurrency Analysis

#### Concuerror - Systematic Concurrency Testing ✅
- **Developer**: Academic (University of Athens, Uppsala)
- **Approach**: Stateless model checking
- **Purpose**: Detect race conditions, deadlocks in concurrent programs
- **Method**: Systematically explores process interleavings
- **Key Technique**: Preemption bounding to manage state explosion
- **Status**: Mature, integrated with erlang.mk

**How it works:**
```
Unit Test → Instrument Code → Explore Interleavings → Detect Races → Report Errors
```

---

## 3. Language Server & Code Intelligence (2024)

### Official Elixir Language Server Team (Aug 2024)
- **Team**: Jonatan Kłosko, Łukasz Samson, Mitch Hanberg, Steve Cohen
- **Funding**: Fly.io, Livebook
- **Goal**: Unify code intelligence infrastructure across tools/editors

### Key Projects

#### ElixirLS - Language Server Protocol
- **Features**: Code completion, go-to-definition, signature help, diagnostics
- **Mechanisms**:
  1. **Reflection**: Query compiled modules (precise but limited)
  2. **AST Analysis**: Parse current buffer (works for uncompiled code)
- **Challenge**: Metaprogramming makes 100% accuracy infeasible

#### ElixirSense - Context-Aware Analysis
- **Purpose**: Introspect context-aware information
- **Used by**: ElixirLS, other editors
- **Capabilities**: Completion, docs, signature info, jump-to-def

#### Expert - Official Implementation
- **Status**: Official unified language server (2024+)
- **Goal**: Replace fragmented ecosystem with canonical implementation

### Elixir v1.18 (Dec 2024) - Major Analysis Improvements
- **Type Checking**: Function call type checking
- **LSP Listeners**: Compiler lock + cross-process listening
- **Built-in JSON**: Native JSON support
- **Gradual Set-Theoretic Types**: Formalized type system
- **Code.Fragment**: Deduplicate analysis APIs across language servers

---

## 4. Compiler Infrastructure for Analysis

### Mix Compiler Tracers (Elixir 1.10+)
- **Purpose**: Observe compilation events for static analysis
- **API**: `trace/2` callback with event name + `Macro.Env`
- **Events**: `:remote_macro`, `:local_function`, `:imported_function`, etc.
- **Use Cases**:
  - Track macro usage
  - License compliance scanning (Paraxial.io)
  - Custom compile-time analysis tools

### Erlang Abstract Format
- **Definition**: Standard representation of parse trees as Erlang terms
- **Usage**: Foundation for all BEAM static analysis
- **Debug Info**: Stored in `.beam` files with `+debug_info` flag
- **Access**: Via `beam_lib:chunks/2`

### AST Traversal APIs
- **Elixir**: `Macro.prewalk/2`, `Macro.postwalk/2`, `Macro.traverse/3`
- **Traversal**: Depth-first, pre-order or post-order
- **Use Cases**: Custom code analyzers, macro transformations

---

## 5. Academic Research Landscape

### Recent Papers (2023-2024)

1. **"Guard Analysis and Safe Erasure Gradual Typing: a Type System for Elixir"** (2024)
   - arXiv:2408.14345
   - Formalizes Elixir's new official type system
   - Combines gradual + semantic subtyping

2. **"Same Same but Different: A Comparative Analysis of Static Type Checkers in Erlang"** (2024)
   - ACM SIGPLAN Erlang Workshop
   - Compares: Dialyzer, Gradualizer, eqWAlizer, Etylizer
   - Finding: 25%-45% disagreement on test cases

3. **"InfERL: Scalable and Extensible Erlang Static Analysis"** (2022)
   - ACM SIGPLAN Erlang Workshop
   - Adapts Meta's Infer to Erlang
   - Production deployment at WhatsApp

4. **"Set-theoretic Types for Erlang"** (2023)
   - arXiv:2302.12783
   - First set-theoretic type system for dynamic language
   - Foundation for Etylizer

5. **"A Gradual Type System for Elixir"** (2021)
   - ScienceDirect
   - Theoretical foundation for Gradient

### Key Research Institutions
- **Eötvös Loránd University** (Hungary) - RefactorErl
- **Uppsala University** (Sweden) - Concuerror
- **University of Kaiserslautern** (Germany) - Etylizer
- **WhatsApp/Meta** (USA) - eqWAlizer, InfERL

---

## 6. Why No CPG for Elixir? Deep Analysis

### Technical Challenges

#### 1. Metaprogramming Complexity
```elixir
# Code is data, data is code - AST manipulation at compile-time
defmacro dynamic_function(name) do
  quote do
    def unquote(name)(), do: unquote(name)
  end
end

# How do you build a static CFG when functions are defined dynamically?
```

#### 2. Actor Model Concurrency
- Processes communicate via messages (not shared memory)
- Dynamic process spawning
- Message passing patterns hard to represent in traditional CFG/DFG

#### 3. Hot Code Swapping
- BEAM allows replacing modules at runtime
- Multiple versions of same module can coexist
- Traditional static analysis assumes immutable code

#### 4. Dynamic Typing with Specs
- Type specs are **optional documentation**
- Runtime types can differ from specs
- Success typing works **without specs**

### Why Success Typing Works Better

```erlang
%% Traditional type system: REJECT this code
-spec process(list()) -> atom().
process([]) -> empty;
process([H|_]) -> H.  % H could be anything, not just atom!

%% Success typing: ACCEPT (finds actual errors, not theoretical ones)
%% Only fails if you can PROVE it will crash at runtime
```

### Alternative: Semantic Program Graph (RefactorErl)

RefactorErl's SPG is essentially a **domain-specific CPG for Erlang**:

- **AST representation**: ✅
- **Control flow**: ✅ (sequential + parallel constructs)
- **Data flow**: ✅
- **Behavior flow**: ✅ (OTP-specific!)
- **Dependency graph**: ✅
- **Call graph**: ✅

**Key difference**: Tailored for functional/concurrent paradigm, not bolted-on from imperative world.

---

## 7. Comparison: CPG vs. BEAM Ecosystem Approaches

| Feature | Traditional CPG | BEAM Ecosystem |
|---------|----------------|----------------|
| **Languages** | Java, C++, Python, JS | Erlang, Elixir |
| **Graph Type** | Unified supergraph | Specialized graphs (SPG, success types) |
| **Type Checking** | Static/gradual | Success typing + gradual options |
| **Concurrency** | Thread-based (CFG) | Actor-based (message flow) |
| **Tooling** | Joern, Semgrep | Dialyzer, eqWAlizer, RefactorErl |
| **Industry Use** | Security analysis | Reliability + type safety |
| **False Positives** | Common | Minimal (success typing) |
| **Coverage** | Deep (all paths) | Selective (provable errors) |
| **Adoption** | Widespread | BEAM-only |

---

## 8. Practical Tools for Elixir/Erlang Code Analysis (2025)

### Production-Ready Stack

```elixir
# mix.exs
def project do
  [
    # Type checking
    {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},

    # Code quality
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},

    # Security
    {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},

    # Documentation
    {:ex_doc, "~> 0.34", only: :dev, runtime: false},

    # Testing
    {:excoveralls, "~> 0.18", only: :test},
    {:stream_data, "~> 1.1", only: [:dev, :test]}
  ]
end
```

### Analysis Pipeline

```bash
# 1. Format check
mix format --check-formatted

# 2. Linting + patterns
mix credo --strict

# 3. Type analysis
mix dialyzer

# 4. Security scanning (Phoenix apps)
mix sobelow --config

# 5. Test coverage
mix coveralls.html

# 6. Documentation
mix docs
```

### Advanced: Compiler Tracers

```elixir
# lib/my_tracer.ex
defmodule MyTracer do
  def trace(:remote_macro, env) do
    IO.puts("Macro called: #{inspect(env.module)}.#{env.function}")
    :ok
  end

  def trace(_event, _env), do: :ok
end

# mix.exs
def project do
  [
    compilers: Mix.compilers(),
    tracers: [MyTracer]
  ]
end
```

---

## 9. Gap Analysis: What's Missing?

### Missing Capabilities (compared to CPG ecosystems)

1. **Security Vulnerability Detection**
   - No semantic code search like Semgrep
   - Sobelow is pattern-based (AST matching), not dataflow-based
   - No taint analysis for injection vulnerabilities

2. **Architectural Pattern Detection**
   - No automated detection of design patterns
   - No architectural smell detection
   - Credo checks are limited to local patterns

3. **Cross-Module Dataflow**
   - Dialyzer analyzes across modules but doesn't expose DFG
   - No query language for dataflow paths
   - RefactorErl has this but limited adoption

4. **Interactive Code Querying**
   - Joern has interactive shell for CPG queries
   - Elixir has no equivalent (except RefactorErl's query language)

5. **Complexity Metrics**
   - No standard cyclomatic complexity analyzer
   - No cognitive complexity metrics
   - Limited to Credo's basic checks

### Opportunities

1. **Build Elixir-specific CPG**
   - Leverage compiler tracers
   - Use Erlang Abstract Format
   - Integrate with Foundation layer (from elixir_scope project)

2. **Enhance RefactorErl**
   - Modernize for Elixir ecosystem
   - Add Language Server integration
   - Expose SPG via GraphQL/REST API

3. **Dataflow Analysis Layer**
   - Build on Dialyzer's constraint system
   - Expose DFG for security analysis
   - Integrate with eqWAlizer for precision

---

## 10. Recommendations for ElixirScope Project

### Strategic Position

**ElixirScope would be the FIRST Code Property Graph implementation for Elixir/Erlang.**

### Architecture Alignment

Your planned 8-layer architecture aligns well:

```
✅ Layer 2: AST - Parse Elixir/Erlang → Abstract Format
✅ Layer 3: Graph - Build on libgraph (proven algorithms)
✅ Layer 4: CPG - NOVEL: First CPG for BEAM!
✅ Layer 5: Analysis - Architectural patterns, security
✅ Layer 6: Capture - Runtime instrumentation (ex_dbg integration?)
✅ Layer 7: Intelligence - AI-assisted analysis
✅ Layer 8: Debugger - Time-travel debugging
```

### Key Differentiators

1. **First-mover**: No existing CPG for Elixir
2. **BEAM-native**: Designed for functional/concurrent paradigm
3. **Unified platform**: Static + dynamic analysis
4. **OTP-aware**: Understand supervision trees, GenServers, etc.

### Technical Recommendations

#### 1. CPG Construction Strategy

```elixir
# AST Layer → Parse both Elixir and Erlang
Code.string_to_quoted!()  # Elixir
:erl_parse.parse_form()   # Erlang Abstract Format

# Graph Layer → Use libgraph + custom extensions
{:libgraph, "~> 0.16"}  # Proven algorithms
CustomCPG.Builder        # BEAM-specific graph types

# CPG Layer → Build unified graph
- AST nodes → Graph vertices
- Relationships → Graph edges
- Properties → Vertex/edge metadata

# Edge Types
:ast_child        # AST parent-child
:control_flow     # Execution order
:data_flow        # Variable dependencies
:call             # Function calls
:message_flow     # Process messages (UNIQUE to BEAM!)
:supervision      # OTP supervision (UNIQUE!)
```

#### 2. Leverage Existing Tools

- **Dialyzer**: Extract success types for nodes
- **Compiler Tracers**: Track compile-time dependencies
- **ElixirSense**: Extract context for IDE features
- **RefactorErl**: Study SPG design (don't reinvent)

#### 3. Novel BEAM-Specific Features

```elixir
# Message Flow Edges (Actor Model)
send(pid, msg)  →  CPG.add_edge(sender_node, receiver_node, :message_flow)

# Supervision Edges (OTP)
Supervisor.start_child()  →  CPG.add_edge(supervisor, child, :supervises)

# Behavior Callbacks (OTP)
GenServer.handle_call()  →  CPG.add_edge(caller, callback, :otp_callback)
```

#### 4. Integration with ex_dbg

The **ex_dbg** runtime debugger could feed data to **elixir_scope** CPG:

```
ex_dbg (runtime) → captures actual message flows, state changes
    ↓
elixir_scope CPG (static) → validates against expected behavior
    ↓
Intelligence Layer → detects anomalies (actual vs. expected)
```

### Competitive Analysis

| Project | Type | Focus | Status | Overlap |
|---------|------|-------|--------|---------|
| **Credo** | Linter | Code style | ✅ Mature | Low (complementary) |
| **Dialyzer** | Type checker | Bug detection | ✅ Mature | Medium (type analysis) |
| **Sobelow** | Security | Phoenix vulns | ✅ Active | High (security analysis) |
| **RefactorErl** | Refactoring | SPG + queries | 🟡 Academic | **HIGH (direct competitor)** |
| **InfERL** | Static analysis | Reliability | ✅ WhatsApp | Low (not open-sourced) |
| **ex_dbg** | Runtime debug | Live inspection | ✅ Your project | Low (complementary) |
| **elixir_scope** | CPG platform | Everything | 🔴 Planning | **UNIQUE (no CPG exists!)** |

### Market Opportunity

1. **Security companies** need BEAM-specific SAST tools
2. **Large Elixir shops** (Discord, WhatsApp, Pinterest) need code intelligence at scale
3. **Consultancies** need architectural analysis tools
4. **Academia** needs research platform for functional language analysis

### Risks & Challenges

1. **Scope creep**: 54k LOC reference implementation is massive
2. **Metaprogramming**: Hard to analyze statically
3. **Adoption**: Developers might stick with Credo + Dialyzer
4. **Maintenance**: Keeping up with Elixir language evolution

### Mitigation Strategy

1. **Phase 1**: Build minimal CPG (AST + Graph + basic CPG)
2. **Phase 2**: Add one killer feature (e.g., security dataflow analysis)
3. **Phase 3**: Prove value with real-world case studies
4. **Phase 4**: Scale to full 8-layer architecture

---

## 11. Conclusion

### Key Findings

1. **No CPG exists for Elixir/Erlang** - virgin territory!
2. **RefactorErl has SPG** - closest equivalent, but academic/limited
3. **BEAM ecosystem uses alternative approaches** - success typing, gradual typing
4. **Recent innovation** (2022-2024): eqWAlizer, InfERL, official type system
5. **Gap**: Security dataflow analysis, architectural patterns, code querying

### Strategic Recommendation

**BUILD IT!** ElixirScope has a unique opportunity to be the first comprehensive CPG-based code intelligence platform for Elixir/Erlang.

**Focus Areas:**
1. ✅ Novel CPG construction for functional/concurrent paradigm
2. ✅ Security analysis (dataflow, taint tracking)
3. ✅ OTP-aware architectural analysis
4. ✅ Integration with existing tools (Dialyzer, Credo)
5. ✅ Runtime correlation (merge with ex_dbg?)

**Avoid:**
1. ❌ Reinventing type checking (use Dialyzer/eqWAlizer)
2. ❌ Linting rules (Credo does this well)
3. ❌ Trying to be 100% accurate with metaprogramming

### Next Steps

1. **Validate assumptions**: Interview Elixir developers about pain points
2. **Prototype CPG**: Build minimal proof-of-concept (AST → Graph → CPG)
3. **Pick one killer feature**: E.g., "Find all SQL injection vulnerabilities"
4. **Partner with RefactorErl team**: Learn from their SPG experience
5. **Publish research**: Establish academic credibility

---

## References

### Tools & Projects
- Joern: https://joern.io
- Credo: https://github.com/rrrene/credo
- Dialyzer: https://www.erlang.org/doc/apps/dialyzer/
- eqWAlizer: https://github.com/WhatsApp/eqwalizer
- Gradualizer: https://github.com/josefs/Gradualizer
- Etylizer: https://github.com/etylizer/etylizer
- RefactorErl: https://plc.inf.elte.hu/erlang/
- InfERL: Research paper (ACM SIGPLAN 2022)
- Concuerror: https://concuerror.com
- libgraph: https://github.com/bitwalker/libgraph

### Recent Papers
- arXiv:2408.14345 - Guard Analysis and Safe Erasure Gradual Typing (2024)
- arXiv:2302.12783 - Set-theoretic Types for Erlang (2023)
- ACM SIGPLAN Erlang Workshop - InfERL (2022)
- ACM SIGPLAN Erlang Workshop - Comparative Type Checkers (2024)

### Official Documentation
- Elixir Language Server: https://elixir-lang.org/blog/2024/08/15/welcome-elixir-language-server-team/
- Elixir v1.18: https://elixir-lang.org/blog/2024/12/19/elixir-v1-18-0-released/
- Erlang Abstract Format: https://www.erlang.org/doc/apps/erts/absform.html
- Mix Compiler Tracers: https://hexdocs.pm/mix/Mix.Tasks.Compile.Elixir.html

---

**End of Research Report**
