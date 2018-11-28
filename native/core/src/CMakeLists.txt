#扫描目录"."内的源文件
aux_source_directory (. DIR_SRCS)
set(CMAKE_C_FLAGS "-fPIC -Wall")
add_library (core SHARED ${DIR_SRCS})
include_directories(../include ../../include)
install(TARGETS core LIBRARY DESTINATION lib/arm64-v8a)
