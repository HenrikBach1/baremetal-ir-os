#!/bin/bash
# build-single-doc.sh - Generate HTML and PDF documentation from a single markdown file
# Created on June 5, 2025

set -e

# Default settings
INPUT_FILE="baremetal-ir-os.md"
OUTPUT_HTML="${INPUT_FILE%.md}.html"
OUTPUT_PDF="${INPUT_FILE%.md}.pdf"
DOCS_DIR="docs"
HTML_CSS="${DOCS_DIR}/custom.css"
PDF_CSS="${DOCS_DIR}/pdf-styles.css"
METADATA_FILE="${DOCS_DIR}/metadata.yaml"
LOG_FILE="single_doc_generation.log"
VERBOSE=false

# Version information
VERSION="1.0.0"
BUILD_DATE=$(date +"%B %d, %Y")

# Command line options
SKIP_HTML=false
SKIP_PDF=false
FORCE_PDF_ENGINE=""
VERBOSE=false
ADD_SECTION_NUMBERS=false
REMOVE_SECTION_NUMBERS=false

# Print usage information
usage() {
  echo "Usage: $0 [options] [input-file]"
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -v, --verbose              Show more detailed output"
  echo "  --version VERSION          Set documentation version (default: $VERSION)"
  echo "  --skip-html                Skip HTML generation"
  echo "  --skip-pdf                 Skip PDF generation"
  echo "  --html-only                Generate only HTML (not PDF)"
  echo "  --pdf-only                 Generate only PDF (not HTML)"
  echo "  --pdf-engine ENGINE        Force specific PDF engine (wkhtmltopdf, pdflatex, weasyprint)"
  echo "  --output-dir DIRECTORY     Set output directory"
  echo "  --output-name NAME         Set output filename (without extension)"
  echo "  --add-section-numbers      Add section numbering to the markdown file"
  echo "  --remove-section-numbers   Remove section numbering from the markdown file"
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
    --skip-html)
      SKIP_HTML=true
      shift
      ;;
    --skip-pdf)
      SKIP_PDF=true
      shift
      ;;
    --html-only)
      SKIP_PDF=true
      shift
      ;;
    --pdf-only)
      SKIP_HTML=true
      shift
      ;;
    --pdf-engine)
      FORCE_PDF_ENGINE="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --output-name)
      OUTPUT_NAME="$2"
      OUTPUT_HTML="${OUTPUT_NAME}.html"
      OUTPUT_PDF="${OUTPUT_NAME}.pdf"
      shift 2
      ;;
    --add-section-numbers)
      ADD_SECTION_NUMBERS=true
      shift
      ;;
    --remove-section-numbers)
      REMOVE_SECTION_NUMBERS=true
      shift
      ;;
    *)
      # If this is the last argument and it's not an option, assume it's the input file
      if [[ $# -eq 1 && ! $1 == -* ]]; then
        INPUT_FILE="$1"
        OUTPUT_HTML="${INPUT_FILE%.md}.html"
        OUTPUT_PDF="${INPUT_FILE%.md}.pdf"
        
        # If output name is set, use that instead
        if [ -n "$OUTPUT_NAME" ]; then
          OUTPUT_HTML="${OUTPUT_NAME}.html"
          OUTPUT_PDF="${OUTPUT_NAME}.pdf"
        fi
      else
        echo "Unknown option: $1"
        usage
        exit 1
      fi
      shift
      ;;
  esac
done

# Apply output directory if specified
if [ -n "$OUTPUT_DIR" ]; then
  # Create output directory if it doesn't exist
  if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
  fi
  
  # Update output paths
  OUTPUT_HTML="$OUTPUT_DIR/$(basename "$OUTPUT_HTML")"
  OUTPUT_PDF="$OUTPUT_DIR/$(basename "$OUTPUT_PDF")"
fi

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
  log "error" "Input file '$INPUT_FILE' does not exist."
  exit 1
fi

# Check for required dependencies
check_dependencies() {
  local missing_deps=()
  
  # Required dependencies
  if ! command -v pandoc >/dev/null 2>&1; then
    missing_deps+=("pandoc")
  fi
  
  # PDF generation dependencies
  if [ "$SKIP_PDF" = "false" ]; then
    if ! command -v wkhtmltopdf >/dev/null 2>&1 && 
       ! command -v pdflatex >/dev/null 2>&1 && 
       ! command -v weasyprint >/dev/null 2>&1; then
      log "warning" "No PDF generation tools found. Will attempt to use a fallback method."
    fi
  fi
  
  # Report missing dependencies
  if [ ${#missing_deps[@]} -gt 0 ]; then
    log "error" "Missing required dependencies: ${missing_deps[*]}"
    log "info" "Please install the missing dependencies and try again."
    
    if [[ " ${missing_deps[*]} " =~ " pandoc " ]]; then
      log "info" "Install pandoc: sudo apt-get install pandoc"
    fi
    
    exit 1
  fi
}

# Generate HTML from markdown
generate_html() {
  log "process" "Generating HTML from '$INPUT_FILE'..."
  
  # Check if metadata file exists
  METADATA_OPTION=""
  if [ -f "$METADATA_FILE" ]; then
    METADATA_OPTION="--metadata-file=$METADATA_FILE"
  fi
  
  # CSS option
  CSS_OPTION=""
  if [ -f "$HTML_CSS" ]; then
    CSS_OPTION="--css=$HTML_CSS"
  fi
  
  # Run pandoc to generate HTML
  pandoc "$INPUT_FILE" \
    $METADATA_OPTION \
    $CSS_OPTION \
    --standalone \
    --toc \
    --toc-depth=3 \
    --highlight-style=tango \
    --variable="date:$BUILD_DATE" \
    --variable="version:$VERSION" \
    -o "$OUTPUT_HTML"
  
  if [ $? -eq 0 ]; then
    log "success" "HTML generated successfully: $OUTPUT_HTML"
    return 0
  else
    log "error" "HTML generation failed"
    return 1
  fi
}

# Generate PDF from HTML using available tools
generate_pdf() {
  log "process" "Generating PDF from '$INPUT_FILE'..."
  
  # Use forced PDF engine if specified
  if [ -n "$FORCE_PDF_ENGINE" ]; then
    log "info" "Using forced PDF engine: $FORCE_PDF_ENGINE"
    generate_pdf_with_engine "$FORCE_PDF_ENGINE"
    return $?
  fi
  
  # Try wkhtmltopdf first
  if command -v wkhtmltopdf >/dev/null 2>&1; then
    log "info" "Using wkhtmltopdf for PDF generation"
    generate_pdf_with_wkhtmltopdf
    if [ $? -eq 0 ]; then
      return 0
    fi
    log "warning" "wkhtmltopdf failed, trying alternative method"
  fi
  
  # Try pdflatex
  if command -v pdflatex >/dev/null 2>&1; then
    log "info" "Using pdflatex for PDF generation"
    generate_pdf_with_pdflatex
    if [ $? -eq 0 ]; then
      return 0
    fi
    log "warning" "pdflatex failed, trying alternative method"
  fi
  
  # Try weasyprint
  if command -v weasyprint >/dev/null 2>&1; then
    log "info" "Using weasyprint for PDF generation"
    generate_pdf_with_weasyprint
    if [ $? -eq 0 ]; then
      return 0
    fi
    log "warning" "weasyprint failed, trying alternative method"
  fi
  
  # If all else fails, try direct pandoc PDF generation
  log "info" "Using pandoc's built-in PDF generation"
  generate_pdf_with_pandoc_direct
  return $?
}

# Generate PDF with wkhtmltopdf
generate_pdf_with_wkhtmltopdf() {
  # Check if HTML output exists, if not, generate it temporarily
  local temp_html=""
  if [ ! -f "$OUTPUT_HTML" ]; then
    temp_html=$(mktemp --suffix=.html)
    generate_html_for_pdf "$temp_html"
    OUTPUT_HTML="$temp_html"
  fi
  
  # Run wkhtmltopdf
  wkhtmltopdf \
    --enable-local-file-access \
    --print-media-type \
    --footer-center "[page] / [topage]" \
    --footer-font-size 9 \
    "$OUTPUT_HTML" \
    "$OUTPUT_PDF" \
    2>> "$LOG_FILE"
  
  local result=$?
  
  # Clean up temporary file if created
  if [ -n "$temp_html" ] && [ -f "$temp_html" ]; then
    rm "$temp_html"
  fi
  
  if [ $result -eq 0 ]; then
    log "success" "PDF generated successfully with wkhtmltopdf: $OUTPUT_PDF"
    return 0
  else
    log "error" "PDF generation with wkhtmltopdf failed"
    return 1
  fi
}

# Generate PDF with pdflatex (via pandoc)
generate_pdf_with_pdflatex() {
  # Use pandoc with pdf engine
  pandoc "$INPUT_FILE" \
    --pdf-engine=pdflatex \
    --metadata-file="$METADATA_FILE" \
    --toc \
    --toc-depth=3 \
    --highlight-style=tango \
    --variable="date:$BUILD_DATE" \
    --variable="version:$VERSION" \
    -o "$OUTPUT_PDF" \
    2>> "$LOG_FILE"
  
  if [ $? -eq 0 ]; then
    log "success" "PDF generated successfully with pdflatex: $OUTPUT_PDF"
    return 0
  else
    log "error" "PDF generation with pdflatex failed"
    return 1
  fi
}

# Generate PDF with weasyprint
generate_pdf_with_weasyprint() {
  # Check if HTML output exists, if not, generate it temporarily
  local temp_html=""
  if [ ! -f "$OUTPUT_HTML" ]; then
    temp_html=$(mktemp --suffix=.html)
    generate_html_for_pdf "$temp_html"
    OUTPUT_HTML="$temp_html"
  fi
  
  # Run weasyprint
  weasyprint "$OUTPUT_HTML" "$OUTPUT_PDF" 2>> "$LOG_FILE"
  
  local result=$?
  
  # Clean up temporary file if created
  if [ -n "$temp_html" ] && [ -f "$temp_html" ]; then
    rm "$temp_html"
  fi
  
  if [ $result -eq 0 ]; then
    log "success" "PDF generated successfully with weasyprint: $OUTPUT_PDF"
    return 0
  else
    log "error" "PDF generation with weasyprint failed"
    return 1
  fi
}

# Generate PDF directly with pandoc
generate_pdf_with_pandoc_direct() {
  pandoc "$INPUT_FILE" \
    --metadata-file="$METADATA_FILE" \
    --toc \
    --toc-depth=3 \
    --highlight-style=tango \
    --variable="date:$BUILD_DATE" \
    --variable="version:$VERSION" \
    -o "$OUTPUT_PDF" \
    2>> "$LOG_FILE"
  
  if [ $? -eq 0 ]; then
    log "success" "PDF generated successfully with pandoc: $OUTPUT_PDF"
    return 0
  else
    log "error" "PDF generation with pandoc failed"
    return 1
  fi
}

# Generate HTML specifically formatted for PDF conversion
generate_html_for_pdf() {
  local output_file="$1"
  
  # Check if metadata file exists
  METADATA_OPTION=""
  if [ -f "$METADATA_FILE" ]; then
    METADATA_OPTION="--metadata-file=$METADATA_FILE"
  fi
  
  # CSS option
  CSS_OPTION=""
  if [ -f "$PDF_CSS" ]; then
    CSS_OPTION="--css=$PDF_CSS"
  fi
  
  # Run pandoc to generate HTML optimized for PDF conversion
  pandoc "$INPUT_FILE" \
    $METADATA_OPTION \
    $CSS_OPTION \
    --standalone \
    --toc \
    --toc-depth=3 \
    --highlight-style=tango \
    --variable="date:$BUILD_DATE" \
    --variable="version:$VERSION" \
    -o "$output_file"
  
  return $?
}

# Generate PDF with specified engine
generate_pdf_with_engine() {
  local engine="$1"
  
  case "$engine" in
    wkhtmltopdf)
      generate_pdf_with_wkhtmltopdf
      return $?
      ;;
    pdflatex)
      generate_pdf_with_pdflatex
      return $?
      ;;
    weasyprint)
      generate_pdf_with_weasyprint
      return $?
      ;;
    *)
      log "error" "Unknown PDF engine: $engine"
      return 1
      ;;
  esac
}

# Main execution
main() {
  log "info" "Starting documentation generation for $INPUT_FILE"
  log "info" "Version: $VERSION"
  log "info" "Build Date: $BUILD_DATE"
  
  # Check dependencies
  check_dependencies
  
  # Create or clear log file
  echo "Documentation generation log - $(date)" > "$LOG_FILE"
  
  # Handle section numbering if requested
  if [ "$ADD_SECTION_NUMBERS" = "true" ]; then
    log "process" "Adding section numbering to $INPUT_FILE..."
    if [ -f "./section-numbers.sh" ]; then
      chmod +x ./section-numbers.sh
      ./section-numbers.sh "$INPUT_FILE" || {
        log "error" "Failed to add section numbering. Continuing without it."
      }
    else
      log "warning" "section-numbers.sh script not found. Skipping section numbering."
    fi
  fi

  if [ "$REMOVE_SECTION_NUMBERS" = "true" ]; then
    log "process" "Removing section numbering from $INPUT_FILE..."
    if [ -f "./section-numbers.sh" ]; then
      chmod +x ./section-numbers.sh
      ./section-numbers.sh --remove "$INPUT_FILE" || {
        log "error" "Failed to remove section numbering. Continuing anyway."
      }
    else
      log "warning" "section-numbers.sh script not found. Skipping section numbering removal."
    fi
  fi
  
  # Generate HTML
  if [ "$SKIP_HTML" = "false" ]; then
    generate_html
  else
    log "info" "Skipping HTML generation"
  fi
  
  # Generate PDF
  if [ "$SKIP_PDF" = "false" ]; then
    generate_pdf
  else
    log "info" "Skipping PDF generation"
  fi
  
  log "success" "Documentation generation completed"
}

# Run the main function
main

exit 0
