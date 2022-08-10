cmake_minimum_required(VERSION 2.6)

PROJECT(opkg-cl C)

INCLUDE(CheckLibraryExists)

INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/../libopkg)
LINK_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/../libopkg ${CMAKE_CURRENT_SOURCE_DIR}/../libbb)

SET(ubox-static $ENV{FBAU_PF_STAGING}/lib/libubox.a)

ADD_EXECUTABLE(opkg-cl opkg-cl.c)
TARGET_LINK_LIBRARIES(opkg-cl opkg bb ${ubox-static})

CHECK_LIBRARY_EXISTS(pthread pthread_create "" NEED_PTHREAD)
IF(NEED_PTHREAD)
	TARGET_LINK_LIBRARIES(opkg-cl pthread)
ENDIF()

INSTALL(TARGETS opkg-cl RUNTIME DESTINATION bin)
