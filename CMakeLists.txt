cmake_minimum_required(VERSION 3.16)

project(hello-pi)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_INSTALL_PREFIX}/lib/cmake/ /usr/lib/cmake)
set(VC_INST_PATH ${CMAKE_PREFIX_PATH}/opt/vc)
set(VC_LIBS ${VC_INST_PATH}/lib)
set(VC_INCLUDES ${VC_INST_PATH}/include)
set(VCOS_PLATFORM pthreads)
add_definitions(-Wall -Werror)

find_library(mmalcore_LIBS NAMES mmal_core PATHS "${VC_LIBS}")
find_library(mmalutil_LIBS NAMES mmal_util PATHS "${VC_LIBS}")
find_library(mmal_LIBS NAMES mmal PATHS "${VC_LIBS}")
if((NOT mmal_LIBS) OR (NOT mmalutil_LIBS) OR (NOT mmalcore_LIBS))
  message(FATAL_ERROR "Could not find mmal libs")
endif()

find_path(vmcs_host_INC NAMES vmcs_host PATHS "${VC_INCLUDES}/interface")
if(NOT vmcs_host_INC)
  message(FATAL_ERROR "Could not find vmcs_host interfaces")
endif()

find_library(vchostif_LIBS NAMES vchostif PATHS "${VC_LIBS}")
find_library(vchiq_arm_LIBS NAMES vchiq_arm PATHS "${VC_LIBS}")
find_library(vcos_LIBS NAMES vcos PATHS "${VC_LIBS}")
if((NOT vcos_LIBS) OR (NOT vchiq_arm_LIBS) OR (NOT vchostif_LIBS))
  message(FATAL_ERROR "Could not find vcos/vchiq_arm/vchostif libs")
endif()

find_library(wiringPi_LIB NAMES wiringPi)
if(NOT wiringPi_LIB)
  message(FATAL_ERROR "Could not find wiringPi")
endif()

include_directories(${VC_INCLUDES}
  ${VC_INCLUDES}/interface/vcos
  ${VC_INCLUDES}/interface/vcos/${VCOS_PLATFORM})

add_executable(hello-pi hello-pi.c)
target_link_libraries(hello-pi
  optimized
  pthread
  ${vcos_LIBS}
  ${vchiq_arm_LIBS}
  ${vchostif_LIBS}
  wiringPi)
