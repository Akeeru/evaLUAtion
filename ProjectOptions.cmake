include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


include(CheckCXXSourceCompiles)


macro(evaLUAtion_supports_sanitizers)
  # Emscripten doesn't support sanitizers
  if(EMSCRIPTEN)
    set(SUPPORTS_UBSAN OFF)
    set(SUPPORTS_ASAN OFF)
  elseif((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)

    message(STATUS "Sanity checking UndefinedBehaviorSanitizer, it should be supported on this platform")
    set(TEST_PROGRAM "int main() { return 0; }")

    # Check if UndefinedBehaviorSanitizer works at link time
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

    if(HAS_UBSAN_LINK_SUPPORT)
      message(STATUS "UndefinedBehaviorSanitizer is supported at both compile and link time.")
      set(SUPPORTS_UBSAN ON)
    else()
      message(WARNING "UndefinedBehaviorSanitizer is NOT supported at link time.")
      set(SUPPORTS_UBSAN OFF)
    endif()
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    if (NOT WIN32)
      message(STATUS "Sanity checking AddressSanitizer, it should be supported on this platform")
      set(TEST_PROGRAM "int main() { return 0; }")

      # Check if AddressSanitizer works at link time
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

      if(HAS_ASAN_LINK_SUPPORT)
        message(STATUS "AddressSanitizer is supported at both compile and link time.")
        set(SUPPORTS_ASAN ON)
      else()
        message(WARNING "AddressSanitizer is NOT supported at link time.")
        set(SUPPORTS_ASAN OFF)
      endif()
    else()
      set(SUPPORTS_ASAN ON)
    endif()
  endif()
endmacro()

macro(evaLUAtion_setup_options)
  option(evaLUAtion_ENABLE_HARDENING "Enable hardening" ON)
  option(evaLUAtion_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    evaLUAtion_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    evaLUAtion_ENABLE_HARDENING
    OFF)

  evaLUAtion_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR evaLUAtion_PACKAGING_MAINTAINER_MODE)
    option(evaLUAtion_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(evaLUAtion_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(evaLUAtion_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(evaLUAtion_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(evaLUAtion_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(evaLUAtion_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(evaLUAtion_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(evaLUAtion_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(evaLUAtion_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(evaLUAtion_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(evaLUAtion_ENABLE_PCH "Enable precompiled headers" OFF)
    option(evaLUAtion_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(evaLUAtion_ENABLE_IPO "Enable IPO/LTO" ON)
    option(evaLUAtion_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(evaLUAtion_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(evaLUAtion_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(evaLUAtion_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(evaLUAtion_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(evaLUAtion_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(evaLUAtion_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(evaLUAtion_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(evaLUAtion_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(evaLUAtion_ENABLE_PCH "Enable precompiled headers" OFF)
    option(evaLUAtion_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      evaLUAtion_ENABLE_IPO
      evaLUAtion_WARNINGS_AS_ERRORS
      evaLUAtion_ENABLE_SANITIZER_ADDRESS
      evaLUAtion_ENABLE_SANITIZER_LEAK
      evaLUAtion_ENABLE_SANITIZER_UNDEFINED
      evaLUAtion_ENABLE_SANITIZER_THREAD
      evaLUAtion_ENABLE_SANITIZER_MEMORY
      evaLUAtion_ENABLE_UNITY_BUILD
      evaLUAtion_ENABLE_CLANG_TIDY
      evaLUAtion_ENABLE_CPPCHECK
      evaLUAtion_ENABLE_COVERAGE
      evaLUAtion_ENABLE_PCH
      evaLUAtion_ENABLE_CACHE)
  endif()

  evaLUAtion_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (evaLUAtion_ENABLE_SANITIZER_ADDRESS OR evaLUAtion_ENABLE_SANITIZER_THREAD OR evaLUAtion_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(evaLUAtion_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(evaLUAtion_global_options)
  if(evaLUAtion_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    evaLUAtion_enable_ipo()
  endif()

  evaLUAtion_supports_sanitizers()

  if(evaLUAtion_ENABLE_HARDENING AND evaLUAtion_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR evaLUAtion_ENABLE_SANITIZER_UNDEFINED
       OR evaLUAtion_ENABLE_SANITIZER_ADDRESS
       OR evaLUAtion_ENABLE_SANITIZER_THREAD
       OR evaLUAtion_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${evaLUAtion_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${evaLUAtion_ENABLE_SANITIZER_UNDEFINED}")
    evaLUAtion_enable_hardening(evaLUAtion_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(evaLUAtion_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(evaLUAtion_warnings INTERFACE)
  add_library(evaLUAtion_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  evaLUAtion_set_project_warnings(
    evaLUAtion_warnings
    ${evaLUAtion_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  include(cmake/Linker.cmake)
  # Must configure each target with linker options, we're avoiding setting it globally for now

  if(NOT EMSCRIPTEN)
    include(cmake/Sanitizers.cmake)
    evaLUAtion_enable_sanitizers(
      evaLUAtion_options
      ${evaLUAtion_ENABLE_SANITIZER_ADDRESS}
      ${evaLUAtion_ENABLE_SANITIZER_LEAK}
      ${evaLUAtion_ENABLE_SANITIZER_UNDEFINED}
      ${evaLUAtion_ENABLE_SANITIZER_THREAD}
      ${evaLUAtion_ENABLE_SANITIZER_MEMORY})
  endif()

  set_target_properties(evaLUAtion_options PROPERTIES UNITY_BUILD ${evaLUAtion_ENABLE_UNITY_BUILD})

  if(evaLUAtion_ENABLE_PCH)
    target_precompile_headers(
      evaLUAtion_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(evaLUAtion_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    evaLUAtion_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(evaLUAtion_ENABLE_CLANG_TIDY)
    evaLUAtion_enable_clang_tidy(evaLUAtion_options ${evaLUAtion_WARNINGS_AS_ERRORS})
  endif()

  if(evaLUAtion_ENABLE_CPPCHECK)
    evaLUAtion_enable_cppcheck(${evaLUAtion_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(evaLUAtion_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    evaLUAtion_enable_coverage(evaLUAtion_options)
  endif()

  if(evaLUAtion_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(evaLUAtion_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(evaLUAtion_ENABLE_HARDENING AND NOT evaLUAtion_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR evaLUAtion_ENABLE_SANITIZER_UNDEFINED
       OR evaLUAtion_ENABLE_SANITIZER_ADDRESS
       OR evaLUAtion_ENABLE_SANITIZER_THREAD
       OR evaLUAtion_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    evaLUAtion_enable_hardening(evaLUAtion_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
