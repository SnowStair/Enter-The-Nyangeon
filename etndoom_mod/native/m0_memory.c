#ifndef ETN_M0_MEMORY_IMPL
#define ETN_M0_MEMORY_IMPL
#endif
#include "m0_memory.h"
#include "m0_core.h"
#include <stdint.h>
typedef struct block { struct block *next, *prev; size_t size; } block;
static block *blocks;
static uint64_t allocated, allocation_count;
typedef struct stream { FILE *f; struct stream *next; } stream;
static stream *streams;
void *m0_malloc(size_t n) {
    block *b = malloc(sizeof(*b) + n);
    if (!b) return NULL;
    b->size=n; b->prev=NULL; b->next=blocks;
    if (blocks) blocks->prev=b;
    blocks=b; allocated+=n; allocation_count++;
    return b+1;
}
void m0_free(void *p) {
    block *b;
    if (!p) return;
    b=(block*)p-1;
    if (b->prev) b->prev->next=b->next; else blocks=b->next;
    if (b->next) b->next->prev=b->prev;
    allocated-=b->size; allocation_count--; free(b);
}
void *m0_calloc(size_t n,size_t size) {
    void *p;
    if (size && n>SIZE_MAX/size) return NULL;
    p=m0_malloc(n*size); if(p) memset(p,0,n*size); return p;
}
void *m0_realloc(void *p,size_t n) {
    void *q;
    if(!p) return m0_malloc(n);
    if(!n) {m0_free(p); return NULL;}
    q=m0_malloc(n);
    if(q) {size_t old=((block*)p-1)->size; memcpy(q,p,n<old?n:old);m0_free(p);}
    return q;
}
char *m0_strdup(const char *s) {size_t n=strlen(s)+1;char *r=m0_malloc(n);if(r)memcpy(r,s,n);return r;}
static FILE *track(FILE *f) {
    stream *s;
    if(!f)return NULL;
    s=malloc(sizeof(*s));if(!s){fclose(f);return NULL;}
    s->f=f;s->next=streams;streams=s;return f;
}
FILE *m0_fopen(const char *p,const char *m){return track(fopen(p,m));}
FILE *m0_wfopen(const wchar_t *p,const wchar_t *m){return track(_wfopen(p,m));}
int m0_fclose(FILE *f){stream **s=&streams;while(*s){if((*s)->f==f){stream *old=*s;*s=old->next;free(old);break;}s=&(*s)->next;}return fclose(f);}
void m0_release_memory(void){while(streams)m0_fclose(streams->f);while(blocks)m0_free(blocks+1);}
uint64_t m0_allocated_bytes(void){return allocated;}
uint64_t m0_allocation_count(void){return allocation_count;}
