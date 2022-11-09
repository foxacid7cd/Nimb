#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
#ifndef DLLEXPORT
#  ifdef MSWIN
#    define DLLEXPORT __declspec(dllexport)
#  else
#    define DLLEXPORT
#  endif
#endif
DLLEXPORT void fs_init(void);
DLLEXPORT void fs_loop_lock(void);
DLLEXPORT void fs_loop_unlock(void);
DLLEXPORT int os_chdir(const char *path) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int os_dirname(char_u *buf, size_t len) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool os_isrealdir(const char *name) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool os_isdir(const char *name) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int os_nodetype(const char *name) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int os_exepath(char *buffer, size_t *size) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool os_can_exe(const char *name, char **abspath, _Bool use_path) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT int os_open(const char *path, int flags, int mode);
DLLEXPORT FILE *os_fopen(const char *path, const char *flags);
DLLEXPORT int os_set_cloexec(const int fd);
DLLEXPORT int os_close(const int fd);
DLLEXPORT int os_dup(const int fd) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT ptrdiff_t os_read(const int fd, _Bool *const ret_eof, char *const ret_buf, const size_t size, const _Bool non_blocking) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT ptrdiff_t os_readv(const int fd, _Bool *const ret_eof, struct iovec *iov, size_t iov_size, const _Bool non_blocking) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT ptrdiff_t os_write(const int fd, const char *const buf, const size_t size, const _Bool non_blocking) FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT int os_copy(const char *path, const char *new_path, int flags);
DLLEXPORT int os_fsync(int fd);
DLLEXPORT int32_t os_getperm(const char *name);
DLLEXPORT int os_setperm(const char *const name, int perm) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool os_file_owned(const char *fname) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int os_chown(const char *path, uv_uid_t owner, uv_gid_t group);
DLLEXPORT int os_fchown(int fd, uv_uid_t owner, uv_gid_t group);
DLLEXPORT _Bool os_path_exists(const char *path);
DLLEXPORT int os_file_settime(const char *path, double atime, double mtime);
DLLEXPORT _Bool os_file_is_readable(const char *name) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT int os_file_is_writable(const char *name) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT int os_rename(const char_u *path, const char_u *new_path) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int os_mkdir(const char *path, int32_t mode) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int os_mkdir_recurse(const char *const dir, int32_t mode, char **const failed_dir) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT int os_file_mkdir(char *fname, int32_t mode) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT;
DLLEXPORT int os_mkdtemp(const char *template, char *path) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int os_rmdir(const char *path) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool os_scandir(Directory *dir, const char *path) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT const char *os_scandir_next(Directory *dir) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void os_closedir(Directory *dir) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT int os_remove(const char *path) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool os_fileinfo(const char *path, FileInfo *file_info) FUNC_ATTR_NONNULL_ARG(2);
DLLEXPORT _Bool os_fileinfo_link(const char *path, FileInfo *file_info) FUNC_ATTR_NONNULL_ARG(2);
DLLEXPORT _Bool os_fileinfo_fd(int file_descriptor, FileInfo *file_info) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool os_fileinfo_id_equal(const FileInfo *file_info_1, const FileInfo *file_info_2) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void os_fileinfo_id(const FileInfo *file_info, FileID *file_id) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT uint64_t os_fileinfo_inode(const FileInfo *file_info) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT uint64_t os_fileinfo_size(const FileInfo *file_info) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT uint64_t os_fileinfo_hardlinks(const FileInfo *file_info) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT uint64_t os_fileinfo_blocksize(const FileInfo *file_info) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool os_fileid(const char *path, FileID *file_id) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool os_fileid_equal(const FileID *file_id_1, const FileID *file_id_2) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT _Bool os_fileid_equal_fileinfo(const FileID *file_id, const FileInfo *file_info) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT char *os_realpath(const char *name, char *buf) FUNC_ATTR_NONNULL_ARG(1);
#include "nvim/func_attr.h"
