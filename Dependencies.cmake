include(cmake/CPM.cmake)

# Done as a function so that updates to variables like
# CMAKE_CXX_FLAGS don't propagate out to other
# targets
function(SFMLRPG_setup_dependencies)

  # For each dependency, see if it's
  # already been provided to us by a parent project

  if(NOT TARGET fmtlib::fmtlib)
    cpmaddpackage("gh:fmtlib/fmt#10.1.1")
  endif()

  if(NOT TARGET spdlog::spdlog)
    cpmaddpackage(
      NAME
      spdlog
      VERSION
      1.12.0
      GITHUB_REPOSITORY
      "gabime/spdlog"
      OPTIONS
      "SPDLOG_FMT_EXTERNAL ON"
      "SPDLOG_ENABLE_PCH ON"
      "SPDLOG_BUILD_PIC ON"
      "SPDLOG_WCHAR_SUPPORT ON"
      "SPDLOG_WCHAR_FILENAMES ON"
      "SPDLOG_BUILD_WARNINGS ON")

  endif()

  if(NOT TARGET CLI11::CLI11)
    cpmaddpackage("gh:CLIUtils/CLI11@2.3.2")
  endif()

  if(NOT TARGET sfml::sfml)
    cpmaddpackage(
      NAME SFML
      GITHUB_REPOSITORY SFML/SFML
      GIT_TAG 2.6.0  # Replace with the desired SFML version tag
      OPTIONS
        "SFML_BUILD_EXAMPLES Off"
        "SFML_BUILD_TESTS Off")
  endif()

  if(NOT TARGET tools::tools)
    cpmaddpackage("gh:lefticus/tools#update_build_system")
  endif()

endfunction()
