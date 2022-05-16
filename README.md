# pspsdk-cmake
CMake config for [pspsdk](https://github.com/pspdev/pspsdk).

## Prerequisites

Make sure [pspsdk](https://github.com/pspdev/pspsdk) is installed. `pspsdk-cmake` will complain with appropriate error messages if pspsdk tools are missing.

## Installation

    $ mkdir bin
    $ cd bin
    $ cmake ..
    $ sudo make install
    
## Usage

Include the package in the `CMakeLists.txt` file, CMake will terminate if the package is not found:

    find_package(pspsdk REQUIRED)
    
(optional) Define which (additional) psp libraries are used:
The order of the libraries is important.

    psp_libraries(pspdebug pspgum pspgu)
    
Add the psp executable:

    add_psp_executable(${PROJECT_NAME} ${HEADERS} ${SOURCES})
    
(optional) Create a eboot.pbp target:

    add_pbp(eboot.pbp ${PROJECT_NAME})

(optional) Create a eboot.pbp target with prx exports:

    add_prx_exports(eboot.pbp ${PROJECT_NAME})
    
Then simply run CMake to build the executable (elf):

    $ mkdir bin
    $ cd bin
    $ cmake ..
    $ make

(optional) To build the eboot.pbp archive, run:

    $ make eboot.pbp

## Configuration

Before the `find_package(pspsdk REQUIRED)` line, pspsdk-cmake may be configured using these variables (see examples):

- `PSP_DEBUG`: if set to TRUE, the targets will include debug symbols.
- `PSP_USE_KERNEL_LIBRARIES`: if set to TRUE, targets will use a different set of psp libraries, namely the psp kernel libraries.
- `PSP_LARGE_MEMORY`: builds the executables with large memory enabled using `mksfoex`.
- `PSP_FW_VERSION`: sets the PSP firmware version. 150 by default.

## Examples / Demos

View the [demos directory](/demos) for some example projects using pspsdk-cmake.
