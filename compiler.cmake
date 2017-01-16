# Copyright (C) 2015 EEnginE project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Set compiler flags
#  1st parameter: the CMake compiler ID
# Sections:
# ALL:         compiler options for all build types
# DEBUG:       compiler options only for the DEBUG build type
# RELEASE:     compiler options only for the RELEASE build type
# SANITIZE:    sanitizer option. Will only be enabled on DEBUG build type and when the variable ENABLE_SANITIZERS is set
# MIN_VERSION: the min. compiler version
function( add_compiler COMPILER )
   if( ${ARGC} LESS 1 )
      message( FATAL_ERROR "function 'add_compiler' needs at least 1 parameters" )
   endif( ${ARGC} LESS 1 )

   if( NOT CMAKE_CXX_COMPILER_ID STREQUAL COMPILER )
      return()
   endif( NOT CMAKE_CXX_COMPILER_ID STREQUAL COMPILER )

   message( STATUS "The detected compiler is: ${COMPILER}" )

   set( CURRENT_TARGET "" )
   set( TARGET_LIST ALL DEBUG RELEASE SANITIZE MIN_VERSION )

   split_arg_list( "${TARGET_LIST}" "${ARGN}" )

   if( DEFINED MIN_VERSION )
      if( CMAKE_CXX_COMPILER_VERSION VERSION_LESS "${MIN_VERSION}" )
         message( SEND_ERROR "Minimum compiler version is ${MIN_VERSION} but the current version is ${CMAKE_CXX_COMPILER_VERSION}" )
      endif( CMAKE_CXX_COMPILER_VERSION VERSION_LESS "${MIN_VERSION}" )
   endif( DEFINED MIN_VERSION )

   if( ENABLE_SANITIZERS )
      set( DEBUG "${DEBUG};${SANITIZE}" )
      message( STATUS "Using sanitizer(s) ${SANITIZE} (change with -DENABLE_SANITIZERS)" )
   else( ENABLE_SANITIZERS )
      message( STATUS "Use no sanitizer(s) (change with -DENABLE_SANITIZERS)" )
   endif( ENABLE_SANITIZERS )

   # List --> string
   string( REGEX REPLACE ";" " " ALL     "${ALL}" )
   string( REGEX REPLACE ";" " " DEBUG   "${DEBUG}" )
   string( REGEX REPLACE ";" " " RELEASE "${RELEASE}" )

   set( CMAKE_CXX_FLAGS_DEBUG   "${CMAKE_CXX_FLAGS_DEBUG}   ${ALL} ${DEBUG}"   PARENT_SCOPE )
   set( CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${ALL} ${RELEASE}" PARENT_SCOPE )
endfunction( add_compiler )
