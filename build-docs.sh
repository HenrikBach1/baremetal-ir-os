#!/bin/bash
set -e

# Input/output files
OUTPUT_HTML="baremetal-ir-os.html"
OUTPUT_PDF="baremetal-ir-os.pdf"
PANDOC_INCLUDE_FILE="baremetal-ir-os-pandoc-include.md"
DOCS_DIR="docs"

# Function to generate the pandoc include file automatically
generate_pandoc_include_file() {
  local include_file="$1"
  local docs_dir="$2"
  
  echo "🔄 Generating pandoc include file..."
  
  # Create the header with metadata
  cat > "$include_file" << EOF
---
title: "Baremetal IR OS Documentation"
author: "Henrik Bach"
date: "$(date +"%B %Y")"
---

EOF

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
      fi
    done
  done
  
  # Add any special docs (like ir-spec.md) that don't follow the numbering scheme
  for doc in "$docs_dir"/*.md; do
    # Skip the numbered docs we've already processed
    if [[ ! $(basename "$doc") =~ ^[0-9]+-.*\.md$ ]]; then
      # Extract section title from file (first heading)
      title=$(grep -m 1 "^# " "$doc" | sed 's/^# //')
      
      # Add section title comment and file content
      echo "<!-- Section: $title -->" >> "$include_file"
      cat "$doc" | grep -v "^<!--" | tail -n+2 >> "$include_file"
      echo -e "\n\n" >> "$include_file"
    fi
  done
  
  # Also generate a TOC file for reference
  toc_file="${include_file%.md}-toc.md"
  echo "# Table of Contents" > "$toc_file"
  echo "" >> "$toc_file"
  
  # Extract all the section titles from the include file
  grep "<!-- Section:" "$include_file" | sed 's/<!-- Section: \(.*\) -->/- \1/' >> "$toc_file"
  
  echo "✅ Generated $include_file with content from $docs_dir"
  echo "✅ Generated $toc_file with table of contents"
}

# Generate the pandoc include file
generate_pandoc_include_file "$PANDOC_INCLUDE_FILE" "$DOCS_DIR"

# Generate HTML
echo "🔄 Generating HTML..."
pandoc "$PANDOC_INCLUDE_FILE" -s --toc --toc-depth=3 -o "$OUTPUT_HTML"

# Generate PDF (requires LaTeX)
echo "🔄 Generating PDF..."
if command -v pdflatex >/dev/null 2>&1; then
  pandoc "$PANDOC_INCLUDE_FILE" -s --toc --toc-depth=3 -o "$OUTPUT_PDF" || {
    echo "⚠️ PDF generation failed. You may need to install LaTeX packages."
    echo "   Try: sudo apt-get install texlive-latex-base texlive-fonts-recommended texlive-fonts-extra texlive-latex-extra"
  }
  if [ -f "$OUTPUT_PDF" ]; then
    echo " - $OUTPUT_PDF successfully generated"
  fi
else
  echo "⚠️ PDF generation skipped: pdflatex not installed"
  echo "   To enable PDF generation, install LaTeX: sudo apt-get install texlive-latex-base texlive-fonts-recommended"
fi

echo "✅ Documentation build complete!"
echo " - $OUTPUT_HTML successfully generated"