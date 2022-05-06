cmake_minimum_required(VERSION 3.13)
project(bas)

file(GLOB_RECURSE SRC "src/*.cpp")

if (MSVC)
    add_compile_options(/std:c++17)
else()
    add_compile_options(-std=c++17)
endif ()

add_executable(bas ${SRC})
