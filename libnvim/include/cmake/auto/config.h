#ifndef AUTO_CONFIG_H
#define AUTO_CONFIG_H

/* #undef DEBUG */

#define SIZEOF_INT 4
#define SIZEOF_INTMAX_T 8
#define SIZEOF_INT32_T 4
#define SIZEOF_LONG 8
#define SIZEOF_LONG_LONG 8
#define SIZEOF_SIZE_T 8

#if 8 == 8
#define ARCH_64
#elif 8 == 4
#define ARCH_32
#endif

#define PROJECT_NAME "nvim"

#define HAVE__NSGETENVIRON
#define HAVE_FD_CLOEXEC
#define HAVE_FSEEKO
#define HAVE_GETPWENT
#define HAVE_GETPWNAM
#define HAVE_GETPWUID
#define HAVE_ICONV
#define HAVE_LANGINFO_H
#define HAVE_LOCALE_H
#define HAVE_NL_LANGINFO_CODESET
/* #undef HAVE_NL_MSG_CAT_CNTR */
#define HAVE_PWD_H
#define HAVE_READLINK
#define HAVE_SETPGID
#define HAVE_SETSID
#define HAVE_SIGACTION
#define HAVE_STRNLEN
#define HAVE_STRCASECMP
#define HAVE_STRINGS_H
#define HAVE_STRNCASECMP
#define HAVE_STRPTIME
#define HAVE_SYS_SDT_H
#define HAVE_SYS_UTSNAME_H
/* #undef HAVE_SYS_WAIT_H */
#define HAVE_TERMIOS_H
#define HAVE_WORKING_LIBINTL
#define UNIX
#define CASE_INSENSITIVE_FILENAME
#define USE_FNAME_CASE
#define HAVE_SYS_UIO_H
#ifdef HAVE_SYS_UIO_H
#define HAVE_READV
# ifndef HAVE_READV
#  undef HAVE_SYS_UIO_H
# endif
#endif
#define HAVE_FORKPTY

#define FEAT_TUI

#ifndef UNIT_TESTING
/* #undef LOG_LIST_ACTIONS */
#endif

/* #undef HAVE_BE64TOH */
/* #undef ORDER_BIG_ENDIAN */
#define ENDIAN_INCLUDE_FILE <endian.h>

#define HAVE_EXECINFO_BACKTRACE
#define HAVE_BUILTIN_ADD_OVERFLOW
#define HAVE_WIMPLICIT_FALLTHROUGH_FLAG

#endif  // AUTO_CONFIG_H
