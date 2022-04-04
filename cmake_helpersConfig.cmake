include(CMakeFindDependencyMacro)

if(NOT TARGET cmake_helpers::cmake_helpers)
  include(${CMAKE_CURRENT_LIST_DIR}/helpers.cmake)
endif()
