cmake_minimum_required(VERSION 3.13)
project(bas)

file(GLOB_RECURSE SRC "src/*.cpp")

add_compile_options(-std=c++17)

add_executable(bas ${SRC})
