# cmake_helpers

## A set of cmake helpers functions and find modules

Most notable functions
- setting cpp standard
- enabling target warnings
- setting target visibility
- enabling use of sanitizers for target
- installing and exporting target
- enabling ROS1/ROS2 tooling for target

Include extenal find modules for
- SDL2/SDL2_ttf,SDL_image,SDL_mixer
- IWUY (include what you use tool)


## Usage from plain CMake
- consume directly with find_package(cmake_helpers) in a CMakeLists.txt
- including helpers.cmake will enable the use of the provided macros
- Example usage project: https://github.com/zhivkopetrov/dev_battle.git

## Usage as part of ROS(catkin) / ROS2(colcon) meta-build systems
- consume directly with find_package(cmake_helpers) in the packages CMakeLists.txt
- include helpers.cmake for the package
```
if(NOT DISABLE_ROS_TOOLING)
	include(${cmake_helpers_DIR}/helpers.cmake)
	
    enable_ros_tooling_for_target(
        ${PROJECT_NAME}
        ${CMAKE_CURRENT_SOURCE_DIR}/package.xml
    )
endif()
```
- Example usage project: https://github.com/zhivkopetrov/robotics_v1

## Dependencies
- No dependencies

## Supported Platforms
Linux:
  - g++ 12
  - clang++ 14
  - Emscripten (em++) 3.1.28
  - Robot Operating System 2 (ROS2)
    - Through colcon meta-build system (CMake based)
  - Robot Operating System 1 (ROS1)
    - Through catkin meta-build system (CMake based)
      - Due to soon ROS1 end-of-life catkin builds are not actively supported

Windows:
  - MSVC++ (>= 14.20) Visual Studio 2019
