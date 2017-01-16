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
