# Custom IR Specification

This document defines the custom intermediate representation (IR) designed for the bare-metal JIT-based OS project. The IR incorporates the best features of LLVM, WebAssembly, and Cranelift.

---

## 1. Design Goals

- **SSA Form**: Like LLVM and Cranelift, all variables are in Static Single Assignment form.
- **Structured Control Flow**: Inspired by WebAssembly for predictability and safety.
- **Explicit Memory Model**: Linear memory with controlled access (Wasm style).
- **JIT-Friendly Encoding**: Compact and simple for fast decoding and code generation.
- **Extensibility**: Support for metadata, debugging, and future extensions.

---

## 2. Module Structure

```
.module kernel
.import write_serial(u8) -> void

.func start():
    %0 = const.u8 42
    call write_serial(%0)
    loop:
        br loop
.end
```

### Components
- `.module`: Defines the IR module.
- `.import`: Declares external functions or system calls.
- `.func`: Declares a function with an entry point.
- `const`, `call`, `br`: Basic instructions.

---

## 3. Type System

| Type   | Description          |
|--------|----------------------|
| `u8`   | 8-bit unsigned int   |
| `u32`  | 32-bit unsigned int  |
| `ptr`  | Pointer to memory    |
| `bool` | Boolean              |

Future support for structs, vectors, and metadata is planned.

---

## 4. Instructions

### Arithmetic & Constants
- `const.u8`, `add.u32`, `sub.u32`, `mul.u32`

### Memory
- `load.ptr`, `store.ptr`, `mem.alloc`, `mem.free`

### Control Flow
- `br`, `br_if`, `loop`, `return`, `call`

### Syscalls / Imports
- `call write_serial(%val)`

---

## 5. Memory Model

- **Linear Memory**: Defined like in WebAssembly.
- **No implicit pointers**: All memory access is explicit and bounds-checked.
- **MMIO Access**: Can be implemented using `mmio.read`, `mmio.write`.

---

## 6. Safety Features

- No arbitrary jumps or pointer arithmetic.
- All operations type-checked at JIT time.
- Memory sandboxing per module.

---

## 7. Execution Model

- JIT compiles each function on first call (lazy JIT).
- System starts from `.func start()`.
- Imports are resolved by the JIT host (shim layer).

---

## 8. Comparison Summary

| Feature              | LLVM     | Wasm     | Cranelift | Custom IR |
|----------------------|----------|----------|-----------|------------|
| SSA Form             | ✔        | ✖        | ✔         | ✔          |
| Structured Control   | ✖        | ✔        | ✔         | ✔          |
| Linear Memory        | ✖        | ✔        | ✔         | ✔          |
| Hardware Extensions  | ✖ Native | ✖ Needs Shims | ✖ Needs Shims | ✔ Direct |
| JIT Simplicity       | ✖ Heavy  | ✔ Medium | ✔ Fast    | ✔ Tuned    |

---

## 9. Why Use an Explicit Memory Model?

An explicit memory model means all memory operations are represented as IR instructions—there is no implicit pointer manipulation.

### Benefits

#### 1. Safety by Design
- Eliminates raw pointers and unchecked dereferencing.
- Enables strong guarantees around memory access.

#### 2. Better JIT Control
- Memory access is visible to the JIT for runtime safety and optimizations.

#### 3. Portability
- Target-agnostic model makes it easier to JIT on multiple architectures.

#### 4. Hardware-Friendly
- Clear memory-mapped I/O via explicit `mmio.load`, `mmio.store`.

#### 5. Module Isolation
- Memory can be sandboxed on a per-module basis.
- No hidden aliasing or cross-module access.

#### 6. Tooling & Verification
- Makes IR easier to analyze, simulate, and verify.
- Reduces chances of memory bugs and undefined behavior.

### Comparison with Implicit Models

| Feature                  | Implicit (C-style) | Explicit (This IR)         |
|--------------------------|--------------------|-----------------------------|
| Pointer safety           | ❌ Unsafe           | ✅ Checked and controlled    |
| Verifiability            | ❌ Difficult        | ✅ Easier with clear ops     |
| Debugging                | ⚠️ Complex          | ✅ Transparent               |
| Portability              | ⚠️ Platform-tied    | ✅ ISA-independent           |
| Memory bugs              | ❌ Frequent         | ✅ Largely prevented         |

### Example

**Implicit Memory Model (C-style):**
```c
int* p = get_ptr();
*p = 42; // assumes p is valid
```

**Explicit Memory Model (Custom IR):**
```ir
%ptr = mem.alloc 4
store.u32 %ptr, 42
```

By enforcing explicit memory operations, the IR maintains a clean and safe abstraction barrier between modules and hardware.

---

## 10. Translating Linear Memory Model to Native Memory and MMIO

### What is the Linear Memory Model?

The linear memory model treats memory as a contiguous, byte-addressable array. This is simple, predictable, and easy to sandbox. Inspired by WebAssembly, this model allows our IR to operate on a well-defined virtual memory space.

### Why It's Chosen

- Encourages deterministic memory access
- Easy to implement and simulate
- Aligns with sandboxed and modular execution
- Simplifies memory safety enforcement

---

### Mapping to Complex Native Memory Architectures

Real hardware does not always present a flat linear memory space. Here's how our IR and JIT translate between them:

#### 1. Memory Segmentation

Native systems often split memory into:
- Stack, heap, data, text (code) sections
- Special-purpose memory (e.g., BIOS, DMA, GPU)

**IR Handling:**  
The JIT or runtime assigns ranges in the linear memory space to correspond to these segments. Example:
```text
0x00000000 - 0x0000FFFF → Stack
0x00010000 - 0x001FFFFF → Heap
```

#### 2. Virtual Memory

IR doesn’t assume an MMU. If an MMU exists, the JIT/runtime may:
- Allocate real pages per IR segment
- Insert page faults or protection hooks
- Emulate access violations for debugging

#### 3. MMIO (Memory-Mapped I/O)

IR instructions never access MMIO regions directly via raw pointers. Instead, the IR uses **explicit instructions**:

```ir
mmio.write 0xF0000000, 0x01
%data = mmio.read 0xF0000004
```

These are translated by the JIT into:
- Inline hardware-specific instructions (e.g., `str`/`ldr` on ARM)
- Memory barriers or volatile access
- Safe, bound-checked interfaces

This avoids unsafe or accidental interaction with device registers.

---

### Benefits of This Translation Layer

- **Portability**: The same IR binary runs across multiple hardware platforms.
- **Security**: MMIO and native memory are not exposed blindly.
- **Debuggability**: Easy to track which part of memory is accessed.
- **Sandboxing**: Modules cannot reach outside their memory zone.

---

### Summary Table

| Native Feature      | IR Representation       | Translation Strategy              |
|---------------------|--------------------------|-----------------------------------|
| Stack/Heap Segments | Linear memory offsets    | Address ranges within memory pool |
| Virtual Memory      | Not assumed              | JIT manages mapping if needed     |
| MMIO Registers      | `mmio.read/write` ops    | Translated to native access ops   |

This abstraction keeps the IR simple while giving the JIT flexibility to produce efficient, hardware-safe code.

