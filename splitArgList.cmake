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


# split_arg_list is an utility macro that splits the parameters into specific SECTIONS.
# This alows for an easy implementation of the CMake like parameter system.
#
# Every item in `SECTIONS` will be can then be accessed as a variable.
#
# Example:
#
# set( ARGV "FOO;first;second;BAR;third;fourth" )
# split_arg_list( "FOO;BAR" "${ARGV}" )
#
# # ==> FOO = "first;second"
# #     BAR = "third;fourth"

function( split_arg_list SECTIONS ARGS )
  # clear vars
  foreach( I IN LISTS SECTIONS )
    set( ${I} "" )
  endforeach( I IN LISTS SECTIONS )

  foreach( I IN LISTS ARGS )
    set( SKIP OFF )
    foreach( J IN LISTS SECTIONS )
      if( I STREQUAL J )
        set( CURRENT_TARGET ${I} )
        set( SKIP ON )
        break()
      endif( I STREQUAL J )
    endforeach( J IN LISTS SECTIONS )

    if( SKIP )
      continue()
    endif( SKIP )

    if( CURRENT_TARGET STREQUAL "" )
      message( WARNING "split_arg_list: no target set; skip ${I}" )
      continue()
    endif( CURRENT_TARGET STREQUAL "" )

    list( APPEND ${CURRENT_TARGET} "${I}" )
  endforeach( I IN LISTS ARGS )

  # Move vars to the parent scope
  foreach( I IN LISTS SECTIONS )
    if( I STREQUAL "" )
      continue()
    endif( I STREQUAL "" )
    set( ${I} "${${I}}" PARENT_SCOPE )
  endforeach( I IN LISTS SECTIONS )
endfunction( split_arg_list )
