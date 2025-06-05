#!/bin/bash
set -e

# Default settings
OUTPUT_HTML="baremetal-ir-os.html"
OUTPUT_PDF="baremetal-ir-os.pdf"
PANDOC_INCLUDE_FILE="baremetal-ir-os-pandoc-include.md"
DOCS_DIR="docs"
PDF_GENERATED=false
HTML_CSS="${DOCS_DIR}/custom.css"
PDF_CSS="${DOCS_DIR}/pdf-styles.css"
METADATA_FILE="${DOCS_DIR}/metadata.yaml"
TEMP_HTML="temp_output.html"
LOG_FILE="pdf_generation.log"

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
  echo "Usage: $0 [options]"
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
  echo "  --docs-dir DIRECTORY       Set documentation source directory (default: $DOCS_DIR)"
  echo "  --add-section-numbers      Add section numbering to markdown files"
  echo "  --remove-section-numbers   Remove section numbering from markdown files"
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
      OUTPUT_HTML="$OUTPUT_DIR/$(basename "$OUTPUT_HTML")"
      OUTPUT_PDF="$OUTPUT_DIR/$(basename "$OUTPUT_PDF")"
      shift 2
      ;;
    --docs-dir)
      DOCS_DIR="$2"
      HTML_CSS="${DOCS_DIR}/custom.css"
      PDF_CSS="${DOCS_DIR}/pdf-styles.css"
      METADATA_FILE="${DOCS_DIR}/metadata.yaml"
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
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Create output directory if specified and doesn't exist
if [ -n "$OUTPUT_DIR" ] && [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
fi

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
      log "warning" "No PDF generation tools found. Will attempt to install one."
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

# Check if we need to install a PDF converter
ensure_pdf_converter() {
  if ! command -v wkhtmltopdf >/dev/null 2>&1 && 
     ! command -v pdflatex >/dev/null 2>&1 && 
     ! command -v weasyprint >/dev/null 2>&1; then
    log "process" "No PDF converter found. Attempting to install wkhtmltopdf..."
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update && sudo apt-get install -y wkhtmltopdf
    elif command -v brew >/dev/null 2>&1; then
      brew install wkhtmltopdf
    elif command -v pip >/dev/null 2>&1; then
      pip install weasyprint
    else
      log "warning" "Unable to install PDF converter automatically. PDF generation may fail."
    fi
  fi
}

# Function to generate the metadata file
generate_metadata_file() {
  local metadata_file="$1"
  local version="$2"
  local build_date="$3"
  
  log "process" "Generating metadata file..."
  
  cat > "$metadata_file" << EOF
---
title: "Baremetal IR OS Documentation"
author: "Henrik Bach"
date: "$build_date"
subtitle: "A Comprehensive Guide (v$version)"
abstract: |
  This documentation covers the design, architecture, and implementation of the Baremetal IR OS.
  It provides detailed information about the intermediate representation (IR) design, JIT engine,
  operating system subsystems, hardware integration, and development notes.
  
  Version: $version
  Build Date: $build_date
geometry: "margin=1in"
fontsize: 11pt
mainfont: "DejaVu Serif"
monofont: "DejaVu Sans Mono"
lang: "en-US"
colorlinks: true
linkcolor: "blue"
urlcolor: "blue"
toc-depth: 3
secnumdepth: 3
header-includes:
  - \usepackage{fancyhdr}
  - \pagestyle{fancy}
  - \fancyhead[RE,RO]{\rightmark}
  - \fancyfoot[C]{Page \thepage}
---
EOF
  
  log "success" "Generated $metadata_file with version $version"
}

# Function to generate the pandoc include file automatically
generate_pandoc_include_file() {
  local include_file="$1"
  local docs_dir="$2"
  
  log "process" "Generating pandoc include file..."
  
  # Create the header with metadata
  cat > "$include_file" << EOFMD
---
title: "Baremetal IR OS Documentation"
author: "Henrik Bach"
date: "$(date +"%B %Y")"
---

EOFMD

  # Add numbered docs in order (00-xx through 10-xx)
  for i in $(seq -f "%02g" 0 10); do
    for doc in "$docs_dir"/"$i"-*.md; do
      if [ -f "$doc" ]; then
        # Extract section title from file (first heading)
        title=$(grep -m 1 "^# " "$doc" | sed 's/^# //')
        
        # Add section title comment and file content
        echo "<!-- Section: $title -->" >> "$include_file"
        cat "$doc" | grep -v "^<!--" | tail -n+2 >> "$include_file"
        echo -e "\n\n" >> "$include_file"
        
        if [ "$VERBOSE" = "true" ]; then
          log "info" "Added content from $(basename "$doc")"
        fi
      fi
    done
  done
  
  # Add any special docs (like ir-spec.md) that don't follow the numbering scheme
  for doc in "$docs_dir"/*.md; do
    # Skip the numbered docs we've already processed
    if [[ ! $(basename "$doc") =~ ^[0-9]+-.*\.md$ ]]; then
      # Skip metadata file
      if [[ $(basename "$doc") != "metadata.yaml" ]]; then
        # Extract section title from file (first heading)
        title=$(grep -m 1 "^# " "$doc" | sed 's/^# //')
        
        # Add section title comment and file content
        echo "<!-- Section: $title -->" >> "$include_file"
        cat "$doc" | grep -v "^<!--" | tail -n+2 >> "$include_file"
        echo -e "\n\n" >> "$include_file"
        
        if [ "$VERBOSE" = "true" ]; then
          log "info" "Added content from $(basename "$doc")"
        fi
      fi
    fi
  done
  
  # Also generate a TOC file for reference
  toc_file="${include_file%.md}-toc.md"
  echo "# Table of Contents" > "$toc_file"
  echo "" >> "$toc_file"
  
  # Extract all the section titles from the include file
  grep "<!-- Section:" "$include_file" | sed 's/<!-- Section: \(.*\) -->/- \1/' >> "$toc_file"
  
  log "success" "Generated $include_file with content from $docs_dir"
  log "success" "Generated $toc_file with table of contents"
}

# Function to handle the PDF generation
generate_pdf() {
  local method="$1"
  local command="$2"
  
  log "process" "Trying $method..."
  echo "Attempting PDF generation with $method at $(date)" >> "$LOG_FILE"
  
  if eval "$command" >> "$LOG_FILE" 2>&1; then
    log "success" "$OUTPUT_PDF successfully generated using $method"
    echo "PDF successfully generated with $method at $(date)" >> "$LOG_FILE"
    PDF_GENERATED=true
    return 0
  else
    log "warning" "PDF generation with $method failed. See $LOG_FILE for details."
    echo "PDF generation failed with $method at $(date)" >> "$LOG_FILE"
    echo "--- Command output ---" >> "$LOG_FILE"
    return 1
  fi
}

# Check dependencies first
check_dependencies

# Handle section numbering if requested
if [ "$ADD_SECTION_NUMBERS" = "true" ]; then
  log "process" "Adding section numbering to markdown files..."
  if [ -f "./section-numbers.sh" ]; then
    chmod +x ./section-numbers.sh
    ./section-numbers.sh --all --docs-dir "$DOCS_DIR" || {
      log "error" "Failed to add section numbering. Continuing without it."
    }
  else
    log "warning" "section-numbers.sh script not found. Skipping section numbering."
  fi
fi

if [ "$REMOVE_SECTION_NUMBERS" = "true" ]; then
  log "process" "Removing section numbering from markdown files..."
  if [ -f "./section-numbers.sh" ]; then
    chmod +x ./section-numbers.sh
    ./section-numbers.sh --all --docs-dir "$DOCS_DIR" --remove || {
      log "error" "Failed to remove section numbering. Continuing anyway."
    }
  else
    log "warning" "section-numbers.sh script not found. Skipping section numbering removal."
  fi
fi

# Generate the metadata file
generate_metadata_file "$METADATA_FILE" "$VERSION" "$BUILD_DATE"

# Generate the pandoc include file
generate_pandoc_include_file "$PANDOC_INCLUDE_FILE" "$DOCS_DIR"

# Ensure we have a PDF converter if needed
if [ "$SKIP_PDF" = "false" ]; then
  ensure_pdf_converter
fi

# Generate HTML
if [ "$SKIP_HTML" = "false" ]; then
  log "process" "Generating HTML..."
  pandoc "$PANDOC_INCLUDE_FILE" --metadata-file="$METADATA_FILE" -s --toc --toc-depth=3 --css="$HTML_CSS" -o "$OUTPUT_HTML" && {
    HTML_SIZE=$(du -h "$OUTPUT_HTML" | cut -f1)
    log "success" "$OUTPUT_HTML successfully generated (Size: $HTML_SIZE)"
  } || {
    log "error" "HTML generation failed. Please check pandoc installation."
    exit 1
  }
fi

# Generate PDF - try multiple methods
if [ "$SKIP_PDF" = "false" ]; then
  log "process" "Generating PDF..."

  # Clear any previous log file
  > "$LOG_FILE"

  # If a specific PDF engine is forced, use only that
  if [ -n "$FORCE_PDF_ENGINE" ]; then
    case "$FORCE_PDF_ENGINE" in
      wkhtmltopdf)
        if command -v wkhtmltopdf >/dev/null 2>&1; then
          # First convert to HTML with PDF-specific CSS
          pandoc "$PANDOC_INCLUDE_FILE" --metadata-file="$METADATA_FILE" -s --toc --toc-depth=3 --css="$PDF_CSS" -o "$TEMP_HTML"
          
          # Use wkhtmltopdf with improved options
          generate_pdf "wkhtmltopdf" "wkhtmltopdf --enable-local-file-access --page-size Letter --margin-top 25 --margin-right 20 --margin-bottom 25 --margin-left 20 --encoding utf-8 \"$TEMP_HTML\" \"$OUTPUT_PDF\"" && rm -f "$TEMP_HTML" || rm -f "$TEMP_HTML"
        else
          log "error" "Forced PDF engine wkhtmltopdf not found. Please install it first."
          exit 1
        fi
        ;;
      pdflatex)
        if command -v pdflatex >/dev/null 2>&1; then
          generate_pdf "pdflatex" "pandoc \"$PANDOC_INCLUDE_FILE\" --metadata-file=\"$METADATA_FILE\" -s --toc --toc-depth=3 --css=\"$PDF_CSS\" --pdf-engine=pdflatex -V geometry:margin=1in -o \"$OUTPUT_PDF\""
        else
          log "error" "Forced PDF engine pdflatex not found. Please install it first."
          exit 1
        fi
        ;;
      weasyprint)
        if command -v weasyprint >/dev/null 2>&1; then
          # First convert to HTML with PDF-specific CSS
          pandoc "$PANDOC_INCLUDE_FILE" --metadata-file="$METADATA_FILE" -s --toc --toc-depth=3 --css="$PDF_CSS" -o "$TEMP_HTML"
          
          # Use weasyprint
          generate_pdf "weasyprint" "weasyprint \"$TEMP_HTML\" \"$OUTPUT_PDF\"" && rm -f "$TEMP_HTML" || rm -f "$TEMP_HTML"
        else
          log "error" "Forced PDF engine weasyprint not found. Please install it first."
          exit 1
        fi
        ;;
      *)
        log "error" "Unknown PDF engine: $FORCE_PDF_ENGINE"
        log "info" "Supported engines: wkhtmltopdf, pdflatex, weasyprint"
        exit 1
        ;;
    esac
  else
    # Try auto-detected methods in preferred order
    
    # Try wkhtmltopdf first since we know it works
    if command -v wkhtmltopdf >/dev/null 2>&1; then
      # First convert to HTML with PDF-specific CSS
      pandoc "$PANDOC_INCLUDE_FILE" --metadata-file="$METADATA_FILE" -s --toc --toc-depth=3 --css="$PDF_CSS" -o "$TEMP_HTML"
      
      # Use wkhtmltopdf with improved options
      generate_pdf "wkhtmltopdf" "wkhtmltopdf --enable-local-file-access --page-size Letter --margin-top 25 --margin-right 20 --margin-bottom 25 --margin-left 20 --encoding utf-8 \"$TEMP_HTML\" \"$OUTPUT_PDF\"" && rm -f "$TEMP_HTML" || rm -f "$TEMP_HTML"

    # Method 1: Try using LaTeX (best quality)
    elif command -v pdflatex >/dev/null 2>&1; then
      generate_pdf "pdflatex" "pandoc \"$PANDOC_INCLUDE_FILE\" --metadata-file=\"$METADATA_FILE\" -s --toc --toc-depth=3 --css=\"$PDF_CSS\" --pdf-engine=pdflatex -V geometry:margin=1in -o \"$OUTPUT_PDF\""
      
    # Method 3: Try using weasyprint if available
    elif command -v weasyprint >/dev/null 2>&1; then
      # First convert to HTML with PDF-specific CSS
      pandoc "$PANDOC_INCLUDE_FILE" --metadata-file="$METADATA_FILE" -s --toc --toc-depth=3 --css="$PDF_CSS" -o "$TEMP_HTML"
      
      # Use weasyprint
      generate_pdf "weasyprint" "weasyprint \"$TEMP_HTML\" \"$OUTPUT_PDF\"" && rm -f "$TEMP_HTML" || rm -f "$TEMP_HTML"
      
    # Method 4: Try using Pandoc's built-in PDF generation with alternative engines
    else
      for engine in xelatex lualatex tectonic; do
        if command -v $engine >/dev/null 2>&1; then
          if generate_pdf "$engine" "pandoc \"$PANDOC_INCLUDE_FILE\" --metadata-file=\"$METADATA_FILE\" -s --toc --toc-depth=3 --css=\"$PDF_CSS\" --pdf-engine=$engine -V geometry:margin=1in -o \"$OUTPUT_PDF\""; then
            break
          fi
        fi
      done
    fi
  fi

  # If all methods failed, try browser-based fallback
  if [ "$PDF_GENERATED" != "true" ]; then
    log "warning" "PDF generation failed with all available methods."
    log "info" "To enable PDF generation, you can try installing one of these packages:"
    log "info" "1. wkhtmltopdf (recommended): sudo apt-get install wkhtmltopdf"
    log "info" "2. LaTeX (best quality): sudo apt-get install texlive-latex-base texlive-fonts-recommended texlive-fonts-extra texlive-latex-extra"
    log "info" "3. WeasyPrint: pip install weasyprint"
    
    # Generate a simplified PDF as fallback using direct conversion from HTML
    log "process" "Trying to create a simple PDF from HTML as fallback..."
    if [ -f "$OUTPUT_HTML" ]; then
      OUTPUT_PDF_SIMPLE="${OUTPUT_PDF%.pdf}-simple.pdf"
      
      # Try Chrome/Chromium first with better options
      for browser in google-chrome chrome chromium chromium-browser; do
        if command -v $browser >/dev/null 2>&1; then
          log "info" "Using $browser for fallback PDF generation..."
          $browser --headless --disable-gpu --no-sandbox --print-to-pdf="$OUTPUT_PDF_SIMPLE" "file://$(pwd)/$OUTPUT_HTML" && {
            log "success" "$OUTPUT_PDF_SIMPLE successfully generated as fallback using $browser"
            break
          }
        fi
      done
      
      # Try Firefox if Chrome/Chromium failed
      if [ ! -f "$OUTPUT_PDF_SIMPLE" ] && command -v firefox >/dev/null 2>&1; then
        if command -v xvfb-run >/dev/null 2>&1; then
          xvfb-run firefox -headless -print "file://$(pwd)/$OUTPUT_HTML" -printmode pdf -printfile "$OUTPUT_PDF_SIMPLE" && {
            log "success" "$OUTPUT_PDF_SIMPLE successfully generated as fallback using Firefox"
          }
        else
          # Try Firefox without xvfb if not available
          firefox -headless -print "file://$(pwd)/$OUTPUT_HTML" -printmode pdf -printfile "$OUTPUT_PDF_SIMPLE" && {
            log "success" "$OUTPUT_PDF_SIMPLE successfully generated as fallback using Firefox"
          }
        fi
      fi
      
      # Try using the CUPS-PDF virtual printer if available
      if [ ! -f "$OUTPUT_PDF_SIMPLE" ] && command -v lp >/dev/null 2>&1 && command -v cupsfilter >/dev/null 2>&1; then
        log "info" "Trying CUPS-PDF as last resort..."
        cupsfilter "$OUTPUT_HTML" > "$OUTPUT_PDF_SIMPLE" && {
          log "success" "$OUTPUT_PDF_SIMPLE generated as fallback using CUPS"
        }
      fi
      
      if [ ! -f "$OUTPUT_PDF_SIMPLE" ]; then
        log "warning" "All fallback PDF generation methods failed."
      fi
    fi
  fi
fi

# Generate a summary report
log "success" "Documentation build complete on $(date)!"
echo "=================== Build Summary ==================="

if [ "$SKIP_HTML" = "false" ]; then
  HTML_SIZE=$(du -h "$OUTPUT_HTML" | cut -f1)
  echo " - $OUTPUT_HTML successfully generated (Size: $HTML_SIZE)"
else
  echo " - HTML generation skipped"
fi

if [ "$SKIP_PDF" = "false" ]; then
  if [ "$PDF_GENERATED" = "true" ]; then
    PDF_SIZE=$(du -h "$OUTPUT_PDF" | cut -f1)
    echo " - $OUTPUT_PDF successfully generated (Size: $PDF_SIZE)"
  elif [ -f "${OUTPUT_PDF%.pdf}-simple.pdf" ]; then
    PDF_SIZE=$(du -h "${OUTPUT_PDF%.pdf}-simple.pdf" | cut -f1)
    echo " - ${OUTPUT_PDF%.pdf}-simple.pdf generated as fallback (Size: $PDF_SIZE)"
    echo " - Note: This is a simplified version. For better quality, install a PDF generator"
  else
    echo " - ⚠️ PDF generation failed. See $LOG_FILE for details."
  fi
  echo " - Build log available at: $LOG_FILE"
else
  echo " - PDF generation skipped"
fi

echo "==================================================="

# Exit with success
exit 0
