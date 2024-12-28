from conan import ConanFile
from conan.tools.cmake import CMake, CMakeToolchain
from conan.tools.scm import Git
from conan.tools.files import copy


class cmake_hepersRecipe(ConanFile):
    name = "cmake_helpers"
    version = "1.0"
    # No settings/options are necessary, this is header only
    no_copy_source = True
    
    # Optional metadata
    license = "MIT"
    author = "Zhivko Petrov"
    url = "https://github.com/zhivkopetrov/cmake_helpers"
    description = "A set of cmake helpers functions and find modules"
    
    # Binary configuration
    options = {
        "disable_ros_tooling": [True, False]
    }
    default_options = {
        "disable_ros_tooling": True
    }
    
    def source(self):
        git = Git(self)
        git.clone(url=self.url + ".git", target=".")
        git.checkout("master") # TODO: pin a version
        
    def generate(self):
        tc = CMakeToolchain(self)
        tc.variables["DISABLE_ROS_TOOLING"] = "ON" if self.options.disable_ros_tooling else "OFF"
        tc.generate()

    def package(self):
        if self.options.disable_ros_tooling:
            copy(self, "helpers.cmake", self.source_folder, self.package_folder)
            copy(self, self.name + "Config.cmake", self.source_folder, self.package_folder)
            copy(self, "find_modules/*", self.source_folder, self.package_folder)
        else:
            cmake = CMake(self)
            cmake.install()

    def package_info(self):
        # For header-only packages, libdirs and bindirs are not used
        # so it's recommended to set those as empty.
        self.cpp_info.bindirs = []
        self.cpp_info.libdirs = []
