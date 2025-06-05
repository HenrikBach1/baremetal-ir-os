# JIT Engine Design

## Requirements
- Bare-metal operation
- IR decoding and codegen
- Memory allocator for code and data

## Strategy
- Static + lazy JIT modes
- In-place or trampoline execution
- Embedded minimal allocator

## Tools Considered
- LLVM MCJIT / ORC JIT
- Cranelift
- Custom lightweight JIT
For full details, see [`ir-spec.md`](ir-spec.md).
For how linear memory is translated to native models and MMIO, see Section 10 of [`ir-spec.md`](ir-spec.md).
