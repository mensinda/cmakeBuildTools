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

# new_project_executable searches for source files in PATH and generates a CMakeLists.txt.
# The (optional) CMakeScript.cmake in PATH will be executed first
#
# Usage:
# new_project_executable
#    NAME         <Name of the library>
#    PATH         <path to the source dir>
#    TEMPLATE     <path to the CMake template file>
#    DEPENDENCIES <dependencies (optional)>
#
# Variables available in the template:
#    CM_CURRENT_SRC_CPP
#    CM_CURRENT_SRC_HPP
#    CM_CURRENT_EXE_SRC
#    CM_CURRENT_EXE_INC
#    CM_CURRENT_EXE_LC
#    CM_CURRENT_EXE_UC
#    CURRENT_INCLUDE_DIRS
#
# Exported variables (multiple calls to new_project_executable will extend these lists)
#    ${PROJECT_NAME}_SUBDIR_LIST              <List of all generated subdirectories>
#    ${PROJECT_NAME}_ALL_UNASIGNED_<H,C>PP    <List of ALL source files (has a CPP and HPP version)>
#    ${PROJECT_NAME}_ALL_SRC_${I}_<H,C>PP     <List of source files for platform target ${I} (has a CPP and HPP version)>
#    ${PROJECT_NAME}_ALL_SRC_ALL_<H,C>PP      <List of source files for all platform targets (has a CPP and HPP version)>
function( new_project_executable )
  set( options )
  set( oneValueArgs   NAME PATH TEMPLATE )
  set( multiValueArgs DEPENDENCIES )
  cmake_parse_arguments( OPTS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  set( CM_CURRENT_EXE_LC  ${OPTS_NAME} )
  string( TOUPPER ${OPTS_NAME} CM_CURRENT_EXE_UC )
  set( CM_CURRENT_EXE_SRC "${CM_CURRENT_EXE_UC}_SRC" )
  set( CM_CURRENT_EXE_INC "${CM_CURRENT_EXE_UC}_INC" )

  foreach( I IN LISTS oneValueArgs )
    if( "${OPTS_${I}}" STREQUAL "" )
      message( ERROR "Invalid use of new_project_executable: Section ${I} not defined!" )
    endif( "${OPTS_${I}}" STREQUAL "" )
  endforeach( I IN LISTS oneValueArgs )

  foreach( I IN LISTS OPTS_DEPENDENCIES )
    string( APPEND CM_CURRENT_EXE_DEP "${I} " )
  endforeach()
  string( STRIP "${CM_CURRENT_EXE_DEP}" CM_CURRENT_EXE_DEP )

  message( STATUS "Adding Executable ${CM_CURRENT_EXE_LC}:" )

  if( EXISTS ${OPTS_PATH}/CMakeScript.cmake )
    message( STATUS "  - Found CMakeScript.cmake" )
    include( ${OPTS_PATH}/CMakeScript.cmake )
  endif( EXISTS ${OPTS_PATH}/CMakeScript.cmake  )

  find_source_files(  PATH ${OPTS_PATH} EXT_CPP "cpp" "cxx" "C" "c" EXT_HPP "hpp" "hxx" "H" "h" )
  export_found_files( ${OPTS_PATH} )

  select_sources() # Sets CM_CURRENT_SRC_CPP and CM_CURRENT_SRC_HPP and CURRENT_INCLUDE_DIRS

  list( APPEND ${PROJECT_NAME}_SUBDIR_LIST "${OPTS_PATH}" )

  configure_file( "${OPTS_TEMPLATE}" "${OPTS_PATH}/CMakeLists.txt" @ONLY )
  set( ${PROJECT_NAME}_LIB_INCLUDE_DIRECTORIES "${${PROJECT_NAME}_LIB_INCLUDE_DIRECTORIES}"  PARENT_SCOPE )
  set( ${PROJECT_NAME}_SUBDIR_LIST             "${${PROJECT_NAME}_SUBDIR_LIST}"              PARENT_SCOPE )
endfunction( new_project_executable )


