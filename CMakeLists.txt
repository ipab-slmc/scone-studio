cmake_minimum_required(VERSION 3.10)

option(SCONE_SUPERBUILD "Configure a superbuild that builds all dependencies first." ON)

if(SCONE_SUPERBUILD)
	project(scone-superbuild LANGUAGES NONE)
	include("${CMAKE_CURRENT_LIST_DIR}/cmake/Superbuild.cmake")
else()
	include("${CMAKE_CURRENT_LIST_DIR}/cmake/SconeProject.cmake")
endif()
