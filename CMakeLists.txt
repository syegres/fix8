# -----------------------------------------------------------------------------------------
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
# ----------------------------------------------------------------------------------------
cmake_minimum_required (VERSION 3.20)
include(cmake/buildutils.cmake)
project (fix8
   LANGUAGES CXX C
	HOMEPAGE_URL https://github.com/fix8/fix8
   DESCRIPTION "Open Source C++ FIX Engine"
   VERSION 1.5.0)

# ----------------------------------------------------------------------------------------
# options
fix8_setbuildtype(FIX8 Release)
fix8_addoption("BUILD_UNITTESTS|enable building unit tests|true")
fix8_addoption("BUILD_ALL_WARNINGS|enable building with all warnings|true")
fix8_addoption("BUILD_DOXYGEN_DOCS|enable building of self documentation|true")

# ----------------------------------------------------------------------------------------
# deps
find_package(ZLIB REQUIRED)
fix8_fetch(tcmalloc google/tcmalloc master)
fix8_fetch(poco pocoproject/poco poco-1.12.5-release)

# ----------------------------------------------------------------------------------------
# runtime
macro(build_lib name type)
	add_library(${name} ${type} ${rsrc})
	target_link_libraries(${name} PUBLIC Poco::Foundation Poco::Net Poco::Util Poco::NetSSL Poco::Crypto Poco::XML ZLIB::ZLIB)
	target_include_directories(${name} PRIVATE include ${tcmalloc})
	comp_opts(${name})
	install(TARGETS ${name})
endmacro()

set(rtdir ${CMAKE_SOURCE_DIR}/runtime)
file(GLOB rsrc "${rtdir}/*.cpp" "${rtdir}/*.c")
build_lib(fix8 SHARED)
build_lib(fix8stat STATIC)
set_target_properties(fix8stat PROPERTIES OUTPUT_NAME fix8)
install(DIRECTORY include DESTINATION include)

# ----------------------------------------------------------------------------------------
# compiler
set(compdir ${CMAKE_SOURCE_DIR}/compiler)
file(GLOB csrc "${compdir}/*.cpp")
add_executable(f8c ${csrc})
target_link_libraries(f8c PUBLIC Poco::Foundation Poco::Net Poco::Util Poco::NetSSL Poco::Crypto Poco::XML fix8)
target_include_directories(f8c PRIVATE ${compdir} include ${tcmalloc})
comp_opts(f8c)
install(TARGETS f8c)

# ----------------------------------------------------------------------------------------
# util
set(utildir ${CMAKE_SOURCE_DIR}/util)
add_executable(seqedit ${utildir}/seqedit.cpp)
target_link_libraries(seqedit PUBLIC Poco::Foundation Poco::Net Poco::Util Poco::NetSSL Poco::Crypto Poco::XML fix8)
target_include_directories(seqedit PRIVATE ${utildir} include ${tcmalloc})
comp_opts(seqedit)
install(TARGETS seqedit)

# ----------------------------------------------------------------------------------------
# shared standard schema libs
fix8_gen_shared_library(FIX40 schema/FIX40.xml --verbose --namespace FIX40 -p FIX40)
target_link_libraries(FIX40 PRIVATE fix8)
fix8_gen_shared_library(FIX41 schema/FIX41.xml --verbose --namespace FIX41 -p FIX41)
target_link_libraries(FIX41 PRIVATE fix8)
fix8_gen_shared_library(FIX42 schema/FIX42.xml --verbose --namespace FIX42 -p FIX42)
target_link_libraries(FIX42 PRIVATE fix8)
fix8_gen_shared_library(FIX43 schema/FIX43.xml --verbose --namespace FIX43 -p FIX43)
target_link_libraries(FIX43 PRIVATE fix8)
fix8_gen_shared_library(FIX44 schema/FIX44.xml --verbose --namespace FIX44 -p FIX44)
target_link_libraries(FIX44 PRIVATE fix8)
fix8_gen_shared_library(FIX50 schema/FIX50.xml --verbose --namespace FIX50 -p FIX50 --fixt ${CMAKE_SOURCE_DIR}/schema/FIXT11.xml)
target_link_libraries(FIX50 PRIVATE fix8)
fix8_gen_shared_library(FIX50SP1 schema/FIX50SP1.xml --verbose --namespace FIX50SP1 -p FIX50SP1 --fixt ${CMAKE_SOURCE_DIR}/schema/FIXT11.xml)
target_link_libraries(FIX50SP1 PRIVATE fix8)
fix8_gen_shared_library(FIX50SP2 schema/FIX50SP2.xml --verbose --namespace FIX50SP2 -p FIX50SP2 --fixt ${CMAKE_SOURCE_DIR}/schema/FIXT11.xml)
target_link_libraries(FIX50SP2 PRIVATE fix8)
install(TARGETS FIX40 FIX41 FIX42 FIX43 FIX44 FIX50 FIX50SP1 FIX50SP2)
install(DIRECTORY include DESTINATION include)
install(DIRECTORY schema DESTINATION .)

# ----------------------------------------------------------------------------------------
# unit tests
if(BUILD_UNITTESTS)
	fix8_fetch(googletest google/googletest main)
	set(EXTRA_FIELDS "<field number='9999' name='SampleUserField'  type='STRING' messages='NewOrderSingle:N ExecutionReport:N OrderCancelRequest:Y' /><field number='9991' name='SampleUserField2' type='STRING' messages='NewOrderSingle:N ExecutionReport:N OrderCancelRequest:Y' />")
	fix8_gen_shared_library(utest schema/FIX42UTEST.xml --verbose -F ${EXTRA_FIELDS} -p utest --namespace UTEST)
	target_link_libraries(utest PRIVATE fix8)
	include(GoogleTest)
	enable_testing()
	build_test(utests message_test)
	build_test(utests fileLogger_test)
	build_test(utests filePersister_test)
	add_executable(session_test utests/session_test.cpp utests/mockConnection.cpp)
	target_link_libraries(session_test PUBLIC Poco::Foundation Poco::Net Poco::Util Poco::NetSSL Poco::Crypto Poco::XML fix8 utest GTest::gtest GTest::gtest_main)
	target_include_directories(session_test PRIVATE utests include ${CMAKE_BINARY_DIR}/generated/FIX42UTEST)
	comp_opts(session_test)
#gtest_discover_tests(session_test)
endif()

# ----------------------------------------------------------------------------------------
# test apps
add_executable(f8test test/myfix.cpp)
fix8_gen_shared_library(Myfix schema/FIX50SP2.xml --verbose --namespace TEX --fixt ${CMAKE_SOURCE_DIR}/schema/FIXT11.xml)
target_link_libraries(f8test PUBLIC Poco::Foundation Poco::Net Poco::Util Poco::NetSSL Poco::Crypto Poco::XML fix8 Myfix GTest::gtest GTest::gtest_main)
target_include_directories(f8test PRIVATE test include ${CMAKE_BINARY_DIR}/generated/Myfix)
comp_opts(f8test)

add_executable(f8print test/myprint.cpp)
target_link_libraries(f8print PUBLIC Poco::Foundation Poco::Net Poco::Util Poco::NetSSL Poco::Crypto Poco::XML fix8 Myfix GTest::gtest GTest::gtest_main)
target_include_directories(f8print PRIVATE test include ${CMAKE_BINARY_DIR}/generated/Myfix)
comp_opts(f8print)

add_executable(harness test/harness.cpp)
target_link_libraries(harness PUBLIC Poco::Foundation Poco::Net Poco::Util Poco::NetSSL Poco::Crypto Poco::XML fix8 Myfix GTest::gtest GTest::gtest_main)
target_include_directories(harness PRIVATE test include ${CMAKE_BINARY_DIR}/generated/Myfix)
comp_opts(harness)

add_executable(hftest test/hftest.cpp)
fix8_gen_shared_library(Perf schema/FIX42PERF.xml --verbose --namespace TEX --second --noconst --prefix Perf --norealm)
target_link_libraries(hftest PUBLIC Poco::Foundation Poco::Net Poco::Util Poco::NetSSL Poco::Crypto Poco::XML fix8 Perf GTest::gtest GTest::gtest_main)
target_include_directories(hftest PRIVATE test include ${CMAKE_BINARY_DIR}/generated/FIX42PERF)
comp_opts(hftest)
install(TARGETS f8test f8print harness harness)

# ----------------------------------------------------------------------------------------
# generated docs
if(BUILD_DOXYGEN_DOCS)
	add_subdirectory(doc)
endif()

# ----------------------------------------------------------------------------------------
target_include_directories(${PROJECT_NAME} INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include)

# ----------------------------------------------------------------------------------------
# to dump all non-empty cmake variables
# cmake -DCMAKE_DUMP_VARS=true ..
option(CMAKE_DUMP_VARS "dump all cmake vars" false)
if(CMAKE_DUMP_VARS)
   get_cmake_property(varname VARIABLES)
   foreach (var ${varname})
      if(NOT ${var} STREQUAL "")
         message(STATUS "${var}=${${var}}")
      endif()
   endforeach()
endif()

