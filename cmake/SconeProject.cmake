include("${CMAKE_CURRENT_LIST_DIR}/EnvConfig.cmake")

# Setup VERSION from VERSION.txt
file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/submodules/scone/VERSION.txt" SCONE_VERSION_FULL)
string(REGEX MATCH "[0-9]+.[0-9]+.[0-9]+" SCONE_VERSION ${SCONE_VERSION_FULL})
string(REGEX MATCH "-.+" SCONE_VERSION_POSTFIX ${SCONE_VERSION_FULL})

project(scone-studio VERSION ${SCONE_VERSION})

# Use position-independent code on Unix (required for static libraries)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# scone-studio options
option(SCONE_STUDIO_CPACK "Build SCONE Studio installer using CPack" OFF)
option(SCONE_STUDIO_CPACK_DEBIAN "Build debian installer using CPack" OFF)

if(SCONE_STUDIO_CPACK)
	set(CPACK_PACKAGE_VERSION "${SCONE_VERSION_FULL}")
endif()

# To create a folder hierarchy within Visual Studio.
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# compilation database for completion on Linux
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Default install prefix for non-superbuild use.
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
	set(CMAKE_INSTALL_PREFIX "${SCONE_INSTALL_PREFIX}" CACHE PATH "Install prefix." FORCE)
endif()

# Place build products (libraries, executables) in root
# binary (build) directory. Otherwise, they get scattered around
# the build directory and so the dll's aren't next to the executables.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

# set CMAKE_INSTALL_BINDIR etc.
include(GNUInstallDirs)

# Set INSTALL directories
set(CMAKE_INSTALL_RPATH "\$ORIGIN")

if(NOT DEFINED OSG_DIR)
	set(OSG_DIR "${OSG_INSTALL_PREFIX}" CACHE PATH "OpenSceneGraph install prefix.")
endif()

if(NOT DEFINED OPENSIM_INSTALL_DIR)
	set(OPENSIM_INSTALL_DIR "${OPENSIM_INSTALL_PREFIX}" CACHE PATH "OpenSim install prefix.")
endif()

if(NOT DEFINED OPENSIM_INCLUDE_DIR)
	set(OPENSIM_INCLUDE_DIR "${OPENSIM_INSTALL_PREFIX}/sdk/include" CACHE PATH "OpenSim include directory.")
endif()

if(NOT DEFINED SIMBODY_HOME)
	set(SIMBODY_HOME "${SIMBODY_INSTALL_PREFIX}" CACHE PATH "Simbody install prefix.")
endif()

list(APPEND CMAKE_PREFIX_PATH
	"${OSG_INSTALL_PREFIX}"
	"${OSG_INSTALL_PREFIX}/lib"
	"${OSG_INSTALL_PREFIX}/lib64"
	"${SIMBODY_INSTALL_PREFIX}"
	"${OPENSIM_INSTALL_PREFIX}"
)
list(REMOVE_DUPLICATES CMAKE_PREFIX_PATH)

#
# Add targets
#
add_subdirectory(submodules/scone)

# Required packages
find_package(Qt5 COMPONENTS Widgets OpenGL PrintSupport REQUIRED)
add_subdirectory(submodules/vis)
add_subdirectory(src/sconestudio)

enable_testing()

#
# Installation / packaging (CPack)
#
if(SCONE_STUDIO_CPACK)
	# package any required system libraries
	include(InstallRequiredSystemLibraries)

	# set necessary CPack variables
	set(CPACK_PACKAGE_NAME "scone")
	set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
	set(CPACK_PACKAGE_VENDOR "Goatstream")
	set(CPACK_PACKAGE_CONTACT "info@goatstream.com")
	set(CPACK_PACKAGE_HOMEPAGE_URL "https://goatstream.com")
	set(CPACK_PACKAGE_DESCRIPTION "A tool for predictive musculoskeletal simulations")
	set(CPACK_PACKAGE_EXECUTABLES "sconestudio;SCONE Command Line Interface")
	set(CPACK_OUTPUT_FILE_PREFIX "./../packages")

	# install scenarios
	install(DIRECTORY "${CMAKE_SOURCE_DIR}/submodules/scone/scenarios/Examples2" DESTINATION "./scone/scenarios")
	install(DIRECTORY "${CMAKE_SOURCE_DIR}/submodules/scone/scenarios/Examples3" DESTINATION "./scone/scenarios")
	install(DIRECTORY "${CMAKE_SOURCE_DIR}/submodules/scone/scenarios/Tutorials2" DESTINATION "./scone/scenarios")
	install(DIRECTORY "${CMAKE_SOURCE_DIR}/submodules/scone/scenarios/Tutorials3" DESTINATION "./scone/scenarios")
	install(DIRECTORY "${CMAKE_SOURCE_DIR}/submodules/scone/scenarios/Benchmarks" DESTINATION "./scone/scenarios")
	install(DIRECTORY "${CMAKE_SOURCE_DIR}/submodules/scone/scenarios/SconePy" DESTINATION "./scone/scenarios")
	install(DIRECTORY "${CMAKE_SOURCE_DIR}/resources" DESTINATION ".")

	# install licenses
	install(FILES "${CMAKE_SOURCE_DIR}/LICENSE" "${CMAKE_SOURCE_DIR}/THIRD_PARTY_NOTICES.md" DESTINATION ".")
	install(DIRECTORY "${CMAKE_SOURCE_DIR}/licenses" DESTINATION ".")
	install(FILES "${CMAKE_SOURCE_DIR}/submodules/scone/LICENSE" "${CMAKE_SOURCE_DIR}/submodules/scone/THIRD_PARTY_NOTICES.md" DESTINATION "./scone")
	install(DIRECTORY "${CMAKE_SOURCE_DIR}/submodules/scone/licenses" DESTINATION "./scone")

	# packaging: package installation as archive
	set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY OFF)

	if(SCONE_STUDIO_CPACK_DEBIAN)
		# packaging: package installation as a DEB
		set(CPACK_GENERATOR DEB)
		set(CPACK_PACKAGING_INSTALL_PREFIX "/opt/scone")
		set(CPACK_DEBIAN_PACKAGE_DEPENDS "libstdc++6, zlib1g, freeglut3, qtbase5-dev, libpng16-16")
		set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
		set(CPACK_STRIP_FILES YES)

		# packaging: configure a script that creates symlinks /usr/local/bin/ --> /opt/scone/bin/
		configure_file("${PROJECT_SOURCE_DIR}/tools/postinst.in" "postinst" @ONLY)

		# packaging: configure a script that destroys the above symlink on uninstall
		configure_file("${PROJECT_SOURCE_DIR}/tools/postrm.in" "postrm" @ONLY)

		# packaging: tell debian packager to use the scripts for postinst and postrm actions
		set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA "${CMAKE_BINARY_DIR}/postinst;${CMAKE_BINARY_DIR}/postrm")
	else()
		set(CPACK_PACKAGING_INSTALL_PREFIX "/scone")
		set(CPACK_GENERATOR TGZ)
	endif()

	# CPack vars etc. now fully configured, so include it
	include(CPack)
endif()
