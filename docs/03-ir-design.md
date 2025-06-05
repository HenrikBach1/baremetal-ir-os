# Intermediate Representation (IR) Design

## Format Selection

This project requires an intermediate representation (IR) suitable for OS-level abstractions, real-time execution, and JIT compilation in a constrained bare-metal environment. Here are the primary candidates:

### 1. LLVM IR
**Pros:**
- Mature ecosystem
- Rich type system and metadata
- Strong optimization passes
- Large community and tool support

**Cons:**
- Not designed for minimal or bare-metal use
- Complex and heavyweight
- IR closely tied to host target

### 2. WebAssembly (Wasm)
**Note on "Needs shims":**
WebAssembly is sandboxed and lacks direct access to system-level features like memory-mapped I/O or interrupts. A shim is a host-side function or runtime adapter that bridges this gap, exposing hardware functionality via controlled interfaces.

Example:
```c
// Provided by the host runtime
extern void write_serial(char c);
```

**Pros:**
- Safe by design (no arbitrary memory access)
- Portable binary format
- Strong sandboxing and linear memory model
- Designed for near-native performance

**Cons:**
- Limited system-level primitives (e.g., no direct memory-mapped I/O)
- Requires extensions or shims for hardware access
- Minimal standard library

### 3. Cranelift IR
**Note on "Needs shims":**
Cranelift IR is designed for fast JIT compilation of high-level languages but does not directly support hardware features. Like Wasm, it relies on runtime "shims" to expose bare-metal functionality.

Example:
```rust
// Shim implemented in the runtime
fn irq_enable(line: u8) { /* platform-specific implementation */ }
```

**Pros:**
- Designed for fast, minimal JIT compilation
- Simpler than LLVM IR
- Well-suited for dynamic languages and secure execution

**Cons:**
- Less mature and flexible than LLVM
- Fewer optimization capabilities
- Small community and fewer backends

### 4. Custom IR
**Pros:**
- Tailored to exact OS/kernel needs
- Lightweight and minimal
- Easier to secure or verify

**Cons:**
- Requires tooling from scratch
- Lacks external ecosystem
- Debugging and introspection harder

## Extensions Required

Regardless of the chosen IR, the following extensions or capabilities are necessary:

- **System Calls Interface**: Primitive to invoke JIT/syscall layer
- **Hardware IO Primitives**: Support for MMIO and interrupts
- **Memory Management**: Allocate/free memory from IR
- **Atomic Operations**: Basic concurrency support

## Safety & Verification

A strong advantage of using IR is the ability to enforce safety and verification:

- **Type-safety**: Reduce undefined behavior
- **Static Analyzability**: Easier reasoning for memory and control flow
- **Deterministic Execution**: Favor reproducibility and verifiability

## Evaluation Summary

| IR           | Size | Tooling | Safety | HW Integration | Maturity |
|--------------|------|---------|--------|----------------|----------|
| LLVM IR      | ✖ Large | ✔ Excellent | ✔ Strong | ✖ Weak (complex) | ✔ High |
| Wasm         | ✔ Small | ✔ Good | ✔ Strong | ✖ Needs shims (see note) | ✔ High |
| Cranelift IR | ✔ Mid  | ✔ Medium | ✔ Medium | ✖ Needs shims (see note) | ✖ Low |
| Custom IR    | ✔ Minimal | ✖ None | ✔ Tunable | ✔ Native-friendly | ✖ Low |

The ideal choice depends on project tradeoffs: LLVM IR for mature toolchain; Wasm for safety; Cranelift for speed; custom IR for control.
For full details, see [`ir-spec.md`](ir-spec.md).
