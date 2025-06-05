#!/bin/bash

# Build documentation using pandoc with includes
# Requires: pandoc, pandoc-include (https://github.com/DCsunset/pandoc-include)

set -e

INPUT="baremetal-ir-os-pandoc-include.md"
OUTPUT_HTML="baremetal-ir-os.html"
OUTPUT_PDF="baremetal-ir-os.pdf"
TMP_FILE="baremetal-ir-os-combined.md"

# Expand includes
pandoc-include "$INPUT" -o "$TMP_FILE"

# Convert to HTML
pandoc "$TMP_FILE" -s -o "$OUTPUT_HTML"

# Convert to PDF (requires LaTeX installed)
pandoc "$TMP_FILE" -s -o "$OUTPUT_PDF"

echo "✅ Generated:"
echo " - $OUTPUT_HTML"
echo " - $OUTPUT_PDF"

# Clean up temporary file
rm "$TMP_FILE"
