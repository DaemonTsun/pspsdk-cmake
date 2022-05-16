cmake_minimum_required(VERSION 3.18)

# set(PSP_DEBUG TRUE)
# set(PSP_USE_KERNEL_LIBRARIES FALSE)
# set(PSP_LARGE_MEMORY TRUE)
# set(PSP_FW_VERSION 150)
find_package(pspsdk REQUIRED)

project(cmake-cube)

set(SRC "${CMAKE_SOURCE_DIR}/src")

file(GLOB_RECURSE HEADERS "${SRC}/*.h" "${SRC}/*.hpp" "${SRC}/*.tcc")
file(GLOB_RECURSE SOURCES "${SRC}/*.c" "${SRC}/*.cpp")

add_custom_command(OUTPUT "logo.o"
    COMMAND bin2o -i "${SRC}/logo.raw" "logo.o" logo)

include_directories("${SRC}")

psp_libraries(pspgum pspgu)
add_psp_executable(${PROJECT_NAME} ${HEADERS} ${SOURCES} logo.o)

# add_prx_exports(eboot.pbp ${PROJECT_NAME})
add_pbp(eboot.pbp ${PROJECT_NAME})
