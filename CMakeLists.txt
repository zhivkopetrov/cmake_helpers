#author Zhivko Petrov

cmake_minimum_required(VERSION 3.10.2)

project(
    cmake_helpers 
    VERSION 1.0.0
)

if(NOT DISABLE_ROS_TOOLING)
	find_package(ament_cmake REQUIRED)
	
	set(ProjectPath share/${PROJECT_NAME})
	install(
	    FILES package.xml
	    DESTINATION ${ProjectPath}
	)
	
	# Install the helpers.cmake so it can be reused from other ROS2 packages
	set(CMakeProjectPath ${ProjectPath}/cmake)
	install(
	    FILES helpers.cmake
	    DESTINATION ${CMakeProjectPath}
	)
	install(
	    DIRECTORY find_modules
	    DESTINATION ${CMakeProjectPath}
	)
	
	ament_package()
endif()