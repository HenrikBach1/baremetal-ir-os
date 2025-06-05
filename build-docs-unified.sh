#!/bin/bash
# build-docs-unified.sh - Driver script for all document formatters
# Created on June 5, 2025

set -e

# Default settings
OUTPUT_BASENAME="baremetal-ir-os"
DOCS_DIR="docs"
VERBOSE=false
ADD_SECTION_NUMBERS=false
FORMATS=("html" "pdf")  # Default formats to generate
SINGLE_FILE=""

# Version information
VERSION="1.0.0"
BUILD_DATE=$(date +"%B %d, %Y")

# Print usage information
usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -v, --verbose              Show more detailed output"
  echo "  --version VERSION          Set documentation version (default: $VERSION)"
  echo "  --formats FORMAT[,FORMAT]  Specify output formats (markdown,html,pdf) (default: html,pdf)"
  echo "  --output-name NAME         Set output filename base without extension (default: $OUTPUT_BASENAME)"
  echo "  --output-dir DIRECTORY     Set output directory"
  echo "  --docs-dir DIRECTORY       Set documentation source directory (default: $DOCS_DIR)"
  echo "  --add-section-numbers      Add section numbering to markdown files"
  echo "  --remove-section-numbers   Remove section numbering from markdown files"
  echo "  --single-file FILE         Process a single markdown file instead of the docs directory"
  echo ""
  echo "Examples:"
  echo "  # Generate all formats (markdown, HTML, PDF)"
  echo "  $0 --formats markdown,html,pdf"
  echo ""
  echo "  # Generate only markdown format with section numbers"
  echo "  $0 --formats markdown --add-section-numbers"
  echo ""
  echo "  # Generate PDF for a single file"
  echo "  $0 --formats pdf --single-file your-file.md"
}

# Log function with verbose mode support
log() {
  local level="$1"
  local message="$2"
  
  case $level in
    info)
      if [ "$VERBOSE" = "true" ]; then
        echo "ℹ️ $message"
      fi
      ;;
    success)
      echo "✅ $message"
      ;;
    warning)
      echo "⚠️ $message"
      ;;
    error)
      echo "❌ $message"
      ;;
    *)
      echo "🔄 $message"
      ;;
  esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      usage
      exit 0
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    --formats)
      IFS=',' read -ra FORMATS <<< "$2"
      shift 2
      ;;
    --output-name)
      OUTPUT_BASENAME="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --docs-dir)
      DOCS_DIR="$2"
      shift 2
      ;;
    --add-section-numbers)
      ADD_SECTION_NUMBERS=true
      REMOVE_SECTION_NUMBERS=false
      shift
      ;;
    --remove-section-numbers)
      REMOVE_SECTION_NUMBERS=true
      ADD_SECTION_NUMBERS=false
      shift
      ;;
    --single-file)
      SINGLE_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Set the output directory option string if provided
OUTPUT_DIR_OPT=""
if [ -n "$OUTPUT_DIR" ]; then
  OUTPUT_DIR_OPT="--output-dir $OUTPUT_DIR"
  # Create the directory if it doesn't exist
  if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    log "info" "Created output directory: $OUTPUT_DIR"
  fi
fi

# Set the verbose option string if enabled
VERBOSE_OPT=""
if [ "$VERBOSE" = "true" ]; then
  VERBOSE_OPT="-v"
fi

# Set the section numbering option string if enabled
SECTION_NUMBERS_OPT=""
if [ "$ADD_SECTION_NUMBERS" = "true" ]; then
  SECTION_NUMBERS_OPT="--add-section-numbers"
elif [ "$REMOVE_SECTION_NUMBERS" = "true" ]; then
  SECTION_NUMBERS_OPT="--remove-section-numbers"
fi

# Validate formats
for format in "${FORMATS[@]}"; do
  if [[ ! "$format" =~ ^(markdown|html|pdf)$ ]]; then
    log "error" "Invalid format: $format. Supported formats are: markdown, html, pdf"
    exit 1
  fi
done

# Function to generate markdown documentation
generate_markdown() {
  if [ -n "$SINGLE_FILE" ]; then
    log "error" "The markdown format with --single-file is not supported as it would just be a copy of the input file."
    log "info" "If you want to add section numbering to a single file, use the section-numbers.sh script directly."
    return 1
  fi
  
  log "process" "Generating markdown documentation..."
  
  # Check if build-markdown.sh exists
  if [ ! -f "./build-markdown.sh" ]; then
    log "error" "build-markdown.sh script not found."
    return 1
  fi
  
  # Make sure the script is executable
  chmod +x ./build-markdown.sh
  
  # Build command
  local cmd="./build-markdown.sh $VERBOSE_OPT --version $VERSION --docs-dir $DOCS_DIR"
  
  # Add output file option
  local output_file="${OUTPUT_BASENAME}-full.md"
  if [ -n "$OUTPUT_DIR" ]; then
    output_file="$OUTPUT_DIR/$output_file"
  fi
  cmd="$cmd --output-file $output_file"
  
  # Add section numbering option if requested
  if [ "$ADD_SECTION_NUMBERS" = "true" ]; then
    cmd="$cmd --add-section-numbers"
  fi
  
  # Execute the command
  log "info" "Running: $cmd"
  eval "$cmd"
  
  if [ $? -eq 0 ]; then
    log "success" "Markdown documentation generated successfully: $output_file"
    return 0
  else
    log "error" "Failed to generate markdown documentation."
    return 1
  fi
}

# Function to generate HTML and/or PDF documentation using build-docs.sh
generate_html_pdf() {
  log "process" "Generating HTML/PDF documentation..."
  
  # Check if build-docs.sh exists
  if [ ! -f "./build-docs.sh" ]; then
    log "error" "build-docs.sh script not found."
    return 1
  fi
  
  # Make sure the script is executable
  chmod +x ./build-docs.sh
  
  # Build basic command
  local cmd="./build-docs.sh $VERBOSE_OPT --version $VERSION --docs-dir $DOCS_DIR $OUTPUT_DIR_OPT $SECTION_NUMBERS_OPT"
  
  # Add format-specific options
  local generate_html=false
  local generate_pdf=false
  
  for format in "${FORMATS[@]}"; do
    if [ "$format" = "html" ]; then
      generate_html=true
    elif [ "$format" = "pdf" ]; then
      generate_pdf=true
    fi
  done
  
  if [ "$generate_html" = "true" ] && [ "$generate_pdf" = "false" ]; then
    cmd="$cmd --html-only"
  elif [ "$generate_html" = "false" ] && [ "$generate_pdf" = "true" ]; then
    cmd="$cmd --pdf-only"
  fi
  
  # Execute the command
  log "info" "Running: $cmd"
  eval "$cmd"
  
  if [ $? -eq 0 ]; then
    log "success" "HTML/PDF documentation generated successfully"
    return 0
  else
    log "error" "Failed to generate HTML/PDF documentation."
    return 1
  fi
}

# Function to generate documentation for a single file
generate_single_file() {
  log "process" "Generating documentation for single file: $SINGLE_FILE"
  
  # Check if the file exists
  if [ ! -f "$SINGLE_FILE" ]; then
    log "error" "File not found: $SINGLE_FILE"
    return 1
  fi
  
  # Check if build-single-doc.sh exists
  if [ ! -f "./build-single-doc.sh" ]; then
    log "error" "build-single-doc.sh script not found."
    return 1
  fi
  
  # Make sure the script is executable
  chmod +x ./build-single-doc.sh
  
  # Build command
  local cmd="./build-single-doc.sh $VERBOSE_OPT --version $VERSION $SECTION_NUMBERS_OPT"
  
  # Add output directory if specified
  if [ -n "$OUTPUT_DIR" ]; then
    cmd="$cmd --output-dir $OUTPUT_DIR"
  fi
  
  # Add output name if specified
  if [ "$OUTPUT_BASENAME" != "baremetal-ir-os" ]; then
    cmd="$cmd --output-name $OUTPUT_BASENAME"
  fi
  
  # Add format-specific options
  local skip_html=false
  local skip_pdf=false
  
  for format in "${FORMATS[@]}"; do
    if [ "$format" != "html" ]; then
      skip_html=true
    fi
    if [ "$format" != "pdf" ]; then
      skip_pdf=true
    fi
  done
  
  if [ "$skip_html" = "true" ] && [ "$skip_pdf" = "false" ]; then
    cmd="$cmd --pdf-only"
  elif [ "$skip_html" = "false" ] && [ "$skip_pdf" = "true" ]; then
    cmd="$cmd --html-only"
  fi
  
  # Add the file path
  cmd="$cmd $SINGLE_FILE"
  
  # Execute the command
  log "info" "Running: $cmd"
  eval "$cmd"
  
  if [ $? -eq 0 ]; then
    log "success" "Documentation for single file generated successfully"
    return 0
  else
    log "error" "Failed to generate documentation for single file."
    return 1
  fi
}

# Main execution
log "info" "Starting unified documentation build process"
log "info" "Formats: ${FORMATS[*]}"
log "info" "Version: $VERSION"
log "info" "Build Date: $BUILD_DATE"

# Track overall success status
OVERALL_SUCCESS=true

if [ -n "$SINGLE_FILE" ]; then
  # Single file mode
  generate_single_file || OVERALL_SUCCESS=false
else
  # Multiple formats mode
  for format in "${FORMATS[@]}"; do
    case "$format" in
      markdown)
        generate_markdown || OVERALL_SUCCESS=false
        ;;
      html|pdf)
        # We'll handle HTML and PDF together since they use the same script
        if [[ " ${FORMATS[*]} " =~ " html " ]] || [[ " ${FORMATS[*]} " =~ " pdf " ]]; then
          generate_html_pdf
          # Skip processing these formats again
          FORMATS=("${FORMATS[@]/html}")
          FORMATS=("${FORMATS[@]/pdf}")
          break
        fi
        ;;
    esac
  done
fi

if [ "$OVERALL_SUCCESS" = "true" ]; then
  log "success" "Documentation build completed successfully"
  exit 0
else
  log "error" "Documentation build completed with errors"
  exit 1
fi
