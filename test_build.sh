#!/bin/bash
set -e
VERSION="1.0.0"
BUILD_TIMESTAMP=$(date +"%B %d, %Y at %H:%M:%S UTC")
OUTPUT_FILE="test-baremetal.md"

echo "Creating test markdown file..."

cat > "$OUTPUT_FILE" << EOFMD
---
title: "Baremetal IR OS Documentation"
author: "Henrik Bach"
date: "${BUILD_TIMESTAMP}"
version: "${VERSION}"
---

# Baremetal IR OS Documentation

**Version:** ${VERSION}
**Generated:** ${BUILD_TIMESTAMP}
**Build System:** Automated Documentation Generator

EOFMD

echo "Test file created: $OUTPUT_FILE"
ls -la "$OUTPUT_FILE"
