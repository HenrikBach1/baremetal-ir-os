# Intermediate Representation (IR) Design

Our custom IR serves as the foundation for all code execution in the Baremetal IR OS, providing a platform-independent representation that can be dynamically optimized.

## IR Format Overview

The IR uses a hybrid design combining aspects of:
- Static Single Assignment (SSA) form for data flow tracking
- Control flow graphs for representing program structure
- Type information for optimization and safety

## Core IR Instructions

### Memory Operations
- `load <type> <address> -> <result>`
- `store <type> <value> <address>`
- `alloc <type> <size> -> <result>`
- `free <address>`

### Arithmetic Operations
- `add <type> <op1> <op2> -> <result>`
- `sub <type> <op1> <op2> -> <result>`
- `mul <type> <op1> <op2> -> <result>`
- `div <type> <op1> <op2> -> <result>`

### Control Flow
- `branch <condition> <true_label> <false_label>`
- `jump <label>`
- `call <function> <args...> -> <result>`
- `return <value>`

## Type System

The IR includes a comprehensive type system:
- Primitive types (int32, int64, float32, float64, etc.)
- Pointer types with metadata for memory management
- Structure types for complex data organization
- Function types with parameter and return information

## IR Metadata

Instructions can include metadata for:
- Optimization hints
- Debug information
- Safety checks
- Hardware-specific directives

