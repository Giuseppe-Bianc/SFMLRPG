include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(SFMLRPG_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(SFMLRPG_setup_options)
  option(SFMLRPG_ENABLE_HARDENING "Enable hardening" ON)
  option(SFMLRPG_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    SFMLRPG_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    SFMLRPG_ENABLE_HARDENING
    OFF)

  SFMLRPG_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR SFMLRPG_PACKAGING_MAINTAINER_MODE)
    option(SFMLRPG_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(SFMLRPG_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(SFMLRPG_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(SFMLRPG_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(SFMLRPG_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(SFMLRPG_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(SFMLRPG_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(SFMLRPG_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(SFMLRPG_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(SFMLRPG_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(SFMLRPG_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(SFMLRPG_ENABLE_PCH "Enable precompiled headers" OFF)
    option(SFMLRPG_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(SFMLRPG_ENABLE_IPO "Enable IPO/LTO" ON)
    option(SFMLRPG_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(SFMLRPG_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(SFMLRPG_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(SFMLRPG_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(SFMLRPG_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(SFMLRPG_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(SFMLRPG_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(SFMLRPG_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(SFMLRPG_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(SFMLRPG_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(SFMLRPG_ENABLE_PCH "Enable precompiled headers" OFF)
    option(SFMLRPG_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      SFMLRPG_ENABLE_IPO
      SFMLRPG_WARNINGS_AS_ERRORS
      SFMLRPG_ENABLE_USER_LINKER
      SFMLRPG_ENABLE_SANITIZER_ADDRESS
      SFMLRPG_ENABLE_SANITIZER_LEAK
      SFMLRPG_ENABLE_SANITIZER_UNDEFINED
      SFMLRPG_ENABLE_SANITIZER_THREAD
      SFMLRPG_ENABLE_SANITIZER_MEMORY
      SFMLRPG_ENABLE_UNITY_BUILD
      SFMLRPG_ENABLE_CLANG_TIDY
      SFMLRPG_ENABLE_CPPCHECK
      SFMLRPG_ENABLE_COVERAGE
      SFMLRPG_ENABLE_PCH
      SFMLRPG_ENABLE_CACHE)
  endif()

  SFMLRPG_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (SFMLRPG_ENABLE_SANITIZER_ADDRESS OR SFMLRPG_ENABLE_SANITIZER_THREAD OR SFMLRPG_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(SFMLRPG_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(SFMLRPG_global_options)
  if(SFMLRPG_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    SFMLRPG_enable_ipo()
  endif()

  SFMLRPG_supports_sanitizers()

  if(SFMLRPG_ENABLE_HARDENING AND SFMLRPG_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR SFMLRPG_ENABLE_SANITIZER_UNDEFINED
       OR SFMLRPG_ENABLE_SANITIZER_ADDRESS
       OR SFMLRPG_ENABLE_SANITIZER_THREAD
       OR SFMLRPG_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${SFMLRPG_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${SFMLRPG_ENABLE_SANITIZER_UNDEFINED}")
    SFMLRPG_enable_hardening(SFMLRPG_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(SFMLRPG_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(SFMLRPG_warnings INTERFACE)
  add_library(SFMLRPG_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  SFMLRPG_set_project_warnings(
    SFMLRPG_warnings
    ${SFMLRPG_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(SFMLRPG_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    configure_linker(SFMLRPG_options)
  endif()

  include(cmake/Sanitizers.cmake)
  SFMLRPG_enable_sanitizers(
    SFMLRPG_options
    ${SFMLRPG_ENABLE_SANITIZER_ADDRESS}
    ${SFMLRPG_ENABLE_SANITIZER_LEAK}
    ${SFMLRPG_ENABLE_SANITIZER_UNDEFINED}
    ${SFMLRPG_ENABLE_SANITIZER_THREAD}
    ${SFMLRPG_ENABLE_SANITIZER_MEMORY})

  set_target_properties(SFMLRPG_options PROPERTIES UNITY_BUILD ${SFMLRPG_ENABLE_UNITY_BUILD})

  if(SFMLRPG_ENABLE_PCH)
    target_precompile_headers(
      SFMLRPG_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(SFMLRPG_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    SFMLRPG_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(SFMLRPG_ENABLE_CLANG_TIDY)
    SFMLRPG_enable_clang_tidy(SFMLRPG_options ${SFMLRPG_WARNINGS_AS_ERRORS})
  endif()

  if(SFMLRPG_ENABLE_CPPCHECK)
    SFMLRPG_enable_cppcheck(${SFMLRPG_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(SFMLRPG_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    SFMLRPG_enable_coverage(SFMLRPG_options)
  endif()

  if(SFMLRPG_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(SFMLRPG_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(SFMLRPG_ENABLE_HARDENING AND NOT SFMLRPG_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR SFMLRPG_ENABLE_SANITIZER_UNDEFINED
       OR SFMLRPG_ENABLE_SANITIZER_ADDRESS
       OR SFMLRPG_ENABLE_SANITIZER_THREAD
       OR SFMLRPG_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    SFMLRPG_enable_hardening(SFMLRPG_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
