#include <klib.h>
#include <rtthread.h>

char *strchr(const char *s, int c) {
  assert(0);
}

char *strrchr(const char *s, int c) {
  assert(0);
}

char *strstr(const char *haystack, const char *needle) {
  return rt_strstr(haystack, needle);
}

long strtol(const char *restrict nptr, char **restrict endptr, int base) {
  assert(0);
}

char *strncat(char *restrict dst, const char *restrict src, size_t sz) {
  assert(0);
}
