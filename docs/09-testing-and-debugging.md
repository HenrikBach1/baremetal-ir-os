# Testing and Debugging

The Baremetal IR OS project employs comprehensive testing and debugging strategies to ensure reliability and facilitate development.

## 1. Testing Framework

### 1.1. Unit Testing
- Each component has dedicated unit tests
- Mocking framework for hardware dependencies
- Automated test runs on each commit

### 1.2. Integration Testing
- Full-system tests in emulated environments
- Hardware-in-the-loop testing for supported platforms
- Performance benchmarking suite

### 1.3. Test Organization
- `tests/unit/` - Component-level tests
- `tests/integration/` - System-level tests
- `tests/performance/` - Performance benchmarks
- `tests/platforms/` - Platform-specific tests

## 2. Running Tests

```bash
# Run all tests
cd build
make test

# Run specific test suite
ctest -R UnitTests

# Run with verbose output
ctest -V -R IntegrationTests
```

## 3. Debugging Tools

### 3.1. Trace and Logging
- Runtime configurable log levels
- Component-specific log channels
- Performance tracing infrastructure

### 3.2. Debugger Integration
- GDB server support for remote debugging
- JTAG interface for hardware debugging
- IR-level debugging with source mapping

### 3.3. Memory Analysis
- Memory leak detection
- Heap profiling
- Memory access validation

## 4. Debugging Process

### 4.1. System-Level Debugging
1. Enable verbose logging with `--log-level=debug`
2. Capture boot sequence with `--trace-boot`
3. Use the integrated debugger with `--debug-port=1234`
4. Connect with GDB: `gdb -ex "target remote localhost:1234"`

### 4.2. IR Debugging
1. Compile with debug info: `--ir-debug-info`
2. Use the IR debugger: `ir-debug program.ir`
3. Set breakpoints on IR instructions
4. Inspect IR state during execution

### 4.3. JIT Debugging
1. Enable JIT debugging with `--jit-debug`
2. Dump generated code with `--dump-jit-code=file.asm`
3. Use the JIT profiler with `--jit-profile`
4. Analyze hotspots with `analyze-jit-profile results.prof`

## 5. Issue Reporting

When reporting issues, please include:
1. Detailed description of the problem
2. Steps to reproduce
3. System configuration
4. Relevant logs and debug output
5. Expected vs. actual behavior

