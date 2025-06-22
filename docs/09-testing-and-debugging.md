# Testing and Debugging

The Baremetal IR OS project employs comprehensive testing and debugging strategies to ensure reliability and facilitate development.

## Testing Framework

### Unit Testing
- Each component has dedicated unit tests
- Mocking framework for hardware dependencies
- Automated test runs on each commit

### Integration Testing
- Full-system tests in emulated environments
- Hardware-in-the-loop testing for supported platforms
- Performance benchmarking suite

### Test Organization
- `tests/unit/` - Component-level tests
- `tests/integration/` - System-level tests
- `tests/performance/` - Performance benchmarks
- `tests/platforms/` - Platform-specific tests

## Running Tests

```bash
# Run all tests
cd build
make test

# Run specific test suite
ctest -R UnitTests

# Run with verbose output
ctest -V -R IntegrationTests
```

## Debugging Tools

### Trace and Logging
- Runtime configurable log levels
- Component-specific log channels
- Performance tracing infrastructure

### Debugger Integration
- GDB server support for remote debugging
- JTAG interface for hardware debugging
- IR-level debugging with source mapping

### Memory Analysis
- Memory leak detection
- Heap profiling
- Memory access validation

## Debugging Process

### System-Level Debugging
1. Enable verbose logging with `--log-level=debug`
2. Capture boot sequence with `--trace-boot`
3. Use the integrated debugger with `--debug-port=1234`
4. Connect with GDB: `gdb -ex "target remote localhost:1234"`

### IR Debugging
1. Compile with debug info: `--ir-debug-info`
2. Use the IR debugger: `ir-debug program.ir`
3. Set breakpoints on IR instructions
4. Inspect IR state during execution

### JIT Debugging
1. Enable JIT debugging with `--jit-debug`
2. Dump generated code with `--dump-jit-code=file.asm`
3. Use the JIT profiler with `--jit-profile`
4. Analyze hotspots with `analyze-jit-profile results.prof`

## Issue Reporting

When reporting issues, please include:
1. Detailed description of the problem
2. Steps to reproduce
3. System configuration
4. Relevant logs and debug output
5. Expected vs. actual behavior

