#   Copyright (c) 2024 YottaDB LLC
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Prelim
cmake_minimum_required(VERSION 3.14)
include(FetchContent)
# The GIT_TAG is, at the time of this writing, the latest commit in YDBCMake.
# It is fixed at that point to ensure reproducible builds.
# Keep this periodically up to date with future YDBCMake commits.
FetchContent_Declare(YDBCMake
	GIT_REPOSITORY	https://gitlab.com/YottaDB/Tools/YDBCMake.git
	GIT_TAG		e980b310b464c43d98a9731f126bdc6375b3fe1e
)

FetchContent_MakeAvailable(YDBCMake)
message(STATUS "YDBCMake Source Directory: ${ydbcmake_SOURCE_DIR}")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${ydbcmake_SOURCE_DIR}/ydbcmake/")

# Needed because we are compiling C code with flags
if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "")
endif()
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

project(ydbcurl
	LANGUAGES C M
	VERSION 1.0.0
)

# Find YottaDB and get Install Destination
find_package(YOTTADB REQUIRED)
message(STATUS "Install Location: ${YOTTADB_PLUGIN_PREFIX}")

# Find libcurl
find_package(CURL REQUIRED)
if(CURL_FOUND)
    message(STATUS "Found CURL version: ${CURL_VERSION_STRING}")
    message(STATUS "Using CURL include dir(s): ${CURL_INCLUDE_DIRS}")
    message(STATUS "Using CURL lib(s): ${CURL_LIBRARIES}")
endif()

# Install CURL Shared Library
add_library(curl SHARED libcurl.c)
target_include_directories(curl PRIVATE ${YOTTADB_INCLUDE_DIRS})
target_link_libraries(curl PRIVATE ${CURL_LIBRARIES})
install(TARGETS curl DESTINATION ${YOTTADB_C_PLUGIN_DIR})

# Create libcurl_test test shared library
set(m_sources r/_ut.m r/_ut1.m r/libcurlPluginTests.m)
add_ydb_library(libcurltest SOURCES ${m_sources})


# Handle the .xc file
# Runtime version
set(install_dir ${YOTTADB_PLUGIN_PREFIX})
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/libcurl.xc.in
  ${CMAKE_CURRENT_BINARY_DIR}/libcurl.xc
)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libcurl.xc
  DESTINATION ${YOTTADB_PLUGIN_PREFIX}/
)

# Test version
set(install_dir ${CMAKE_CURRENT_BINARY_DIR})
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/libcurl.xc.in
  ${CMAKE_CURRENT_BINARY_DIR}/libcurl_test.xc
)

# Testing
enable_testing()
add_test(libcurl_test ${CMAKE_M_COMPILER} -run libcurlPluginTests)
set_tests_properties(libcurl_test PROPERTIES FAIL_REGULAR_EXPRESSION "FAIL")
set_tests_properties(libcurl_test PROPERTIES
	ENVIRONMENT "ydb_xc_libcurl=${CMAKE_CURRENT_BINARY_DIR}/libcurl_test.xc;ydb_routines=${CMAKE_CURRENT_BINARY_DIR}/libcurltest.so ${mumps_dir}/libyottadbutil.so;ydb_chset=M")

if(EXISTS ${mumps_dir}/utf8)
	add_test(libcurl_test_utf8 ${CMAKE_M_COMPILER} -run libcurlPluginTests)
	set_tests_properties(libcurl_test_utf8 PROPERTIES FAIL_REGULAR_EXPRESSION "FAIL")
	set_tests_properties(libcurl_test_utf8 PROPERTIES
		ENVIRONMENT "ydb_xc_libcurl=${CMAKE_CURRENT_BINARY_DIR}/libcurl_test.xc;ydb_routines=${CMAKE_CURRENT_BINARY_DIR}/utf8/libcurltest.so ${mumps_dir}/utf8/libyottadbutil.so;ydb_chset=UTF-8;ydb_icu_version=${ydb_icu_version}")
endif()

