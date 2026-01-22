if(NOT (UNIX AND NOT APPLE))
	message(FATAL_ERROR "This build configuration supports Ubuntu Linux only.")
endif()

set(LINUX TRUE)

set(SCONE_BUILD_TYPE "Debug" CACHE STRING "Build type for single-config generators.")
if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE "${SCONE_BUILD_TYPE}" CACHE STRING "Build type for single-config generators." FORCE)
else()
	set(SCONE_BUILD_TYPE "${CMAKE_BUILD_TYPE}" CACHE STRING "Build type for single-config generators." FORCE)
endif()

set(SCONE_THIRDPARTY_ROOT "${CMAKE_BINARY_DIR}/third_party" CACHE PATH "Root folder for third-party dependency builds and installs.")
set(SCONE_THIRDPARTY_BUILD_ROOT "${SCONE_THIRDPARTY_ROOT}/build" CACHE PATH "Build directory for third-party dependencies.")

set(OSG_INSTALL_PREFIX "${SCONE_THIRDPARTY_ROOT}/osg" CACHE PATH "OpenSceneGraph install prefix.")
set(SIMBODY_INSTALL_PREFIX "${SCONE_THIRDPARTY_ROOT}/simbody" CACHE PATH "Simbody install prefix.")
set(OPENSIM_INSTALL_PREFIX "${SCONE_THIRDPARTY_ROOT}/opensim3" CACHE PATH "OpenSim 3 install prefix.")

set(SCONE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install" CACHE PATH "SCONE install prefix.")
