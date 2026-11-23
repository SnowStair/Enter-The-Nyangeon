#ifndef ETN_M0_MEMORY_H
#define ETN_M0_MEMORY_H
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <wchar.h>
void *m0_malloc(size_t n);
void *m0_calloc(size_t n, size_t size);
void *m0_realloc(void *p, size_t n);
void m0_free(void *p);
char *m0_strdup(const char *s);
FILE *m0_fopen(const char *p, const char *m);
FILE *m0_wfopen(const wchar_t *p, const wchar_t *m);
int m0_fclose(FILE *f);
void m0_release_memory(void);
__attribute__((noreturn)) void m0_fail(const char *message);
const char *m0_config_dir(void);
void m0_apply_config(void);
#ifndef ETN_M0_MEMORY_IMPL
#define malloc m0_malloc
#define calloc m0_calloc
#define realloc m0_realloc
#define free m0_free
#define strdup m0_strdup
#define _strdup m0_strdup
#define fopen m0_fopen
#define _wfopen m0_wfopen
#define fclose m0_fclose
#endif
#endif
