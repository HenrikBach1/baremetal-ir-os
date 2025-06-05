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

## 📚 Documentation Tools

### Unified Documentation Generator

The simplest way to build documentation in any format:

```bash
# Generate documentation in multiple formats
./build-docs-unified.sh --formats markdown,html,pdf

# Show help and available options
./build-docs-unified.sh --help

# Generate only HTML documentation
./build-docs-unified.sh --formats html

# Generate only PDF documentation
./build-docs-unified.sh --formats pdf

# Generate documentation with section numbering
./build-docs-unified.sh --formats html,pdf --add-section-numbers

# Generate documentation for a single file
./build-docs-unified.sh --formats pdf --single-file your-file.md
```

### Individual Documentation Tools

If you prefer to use the individual documentation tools directly:


### Building Complete Documentation

The project includes a documentation build system that combines all markdown files in the `docs/` directory:

```bash
# Generate both HTML and PDF documentation
./build-docs.sh

# Show help and available options
./build-docs.sh --help

# Generate only HTML documentation
./build-docs.sh --html-only

# Generate only PDF documentation
./build-docs.sh --pdf-only

# Generate documentation with verbose output
./build-docs.sh --verbose

# Add section numbering to markdown files
./build-docs.sh --add-section-numbers

# Remove section numbering from markdown files
./build-docs.sh --remove-section-numbers
```

### Building Consolidated Markdown

To create a single consolidated markdown file from all documentation:

```bash
# Generate a single markdown file combining all docs
./build-markdown.sh

# Show help and available options
./build-markdown.sh --help

# Generate with section numbering
./build-markdown.sh --add-section-numbers

# Specify custom output filename
./build-markdown.sh --output-file custom-name.md

# Generate without table of contents
./build-markdown.sh --no-toc

# Generate without YAML metadata header
./build-markdown.sh --no-metadata
```

### Building Single-File Documentation

For working with standalone markdown files, use the single-file documentation generator:

```bash
# Generate HTML and PDF from baremetal-ir-os.md
./build-single-doc.sh

# Generate for a specific markdown file
./build-single-doc.sh your-file.md

# Show help and available options
./build-single-doc.sh --help

# Specify output name and directory
./build-single-doc.sh --output-dir output --output-name custom-name your-file.md

# Add section numbering to the markdown file
./build-single-doc.sh --add-section-numbers your-file.md

# Remove section numbering from the markdown file
./build-single-doc.sh --remove-section-numbers your-file.md
```

### Installing Documentation Tools

If you're missing required dependencies:

```bash
# Install dependencies for documentation generation
./install-doc-tools.sh
```

### Managing Section Numbering

For easier navigation and referencing, you can add or remove section numbering in markdown files:

```bash
# Add section numbering to a specific file
./section-numbers.sh your-file.md

# Remove section numbering from a specific file
./section-numbers.sh --remove your-file.md

# Add section numbering to all files in docs directory
./section-numbers.sh --all

# Add section numbering to first level headings as well (default starts at H2)
./section-numbers.sh --include-h1 your-file.md

# Show help and available options
./section-numbers.sh --help
```

Section numbering converts headers like:
```markdown
## Architecture
### System Components
```

To numbered headers like:
```markdown
## 1. Architecture
### 1.1. System Components
```

This makes it easier to reference specific sections in discussions and communications.

---

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
