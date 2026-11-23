#ifndef ETN_M1_OBSERVER_H
#define ETN_M1_OBSERVER_H
#include <stdint.h>
#include "m0_core.h"
/* JSON identities are decimal strings; callers copy every returned buffer. */
M0_API uint64_t m1_world_epoch(void);
M0_API const char *m1_resources(void);
M0_API int m1_resource_read(int kind, int index, int offset, uint8_t *out, int capacity);
M0_API const char *m1_events(void);
M0_API int m1_ack_events(uint64_t sequence);
void m1_observer_world_begin(void);
void m1_observer_world_commit(void);
void m1_observer_spawn(void *object);
void m1_observer_remove(void *object);
void m1_observer_teleport(void *object);
void m1_observer_audio(int type,int channel,uint64_t instance,int resource,uint64_t origin,int a,int b,int c);
uint64_t m1_entity_id(const void *object);
int m1_observer_ok(void);
const char *m1_observer_error(void);
void m1_observer_reset_events(void);
#endif
