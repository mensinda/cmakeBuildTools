# cmakeBuildTools
Useful functions for CMake projects

# function `split_arg_list( SECTIONS ARGS )`
split_arg_list is an utility macro that splits the parameters into specific SECTIONS. This alows for an easy implementation of the CMake like parameter system.

Every item in `SECTIONS` will be can then be accessed as a variable.

Example:
```cmake
# set( ARGV "FOO;first;second;BAR;third;fourth" )
split_arg_list( "FOO;BAR" "${ARGV}" )
# ==> FOO = "first;second"
#     BAR = "third;fourth"
```

# function `add_compiler( COMPILER ARG1 ARG2 ... )`

Set compiler flags
1st parameter: the CMake compiler ID
Sections:
```
ALL:         compiler options for all build types
DEBUG:       compiler options only for the DEBUG build type
RELEASE:     compiler options only for the RELEASE build type
SANITIZE:    sanitizer option. Will only be enabled on DEBUG build type and when the variable ENABLE_SANITIZERS is set
MIN_VERSION: the min. compiler version
```

# function `enum2str_generate( ... )`
 Usage:
```
 enum2str_generate
    PATH           <path to generate files in>
    CLASS_NAME     <name of the class (file names will be PATH/CLASS_NAME.{hpp,cpp})>
    FUNC_NAME      <the name of the function>
    INCLUDES       <files to include (where the enums are)>
    NAMESPACE      <namespace to use>
    ENUMS          <list of enums to generate>
    BLACKLIST      <blacklist for enum constants>
    USE_CONSTEXPR  <whether to use constexpr or not (default: off)>
    USE_C_STRINGS  <whether to use c strings instead of std::string or not (default: off)>
```

# function `find_source_files(...)`

Searches the a directory recursively for source files

```
Usage:
 find_source_files
    PATH    <root search path>
    EXT_CPP <cpp file extensions (without the first '.')>
    EXT_HPP <hpp file extensions (without the first '.')>

Generated variables:
  ${PROJECT_NAME}_UNASIGNED_{C,H}PP  # All source files
  ${PROJECT_NAME}_ALL_{C,H}PP        # Source files independent of OS / target
  ${PROJECT_NAME}_${TARGET}_{C,H}PP  # Source files of target ${TARGET}
```

ALL sections must be set!

# macro `export_found_files(ROOT_PATH)`

Exports all lists from find_source_files with an additional ALL prefix

# function `add_platform(...)`

Adds a operating system with (multiple) graphic API's

```
Usage:
  add_platform
    OS     <the operating system>
    TARGET <supported targets (aka subdirectories in the source tree) of the OS>

 Variables:
    PLATFORM_TARGET               - the secondary target of one OS
    ${PROJECT_NAME}_PLATFORM_LIST - list of all platforms added so far (output)
```

# check_platform()

Checks the the `PLATFORM_TARGET` list. Also generates a `CM_${I}` variable (= 0/1) for every target of
each platform / OS.

# function `select_sources()`

Sets `CM_CURRENT_SRC_CPP`, `CM_CURRENT_SRC_HPP` and `CURRENT_INCLUDE_DIRS` for the current platform

# function `run_git()`

Collects version information about the current git repository

Output variables:
```
 - CMAKE_BUILD_TYPE (if not already set)
 - DEBUG_LOGGING
 - CM_VERSION_MAJOR
 - CM_VERSION_MINOR
 - CM_VERSION_SUBMINOR
 - CM_TAG_DIFF
 - CM_VERSION_GIT
```

# function `generate_format_command(CMD_NAME CM_CLANG_FORMAT_VER)`

Adds a new make target `CMD_NAME` that formats the entire source code with clang-format
