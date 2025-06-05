# Hardware Integration

## Device Access
- MMIO mapping from IR
- Trap-based I/O
- Interrupt bridging

## Considerations
- Performance of emulated vs native drivers
- Timer and clock abstraction
- Debug output (serial/log buffer)
For how linear memory is translated to native models and MMIO, see Section 10 of [`ir-spec.md`](ir-spec.md).
