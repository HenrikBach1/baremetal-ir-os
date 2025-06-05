# baremetal-ir-os

A research-driven project exploring the design and implementation of a **bare-metal OS** using a **custom intermediate representation (IR)** as its ISA. This IR is executed via a **JIT compiler** running directly on hardware, inspired by LLVM IR, WebAssembly, and Cranelift.

---

## 📂 Documentation Structure

The following documents are found in the [`docs/`](docs/) folder:

| File                            | Description |
|---------------------------------|-------------|
| [`00-overview.md`](docs/00-overview.md)           | Project overview and goals |
| [`01-motivation.md`](docs/01-motivation.md)         | Why use IR for OS design |
| [`02-architecture.md`](docs/02-architecture.md)       | High-level system architecture |
| [`03-ir-design.md`](docs/03-ir-design.md)          | IR format options, analysis, and justification |
| [`04-jit-engine.md`](docs/04-jit-engine.md)         | JIT design considerations and engine candidates |
| [`05-boot-and-runtime.md`](docs/05-boot-and-runtime.md) | Boot process and runtime initialization |
| [`06-os-subsystem-design.md`](docs/06-os-subsystem-design.md) | Kernel services and system abstractions |
| [`07-hardware-integration.md`](docs/07-hardware-integration.md) | Interfacing with hardware and MMIO |
| [`08-dev-notes.md`](docs/08-dev-notes.md)          | Experimental notes and open design questions |
| [`09-testing-and-debugging.md`](docs/09-testing-and-debugging.md) | Testing strategy and debug tools |
| [`10-roadmap.md`](docs/10-roadmap.md)             | Development milestones and future goals |
| [`ir-spec.md`](docs/ir-spec.md)                   | Custom IR specification (syntax, memory model, MMIO) |

---

## 🚀 Project Goals

- Define a portable, safe, and efficient IR for OS-level development
- Implement a JIT that runs directly on bare-metal and interprets the IR
- Build core kernel features (memory, syscalls, drivers) in IR
- Maintain transparency, verifiability, and modularity throughout

---

## 🔧 Getting Started

This project is still in early design stages. To contribute or explore:

1. Clone the repository:
```bash
git clone https://github.com/HenrikBach1/baremetal-ir-os.git
cd baremetal-ir-os
```

2. Review the [IR Specification](docs/ir-spec.md) and [Architecture](docs/02-architecture.md)

3. Contributions are welcome via PR or issues.

---

## 📚 Building Documentation

The project includes a comprehensive documentation build system that can generate both HTML and PDF documentation from the Markdown source files.

### Prerequisites

- [Pandoc](https://pandoc.org/) is required for documentation generation
- For PDF generation, one of the following is required:
  - [wkhtmltopdf](https://wkhtmltopdf.org/) (recommended)
  - [LaTeX](https://www.latex-project.org/) (best quality, but larger installation)
  - [WeasyPrint](https://weasyprint.org/) (Python-based alternative)

The build script will attempt to install wkhtmltopdf if no PDF converter is found.

### Basic Usage

To build both HTML and PDF documentation:

```bash
./build-docs.sh
```

This will generate:
- `baremetal-ir-os.html` - The complete HTML documentation
- `baremetal-ir-os.pdf` - The complete PDF documentation (if a PDF converter is available)

### Advanced Options

The build script supports several command-line options:

```bash
./build-docs.sh --help
```

Examples:

```bash
# Generate only HTML documentation
./build-docs.sh --html-only

# Generate only PDF documentation with a specific version number
./build-docs.sh --pdf-only --version 1.2.0

# Force using a specific PDF engine
./build-docs.sh --pdf-engine wkhtmltopdf

# Generate documentation with verbose output
./build-docs.sh --verbose
```

---

## 📜 License

See [LICENSE](LICENSE) for details.
