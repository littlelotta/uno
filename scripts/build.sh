#!/bin/bash
SELF=`echo $0 | sed 's/\\\\/\\//g'`
cd "`dirname "$SELF"`/.." || exit 1
source scripts/common.sh

# Configuration
BUILD_PLATFORM=1
BUILD_UNOCORE=0
BUILD_LIBRARY=1
CONFIGURATION="Debug"
REBUILD_LIBRARY=0

# Parse options
for arg in "$@"; do
    case $arg in
    -h|--help)
        echo "Build options:"
        echo "  --unocore   Generate Uno.Runtime.Core.csproj"
        echo "  --rebuild   Rebuild package library"
        echo "  --all       Build everything"
        echo ""
        echo "Configuration options:"
        echo "  --debug     Use 'Debug' configuration (default)"
        echo "  --release   Use 'Release' configuration"
        exit 0
        ;;
    --debug)
        CONFIGURATION="Debug"
        ;;
    --release)
        CONFIGURATION="Release"
        ;;
    --unocore)
        BUILD_PLATFORM=0
        BUILD_UNOCORE=1
        BUILD_LIBRARY=0
        ;;
    --all)
        BUILD_PLATFORM=1
        BUILD_UNOCORE=1
        BUILD_LIBRARY=1
        REBUILD_LIBRARY=1
        ;;
    --rebuild)
        REBUILD_LIBRARY=1
        ;;
    *)
        echo "ERROR: Invalid argument '$arg'" >&2
        exit 1
        ;;
    esac
done

if [ "$BUILD_UNOCORE" = 1 ]; then
    h1 "Building Uno.Runtime.Core.csproj"
    SRC_DIR="Library/Core/UnoCore"
    OUT_DIR="$SRC_DIR/build/corelib/Debug"
    DST_DIR="src/runtime/Uno.Runtime.Core"

    # Build Uno project
    uno build corelib $SRC_DIR -z

    # Build C# project
    csharp-build $OUT_DIR/*.sln

    # Replace C# project
    rm -rf ${OUT_DIR:?}/{bin,obj}
    rm -rf $DST_DIR
    p cp -R $OUT_DIR $DST_DIR
    rm $DST_DIR/*.sln
fi

if [ "$BUILD_PLATFORM" = 1 ]; then
    h1 "Building platform tools"

    # Get version number
    VERSION=`cat VERSION.txt`

    # Build C# solution
    csharp-build uno.sln
fi

if [ "$BUILD_LIBRARY" = 1 ]; then
    h1 "Building standard library"
    if [ "$REBUILD_LIBRARY" = 1 ]; then
        uno doctor -ac$CONFIGURATION --build-number=$VERSION
    else
        uno doctor -ec$CONFIGURATION --build-number=$VERSION
    fi
fi
