cmake_minimum_required(VERSION 3.18)

# set(PSP_DEBUG TRUE)
# set(PSP_USE_KERNEL_LIBRARIES FALSE)
# set(PSP_LARGE_MEMORY TRUE)
# set(PSP_FW_VERSION 150)
find_package(pspsdk REQUIRED)

project(cmake-kprint)

set(SRC "${CMAKE_SOURCE_DIR}/src")

file(GLOB_RECURSE HEADERS "${SRC}/*.h" "${SRC}/*.hpp" "${SRC}/*.tcc")
file(GLOB_RECURSE SOURCES "${SRC}/*.c" "${SRC}/*.cpp")

include_directories("${SRC}")

psp_libraries(pspdebug psphprm_driver)
add_psp_executable(${PROJECT_NAME} ${HEADERS} ${SOURCES} )

# add_prx_exports(eboot.pbp ${PROJECT_NAME})
add_pbp(eboot.pbp ${PROJECT_NAME})
