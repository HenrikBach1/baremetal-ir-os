# Custom IR Specification

This document provides a detailed specification of the Intermediate Representation (IR) used in the Baremetal IR OS.

## 1. IR File Format

IR code is stored in text format with the following structure:

```
; Module declaration
module "example_module"

; External declarations
external func @printf(i8*, ...) -> i32

; Global variables
global @counter i32 = 0

; Type definitions
type %person = { i8*, i32 }

; Function definition
func @main() -> i32 {
  ; Basic blocks
  entry:
    %ptr = alloc i32
    store i32 42, %ptr
    %val = load i32, %ptr
    br %val, eq, 42, then, else
    
  then:
    %result = call @compute(i32 %val)
    return i32 %result
    
  else:
    return i32 0
}
```

## 2. Type System

### 2.1. Primitive Types
- `i8`, `i16`, `i32`, `i64`: Integer types of specified bit width
- `u8`, `u16`, `u32`, `u64`: Unsigned integer types
- `f32`, `f64`: Floating-point types
- `bool`: Boolean type (1-bit)
- `void`: Represents no value

### 2.2. Derived Types
- Pointers: `<type>*` (e.g., `i32*`)
- Arrays: `[<size> x <type>]` (e.g., `[10 x i32]`)
- Structures: `{ <type>, <type>, ... }` (e.g., `{ i32, i8* }`)
- Functions: `(<param_types>) -> <return_type>`

## 3. Instructions

### 3.1. Memory Operations
- `%ptr = alloc <type> [, <size>]`: Allocate memory
- `free <ptr>`: Free allocated memory
- `%val = load <type>, <ptr>`: Load value from memory
- `store <type> <val>, <ptr>`: Store value to memory
- `%ptr = getelementptr <type>, <ptr>, <indices...>`: Compute address of structure element

### 3.2. Arithmetic Operations
- `%result = add <type> <op1>, <op2>`: Addition
- `%result = sub <type> <op1>, <op2>`: Subtraction
- `%result = mul <type> <op1>, <op2>`: Multiplication
- `%result = div <type> <op1>, <op2>`: Division
- `%result = rem <type> <op1>, <op2>`: Remainder
- `%result = neg <type> <op>`: Negation

### 3.3. Bitwise Operations
- `%result = and <type> <op1>, <op2>`: Bitwise AND
- `%result = or <type> <op1>, <op2>`: Bitwise OR
- `%result = xor <type> <op1>, <op2>`: Bitwise XOR
- `%result = shl <type> <op>, <bits>`: Shift left
- `%result = shr <type> <op>, <bits>`: Shift right
- `%result = not <type> <op>`: Bitwise NOT

### 3.4. Control Flow
- `br <cond>, <op>, <val>, <true_label>, <false_label>`: Conditional branch
- `jump <label>`: Unconditional jump
- `%result = call <func>(<args>...)`: Function call
- `return <type> <value>`: Return from function
- `unreachable`: Marks unreachable code

### 3.5. Conversion Operations
- `%result = zext <from_type> <value> to <to_type>`: Zero extension
- `%result = sext <from_type> <value> to <to_type>`: Sign extension
- `%result = trunc <from_type> <value> to <to_type>`: Truncation
- `%result = bitcast <from_type> <value> to <to_type>`: Bit pattern reinterpretation
- `%result = inttoptr <int_type> <value> to <ptr_type>`: Integer to pointer conversion
- `%result = ptrtoint <ptr_type> <value> to <int_type>`: Pointer to integer conversion

## 4. Metadata

Instructions and declarations can include metadata:

```
%result = add i32 %a, %b, !debug !1, !optimize !2

!1 = !{!"line", 42, "file.c"}
!2 = !{!"inline"}
```

## 5. Extensions

The IR supports extensions for specialized hardware:

```
; Vector operations
%vec = vload <4 x f32>, %ptr
%result = vadd <4 x f32> %vec1, %vec2

; Custom hardware accelerator
%result = hwaccel "crypto.aes", i8* %data, i64 %len, i8* %key
```

## 6. Binary Format

For efficient storage and transmission, the IR can be serialized to a binary format (BIRF) with the following sections:

1. Header: Magic number, version, module name
2. Type Table: Type definitions
3. Global Variables: Global variable declarations
4. Function Table: Function declarations and signatures
5. Instruction Stream: Serialized instruction sequences
6. Metadata Table: Associated metadata
7. String Table: String constants

