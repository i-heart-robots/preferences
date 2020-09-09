#
# Configuration.cmake file 
# Sets up configuration for prod / test / dev split 
# 
# Unless passed in or cached from the last time it was passed in, 
# default to a RelWithAssertions build
# Coverage and RelWithAssertions are custom configurations:
# Currently, the build is released with different types. 
#  
#   Coverage builds:            Coverage 
#   Unit test sanitizer:        Debug
#   Normal tests:               RelWithAssertions
#   PR / feature builds:        RelWithAssertions
#   flight-test builds (rc):    RelWithAssertions
#   crewed candidate builds:    RelWithAssertions
#   customer builds:            RelWithAssertions
# 

# Debug build configuration with sanitizers activated
# https://clang.llvm.org/docs/AddressSanitizer.html
# https://github.com/google/sanitizers/wiki/AddressSanitizer
# https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html
# https://clang.llvm.org/docs/ThreadSafetyAnalysis.html
SET(CMAKE_CXX_FLAGS_DEBUG 
  "-g -O0 -fsanitize=address,undefined -fno-sanitize-recover=all"
  CACHE STRING ""
  FORCE)

# RelWithAssertions
# Note that this is missing "-DNDEBUG" which takes out assertions
SET(CMAKE_CXX_FLAGS_RELWITHASSERTIONS
  "-g -O3" # debug symbols, full optimization, with assertions
  CACHE STRING "" 
  FORCE)

# Coverage
# Turn on coverage flags, debug and no optimization
SET(CMAKE_CXX_FLAGS_COVERAGE 
  "-g -O0 -fprofile-arcs -ftest-coverage"
  CACHE STRING "" 
  FORCE)

# Test
# Running tests with sanitizers. This should be equal to RELEASE + "-g" + sanitizers
SET(CMAKE_CXX_FLAGS_TEST 
  "-g -O3 -DNDEBUG -fsanitize=address,undefined -fno-sanitize-recover=all"
  CACHE STRING "" 
  FORCE)

# Release
SET(CMAKE_CXX_FLAGS_RELEASE 
  "-O3 -DNDEBUG" # full-optimization, no assertions
  CACHE STRING "" 
  FORCE)

# Options for build types: (see http://www.brianlheim.com/2018/04/09/cmake-cheat-sheet.html)
# Example debug build from the command line: catkin_make -DCMAKE_BUILD_TYPE=Debug
if (NOT EXISTS ${CMAKE_BINARY_DIR}/CMakeCache.txt)
    if (NOT CMAKE_BUILD_TYPE)
        set(CMAKE_BUILD_TYPE "RelWithAssertions" CACHE STRING "" FORCE)
    endif()
endif()
