# Developer Notes

This section provides guidance for developers working on the Baremetal IR OS project, including development environment setup, coding standards, and contribution guidelines.

## Development Environment

### Required Tools
- **Compiler Toolchain**: LLVM/Clang 15.0 or later
- **Build System**: CMake 3.21 or later
- **Emulation**: QEMU 7.0 or later for testing
- **Debugger**: GDB with target architecture support
- **Version Control**: Git 2.35 or later

### Setup Instructions
```bash
# Clone repository with submodules
git clone --recursive https://github.com/baremetal-ir-os/core.git
cd core

# Install dependencies (Ubuntu/Debian)
./scripts/install-deps.sh

# Configure build
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Debug ..

# Build the project
make -j$(nproc)
```

## Code Organization

The project follows a modular structure:
- `src/core/` - Core runtime and JIT engine
- `src/hal/` - Hardware abstraction layer
- `src/os/` - OS services and subsystems
- `src/ir/` - IR definition and utilities
- `tools/` - Development and debugging tools
- `tests/` - Test suites
- `docs/` - Documentation

## Coding Standards

- **Language**: Modern C++20 with limited use of platform-specific extensions
- **Style**: Follow the project style guide in `docs/style-guide.md`
- **Documentation**: All public APIs must be documented using Doxygen
- **Testing**: New features require unit tests and integration tests

## Contribution Workflow

1. Create a feature branch from `develop`
2. Implement changes following coding standards
3. Add tests for new functionality
4. Submit a pull request with a detailed description
5. Address review feedback
6. Once approved, changes will be merged to `develop`

## Common Development Tasks

### Adding a New Hardware Platform
1. Create platform-specific HAL implementation in `src/hal/platforms/`
2. Implement required interfaces defined in `src/hal/hal_interfaces.h`
3. Add platform detection to the build system
4. Create platform-specific tests in `tests/platforms/`

### Extending the IR Specification
1. Update IR definition in `src/ir/ir_spec.h`
2. Add validation rules to `src/ir/validator.cpp`
3. Implement interpretation in `src/core/interpreter.cpp`
4. Add code generation in `src/core/jit/codegen/`
5. Update documentation in `docs/ir-spec.md`

