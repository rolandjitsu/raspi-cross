cmake_minimum_required(VERSION 3.16)

project(hello-pi C CXX)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_INSTALL_PREFIX}/lib/cmake/ /usr/lib/cmake)
set(VC_INST_PATH ${CMAKE_PREFIX_PATH}/opt/vc)
set(VC_LIBS ${VC_INST_PATH}/lib)
set(VC_INCLUDES ${VC_INST_PATH}/include)
set(VCOS_PLATFORM pthreads)

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

find_library(crypt_LIB NAMES crypt)
if(NOT crypt_LIB)
  set(crypt_LIB crypt)
endif()

find_library(m_LIB NAMES m)
if(NOT m_LIB)
  set(m_LIB m)
endif()

# Target: hello (standard C++ Raspberry Pi model reader)
add_executable(hello hello.cpp)
target_compile_features(hello PRIVATE cxx_std_17)
target_compile_options(hello PRIVATE -Wall -Werror -Ofast)

# Target: hello-pi (C application using Broadcom VideoCore and WiringPi)
add_executable(hello-pi hello-pi.c)
target_compile_options(hello-pi PRIVATE -Wall -Werror)
target_include_directories(hello-pi PRIVATE
  ${VC_INCLUDES}
  ${VC_INCLUDES}/interface/vcos
  ${VC_INCLUDES}/interface/vcos/${VCOS_PLATFORM}
)
target_link_libraries(hello-pi PRIVATE
  pthread
  ${m_LIB}
  ${crypt_LIB}
  ${vcos_LIBS}
  ${vchiq_arm_LIBS}
  ${vchostif_LIBS}
  ${wiringPi_LIB}
)
