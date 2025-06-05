#!/bin/bash
# section-numbers.sh - Add or remove section numbering to/from markdown files
# Created on June 5, 2025

set -e

# Default settings
ADD_NUMBERS=true
DOCS_DIR="docs"
VERBOSE=false
SINGLE_FILE=""
ALL_DOCS=false
INCLUDE_H1=false

# Print usage information
usage() {
  echo "Usage: $0 [options] [file.md]"
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -v, --verbose              Show more detailed output"
  echo "  -r, --remove               Remove section numbering (default is to add numbering)"
  echo "  -a, --all                  Apply to all markdown files in docs directory"
  echo "  -1, --include-h1           Include H1 headers in numbering (default: start at H2)"
  echo "  --docs-dir DIRECTORY       Set documentation source directory (default: $DOCS_DIR)"
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
    -r|--remove)
      ADD_NUMBERS=false
      shift
      ;;
    -a|--all)
      ALL_DOCS=true
      shift
      ;;
    -1|--include-h1)
      INCLUDE_H1=true
      shift
      ;;
    --docs-dir)
      DOCS_DIR="$2"
      shift 2
      ;;
    *)
      # If this is the last argument and it's not an option, assume it's the input file
      if [[ $# -eq 1 && ! $1 == -* ]]; then
        SINGLE_FILE="$1"
      else
        echo "Unknown option: $1"
        usage
        exit 1
      fi
      shift
      ;;
  esac
done

# Check if at least one file is specified or --all is set
if [ -z "$SINGLE_FILE" ] && [ "$ALL_DOCS" = "false" ]; then
  log "error" "No file specified. Please provide a file path or use --all to process all files."
  usage
  exit 1
fi

# Function to add section numbering to a markdown file
add_section_numbering() {
  local file="$1"
  local temp_file=$(mktemp)
  local h1_count=0
  local h2_count=0
  local h3_count=0
  local h4_count=0
  local h5_count=0
  local h6_count=0
  
  log "process" "Adding section numbering to $file..."
  
  # Process file line by line
  while IFS= read -r line; do
    # Skip YAML frontmatter if present
    if [[ "$line" == "---" && $h1_count -eq 0 && $h2_count -eq 0 ]]; then
      echo "$line" >> "$temp_file"
      # Read until the end of frontmatter
      while IFS= read -r yaml_line; do
        echo "$yaml_line" >> "$temp_file"
        if [[ "$yaml_line" == "---" ]]; then
          break
        fi
      done
      continue
    fi
    
    # Check for different heading levels
    if [[ "$line" =~ ^#[^#].*$ ]]; then  # H1
      if [ "$INCLUDE_H1" = "true" ]; then
        h1_count=$((h1_count + 1))
        h2_count=0
        h3_count=0
        h4_count=0
        h5_count=0
        h6_count=0
        echo "# ${h1_count}. ${line#\# }" >> "$temp_file"
      else
        echo "$line" >> "$temp_file"
      fi
    elif [[ "$line" =~ ^##[^#].*$ ]]; then  # H2
      h2_count=$((h2_count + 1))
      h3_count=0
      h4_count=0
      h5_count=0
      h6_count=0
      if [ "$INCLUDE_H1" = "true" ]; then
        echo "## ${h1_count}.${h2_count}. ${line#\## }" >> "$temp_file"
      else
        echo "## ${h2_count}. ${line#\## }" >> "$temp_file"
      fi
    elif [[ "$line" =~ ^###[^#].*$ ]]; then  # H3
      h3_count=$((h3_count + 1))
      h4_count=0
      h5_count=0
      h6_count=0
      if [ "$INCLUDE_H1" = "true" ]; then
        echo "### ${h1_count}.${h2_count}.${h3_count}. ${line#\### }" >> "$temp_file"
      else
        echo "### ${h2_count}.${h3_count}. ${line#\### }" >> "$temp_file"
      fi
    elif [[ "$line" =~ ^####[^#].*$ ]]; then  # H4
      h4_count=$((h4_count + 1))
      h5_count=0
      h6_count=0
      if [ "$INCLUDE_H1" = "true" ]; then
        echo "#### ${h1_count}.${h2_count}.${h3_count}.${h4_count}. ${line#\#### }" >> "$temp_file"
      else
        echo "#### ${h2_count}.${h3_count}.${h4_count}. ${line#\#### }" >> "$temp_file"
      fi
    elif [[ "$line" =~ ^#####[^#].*$ ]]; then  # H5
      h5_count=$((h5_count + 1))
      h6_count=0
      if [ "$INCLUDE_H1" = "true" ]; then
        echo "##### ${h1_count}.${h2_count}.${h3_count}.${h4_count}.${h5_count}. ${line#\##### }" >> "$temp_file"
      else
        echo "##### ${h2_count}.${h3_count}.${h4_count}.${h5_count}. ${line#\##### }" >> "$temp_file"
      fi
    elif [[ "$line" =~ ^######[^#].*$ ]]; then  # H6
      h6_count=$((h6_count + 1))
      if [ "$INCLUDE_H1" = "true" ]; then
        echo "###### ${h1_count}.${h2_count}.${h3_count}.${h4_count}.${h5_count}.${h6_count}. ${line#\###### }" >> "$temp_file"
      else
        echo "###### ${h2_count}.${h3_count}.${h4_count}.${h5_count}.${h6_count}. ${line#\###### }" >> "$temp_file"
      fi
    else
      # Not a heading, just echo the line
      echo "$line" >> "$temp_file"
    fi
  done < "$file"
  
  # Replace original file with the modified version
  mv "$temp_file" "$file"
  
  log "success" "Added section numbering to $file"
}

# Function to remove section numbering from a markdown file
remove_section_numbering() {
  local file="$1"
  local temp_file=$(mktemp)
  
  log "process" "Removing section numbering from $file..."
  
  # Process file line by line
  while IFS= read -r line; do
    # Check for different heading levels with numbering
    if [[ "$line" =~ ^#[^#].*[0-9]+\.\ .*$ ]]; then  # H1 with numbering
      echo "# ${line#\# *\. }" >> "$temp_file"
    elif [[ "$line" =~ ^##[^#].*[0-9\.]+\.\ .*$ ]]; then  # H2 with numbering
      echo "## ${line#\## *\. }" >> "$temp_file"
    elif [[ "$line" =~ ^###[^#].*[0-9\.]+\.\ .*$ ]]; then  # H3 with numbering
      echo "### ${line#\### *\. }" >> "$temp_file"
    elif [[ "$line" =~ ^####[^#].*[0-9\.]+\.\ .*$ ]]; then  # H4 with numbering
      echo "#### ${line#\#### *\. }" >> "$temp_file"
    elif [[ "$line" =~ ^#####[^#].*[0-9\.]+\.\ .*$ ]]; then  # H5 with numbering
      echo "##### ${line#\##### *\. }" >> "$temp_file"
    elif [[ "$line" =~ ^######[^#].*[0-9\.]+\.\ .*$ ]]; then  # H6 with numbering
      echo "###### ${line#\###### *\. }" >> "$temp_file"
    else
      # Not a numbered heading, just echo the line
      echo "$line" >> "$temp_file"
    fi
  done < "$file"
  
  # Replace original file with the modified version
  mv "$temp_file" "$file"
  
  log "success" "Removed section numbering from $file"
}

# Process a single file
process_file() {
  local file="$1"
  
  # Check if file exists
  if [ ! -f "$file" ]; then
    log "error" "File '$file' does not exist."
    return 1
  fi
  
  # Add or remove section numbering based on the setting
  if [ "$ADD_NUMBERS" = "true" ]; then
    add_section_numbering "$file"
  else
    remove_section_numbering "$file"
  fi
}

# Process all markdown files in the docs directory
process_all_docs() {
  local doc_count=0
  
  # Check if docs directory exists
  if [ ! -d "$DOCS_DIR" ]; then
    log "error" "Directory '$DOCS_DIR' does not exist."
    return 1
  fi
  
  # Find all markdown files in the docs directory
  for file in "$DOCS_DIR"/*.md; do
    if [ -f "$file" ]; then
      process_file "$file"
      doc_count=$((doc_count + 1))
    fi
  done
  
  if [ "$doc_count" -eq 0 ]; then
    log "warning" "No markdown files found in '$DOCS_DIR'."
    return 1
  else
    log "success" "Processed $doc_count markdown files."
  fi
}

# Main execution
main() {
  log "info" "Starting section numbering process"
  
  if [ "$ALL_DOCS" = "true" ]; then
    process_all_docs
  else
    process_file "$SINGLE_FILE"
  fi
  
  log "success" "Section numbering process completed"
}

# Run the main function
main

exit 0