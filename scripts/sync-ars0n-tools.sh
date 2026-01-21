#!/bin/bash
# =================================================================
# ASM-Hawk Tool Container Sync Script
# Syncs tool containers from ars0n-framework-v2
# =================================================================

set -e

# Configuration
ARS0N_PATH="${ARS0N_PATH:-}"
ASM_HAWK_PATH="${ASM_HAWK_PATH:-$(dirname $(dirname $(realpath $0)))}"
BACKUP_DIR="${ASM_HAWK_PATH}/docker/.backup/$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Tools to sync
TOOLS=(
  "subfinder"
  "httpx"
  "nuclei"
  "katana"
  "ffuf"
  "dnsx"
  "gospider"
  "waybackurls"
  "shuffledns"
  "cewl"
  "assetfinder"
  "metabigor"
  "sublist3r"
  "subdomainizer"
  "github-recon"
  "cloud_enum"
  "linkfinder"
)

# Help
show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -s, --source PATH    Path to ars0n-framework-v2 directory"
  echo "  -d, --dest PATH      Path to asm-hawk directory (default: parent of script)"
  echo "  -t, --tool TOOL      Sync specific tool only"
  echo "  -l, --list           List available tools"
  echo "  -n, --dry-run        Show what would be synced without making changes"
  echo "  -b, --no-backup      Skip backup before syncing"
  echo "  -r, --rebuild        Rebuild containers after sync"
  echo "  -h, --help           Show this help"
  echo ""
  echo "Examples:"
  echo "  $0 -s /path/to/ars0n-framework-v2"
  echo "  $0 -s /path/to/ars0n -t subfinder -r"
  echo "  $0 -s /path/to/ars0n --dry-run"
}

# Parse arguments
DRY_RUN=false
NO_BACKUP=false
REBUILD=false
SPECIFIC_TOOL=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--source)
      ARS0N_PATH="$2"
      shift 2
      ;;
    -d|--dest)
      ASM_HAWK_PATH="$2"
      shift 2
      ;;
    -t|--tool)
      SPECIFIC_TOOL="$2"
      shift 2
      ;;
    -l|--list)
      echo "Available tools:"
      for tool in "${TOOLS[@]}"; do
        echo "  - $tool"
      done
      exit 0
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -b|--no-backup)
      NO_BACKUP=true
      shift
      ;;
    -r|--rebuild)
      REBUILD=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      show_help
      exit 1
      ;;
  esac
done

# Validation
if [ -z "$ARS0N_PATH" ]; then
  echo -e "${RED}Error: ars0n-framework-v2 path is required${NC}"
  echo "Use: $0 -s /path/to/ars0n-framework-v2"
  exit 1
fi

if [ ! -d "$ARS0N_PATH" ]; then
  echo -e "${RED}Error: Directory not found: $ARS0N_PATH${NC}"
  exit 1
fi

if [ ! -d "$ARS0N_PATH/docker" ]; then
  echo -e "${RED}Error: No docker directory in: $ARS0N_PATH${NC}"
  exit 1
fi

# Determine which tools to sync
if [ -n "$SPECIFIC_TOOL" ]; then
  TOOLS_TO_SYNC=("$SPECIFIC_TOOL")
else
  TOOLS_TO_SYNC=("${TOOLS[@]}")
fi

# Print header
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         ASM-Hawk Tool Container Sync                          ║${NC}"
echo -e "${BLUE}╠═══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC} Source: ${YELLOW}$ARS0N_PATH${NC}"
echo -e "${BLUE}║${NC} Dest:   ${YELLOW}$ASM_HAWK_PATH${NC}"
echo -e "${BLUE}║${NC} Tools:  ${YELLOW}${#TOOLS_TO_SYNC[@]}${NC}"
if [ "$DRY_RUN" = true ]; then
  echo -e "${BLUE}║${NC} Mode:   ${YELLOW}DRY RUN${NC}"
fi
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Backup existing
if [ "$NO_BACKUP" = false ] && [ "$DRY_RUN" = false ]; then
  echo -e "${BLUE}📦 Creating backup...${NC}"
  mkdir -p "$BACKUP_DIR"
  for tool in "${TOOLS_TO_SYNC[@]}"; do
    if [ -d "$ASM_HAWK_PATH/docker/$tool" ]; then
      cp -r "$ASM_HAWK_PATH/docker/$tool" "$BACKUP_DIR/"
    fi
  done
  echo -e "${GREEN}   Backup saved to: $BACKUP_DIR${NC}"
  echo ""
fi

# Sync tools
echo -e "${BLUE}🔄 Syncing tool containers...${NC}"
SYNCED=0
SKIPPED=0
ERRORS=0

for tool in "${TOOLS_TO_SYNC[@]}"; do
  SOURCE="$ARS0N_PATH/docker/$tool"
  DEST="$ASM_HAWK_PATH/docker/$tool"
  
  if [ ! -d "$SOURCE" ]; then
    echo -e "   ${YELLOW}⚠ $tool${NC} - Not found in source, skipping"
    ((SKIPPED++))
    continue
  fi
  
  if [ "$DRY_RUN" = true ]; then
    echo -e "   ${BLUE}→ $tool${NC} - Would sync from $SOURCE"
  else
    if rsync -av --delete "$SOURCE/" "$DEST/" > /dev/null 2>&1; then
      echo -e "   ${GREEN}✓ $tool${NC} - Synced"
      ((SYNCED++))
    else
      echo -e "   ${RED}✗ $tool${NC} - Failed to sync"
      ((ERRORS++))
    fi
  fi
done

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "Summary:"
echo -e "  ${GREEN}Synced: $SYNCED${NC}"
echo -e "  ${YELLOW}Skipped: $SKIPPED${NC}"
echo -e "  ${RED}Errors: $ERRORS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

# Rebuild if requested
if [ "$REBUILD" = true ] && [ "$DRY_RUN" = false ] && [ $ERRORS -eq 0 ]; then
  echo ""
  echo -e "${BLUE}🔨 Rebuilding containers...${NC}"
  cd "$ASM_HAWK_PATH"
  
  if [ -n "$SPECIFIC_TOOL" ]; then
    docker-compose build "$SPECIFIC_TOOL"
  else
    # Build all tool containers
    docker-compose build ${TOOLS_TO_SYNC[@]}
  fi
  
  echo -e "${GREEN}✓ Containers rebuilt${NC}"
fi

# Compare versions
echo ""
echo -e "${BLUE}📋 Version comparison:${NC}"
echo ""

# Check if there's a version or release info
if [ -f "$ARS0N_PATH/README.md" ]; then
  VERSION=$(grep -oP 'beta-\d+\.\d+\.\d+' "$ARS0N_PATH/README.md" | head -1)
  if [ -n "$VERSION" ]; then
    echo -e "   Ars0n version: ${YELLOW}$VERSION${NC}"
  fi
fi

echo ""
echo -e "${GREEN}✅ Sync complete!${NC}"
echo ""
echo -e "Next steps:"
echo "  1. Review changes in docker/ directory"
echo "  2. Test containers: docker-compose up -d subfinder httpx nuclei"
echo "  3. Run integration tests"
echo ""
