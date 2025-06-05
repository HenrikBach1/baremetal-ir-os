#!/bin/bash
# build-markdown.sh - Generate a single consolidated markdown file from multiple markdown files
# Created on June 5, 2025

set -e

# Default settings
OUTPUT_MARKDOWN="baremetal-ir-os-full.md"
DOCS_DIR="docs"
VERBOSE=false
ADD_SECTION_NUMBERS=false
INCLUDE_TOC=true
INCLUDE_METADATA=true

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
  echo "  --output-file FILENAME     Set output markdown filename (default: $OUTPUT_MARKDOWN)"
  echo "  --docs-dir DIRECTORY       Set documentation source directory (default: $DOCS_DIR)"
  echo "  --add-section-numbers      Add section numbering to the output"
  echo "  --no-toc                   Skip table of contents generation"
  echo "  --no-metadata              Skip YAML metadata header"
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
    --output-file)
      OUTPUT_MARKDOWN="$2"
      shift 2
      ;;
    --docs-dir)
      DOCS_DIR="$2"
      shift 2
      ;;
    --add-section-numbers)
      ADD_SECTION_NUMBERS=true
      shift
      ;;
    --no-toc)
      INCLUDE_TOC=false
      shift
      ;;
    --no-metadata)
      INCLUDE_METADATA=false
      shift
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Check if docs directory exists
if [ ! -d "$DOCS_DIR" ]; then
  log "error" "Directory '$DOCS_DIR' does not exist."
  exit 1
fi

# Function to generate table of contents
generate_toc() {
  local markdown_file="$1"
  local toc_file=$(mktemp)
  
  log "process" "Generating table of contents..."
  
  echo "# Table of Contents" > "$toc_file"
  echo "" >> "$toc_file"
  
  # Extract all headings and convert to TOC entries
  grep -E "^#{1,6} " "$markdown_file" | while read -r line; do
    # Count the number of # to determine heading level
    level=$(echo "$line" | grep -o "^#\+" | wc -c)
    level=$((level - 1))
    
    # Extract the heading text
    text=$(echo "$line" | sed -E 's/^#{1,6} //')
    
    # Create the TOC entry with proper indentation
    indent=$(printf "%$((level - 1))s" "")
    echo "$indent- [$text](#$(echo "$text" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-|-$//g'))" >> "$toc_file"
  done
  
  echo "" >> "$toc_file"
  echo "---" >> "$toc_file"
  echo "" >> "$toc_file"
  
  # Create a temporary file with TOC inserted
  local temp_file=$(mktemp)
  cat "$toc_file" > "$temp_file"
  cat "$markdown_file" >> "$temp_file"
  
  # Replace the original file with the TOC version
  mv "$temp_file" "$markdown_file"
  rm "$toc_file"
  
  log "success" "Table of contents generated"
}

# Function to generate the consolidated markdown file
generate_markdown_file() {
  local output_file="$1"
  local docs_dir="$2"
  local temp_file=$(mktemp)
  
  log "process" "Generating consolidated markdown file..."
  
  # Add metadata header if requested
  if [ "$INCLUDE_METADATA" = "true" ]; then
    log "info" "Adding metadata header"
    cat > "$temp_file" << EOFMD
---
title: "Baremetal IR OS Documentation"
author: "Henrik Bach"
date: "${BUILD_DATE}"
version: "${VERSION}"
---

EOFMD
  fi
  
  # Add title
  echo "# Baremetal IR OS Documentation" >> "$temp_file"
  echo "" >> "$temp_file"
  echo "Version: ${VERSION}" >> "$temp_file"
  echo "Date: ${BUILD_DATE}" >> "$temp_file"
  echo "" >> "$temp_file"
  
  # Add numbered docs in order (00-xx through 10-xx)
  for i in $(seq -f "%02g" 0 10); do
    for doc in "$docs_dir"/"$i"-*.md; do
      if [ -f "$doc" ]; then
        # Extract section title from file (first heading)
        title=$(grep -m 1 "^# " "$doc" | sed 's/^# //')
        
        log "info" "Processing: $(basename "$doc") - $title"
        
        # Add section header
        echo -e "\n## $title\n" >> "$temp_file"
        
        # Add content (skip first line which is the title and any file-specific comments)
        cat "$doc" | grep -v "^<!--" | tail -n+2 >> "$temp_file"
        echo -e "\n" >> "$temp_file"
      fi
    done
  done
  
  # Add any special docs (like ir-spec.md) that don't follow the numbering scheme
  for doc in "$docs_dir"/*.md; do
    # Skip the numbered docs we've already processed
    if [[ ! $(basename "$doc") =~ ^[0-9]+-.*\.md$ ]]; then
      # Skip metadata file and CSS files
      if [[ $(basename "$doc") != "metadata.yaml" && ! $(basename "$doc") =~ \.css$ ]]; then
        # Extract section title from file (first heading)
        title=$(grep -m 1 "^# " "$doc" | sed 's/^# //')
        
        log "info" "Processing special doc: $(basename "$doc") - $title"
        
        # Add section header
        echo -e "\n## $title\n" >> "$temp_file"
        
        # Add content (skip first line which is the title and any file-specific comments)
        cat "$doc" | grep -v "^<!--" | tail -n+2 >> "$temp_file"
        echo -e "\n" >> "$temp_file"
      fi
    fi
  done
  
  # Move temp file to output file
  mv "$temp_file" "$output_file"
  
  # Add section numbering if requested
  if [ "$ADD_SECTION_NUMBERS" = "true" ]; then
    log "process" "Adding section numbering..."
    if [ -f "./section-numbers.sh" ]; then
      chmod +x ./section-numbers.sh
      ./section-numbers.sh "$output_file" || {
        log "error" "Failed to add section numbering. Continuing without it."
      }
    else
      log "warning" "section-numbers.sh script not found. Skipping section numbering."
    fi
  fi
  
  # Generate table of contents if requested
  if [ "$INCLUDE_TOC" = "true" ]; then
    generate_toc "$output_file"
  fi
  
  local file_size=$(du -h "$output_file" | cut -f1)
  log "success" "Consolidated markdown file generated: $output_file (Size: $file_size)"
}

# Main execution
log "info" "Starting markdown consolidation process"
log "info" "Output file: $OUTPUT_MARKDOWN"
log "info" "Version: $VERSION"
log "info" "Build Date: $BUILD_DATE"

# Generate the consolidated markdown file
generate_markdown_file "$OUTPUT_MARKDOWN" "$DOCS_DIR"

log "success" "Markdown consolidation completed"

exit 0
