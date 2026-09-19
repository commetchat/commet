cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "tray_manager")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "tray_manager_plugin")

find_package(PkgConfig REQUIRED)

add_library(${PLUGIN_NAME} SHARED
  "tray_manager_plugin.cc"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

pkg_check_modules(APPINDICATOR IMPORTED_TARGET ayatana-appindicator3-0.1)
if(APPINDICATOR_FOUND)
  target_compile_definitions(${PLUGIN_NAME} PRIVATE HAVE_AYATANA)
else()
  pkg_check_modules(APPINDICATOR IMPORTED_TARGET appindicator3-0.1)
endif()
# COMMET: optional. Without an appindicator the plugin still builds and every
# call answers "not implemented", so the app runs without a tray icon instead
# of failing to build (the Flatpak runtime has none).
if(APPINDICATOR_FOUND)
  target_compile_definitions(${PLUGIN_NAME} PRIVATE HAVE_APPINDICATOR)
  target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::APPINDICATOR)
else()
  message(
    WARNING
    "tray_manager: ayatana-appindicator3-0.1 / appindicator3-0.1 not found -- building without a tray icon. Install libayatana-appindicator3-dev to enable it."
  )
endif()

# List of absolute paths to libraries that should be bundled with the plugin
set(tray_manager_bundled_libraries
  ""
  PARENT_SCOPE
)
