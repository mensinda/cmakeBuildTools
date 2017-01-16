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

# Adds a operating system with (multiple) graphic API's
#
# Usage:
# add_platform
#    OS     <the operating system>
#    TARGET <supported targets (aka subdirectories in the source tree) of the OS>
#
# Variables:
#  PLATFORM_TARGET              - the secondary target of one OS
#  ${PROJECT_NAME}_PLATFORM_LIST - list of all platforms added so far (output)
function( add_platform )
  set( TARGET_LIST OS TARGET )
  split_arg_list( "${TARGET_LIST}" "${ARGV}" )

  foreach( I IN LISTS TARGET_LIST )
    if( "${${I}}" STREQUAL "" )
      message( ERROR "Invalid use of add_platform: Section ${I} not defined!" )
    endif( "${${I}}" STREQUAL "" )
  endforeach( I IN LISTS TARGET_LIST )

  if( ${OS} )
    set( CURRENT_OS_STRING " (current)" )
  endif( ${OS} )

  # Generate the platform list
  message( STATUS "Adding platform support for ${OS}${CURRENT_OS_STRING}. Supported targets are:" )
  foreach( I IN LISTS TARGET )
    string( TOUPPER "${OS}_${I}" VAR_NAME )
    message( STATUS " - ${I}: \t ${VAR_NAME}" )
    list( APPEND PLATFORM_LIST ${VAR_NAME} )
    set( ${VAR_NAME} "${I}" PARENT_SCOPE ) # store <api> in <OS>_<API> for the find sources script
  endforeach( I IN LISTS TARGET )

  # Set default target
  if( ${OS} )
    if( NOT PLATFORM_TARGET )
      list( GET TARGET 0 TEMP )
      string( TOUPPER "${OS}_${TEMP}" VAR_NAME )
      set( PLATFORM_TARGET ${VAR_NAME} PARENT_SCOPE )
    endif( NOT PLATFORM_TARGET )
  endif( ${OS} )

  # Export to parent scope
  list( APPEND ${PROJECT_NAME}_PLATFORM_LIST "${PLATFORM_LIST}" )
  set( ${PROJECT_NAME}_PLATFORM_LIST ${${PROJECT_NAME}_PLATFORM_LIST} PARENT_SCOPE )
endfunction( add_platform )


function( check_platform )
  set( FOUND_PLATFORM_TARGET OFF )

  foreach( I IN LISTS ${PROJECT_NAME}_PLATFORM_LIST )
    set( CM_${I} 0 PARENT_SCOPE )

    if( ${PLATFORM_TARGET} STREQUAL ${I} )
      set( FOUND_PLATFORM_TARGET ON )
      set( CM_${I} 1 PARENT_SCOPE )
      message( STATUS "Using target ${PLATFORM_TARGET} (change with -DPLATFORM_TARGET)\n" )
    endif( ${PLATFORM_TARGET} STREQUAL ${I} )

  endforeach( I IN LISTS ${PROJECT_NAME}_PLATFORM_LIST )

  if( NOT FOUND_PLATFORM_TARGET )
    message( FATAL_ERROR "Unknown target ${PLATFORM_TARGET}" )
  endif( NOT FOUND_PLATFORM_TARGET )
endfunction( check_platform )
