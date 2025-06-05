#!/bin/bash
# install-doc-tools.sh
# Script to install all necessary documentation generation tools

set -e

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Installing Documentation Tools ===${NC}"

# Check for package manager
if command -v apt-get >/dev/null 2>&1; then
    PACKAGE_MANAGER="apt"
elif command -v yum >/dev/null 2>&1; then
    PACKAGE_MANAGER="yum"
elif command -v brew >/dev/null 2>&1; then
    PACKAGE_MANAGER="brew"
else
    echo -e "${RED}No supported package manager found (apt, yum, or brew).${NC}"
    echo "Please install the required tools manually:"
    echo "1. pandoc - https://pandoc.org/installing.html"
    echo "2. wkhtmltopdf - https://wkhtmltopdf.org/downloads.html"
    exit 1
fi

# Install pandoc
echo -e "\n${YELLOW}Installing pandoc...${NC}"
if ! command -v pandoc >/dev/null 2>&1; then
    case $PACKAGE_MANAGER in
        apt)
            sudo apt-get update
            sudo apt-get install -y pandoc
            ;;
        yum)
            sudo yum install -y pandoc
            ;;
        brew)
            brew install pandoc
            ;;
    esac
    echo -e "${GREEN}Pandoc installed successfully.${NC}"
else
    echo -e "${GREEN}Pandoc is already installed.${NC}"
fi

# Install wkhtmltopdf (lightweight PDF converter)
echo -e "\n${YELLOW}Installing wkhtmltopdf...${NC}"
if ! command -v wkhtmltopdf >/dev/null 2>&1; then
    case $PACKAGE_MANAGER in
        apt)
            sudo apt-get update
            sudo apt-get install -y wkhtmltopdf
            ;;
        yum)
            sudo yum install -y wkhtmltopdf
            ;;
        brew)
            brew install wkhtmltopdf
            ;;
    esac
    echo -e "${GREEN}wkhtmltopdf installed successfully.${NC}"
else
    echo -e "${GREEN}wkhtmltopdf is already installed.${NC}"
fi

# Optional: Install LaTeX for best quality PDF generation
echo -e "\n${YELLOW}Do you want to install LaTeX for highest quality PDF generation? (y/N)${NC}"
read -r install_latex
if [[ "$install_latex" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installing LaTeX (this may take a while)...${NC}"
    case $PACKAGE_MANAGER in
        apt)
            sudo apt-get update
            sudo apt-get install -y texlive-latex-base texlive-fonts-recommended texlive-fonts-extra texlive-latex-extra
            ;;
        yum)
            sudo yum install -y texlive-latex texlive-collection-fontsrecommended texlive-collection-latexextra
            ;;
        brew)
            brew install --cask mactex
            ;;
    esac
    echo -e "${GREEN}LaTeX installed successfully.${NC}"
else
    echo -e "${YELLOW}Skipping LaTeX installation.${NC}"
fi

# Optional: Install WeasyPrint as another alternative
echo -e "\n${YELLOW}Do you want to install WeasyPrint as an alternative PDF generator? (y/N)${NC}"
read -r install_weasyprint
if [[ "$install_weasyprint" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installing WeasyPrint...${NC}"
    if command -v pip >/dev/null 2>&1; then
        pip install weasyprint
    elif command -v pip3 >/dev/null 2>&1; then
        pip3 install weasyprint
    else
        case $PACKAGE_MANAGER in
            apt)
                sudo apt-get update
                sudo apt-get install -y python3-pip
                pip3 install weasyprint
                ;;
            yum)
                sudo yum install -y python3-pip
                pip3 install weasyprint
                ;;
            brew)
                brew install python
                pip3 install weasyprint
                ;;
        esac
    fi
    echo -e "${GREEN}WeasyPrint installed successfully.${NC}"
else
    echo -e "${YELLOW}Skipping WeasyPrint installation.${NC}"
fi

echo -e "\n${GREEN}=== Documentation tools installation complete! ===${NC}"
echo -e "You can now generate documentation with:\n  ./build-docs.sh"
