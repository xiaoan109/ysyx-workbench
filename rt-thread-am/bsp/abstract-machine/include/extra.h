typedef long suseconds_t;
typedef unsigned long useconds_t;
#include <sys/types.h>

#ifdef __ISA_NATIVE__
// rename posix API to avoid conflict with glibc in native
#define open      rt_open
#define creat     rt_creat
#define close     rt_close
#define read      rt_read
#define write     rt_write
#define lseek     rt_lseek
#define rename    rt_rename
#define unlink    rt_unlink
#define stat      rt_stat
#define fstat     rt_fstat
#define fsync     rt_fsync
#define fcntl     rt_fcntl
#define ioctl     rt_ioctl
#define ftruncate rt_ftruncate
#define statfs    rt_statfs
#define fstatfs   rt_fstatfs
#define mkdir     rt_mkdir
#define rmdir     rt_rmdir
#define opendir   rt_opendir
#define readdir   rt_readdir
#define telldir   rt_telldir
#define seekdir   rt_seekdir
#define rewinddir rt_rewinddir
#define closedir  rt_closedir
#define chdir     rt_chdir
#define access    rt_access
#define setcwd    rt_setcwd
#define getcwd    rt_getcwd

#define gettimeofday rt_gettimeofday

#endif
