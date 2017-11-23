# Copyright (c) 2017, Daniel Mensinger
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the <organization> nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Usage:
# enum2str_generate
#    PATH             <path to generate files in>
#    CLASS_NAME       <name of the class (file names will be PATH/CLASS_NAME.{hpp,cpp})>
#    FUNC_NAME        <the name of the function>
#    BITFIELD_TYPE    <integer type of the bitfields (e.g. uint64_t)>
#    CONCATINATE_STR  <string used to concatinate bitfield strings>
#    INDENT_STR       <a string used for one level of indentation>
#    INCLUDES         <files to include (where the enums are)>
#    NAMESPACE        <namespace to use>
#    ENUMS            <list of enums to generate>
#    BLACKLIST        <blacklist for enum constants>
#    USE_CONSTEXPR    <whether to use constexpr or not (default: off)>
#    USE_C_STRINGS    <whether to use c strings instead of std::string or not (default: off)>
#    ENABLE_BITFIELDS <enables the generation of bit field functions>
function( enum2str_generate )
  set( options        USE_CONSTEXPR USE_C_STRINGS ENABLE_BITFIELDS)
  set( oneValueArgs   PATH CLASS_NAME FUNC_NAME NAMESPACE INDENT_STR BITFIELD_TYPE CONCATINATE_STR)
  set( multiValueArgs INCLUDES ENUMS BLACKLIST )
  cmake_parse_arguments( OPTS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  if( OPTS_USE_C_STRINGS )
    set( STRING_TYPE "const char *" )
  else()
    set( STRING_TYPE "std::string" )
  endif()

  message( STATUS "Generating enum2str files" )

  if( "${OPTS_INDENT_STR}" STREQUAL "" )
    set( IND "  " )
  else()
    set( IND "${OPTS_INDENT_STR}" )
  endif()

  __enum2str_checkSet( OPTS_PATH )
  __enum2str_checkSet( OPTS_CLASS_NAME )
  __enum2str_checkSet( OPTS_NAMESPACE )
  __enum2str_checkSet( OPTS_FUNC_NAME )

  if( OPTS_ENABLE_BITFIELDS )
    __enum2str_checkSet( OPTS_BITFIELD_TYPE )
    __enum2str_checkSet( OPTS_CONCATINATE_STR )
  endif()

  set( HPP_FILE "${OPTS_PATH}/${OPTS_CLASS_NAME}.hpp" )
  set( CPP_FILE "${OPTS_PATH}/${OPTS_CLASS_NAME}.cpp" )

  enum2str_init()

  #########################
  # Loading include files #
  #########################

  get_property( INC_DIRS DIRECTORY ${CMAKE_HOME_DIRECTORY} PROPERTY INCLUDE_DIRECTORIES )
  message( STATUS "  - Resolving includes:" )

  foreach( I IN LISTS OPTS_INCLUDES )
    set( FOUND 0 )
    set( TEMP )
    find_path( TEMP NAMES ${I} )
    list( APPEND INC_DIRS ${TEMP} )
    foreach( J IN LISTS INC_DIRS )
      if( EXISTS "${J}/${I}" )
        message( STATUS "    - ${I}: ${J}/${I}" )
        file( READ "${J}/${I}" TEMP )
        string( APPEND RAW_DATA "${TEMP}" )
        set( FOUND 1 )
        break()
      endif()
    endforeach()

    if( NOT "${FOUND}" STREQUAL "1" )
      message( FATAL_ERROR "Unable to find ${I}! (Try running include_directories(...))" )
    endif()
  endforeach()

  #####################
  # Finding the enums #
  #####################

  set( CONSTANSTS 0 )

  # Remove comments and macros
  string( REGEX REPLACE "//[^\n]*"                "" RAW_DATA "${RAW_DATA}" )
  string( REGEX REPLACE "/\\*([^*]|\\*[^/])*\\*/" "" RAW_DATA "${RAW_DATA}" )
  string( REGEX REPLACE "\r?\n[ \t]*#[^\n]*"      "" RAW_DATA "${RAW_DATA}" )

  foreach( I IN LISTS OPTS_ENUMS )
    set( ENUM_NS    "" )
    set( ENUM_SCOPE "" )

    # Generate the name of the enum
    string( REGEX REPLACE ".*::" "" ENUM_NAME "${I}" )
    if( "${I}" MATCHES "(.*)::[^:]+" )
      string( REGEX REPLACE "(.*)::[^:]+" "\\1::" ENUM_NS    "${I}" )
      string( REGEX REPLACE "::$"         ""      ENUM_SCOPE "${ENUM_NS}" )
      string( REGEX REPLACE "^[^:]+::"    ""      ENUM_SCOPE "${ENUM_SCOPE}" )
    endif()

    if( NOT ENUM_SCOPE STREQUAL "" )
      string( REGEX MATCH "(struct|class|namespace)[ \t\n]+${ENUM_SCOPE}[^;:]*(:[^{;]+)?[ \t\n]*{.*" P0 "${RAW_DATA}" )
    else()
      set( P0 "${RAW_DATA}" )
    endif()

    # Extract only the enum
    string( REGEX MATCH "enum[ \t\n]+((struct|class)[ \t\n]+)?${ENUM_NAME}[ \t\n]*(:[^{]+)?{[^}]*}" P1 "${P0}" )
    if( "${P1}" STREQUAL "" )
      string( REGEX MATCH "enum[ \t\n]+{[^}]*}[ \t\n]+${ENUM_NAME};" P1 "${P0}" )

      if( "${P1}" STREQUAL "" )
        message( WARNING "enum '${I}' not found!" )
        continue()
      endif()
    endif()

    # Check if the enum is scoped
    string( REGEX MATCH "^enum[ \t\n]+(struct|class)" IS_SCOPED "${P1}" )
    if( NOT IS_SCOPED STREQUAL "" )
      string( APPEND ENUM_NS "${ENUM_NAME}::" )
    endif()

    # Convert the eunmeration to a list
    string( REGEX REPLACE "enum[ \t\n]+((struct|class)[ \t\n]+)?${ENUM_NAME}[ \t\n]*(:[^{]+)?" "" P1 "${P1}" )
    string( REGEX REPLACE "enum[ \t\n]*{"                                                      "" P1 "${P1}" )
    string( REGEX REPLACE "}[ \t\n]*${ENUM_NAME}[ \t\n]*;"                                     "" P1 "${P1}" )
    string( REGEX REPLACE "[ \t\n{};]"                                                         "" P1 "${P1}" )
    string( REGEX REPLACE ",$" "" P1 "${P1}" ) # Remove trailing ,
    string( REGEX REPLACE "," ";" L1 "${P1}" ) # Make a List

    set( ENUMS_TO_USE )
    set( RESULTS )

    # Checking enums
    foreach( J IN LISTS L1 )
      set( EQUALS "" )
      if( "${J}" MATCHES ".+=.+" )
        string( REGEX REPLACE ".+=[ \n\t]*([^ \n\t]+)[ \n\t]*" "\\1" EQUALS "${J}" )
      endif()
      string( REGEX REPLACE "[ \t\n]*=.*" "" J "${J}" )

      if( "${J}" IN_LIST OPTS_BLACKLIST )
        continue()
      endif()

      if( "${EQUALS}" STREQUAL "" )
        list( APPEND ENUMS_TO_USE "${J}" )
      else()
        # Avoid duplicates:
        if( "${J}" IN_LIST ENUMS_TO_USE )
          continue()
        endif()
        if( "${EQUALS}" IN_LIST ENUMS_TO_USE )
          continue()
        endif()
        if( "${EQUALS}" IN_LIST RESULTS )
          continue()
        endif()

        list( APPEND RESULTS "${EQUALS}" )
        list( APPEND ENUMS_TO_USE "${J}" )
      endif()
    endforeach()

    enum2str_add( "${I}" "${ENUM_NAME}" )
    list( LENGTH ENUMS_TO_USE NUM_ENUMS )
    math( EXPR CONSTANSTS "${CONSTANSTS} + ${NUM_ENUMS}" )
  endforeach()

  list( LENGTH OPTS_ENUMS NUM_ENUMS )
  message( STATUS "  - Generated ${NUM_ENUMS} enum2str functions" )
  message( STATUS "  - Found a total of ${CONSTANSTS} constants" )

  enum2str_end()
  message( "" )
endfunction( enum2str_generate )

macro( __enum2str_checkSet )
  if( NOT DEFINED ${ARGV0} )
    message( FATAL_ERROR "enum2str_generate: ${ARGV0} not set" )
  endif()
endmacro( __enum2str_checkSet )

function( enum2str_add )
  set( MAX_LENGTH 0 )

  foreach( I IN LISTS ENUMS_TO_USE )
    string( LENGTH "${I}" LEN )
    if( LEN GREATER MAX_LENGTH )
      set( MAX_LENGTH ${LEN} )
    endif()
  endforeach()

  if( OPTS_USE_CONSTEXPR )
    file( APPEND "${HPP_FILE}" "${IND}/*!\n    * \\brief Converts the enum ${ARGV0} to a c string\n" )
    file( APPEND "${HPP_FILE}" "${IND} * \\param _var The enum value to convert\n" )
    file( APPEND "${HPP_FILE}" "${IND} * \\returns _var converted to a c string\n    */\n" )
    file( APPEND "${HPP_FILE}" "${IND}static constexpr const char *${OPTS_FUNC_NAME}( ${ARGV0} _var ) noexcept {\n" )
    file( APPEND "${HPP_FILE}" "${IND}${IND}switch ( _var ) {\n" )

    foreach( I IN LISTS ENUMS_TO_USE )
      set( PADDING )
      string( LENGTH "${I}" LEN )
      math( EXPR TO_PAD "${MAX_LENGTH} - ${LEN}" )
      foreach( J RANGE ${TO_PAD} )
        string( APPEND PADDING " " )
      endforeach()

      file( APPEND "${HPP_FILE}" "${IND}${IND}${IND}case ${ENUM_NS}${I}:${PADDING}return \"${I}\";\n" )
    endforeach()

    set( PADDING )
    string( LENGTH "default"         LEN )
    string( LENGTH "case ${ENUM_NS}" LEN2 )
    math( EXPR TO_PAD "(${MAX_LENGTH} + ${LEN2}) - ${LEN}" )
    foreach( J RANGE ${TO_PAD} )
      string( APPEND PADDING " " )
    endforeach()

    file( APPEND "${HPP_FILE}" "${IND}${IND}${IND}default:${PADDING}return \"<UNKNOWN>\";\n" )
    file( APPEND "${HPP_FILE}" "${IND}${IND}}\n${IND}}\n\n" )
  else()
    file( APPEND "${HPP_FILE}" "${IND}static ${STRING_TYPE} ${OPTS_FUNC_NAME}( ${ARGV0} _var ) noexcept;\n" )

    file( APPEND "${CPP_FILE}" "/*!\n * \\brief Converts the enum ${ARGV0} to a ${STRING_TYPE}\n" )
    file( APPEND "${CPP_FILE}" " * \\param _var The enum value to convert\n" )
    file( APPEND "${CPP_FILE}" " * \\returns _var converted to a ${STRING_TYPE}\n */\n" )
    file( APPEND "${CPP_FILE}" "${STRING_TYPE} ${OPTS_CLASS_NAME}::${OPTS_FUNC_NAME}( ${ARGV0} _var ) noexcept {\n" )
    file( APPEND "${CPP_FILE}" "${IND}switch ( _var ) {\n" )

    foreach( I IN LISTS ENUMS_TO_USE )
      set( PADDING )
      string( LENGTH "${I}" LEN )
      math( EXPR TO_PAD "${MAX_LENGTH} - ${LEN}" )
      foreach( J RANGE ${TO_PAD} )
        string( APPEND PADDING " " )
      endforeach()

      file( APPEND "${CPP_FILE}" "${IND}${IND}case ${ENUM_NS}${I}:${PADDING}return \"${I}\";\n" )
    endforeach()

    set( PADDING )
    string( LENGTH "default"         LEN )
    string( LENGTH "case ${ENUM_NS}" LEN2 )
    math( EXPR TO_PAD "(${MAX_LENGTH} + ${LEN2}) - ${LEN}" )
    foreach( J RANGE ${TO_PAD} )
      string( APPEND PADDING " " )
    endforeach()

    file( APPEND "${CPP_FILE}" "${IND}${IND}default:${PADDING}return \"<UNKNOWN>\";\n" )
    file( APPEND "${CPP_FILE}" "${IND}}\n}\n\n" )
  endif()

  if( OPTS_ENABLE_BITFIELDS )
    set( FUNC_NAME "${ARGV0}_${OPTS_FUNC_NAME}" )
    string( REGEX REPLACE "::" "_" FUNC_NAME "${FUNC_NAME}" )

    file( APPEND "${HPP_FILE}" "${IND}static std::vector<${STRING_TYPE}> ${FUNC_NAME}_Raw( ${OPTS_BITFIELD_TYPE} _var ) noexcept;\n" )
    file( APPEND "${HPP_FILE}" "${IND}static ${STRING_TYPE} ${FUNC_NAME}( ${OPTS_BITFIELD_TYPE} _var ) noexcept;\n\n" )

    file( APPEND "${CPP_FILE}" "/*!\n * \\brief Converts the enum bitfield ${ARGV0} to std::vector of ${STRING_TYPE}\n" )
    file( APPEND "${CPP_FILE}" " * \\param _var The bitfield value to convert\n" )
    file( APPEND "${CPP_FILE}" " * \\returns _var converted to a std::vector<${STRING_TYPE}>\n */\n" )
    file( APPEND "${CPP_FILE}" "std::vector<${STRING_TYPE}> ${OPTS_CLASS_NAME}::${FUNC_NAME}_Raw( ${OPTS_BITFIELD_TYPE} _var ) noexcept {\n" )
    file( APPEND "${CPP_FILE}" "${IND}std::vector<${STRING_TYPE}> list;\n\n")

    foreach( I IN LISTS ENUMS_TO_USE )
      set( PADDING )
      string( LENGTH "${I}" LEN )
      math( EXPR TO_PAD "${MAX_LENGTH} - ${LEN}" )
      foreach( J RANGE ${TO_PAD} )
        string( APPEND PADDING " " )
      endforeach()

      file( APPEND "${CPP_FILE}" "${IND}if( ( _var & ${ENUM_NS}${I}${PADDING}) == ${ENUM_NS}${I}${PADDING}) list.emplace_back( \"${I}\"${PADDING});\n" )
    endforeach()

    file( APPEND "${CPP_FILE}" "\n${IND}return list;\n" )
    file( APPEND "${CPP_FILE}" "}\n\n" )

    file( APPEND "${CPP_FILE}" "/*!\n * \\brief Converts the enum bitfield ${ARGV0} to a ${STRING_TYPE}\n" )
    file( APPEND "${CPP_FILE}" " * \\param _var The bitfield value to convert\n" )
    file( APPEND "${CPP_FILE}" " * \\returns The _var bitfield converted to a ${STRING_TYPE}\n */\n" )
    file( APPEND "${CPP_FILE}" "${STRING_TYPE} ${OPTS_CLASS_NAME}::${FUNC_NAME}( ${OPTS_BITFIELD_TYPE} _var ) noexcept {\n" )
    file( APPEND "${CPP_FILE}" "${IND}return stringListToString( ${FUNC_NAME}_Raw( _var ) );\n" )
    file( APPEND "${CPP_FILE}" "}\n\n" )
  endif()
endfunction( enum2str_add )


function( enum2str_init )
  string( TOUPPER ${OPTS_CLASS_NAME} OPTS_CLASS_NAME_UPPERCASE )

  file( WRITE  "${HPP_FILE}" "/*!\n" )
  file( APPEND "${HPP_FILE}" " * \\file ${OPTS_CLASS_NAME}.hpp\n" )
  file( APPEND "${HPP_FILE}" " * \\warning This is an automatically generated file!\n" )
  file( APPEND "${HPP_FILE}" " */\n\n" )
  file( APPEND "${HPP_FILE}" "#pragma once\n\n// clang-format off\n\n" )
  file( APPEND "${HPP_FILE}" "#include <string>\n" )

  if( OPTS_ENABLE_BITFIELDS )
    file( APPEND "${HPP_FILE}" "#include <vector>\n" )
  endif()

  foreach( I IN LISTS OPTS_INCLUDES )
    file( APPEND "${HPP_FILE}" "#include <${I}>\n" )
  endforeach()

  file( APPEND "${HPP_FILE}" "\nnamespace ${OPTS_NAMESPACE} {\n\n" )
  file( APPEND "${HPP_FILE}" "class ${OPTS_CLASS_NAME} {\n" )
  file( APPEND "${HPP_FILE}" " public:\n" )

  if( NOT OPTS_USE_CONSTEXPR OR OPTS_ENABLE_BITFIELDS )
    file( WRITE  "${CPP_FILE}" "/*!\n" )
    file( APPEND "${CPP_FILE}" " * \\file ${OPTS_CLASS_NAME}.cpp\n" )
    file( APPEND "${CPP_FILE}" " * \\warning This is an automatically generated file!\n" )
    file( APPEND "${CPP_FILE}" " */\n\n" )
    file( APPEND "${CPP_FILE}" "#pragma GCC diagnostic push\n" )
    file( APPEND "${CPP_FILE}" "#pragma GCC diagnostic ignored \"-Wpragmas\"\n" )
    file( APPEND "${CPP_FILE}" "#pragma GCC diagnostic ignored \"-Wsign-compare\"\n" )
    file( APPEND "${CPP_FILE}" "#pragma GCC diagnostic ignored \"-Wsign-conversion\"\n" )
    file( APPEND "${CPP_FILE}" "#pragma GCC diagnostic ignored \"-Wcovered-switch-default\"\n\n" )
    file( APPEND "${CPP_FILE}" "#include \"${OPTS_CLASS_NAME}.hpp\"\n\n// clang-format off\n\n" )
    file( APPEND "${CPP_FILE}" "namespace ${OPTS_NAMESPACE} {\n\n" )
  endif()

  if( OPTS_ENABLE_BITFIELDS )
    file( APPEND "${HPP_FILE}" "${IND}static ${STRING_TYPE} stringListToString(std::vector<${STRING_TYPE}> _list) noexcept;\n\n\n" )

    file( APPEND "${CPP_FILE}" "/*!\n * \\brief Converts the list of strings to one string concatinated with '${OPTS_CONCATINATE_STR}'\n" )
    file( APPEND "${CPP_FILE}" " * \\param _list The list of strings to convert\n" )
    file( APPEND "${CPP_FILE}" " * \\returns The converted _list\n */\n" )
    file( APPEND "${CPP_FILE}" "${STRING_TYPE} ${OPTS_CLASS_NAME}::stringListToString(std::vector<${STRING_TYPE}> _list) noexcept {\n" )
    file( APPEND "${CPP_FILE}" "${IND}${STRING_TYPE} lResult;\n" )
    file( APPEND "${CPP_FILE}" "${IND}for( size_t i = 0; i < _list.size(); ++i ) {\n" )
    file( APPEND "${CPP_FILE}" "${IND}${IND}if( i != 0 ) {\n" )
    file( APPEND "${CPP_FILE}" "${IND}${IND}${IND}lResult += \"${OPTS_CONCATINATE_STR}\";\n" )
    file( APPEND "${CPP_FILE}" "${IND}${IND}}\n\n" )
    file( APPEND "${CPP_FILE}" "${IND}${IND}lResult += _list[i];\n" )
    file( APPEND "${CPP_FILE}" "${IND}}\n" )
    file( APPEND "${CPP_FILE}" "${IND}return lResult;\n" )
    file( APPEND "${CPP_FILE}" "}\n\n\n" )
  endif()
endfunction( enum2str_init )


function( enum2str_end )
  string( TOUPPER ${OPTS_CLASS_NAME} OPTS_CLASS_NAME_UPPERCASE )

  file( APPEND "${HPP_FILE}" "};\n\n}\n\n// clang-format on\n" )
  if( NOT OPTS_USE_CONSTEXPR OR OPTS_ENABLE_BITFIELDS )
    file( APPEND "${CPP_FILE}" "\n}\n" )
    file( APPEND "${CPP_FILE}" "// clang-format on\n\n#pragma GCC diagnostic pop\n" )
  endif()

endfunction( enum2str_end )
