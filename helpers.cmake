cmake_minimum_required(VERSION 3.10.2)

list(
    APPEND 
        CMAKE_MODULE_PATH 
        ${CMAKE_CURRENT_LIST_DIR}/find_modules
)

function(set_target_cpp_standard Target Standard)
    set_target_properties(
        ${Target}
            PROPERTIES
                CXX_STANDARD ${Standard}
                CXX_STANDARD_REQUIRED YES
                CXX_EXTENSIONS NO
    )
endfunction()

function(enable_target_warnings Target)
    if(CMAKE_CXX_COMPILER_ID MATCHES MSVC)
        target_compile_options(
            ${Target}
                PRIVATE
                    /W4
                    /WX
        )
        return()
    endif()
    
    target_compile_options(
        ${Target}
            PRIVATE
                -Wall
                -Wextra
                -Werror
                -Wundef
                -Wuninitialized
                -Wshadow
                -Wpointer-arith
                -Wcast-align
                -Wcast-qual
                -Wunused-parameter
                -Wdouble-promotion
                -Wnull-dereference
    )
    
    if(CMAKE_CXX_COMPILER_ID MATCHES GNU AND NOT ${USE_IWYU})
        #supported only in GNU
        #however include-what-you-use is not happy with those options
        target_compile_options(
            ${Target}
                PRIVATE
                    -Wlogical-op
                    -Wduplicated-cond
                    -Wduplicated-branches
        )
    endif()
endfunction()

function(enable_target_include_what_you_use Target)
    find_package(IWYU REQUIRED)
    set_target_properties(
        ${Target}
            PROPERTIES 
                CXX_INCLUDE_WHAT_YOU_USE ${IWYU_BINARY_PATH}
    )
endfunction()

function(enable_target_position_independent_code Target)
    set_target_properties(
        ${Target}
            PROPERTIES 
                POSITION_INDEPENDENT_CODE ON
    )
endfunction()

function(set_target_visibility Target)
    if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
        set(DEFAULT_BUILD_TYPE "Debug")
            message(STATUS 
              "Setting build type to '${DEFAULT_BUILD_TYPE}' as none was specified.")
            set(CMAKE_BUILD_TYPE "${DEFAULT_BUILD_TYPE}" CACHE
                STRING "Choose the type of build." FORCE)
    endif()
    
    if((${CMAKE_BUILD_TYPE} MATCHES Release) OR 
       (${CMAKE_BUILD_TYPE} MATCHES MinSizeRel))        
        set_target_properties(
            ${Target}
                PROPERTIES 
                    CXX_VISIBILITY_PRESET hidden
                    VISIBILITY_INLINES_HIDDEN TRUE
        )
    elseif((${CMAKE_BUILD_TYPE} MATCHES Debug) OR 
           (${CMAKE_BUILD_TYPE} MATCHES RelWithDebInfo))  
        if(UNIX)
            set(ExportDynamicFlag "-rdynamic")
        elseif(APPLE)
            set(ExportDynamicFlag "-Wl,-export_dynamic")
        endif()
        
        target_link_libraries(
            ${Target} 
                PRIVATE
                    ${ExportDynamicFlag} # export of static symbols
        ) 
    endif()
    
  
endfunction()

#enable_target_c_sanitizer(${my_target} "address")
# Available sanitizers
#
# GCC: address, thread, leak, undefined
# CLANG: address, memory, thread, leak, undefined
function(enable_target_sanitizer Target Sanitizer)
    if(NOT CMAKE_BUILD_TYPE OR NOT ${CMAKE_BUILD_TYPE} MATCHES Debug)
        message(
            FATAL_ERROR
            "Error: Sanitizers can be enabled only with 'Debug' build\n"
            "Hint: Use 'cmake .. -DCMAKE_BUILD_TYPE=Debug'")
        return()
    endif()
    
    target_link_libraries(
        ${Target}
            PRIVATE
                -fsanitize=${Sanitizer}
    )
    
    if(${Sanitizer} STREQUAL "address")
        target_link_libraries(
            ${Target}
                PRIVATE
                    -fno-omit-frame-pointer
        )
    endif()
    
    if(CMAKE_CXX_COMPILER_ID MATCHES GNU)
        if (${Sanitizer} STREQUAL "undefined")
            target_link_libraries(
                ${Target}
                    PRIVATE
                        -lubsan
            )
        elseif (${Sanitizer} STREQUAL "thread")
            target_link_libraries(
                ${Target}
                    PRIVATE
                        -ltsan
            )
        endif()
    endif()
endfunction()

function(fetch_and_provide_googletest)
    include(FetchContent)

    FetchContent_Declare(
        googletest
        # Specify the commit you depend on and update it regularly.
        URL https://github.com/google/googletest/archive/5376968f6948923e2411081fd9372e71a59d8e77.zip
    )
    # For Windows: Prevent overriding the parent project's compiler/linker settings
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE PARENT_SCOPE)
    FetchContent_MakeAvailable(googletest)
endfunction()

function(set_default_project_output_directories)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib PARENT_SCOPE)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin PARENT_SCOPE)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin PARENT_SCOPE)

    # Explicitly set output directories for all build types (Debug, Release, etc.)
    # Cheers for MSVC
    foreach(OutputConfig ${CMAKE_CONFIGURATION_TYPES})
        string(TOUPPER ${OutputConfig} OutputConfig)

        set(
            CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OutputConfig} 
            ${CMAKE_BINARY_DIR}/lib PARENT_SCOPE
        )

        set(
            CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OutputConfig} 
            ${CMAKE_BINARY_DIR}/bin PARENT_SCOPE
        )

        set(
            CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OutputConfig} 
            ${CMAKE_BINARY_DIR}/bin PARENT_SCOPE
        )
    endforeach()
endfunction()

function(install_and_export_target Target IncludeFolderName)
    install(
        TARGETS 
            ${Target} 
        EXPORT 
            ${Target}Targets
        LIBRARY 
            DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME 
            DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
    
    install(
        DIRECTORY ${IncludeFolderName}/
        DESTINATION ${IncludeFolderName}
    )
    
    install(
        EXPORT ${Target}Targets
        DESTINATION lib/cmake/${Target}
        FILE ${Target}Targets.cmake
        NAMESPACE ${Target}::
    )
    
    include(CMakePackageConfigHelpers)
    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${Target}ConfigVersion.cmake 
        VERSION 1.0.0
        COMPATIBILITY SameMajorVersion
    )
    
    install(
        FILES ${Target}Config.cmake
        DESTINATION lib/cmake/${Target}
    )
endfunction()

# Requires package.xml file to be present in the current directory
function(enable_ros_tooling_for_target Target PackageXml)
    find_package(ament_cmake REQUIRED)

    set(TargetPath share/${Target})

    # Install package.xml file so this package can be processed by ROS toolings
    # Installing this in non-ROS environments won't have any effect, but it won't harm, either.
    install(
        FILES ${PackageXml} 
        DESTINATION ${TargetPath}
    )
    
    # Install launch directory (if any)
    get_filename_component(FullLaunchPath launch REALPATH)
	if ((EXISTS ${FullLaunchPath}) AND (IS_DIRECTORY ${FullLaunchPath}))
		install(
			DIRECTORY launch 
			DESTINATION ${TargetPath}/
		)
	endif()
	
	# Install config directory (if any)
	get_filename_component(FullConfigPath launch REALPATH)
	if ((EXISTS ${FullConfigPath}) AND (IS_DIRECTORY ${FullConfigPath}))
		install(
			DIRECTORY config 
			DESTINATION ${TargetPath}/
		)
	endif()
    
    # ros2 run requires both libraries and binaries to be placed in 'lib'
    install(
        TARGETS ${Target}
        DESTINATION lib/${Target}
    )
    
    # Allows Colcon to find non-Ament packages when using workspace underlays
    set(RsrcIndexPkgPath share/ament_index/resource_index/packages)
    set(RsrcIndexPkgPathTarget ${CMAKE_CURRENT_BINARY_DIR}/${RsrcIndexPkgPath}/${Target})
    file(
        WRITE 
            ${RsrcIndexPkgPathTarget} 
            ""
    )
    install(
        FILES ${RsrcIndexPkgPathTarget}
        DESTINATION ${RsrcIndexPkgPath}
    )
    
    set(AmentHookPath ${TargetPath}/hook)
    set(AmentPrefixPath ${CMAKE_CURRENT_BINARY_DIR}/${AmentHookPath}/ament_prefix_path.dsv)
    file(
        WRITE 
            ${AmentPrefixPath}
            "prepend-non-duplicate;AMENT_PREFIX_PATH;"
    )
    install(
        FILES ${AmentPrefixPath}
        DESTINATION ${AmentHookPath}
    )
    
    set(RosPackagePath ${CMAKE_CURRENT_BINARY_DIR}/${AmentHookPath}/ros_package_path.dsv)
    file(
        WRITE
            ${RosPackagePath}
            "prepend-non-duplicate;ROS_PACKAGE_PATH;"
    )
    install(
        FILES ${RosPackagePath}
        DESTINATION ${AmentHookPath}
    )

    ament_package()
endfunction()
