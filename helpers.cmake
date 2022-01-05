cmake_minimum_required(VERSION 3.10.2)

list(APPEND 
    CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules/find_modules)

function(set_target_cpp_standard target standard)
set_target_properties(
    ${target}
    PROPERTIES
        CXX_STANDARD ${standard}
        CXX_STANDARD_REQUIRED YES
        CXX_EXTENSIONS NO
)
endfunction()

function(enable_target_warnings target)
    target_compile_options(
        ${target}
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
    
    if(CMAKE_CXX_COMPILER_ID MATCHES GNU)
        #supported only in GNU
        target_compile_options(
          ${target}
              PRIVATE
                -Wlogical-op
                -Wduplicated-cond
                -Wduplicated-branches
        )
    endif()
endfunction()

function(enable_target_include_what_you_use target)
    find_package(IWYU REQUIRED)
    set_target_properties(
    ${target}
        PROPERTIES 
        CXX_INCLUDE_WHAT_YOU_USE ${IWYU_BINARY_PATH}
    )
endfunction()

function(enable_target_position_independent_code target)
    set_target_properties(
        ${target}
            PROPERTIES 
            POSITION_INDEPENDENT_CODE ON
    )
endfunction()

function(set_target_visibility target)
    if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
        set(DEFAULT_BUILD_TYPE "Debug")
            message(STATUS 
              "Setting build type to '${DEFAULT_BUILD_TYPE}' as none was specified.")
            set(CMAKE_BUILD_TYPE "${DEFAULT_BUILD_TYPE}" CACHE
                STRING "Choose the type of build." FORCE)
    endif()
    
    if(${CMAKE_BUILD_TYPE} MATCHES Release OR 
       ${CMAKE_BUILD_TYPE} MATCHES MinSizeRel)
        # Default to hidden visibility for symbols
        set(CMAKE_CXX_VISIBILITY_PRESET hidden)
        set(CMAKE_VISIBILITY_INLINES_HIDDEN TRUE)
        
        set_target_properties(
            ${target}
             PROPERTIES 
                CXX_VISIBILITY_PRESET hidden
                VISIBILITY_INLINES_HIDDEN TRUE
        )
    elseif(${CMAKE_BUILD_TYPE} MATCHES Debug OR 
           ${CMAKE_BUILD_TYPE} MATCHES RelWithDebInfo)  
        if(UNIX)
            set(R_DYNAMIC_FLAG "-rdynamic")
        elseif(APPLE)
            set(R_DYNAMIC_FLAG "-Wl,-export_dynamic")
        endif()
    endif()
    
    target_link_libraries(
        ${target} 
            PRIVATE
            ${R_DYNAMIC_FLAG} # export of static symbols
    )   
endfunction()

#enable_target_c_sanitizer(${my_target} "address")
# Available sanitizers
#
# GCC: address, thread, leak, undefined
# CLANG: address, memory, thread, leak, undefined
function(enable_target_sanitizer target sanitizer)
    if(NOT CMAKE_BUILD_TYPE OR NOT ${CMAKE_BUILD_TYPE} MATCHES Debug)
        message(
            FATAL_ERROR
            "Error: Sanitizers can be enabled only with 'Debug' build\n"
            "Hint: Use 'cmake .. -DCMAKE_BUILD_TYPE=Debug'")
        return()
    endif()
    
    target_link_libraries(
        ${target}
            PRIVATE
                -fsanitize=${sanitizer}
    )
    
    if(${sanitizer} STREQUAL "address")
        target_link_libraries(
            ${target}
                PRIVATE
                    -fno-omit-frame-pointer
        )
    endif()
    
    if(CMAKE_CXX_COMPILER_ID MATCHES GNU)
        if (${sanitizer} STREQUAL "undefined")
            target_link_libraries(
                ${target}
                    PRIVATE
                        -lubsan
            )
        elseif (${sanitizer} STREQUAL "thread")
            target_link_libraries(
                ${target}
                    PRIVATE
                        -ltsan
            )
        endif()
    endif()
endfunction()
