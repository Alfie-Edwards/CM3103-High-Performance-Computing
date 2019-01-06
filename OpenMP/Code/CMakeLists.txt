cmake_minimum_required(VERSION 3.8)
project(Blur)

set(CMAKE_C_STANDARD 99)
set(CMAKE_EXE_LINKER_FLAGS "-Wl,--stack,16777216")
set(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} -fopenmp")

set(SOURCE_FILES
        blurOMP.c)

add_executable(Code ${SOURCE_FILES})