option(SCONE_ENABLE_APT_INSTALL "Install Ubuntu system dependencies during the build." ON)
option(SCONE_ENABLE_FPM_INSTALL "Install fpm via gem during the build." ON)
option(SCONE_APT_WAIT_FOR_LOCK "Wait and retry if apt is locked by another process." ON)

set(SCONE_APT_LOCK_RETRIES 30 CACHE STRING "Number of apt retry attempts when the lock is held.")
set(SCONE_APT_LOCK_WAIT_SEC 10 CACHE STRING "Seconds to wait between apt retry attempts.")

set(SCONE_APT_GET "apt-get" CACHE STRING "Command used to install apt packages.")
set(SCONE_APT_SUDO "sudo" CACHE STRING "Command prefix for elevated apt installs (set to empty if running as root).")
set(SCONE_APT_PACKAGES
	"git;rsync;cmake;make;gcc;g++;ruby;ruby-dev;rubygems;libpng-dev;zlib1g-dev;qtbase5-dev;liblapack-dev;freeglut3-dev;libxi-dev;libxmu-dev"
	CACHE STRING "Semicolon-separated list of Ubuntu packages required for the build."
)
string(REPLACE ";" " " SCONE_APT_PACKAGES_SHELL "${SCONE_APT_PACKAGES}")

if(SCONE_ENABLE_APT_INSTALL)
	if(SCONE_APT_WAIT_FOR_LOCK)
		set(SCONE_APT_RETRY_SCRIPT
			"set -euo pipefail\n"
			"attempt=1\n"
			"while [ $attempt -le ${SCONE_APT_LOCK_RETRIES} ]; do\n"
			"  if ${SCONE_APT_SUDO} ${SCONE_APT_GET} update; then\n"
			"    ${SCONE_APT_SUDO} ${SCONE_APT_GET} install -y ${SCONE_APT_PACKAGES_SHELL} && break\n"
			"  fi\n"
			"  echo \"apt-get is busy (attempt $attempt/${SCONE_APT_LOCK_RETRIES}); waiting ${SCONE_APT_LOCK_WAIT_SEC}s...\"\n"
			"  sleep ${SCONE_APT_LOCK_WAIT_SEC}\n"
			"  attempt=$((attempt+1))\n"
			"done\n"
			"if [ $attempt -gt ${SCONE_APT_LOCK_RETRIES} ]; then\n"
			"  echo \"apt-get did not become available in time.\"\n"
			"  exit 1\n"
			"fi\n"
		)
		if(SCONE_ENABLE_FPM_INSTALL)
			add_custom_target(scone_system_deps
				COMMAND ${CMAKE_COMMAND} -E echo "Installing system dependencies with apt (retry on lock)."
				COMMAND /bin/bash -c "${SCONE_APT_RETRY_SCRIPT}"
				COMMAND ${CMAKE_COMMAND} -E echo "Installing fpm via gem."
				COMMAND ${SCONE_APT_SUDO} gem install --no-document fpm
				VERBATIM
			)
		else()
			add_custom_target(scone_system_deps
				COMMAND ${CMAKE_COMMAND} -E echo "Installing system dependencies with apt (retry on lock)."
				COMMAND /bin/bash -c "${SCONE_APT_RETRY_SCRIPT}"
				VERBATIM
			)
		endif()
	else()
		if(SCONE_ENABLE_FPM_INSTALL)
			add_custom_target(scone_system_deps
				COMMAND ${CMAKE_COMMAND} -E echo "Installing system dependencies with apt."
				COMMAND ${SCONE_APT_SUDO} ${SCONE_APT_GET} update
				COMMAND ${SCONE_APT_SUDO} ${SCONE_APT_GET} install -y ${SCONE_APT_PACKAGES}
				COMMAND ${CMAKE_COMMAND} -E echo "Installing fpm via gem."
				COMMAND ${SCONE_APT_SUDO} gem install --no-document fpm
				VERBATIM
			)
		else()
			add_custom_target(scone_system_deps
				COMMAND ${CMAKE_COMMAND} -E echo "Installing system dependencies with apt."
				COMMAND ${SCONE_APT_SUDO} ${SCONE_APT_GET} update
				COMMAND ${SCONE_APT_SUDO} ${SCONE_APT_GET} install -y ${SCONE_APT_PACKAGES}
				VERBATIM
			)
		endif()
	endif()
else()
	add_custom_target(scone_system_deps
		COMMAND ${CMAKE_COMMAND} -E echo "System dependency installation disabled (SCONE_ENABLE_APT_INSTALL=OFF)."
		VERBATIM
	)
endif()
