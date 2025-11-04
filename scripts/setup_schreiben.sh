#!/bin/bash

#
# setup_schreiben.sh
# Setup script for B1 Schreiben Coach module
#
# This script verifies that all necessary files are in place and
# helps configure the Xcode project for the Schreiben functionality.
#
# Created: 23.10.2025
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_ROOT="/Users/t.abkiliamov/Documents/deutsch app/AITalkingApp"
LLM_MODELS_DIR="/Users/t.abkiliamov/Documents/deutsch app/LLMModels"
MODEL_FILE="Mistral-7B-Instruct-v0.3-Q4_K_M.gguf"

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  B1 Schreiben Coach - Setup & Verification${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"

# Function to check file existence
check_file() {
    local file="$1"
    local description="$2"

    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        return 0
    else
        echo -e "${RED}✗${NC} $description - ${RED}MISSING${NC}"
        return 1
    fi
}

# Function to check directory
check_dir() {
    local dir="$1"
    local description="$2"

    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $description"
        return 0
    else
        echo -e "${RED}✗${NC} $description - ${RED}MISSING${NC}"
        return 1
    fi
}

cd "$PROJECT_ROOT" || exit 1

echo -e "${YELLOW}[1/6] Checking Models...${NC}"
# Models
check_file "$PROJECT_ROOT/AITalkingApp/Models/WritingTask.swift" "WritingTask.swift"
check_file "$PROJECT_ROOT/AITalkingApp/Models/WritingAttempt.swift" "WritingAttempt.swift"
echo ""

echo -e "${YELLOW}[2/6] Checking Services...${NC}"
# Services
check_file "$PROJECT_ROOT/AITalkingApp/Services/LLMChecker.swift" "LLMChecker.swift"
check_file "$PROJECT_ROOT/AITalkingApp/Services/LocalGGUFChecker.swift" "LocalGGUFChecker.swift"
check_file "$PROJECT_ROOT/AITalkingApp/Services/HeuristicChecker.swift" "HeuristicChecker.swift"
check_file "$PROJECT_ROOT/AITalkingApp/Services/WritingMetricsAnalyzer.swift" "WritingMetricsAnalyzer.swift"
check_file "$PROJECT_ROOT/AITalkingApp/Services/WritingTimer.swift" "WritingTimer.swift"
check_file "$PROJECT_ROOT/AITalkingApp/Services/ExportService.swift" "ExportService.swift"
check_file "$PROJECT_ROOT/AITalkingApp/Services/WritingStorageService.swift" "WritingStorageService.swift"
echo ""

echo -e "${YELLOW}[3/6] Checking Views...${NC}"
# Views
check_file "$PROJECT_ROOT/AITalkingApp/Views/ModePickerView.swift" "ModePickerView.swift"
check_file "$PROJECT_ROOT/AITalkingApp/Views/WritingTaskPickerView.swift" "WritingTaskPickerView.swift"
check_file "$PROJECT_ROOT/AITalkingApp/Views/WritingEditorView.swift" "WritingEditorView.swift"
check_file "$PROJECT_ROOT/AITalkingApp/Views/WritingResultView.swift" "WritingResultView.swift"
check_file "$PROJECT_ROOT/AITalkingApp/Views/WritingHistoryView.swift" "WritingHistoryView.swift"
echo ""

echo -e "${YELLOW}[4/6] Checking Resources...${NC}"
# Resources
check_dir "$PROJECT_ROOT/AITalkingApp/Resources" "Resources directory"
check_dir "$PROJECT_ROOT/AITalkingApp/Resources/Seeds" "Resources/Seeds directory"
check_file "$PROJECT_ROOT/AITalkingApp/Resources/Seeds/teil1_topics.json" "teil1_topics.json"
check_file "$PROJECT_ROOT/AITalkingApp/Resources/Seeds/teil2_email_scenarios.json" "teil2_email_scenarios.json"
check_file "$PROJECT_ROOT/AITalkingApp/Resources/rubric_prompt_de.txt" "rubric_prompt_de.txt"
echo ""

echo -e "${YELLOW}[5/6] Checking Tests...${NC}"
# Tests
check_file "$PROJECT_ROOT/AITalkingAppTests/WritingMetricsTests.swift" "WritingMetricsTests.swift"
check_file "$PROJECT_ROOT/AITalkingAppTests/ExportServiceTests.swift" "ExportServiceTests.swift"
echo ""

echo -e "${YELLOW}[6/6] Checking LLM Model (optional)...${NC}"
# LLM Model (optional)
if [ -f "$LLM_MODELS_DIR/$MODEL_FILE" ]; then
    echo -e "${GREEN}✓${NC} LLM Model found: $MODEL_FILE"
    FILE_SIZE=$(du -h "$LLM_MODELS_DIR/$MODEL_FILE" | cut -f1)
    echo -e "  ${BLUE}→${NC} Size: $FILE_SIZE"
else
    echo -e "${YELLOW}⚠${NC} LLM Model not found (optional)"
    echo -e "  ${BLUE}→${NC} Path: $LLM_MODELS_DIR/$MODEL_FILE"
    echo -e "  ${BLUE}→${NC} App will use HeuristicChecker as fallback"
fi
echo ""

# Summary
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Setup Verification Complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"

echo -e "${GREEN}Next Steps:${NC}"
echo "1. Open AITalkingApp.xcodeproj in Xcode"
echo "2. Verify all new files are in Target Membership"
echo "3. Clean Build Folder (⌘⇧K)"
echo "4. Build & Run (⌘R)"
echo ""
echo -e "${BLUE}For detailed instructions, see:${NC}"
echo "→ SCHREIBEN_README.md"
echo ""

# Offer to open project
read -p "$(echo -e ${GREEN}Open project in Xcode now? [y/N]:${NC} )" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Opening Xcode..."
    open "$PROJECT_ROOT/AITalkingApp.xcodeproj"
fi

exit 0
