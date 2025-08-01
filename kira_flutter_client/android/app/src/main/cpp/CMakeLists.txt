cmake_minimum_required(VERSION 3.22.1)
project(llama_bridge)

add_library(llama_bridge SHARED
    llama_bridge.cc
)

find_library(log-lib log)

target_include_directories(llama_bridge PUBLIC
    "${DART_SDK_PATH}/include"
)

target_link_libraries(
    llama_bridge
    ${log-lib}
    c++_shared
)
