add_executable(sflmlrpg src/main.cpp 
                        src/casts.h
                        src/headers.h
                        src/Timer.h)

target_link_libraries(
  sflmlrpg
  PRIVATE SFMLRPG::SFMLRPG_options
          SFMLRPG::SFMLRPG_warnings)

target_link_system_libraries(
  sflmlrpg
  PRIVATE
          fmt::fmt
          spdlog::spdlog
          lefticus::tools
          ${SFML_LIBRARIES})

