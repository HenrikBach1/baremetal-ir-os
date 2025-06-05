# System Architecture

## High-Level Overview

```
[Boot ROM] --> [JIT Runtime] --> [IR OS Kernel] --> [System Services]
```

## Components
- **JIT Runtime**: Translates and executes IR code on-demand.
- **IR OS Kernel**: Implements OS services in an extended IR.
- **Device Interface**: IR drivers or native shims.

## Execution Model
- Bootloader initializes memory
- JIT is started and loads the IR kernel
- System runs entirely in IR domain with runtime translation
For full details, see [`ir-spec.md`](ir-spec.md).
For how linear memory is translated to native models and MMIO, see Section 10 of [`ir-spec.md`](ir-spec.md).
