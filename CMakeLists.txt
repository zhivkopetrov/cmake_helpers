#author Zhivko Petrov

cmake_minimum_required(VERSION 3.10.2)

project(
    cmake_helpers 
    VERSION 1.0.0
)

if(NOT DISABLE_ROS_TOOLING)
	find_package(ament_cmake REQUIRED)
	
	install(
	    FILES package.xml
	    DESTINATION share/${PROJECT_NAME}
	)
	
	# Install the helpers.cmake so it can be reused from other ROS2 packages
	install(
	    FILES helpers.cmake
	    DESTINATION share/${PROJECT_NAME}/cmake
	)
	install(
	    DIRECTORY find_modules
	    DESTINATION share/${PROJECT_NAME}/cmake
	)
	
	ament_package()
endif()