# cross compiling settings
set(CMAKE_SYSTEM_NAME Generic) # PSP
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_CROSSCOMPILING TRUE)

set(BUILD_SHARED_LIBS FALSE)
set(EXE_SUFFIX ".elf")

# utility
function(fatal)
    message(FATAL_ERROR ${ARGN})
endfunction()

function(status)
    message(STATUS ${ARGN})
endfunction()

macro(set_if_unset var)
    if (NOT ${var})
        set(${var} ${ARGN})
    endif()
endmacro()

macro(set_resource_default res path)
    if (NOT ${res})
        if (EXISTS "${path}")
            status("${res} found at ${path}")
            set(${res} "${path}")
        else()
            status("${res} not found at ${path}, defaulting to ${ARGN}")
            set(${res} ${ARGN})
        endif()
    endif()
endmacro()

# variables
set_if_unset(RES_DIR "${CMAKE_SOURCE_DIR}/res")

# make sure all the pspsdk programs exist
set(PSPSDK_PROGRAMS "psp-config" "mksfo" "pack-pbp" "psp-fixup-imports" "psp-strip" "psp-prxgen" "psp-build-exports" "psp-gcc" "psp-g++")

foreach(prog ${PSPSDK_PROGRAMS})
    string(REGEX REPLACE "-" "_" prog_var ${prog})
    string(TOUPPER ${prog_var} prog_var)

    find_program(${prog_var} ${prog})

    if(${${prog_var}} MATCHES "-NOTFOUND")
        fatal("${prog} not found")
    else()
        status("${prog} found")
    endif()
endforeach()

# set compiler
set(CMAKE_C_COMPILER   ${PSP_GCC})
set(CMAKE_CXX_COMPILER ${PSP_G++})
# this is needed to bypass (failing) compiler tests
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)

# set find root path
set(CMAKE_FIND_ROOT_PATH "")
foreach(i "--pspsdk-path" "--psp-prefix")#"--pspdev-path")
    execute_process(COMMAND "${PSP_CONFIG}" ${i}
                    OUTPUT_VARIABLE output
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    list(APPEND CMAKE_FIND_ROOT_PATH "${output}")
    include_directories(SYSTEM "${output}/include")
    link_directories("${output}/lib")
    # list(APPEND CMAKE_EXE_LINKER_FLAGS "-L${output}/lib")
endforeach()

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# set install path
execute_process(COMMAND ${PSP_CONFIG} "--psp-prefix"
                OUTPUT_VARIABLE CMAKE_INSTALL_PREFIX
                OUTPUT_STRIP_TRAILING_WHITESPACE)

# large memory
if(PSP_LARGE_MEMORY)
    find_program(MKSFO "mksfoex")
    
    if(NOT MKSFO)
        fatal("mksfoex not found")
    else()
        status("mksfoex found")
    endif()
    
    set(MKSFO "${MKSFO} -d MEMSIZE=1")
endif()

# firmware vesion
set_if_unset(PSP_FW_VERSION 150)

# does not appear to work
# add_definitions(-D_PSP_FW_VERSION=${PSP_FW_VERSION})

if(NOT PSP_DEBUG)
    set(PSP_DEBUG_FLAG "-G0")
endif()

set(CMAKE_C_FLAGS "${PSP_DEBUG_FLAG} -Wall -D_PSP_FW_VERSION=${PSP_FW_VERSION}" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS ${CMAKE_C_FLAGS} "-fno-exceptions -fno-rtti" CACHE STRING "" FORCE)

# pspsdk path
execute_process(COMMAND ${PSP_CONFIG} "--pspsdk-path"
                OUTPUT_VARIABLE PSPSDK_PATH
                OUTPUT_STRIP_TRAILING_WHITESPACE)

# pspsdk libs
if(PSP_USE_KERNEL_LIBRARIES)
    set(PSPSDK_LIBRARIES -nostdlib -lpspdebug -lpspdisplay_driver -lpspctrl_driver -lpspmodinfo -lpspsdk -lpspkernel)
else()
    set(PSPSDK_LIBRARIES -lpspdebug -lpspdisplay -lpspge -lpspctrl -lpspsdk -lpspnet -lpspnet_apctl)
endif()

set(LD_PAGESIZE "-Wl,-zmax-page-size=128")
list(APPEND CMAKE_EXE_LINKER_FLAGS ${LD_PAGESIZE})

# set ldflags
string(REPLACE ";" " " CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS ${CMAKE_EXE_LINKER_FLAGS} CACHE STRING "")

# EBOOT
set_resource_default(PSP_EBOOT_ICON "${RES_DIR}/ICON0.PNG" "NULL")
set_resource_default(PSP_EBOOT_ICON1 "${RES_DIR}/ICON1.PNG" "NULL")
set_resource_default(PSP_EBOOT_PIC0 "${RES_DIR}/PIC0.PNG" "NULL")
set_resource_default(PSP_EBOOT_PIC1 "${RES_DIR}/PIC1.PNG" "NULL")
set_resource_default(PSP_EBOOT_SND0 "${RES_DIR}/SND0.AT3" "NULL")
set_resource_default(PSP_EBOOT_PSAR "${RES_DIR}/DATA.PSAR" "NULL")
set_if_unset(PSP_EBOOT_SFO "${RES_DIR}/PARAM.SFO") # should this be in bin instead?
set_if_unset(PSP_EBOOT_PBP "${CMAKE_BINARY_DIR}/EBOOT.PBP")

# target
macro(psp_libraries)
    # the used psp libraries
    set(PSP_LIBS ${ARGN})
endmacro()

macro(add_psp_executable PNAME)
    set_if_unset(PSP_TARGET ${PNAME})
    set_if_unset(PSP_EBOOT_TITLE ${PSP_TARGET})

    add_executable(${PSP_TARGET} ${ARGN})
    set_target_properties(${PSP_TARGET} PROPERTIES SUFFIX ${EXE_SUFFIX})
    target_link_libraries(${PSP_TARGET} ${PSP_LIBS} ${PSPSDK_LIBRARIES})

    add_custom_command(OUTPUT "${PSP_EBOOT_SFO}"
                       COMMAND "${MKSFO}" "'${PSP_EBOOT_TITLE}'" "${PSP_EBOOT_SFO}")

    add_custom_command(TARGET ${PSP_TARGET} POST_BUILD
                       COMMAND "${PSP_FIXUP_IMPORTS}" "${PSP_TARGET}${EXE_SUFFIX}")
endmacro()

macro(add_prx_exports target PSP_TARGET)
    list(APPEND CMAKE_EXE_LINKER_FLAGS
         "-specs=${PSPSDK_PATH}/lib/prxspecs"
         "-Wl,-q,-T${PSPSDK_PATH}/lib/linkfile.prx")
    string(REPLACE ";" " " CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}")

    if(PRX_EXPORTS)
        string(REGEX REPLACE ".exp$" ".o" EXPORT_OBJ ${PRX_EXPORTS})
    else()
        set(EXPORT_OBJ ${PSPSDK_PATH}/lib/prxexports.o)
    endif()

    add_custom_command(OUTPUT ${PSP_TARGET}.prx
        COMMAND ${PSP_PRXGEN} ${PSP_TARGET}${EXE_SUFFIX} ${PSP_TARGET}.prx
        DEPENDS ${PSP_TARGET})

    add_custom_command(OUTPUT ${PSP_EBOOT_PBP}
        COMMAND ${PACK_PBP} ${PSP_EBOOT_PBP} ${PSP_EBOOT_SFO} ${PSP_EBOOT_ICON}
          ${PSP_EBOOT_ICON1} ${PSP_EBOOT_PIC0} ${PSP_EBOOT_PIC1}
          ${PSP_EBOOT_SND0} ${PSP_TARGET}.prx ${PSP_EBOOT_PSAR}
        DEPENDS ${PSP_EBOOT_SFO} ${PSP_TARGET}.prx)

    add_library(prx_exports ${EXPORT_OBJ})
    set_target_properties(prx_exports PROPERTIES LINKER_LANGUAGE C)
    set_source_files_properties(${EXPORT_OBJ} PROPERTIES EXTERNAL_OBJECT true GENERATED true)
    target_link_libraries(${PSP_TARGET} prx_exports)
    add_custom_target("${target}" DEPENDS "${PSP_EBOOT_PBP}")
endmacro()

macro(add_pbp target PSP_TARGET)
    set(PSP_STRIP_TARGET "${PSP_TARGET}_strip${EXE_SUFFIX}")

    add_custom_command(OUTPUT "${PSP_EBOOT_PBP}"
        COMMAND "${PSP_STRIP}" "${PSP_TARGET}${EXE_SUFFIX}"
                -o "${PSP_STRIP_TARGET}"
        COMMAND "${PACK_PBP}" "${PSP_EBOOT_PBP}" "${PSP_EBOOT_SFO}" "${PSP_EBOOT_ICON}"
                "${PSP_EBOOT_ICON1}" "${PSP_EBOOT_PIC0}" "${PSP_EBOOT_PIC1}"
                "${PSP_EBOOT_SND0}" "${PSP_STRIP_TARGET}" "${PSP_EBOOT_PSAR}"
        COMMAND rm -f "${PSP_STRIP_TARGET}"
        DEPENDS "${PSP_EBOOT_SFO}" "${PSP_TARGET}")

    add_custom_target("${target}" DEPENDS "${PSP_EBOOT_PBP}")
endmacro()
