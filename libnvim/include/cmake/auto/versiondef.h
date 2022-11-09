#ifndef AUTO_VERSIONDEF_H
#define AUTO_VERSIONDEF_H

#define NVIM_VERSION_MAJOR 0
#define NVIM_VERSION_MINOR 9
#define NVIM_VERSION_PATCH 0
#define NVIM_VERSION_PRERELEASE "-dev"

/* #undef NVIM_VERSION_MEDIUM */
#ifndef NVIM_VERSION_MEDIUM
# include "auto/versiondef_git.h"
#endif

#define NVIM_API_LEVEL 10
#define NVIM_API_LEVEL_COMPAT 0
#define NVIM_API_PRERELEASE false

#define NVIM_VERSION_CFLAGS "/Applications/Xcode-14.1.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=1 -DNVIM_TS_HAS_SET_MATCH_LIMIT -DNVIM_TS_HAS_SET_ALLOCATOR -O2 -g -Wall -Wextra -pedantic -Wno-unused-parameter -Wstrict-prototypes -std=gnu99 -Wshadow -Wconversion -Wdouble-promotion -Wmissing-noreturn -Wmissing-format-attribute -Wmissing-prototypes -Wimplicit-fallthrough -Wvla -fstack-protector-strong -fno-common -fdiagnostics-color=always -DINCLUDE_GENERATED_DECLARATIONS -DNVIM_MSGPACK_HAS_FLOAT32 -DNVIM_UNIBI_HAS_VAR_FROM -DMIN_LOG_LEVEL=3 -I/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/build/cmake.config -I/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/src -I/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/.deps/usr/include -I/opt/local/include -I/Library/Frameworks/Mono.framework/Headers -I/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/build/src/nvim/auto -I/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Targets/libNims/build/include"
#define NVIM_VERSION_BUILD_TYPE "RelWithDebInfo"

#endif  // AUTO_VERSIONDEF_H
