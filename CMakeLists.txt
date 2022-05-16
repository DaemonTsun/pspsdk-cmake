cmake_minimum_required(VERSION 3.18)

project(pspsdk-cmake)

# sources
set(SOURCE_CMAKE_CONFIG_FILE "${CMAKE_SOURCE_DIR}/cmake/pspsdkConfig.cmake")

# install
install(FILES "${SOURCE_CMAKE_CONFIG_FILE}" DESTINATION "share/${PROJECT_NAME}/cmake")
