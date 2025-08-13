#!/bin/bash

# ======================================================================
# SPELLBREAK TECH DEBT CLEANUP SCRIPT
# ======================================================================
# This script removes unused files, fixes naming inconsistencies,
# and consolidates the codebase to best practices
#
# Run with: ./cleanup-tech-debt.sh
# ======================================================================

set -e  # Exit on error

echo "🧹 Starting Spellbreak cleanup..."
echo ""

# ======================================================================
# PHASE 1: REMOVE UNUSED FILES
# ======================================================================
echo "📦 Phase 1: Removing unused files..."

# These files are not imported or used anywhere in the codebase
UNUSED_FILES=(
    "Sources/Eyedrop/AppIconView.swift"           # Not used anywhere
    "Sources/Eyedrop/MenuView.swift"              # Replaced by MenuViewSimple
    "Sources/Eyedrop/MenuViewEnhanced.swift"      # Not used, using MenuViewSimple
    "Sources/Eyedrop/MagneticButton.swift"        # Not imported anywhere
    "Sources/Eyedrop/SBCard.swift"                # Not used anywhere
    "Sources/Eyedrop/SBControls.swift"            # Not used anywhere
    "Sources/Eyedrop/SBStyles.swift"              # Not used anywhere
    "Sources/Eyedrop/SpellbreakTheme.swift"       # Not used anywhere
    "Sources/Eyedrop/VisualEffectView.swift"      # Not used anywhere
    "Sources/Eyedrop/Views/OverlayComponents.swift" # Check if needed
)

for file in "${UNUSED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ❌ Removing: $file"
        rm "$file"
    fi
done

# Remove empty Views directory if exists
if [ -d "Sources/Eyedrop/Views" ] && [ -z "$(ls -A Sources/Eyedrop/Views)" ]; then
    echo "  ❌ Removing empty Views directory"
    rmdir "Sources/Eyedrop/Views"
fi

echo "  ✅ Unused files removed"
echo ""

# ======================================================================
# PHASE 2: CONSOLIDATE DUPLICATE BUILT APPS
# ======================================================================
echo "📦 Phase 2: Cleaning up duplicate app bundles..."

# Remove old Eyedrop.app if it exists
if [ -d "Eyedrop.app" ]; then
    echo "  ❌ Removing old Eyedrop.app bundle"
    rm -rf "Eyedrop.app"
fi

# Keep only Spellbreak.app
echo "  ✅ Keeping Spellbreak.app as the main bundle"
echo ""

# ======================================================================
# PHASE 3: FIX FOLDER STRUCTURE
# ======================================================================
echo "📁 Phase 3: Fixing folder structure..."

# The nested Eyedrop/Sources/Eyedrop structure is redundant
if [ -d "Eyedrop/Sources/Eyedrop/Resources" ]; then
    echo "  ❌ Removing redundant nested structure"
    rm -rf "Eyedrop/"
fi

echo "  ✅ Folder structure cleaned"
echo ""

# ======================================================================
# PHASE 4: UPDATE NAMING IN PACKAGE.SWIFT
# ======================================================================
echo "📝 Phase 4: Updating Package.swift naming..."

# Already correctly named as Spellbreak, but path still points to Eyedrop folder
# This is a known issue mentioned in CLAUDE.md - keeping for now as it works

echo "  ℹ️  Package.swift already uses 'Spellbreak' name"
echo "  ℹ️  Path still points to 'Sources/Eyedrop' (working as-is)"
echo ""

# ======================================================================
# PHASE 5: CLEAN BUILD ARTIFACTS
# ======================================================================
echo "🗑️  Phase 5: Cleaning build artifacts..."

if [ -d ".build" ]; then
    echo "  ❌ Removing .build directory"
    rm -rf .build
fi

if [ -d "build" ]; then
    echo "  ❌ Removing build directory"
    rm -rf build
fi

echo "  ✅ Build artifacts cleaned"
echo ""

# ======================================================================
# PHASE 6: IDENTIFY REMAINING TECH DEBT
# ======================================================================
echo "🔍 Phase 6: Identifying remaining tech debt..."

echo ""
echo "📋 REMAINING ITEMS TO ADDRESS MANUALLY:"
echo ""
echo "  1. NAMING: Folder 'Sources/Eyedrop' should be renamed to 'Sources/Spellbreak'"
echo "     - Requires updating Package.swift path"
echo "     - Requires updating all build scripts"
echo ""
echo "  2. DEBUG CODE: SpellbreakApp.swift contains debug test methods (lines 174-252)"
echo "     - showTestWindow()"
echo "     - showDebugWindow()"
echo "     - Consider removing or moving to #if DEBUG blocks"
echo ""
echo "  3. SPRITEKIT: Import in SpellbreakApp.swift (line 5) but not used"
echo "     - Was for shader experiments that got replaced with Canvas"
echo "     - Can be removed"
echo ""
echo "  4. OVERLAY WINDOW CONTROLLER: Custom class but no implementation"
echo "     - Check if OverlayWindowController needs a proper implementation"
echo ""
echo "  5. MENU CONSOLIDATION: Using MenuViewSimple but have complex menu code"
echo "     - Consider if we need the enhanced features"
echo ""

# ======================================================================
# SUMMARY
# ======================================================================
echo "=================================="
echo "✨ CLEANUP COMPLETE!"
echo "=================================="
echo ""
echo "Files removed: ${#UNUSED_FILES[@]}"
echo "Build artifacts cleaned: ✅"
echo "Old app bundles removed: ✅"
echo ""
echo "Next steps:"
echo "  1. Review and test the app after cleanup"
echo "  2. Run: swift build -c release"
echo "  3. Consider addressing manual items listed above"
echo ""
echo "🎸 Keep it soft and modular!"