cmake_minimum_required(VERSION 3.22.1)
project(llama_bridge)

add_library(llama SHARED
    llama_bridge.cc
)

find_library(log-lib log)

target_include_directories(llama PUBLIC
    "${DART_SDK_PATH}/include"
)

target_link_libraries(
    llama
    ${log-lib}
    c++_shared
)
