set(MSGPACK_CMAKE_ARGS
  -DMSGPACK_BUILD_TESTS=OFF
  -DMSGPACK_BUILD_EXAMPLES=OFF
  -DCMAKE_INSTALL_PREFIX=${DEPS_INSTALL_DIR}
  -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
  -DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES_ALT_SEP}
  "-DCMAKE_C_FLAGS:STRING=-fPIC"
  -DCMAKE_GENERATOR=${CMAKE_GENERATOR})

if(MSVC)
  set(MSGPACK_CMAKE_ARGS
    -DMSGPACK_BUILD_TESTS=OFF
    -DMSGPACK_BUILD_EXAMPLES=OFF
    -DCMAKE_INSTALL_PREFIX=${DEPS_INSTALL_DIR}
    -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    -DCMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
    ${BUILD_TYPE_STRING}
    # Make sure we use the same generator, otherwise we may
    # accidentally end up using different MSVC runtimes
    -DCMAKE_GENERATOR=${CMAKE_GENERATOR})
endif()

if(USE_EXISTING_SRC_DIR)
  unset(MSGPACK_URL)
endif()
ExternalProject_Add(msgpack
  URL ${MSGPACK_URL}
  URL_HASH SHA256=${MSGPACK_SHA256}
  DOWNLOAD_NO_PROGRESS TRUE
  DOWNLOAD_DIR ${DEPS_DOWNLOAD_DIR}/msgpack
  CMAKE_ARGS "${MSGPACK_CMAKE_ARGS}"
  LIST_SEPARATOR |)

list(APPEND THIRD_PARTY_DEPS msgpack)