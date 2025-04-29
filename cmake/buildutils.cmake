# -------------------------------------------------------------------------------------------
# SPDX-License-Identifier: LGPL-3.0-or-later
# SPDX-FileCopyrightText: Copyright (C) 2010-25 David L. Dight
# SPDX-FileType: SOURCE
#
# Fix8 is released under the GNU LESSER GENERAL PUBLIC LICENSE Version 3.
#
# Fix8 Open Source FIX Engine.
# Copyright (C) 2010-25 David L. Dight <fix@fix8.org>
#
# Fix8 is free software: you can  redistribute it and / or modify  it under the  terms of the
# GNU Lesser General  Public License as  published  by the Free  Software Foundation,  either
# version 3 of the License, or (at your option) any later version.
#
# Fix8 is distributed in the hope  that it will be useful, but WITHOUT ANY WARRANTY;  without
# even the  implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# You should  have received a copy of the GNU Lesser General Public  License along with Fix8.
# If not, see <https://www.gnu.org/licenses/lgpl-3.0.html/>.
#
# BECAUSE THE PROGRAM IS  LICENSED FREE OF  CHARGE, THERE IS NO  WARRANTY FOR THE PROGRAM, TO
# THE EXTENT  PERMITTED  BY  APPLICABLE  LAW.  EXCEPT WHEN  OTHERWISE  STATED IN  WRITING THE
# COPYRIGHT HOLDERS AND/OR OTHER PARTIES  PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY
# KIND,  EITHER EXPRESSED   OR   IMPLIED,  INCLUDING,  BUT   NOT  LIMITED   TO,  THE  IMPLIED
# WARRANTIES  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS TO
# THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE,
# YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.
#
# IN NO EVENT UNLESS REQUIRED  BY APPLICABLE LAW  OR AGREED TO IN  WRITING WILL ANY COPYRIGHT
# HOLDER, OR  ANY OTHER PARTY  WHO MAY MODIFY  AND/OR REDISTRIBUTE  THE PROGRAM AS  PERMITTED
# ABOVE,  BE  LIABLE  TO  YOU  FOR  DAMAGES,  INCLUDING  ANY  GENERAL, SPECIAL, INCIDENTAL OR
# CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT
# NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
# THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF SUCH
# HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# -------------------------------------------------------------------------------------------
# cmake build utils
# min cmake version 3.20 (Mar 24, 2021)
# -------------------------------------------------------------------------------------------
function(fix8_setbuildtype define_prefix default_type)
	if(NOT "${CMAKE_BUILD_TYPE}" STREQUAL "")
		if (${CMAKE_BUILD_TYPE} STREQUAL "Debug")
			add_compile_definitions(${define_prefix}_DEBUG_BUILD)
		elseif(${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo")
			add_compile_definitions(${define_prefix}_RELWITHDEBINFO_BUILD)
		elseif(${CMAKE_BUILD_TYPE} STREQUAL "MinSizeRel")
			add_compile_definitions(${define_prefix}_MINSIZEREL_BUILD)
		elseif(${default_type} STREQUAL "Release")
			add_compile_definitions(${define_prefix}_RELEASE_BUILD)
		else()
			message(FATAL_ERROR "Unsupported build type ${default_type}")
		endif()
		message("-- ${CMAKE_PROJECT_NAME} version ${CMAKE_PROJECT_VERSION}, build type ${CMAKE_BUILD_TYPE}")
	else()
		set_property(CACHE CMAKE_BUILD_TYPE PROPERTY VALUE ${default_type})
		fix8_setbuildtype(${define_prefix} ${default_type})
	endif()
endfunction()

# -------------------------------------------------------------------------------------------
macro(fix8_addoption option_string)
	string(REPLACE "|" ";" part ${option_string})
	list(GET part 0 opt_name)
	list(GET part 1 opt_description)
	list(GET part 2 opt_default)
	if(NOT DEFINED ${opt_name})
		set(${opt_name} ${opt_default})
	endif()
	option(${opt_name} "${opt_description}" ${${opt_name}})
	message("-- Build: ${opt_description}: ${${opt_name}}")
endmacro()

# -------------------------------------------------------------------------------------------
macro(fix8_fetch modname parturl tag)
	include(FetchContent)
	message(STATUS "Downloading ${modname}...")
	FetchContent_Declare(${modname} GIT_REPOSITORY https://github.com/${parturl}.git GIT_SHALLOW ON GIT_TAG ${tag})
	FetchContent_MakeAvailable(${modname})
endmacro()

# -------------------------------------------------------------------------------------------
function(comp_opts targ)
	target_compile_features(${targ} PRIVATE cxx_std_17)
	if(BUILD_ALL_WARNINGS)
		target_compile_options(${targ} PRIVATE
		$<$<CXX_COMPILER_ID:MSVC>:/W4>
		$<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall -Wextra -Wpedantic>)
	endif()
endfunction()

# -------------------------------------------------------------------------------------------
function(build_test loc x)
	add_executable(${x} ${loc}/${x}.cpp)
	target_link_libraries(${x} PUBLIC Poco::Foundation Poco::Net Poco::Util Poco::NetSSL Poco::Crypto Poco::XML fix8 utest GTest::gtest GTest::gtest_main)
	target_include_directories(${x} PRIVATE ${loc} include ${CMAKE_BINARY_DIR}/generated/FIX42UTEST)
	gtest_discover_tests(${x})
	comp_opts(${x})
endfunction()

# -------------------------------------------------------------------------------------------
macro(fix8_gen_library shared name xml extra_fields)
	if ("${extra_fields}" STREQUAL "_")
		set(args ${ARGV4} ${ARGV5} ${ARGV6} ${ARGV7} ${ARGV8} ${ARGV9} ${ARGV10} ${CMAKE_SOURCE_DIR}/${xml})
	else()
		set(args ${ARGV4} ${ARGV5} ${ARGV6} ${ARGV7} ${ARGV8} ${ARGV9} ${ARGV10} ${CMAKE_SOURCE_DIR}/${xml} -F ${extra_fields})
	endif()
	set(prefix ${CMAKE_BINARY_DIR}/generated/${name})
	file(MAKE_DIRECTORY ${prefix})

	string(FIND "${xml}" "/" has_path_delimiters)
	if (${has_path_delimiters} EQUAL -1)
		set(xml ${CMAKE_SOURCE_DIR}/${xml})
	endif()
	message("-- Using schema ${xml}")
	add_custom_command(
			OUTPUT
			${prefix}/${name}_classes.cpp
			${prefix}/${name}_traits.cpp
			${prefix}/${name}_types.cpp
			${prefix}/${name}_classes.hpp
			${prefix}/${name}_types.hpp
			COMMAND ${CMAKE_COMMAND} -E env LD_LIBRARY_PATH=${LIB_OUTPUT_DIR}/lib $<TARGET_FILE:f8c> ${args}
			MAIN_DEPENDENCY ${xml}
			WORKING_DIRECTORY ${prefix}
			VERBATIM)
	if ("${shared}" STREQUAL "shared")
		set(libname ${name})
		add_library(${libname} SHARED
				${prefix}/${name}_classes.cpp
				${prefix}/${name}_traits.cpp
				${prefix}/${name}_types.cpp
				${prefix}/${name}_classes.hpp
				${prefix}/${name}_types.hpp
				)
		target_compile_definitions(${libname} PRIVATE BUILD_F8_${name}_API)
	else()
		set(libname ${name})
		add_library(${libname} STATIC
				${prefix}/${name}_classes.cpp
				${prefix}/${name}_traits.cpp
				${prefix}/${name}_types.cpp
				${prefix}/${name}_classes.hpp
				${prefix}/${name}_types.hpp
				)
	endif()
	target_include_directories(${libname} PUBLIC ${prefix})
	target_compile_options(${libname} PRIVATE -fno-var-tracking -fno-var-tracking-assignments)
	target_link_libraries(${libname} PUBLIC fix8)
endmacro()

# -------------------------------------------------------------------------------------------
macro(fix8_gen_shared_library name xml)
	fix8_gen_library(shared ${name} ${xml} "_" ${ARGV2} ${ARGV3} ${ARGV4} ${ARGV5} ${ARGV6} ${ARGV7} ${ARGV8} ${ARGV9} ${ARGV10})
endmacro()

# -------------------------------------------------------------------------------------------
macro(add_gen_static_library name xml)
	fix8_gen_library(static ${name} ${xml} "_" ${ARGV2} ${ARGV3} ${ARGV4} ${ARGV5} ${ARGV6} ${ARGV7} ${ARGV8} ${ARGV9} ${ARGV10})
endmacro()
