#ifndef ETN_M0_CORE_H
#define ETN_M0_CORE_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
#define M0_API __declspec(dllexport)
M0_API const char *m0_build_info(void);
M0_API int m0_create(const char *iwad, const char *pwad, const char *savedir, int skill, int map, int jump);
/* ABI 2: episode=0 is Doom II; episode=1..4 is Doom. */
M0_API int m1_create(const char *iwad, const char *pwad, const char *savedir, int skill, int episode, int map, int jump);
/* request_id must increase, result is copied before the next control call. */
M0_API const char *m1_control(const char *action, int arg0, int arg1, int arg2, uint64_t request_id);
M0_API uint64_t m1_world_epoch(void);
M0_API const char *m1_control_status(void);
int m1_is_paused(void);
M0_API int m0_step(int forward, int side, int turn, int buttons, int arti);
M0_API const char *m0_snapshot(void);
M0_API const char *m0_map(void);
M0_API int m0_frame(uint8_t *rgba, int capacity);
M0_API int m0_width(void);
M0_API int m0_height(void);
M0_API const char *m0_error(void);
M0_API void m0_destroy(void);
M0_API uint64_t m0_allocated_bytes(void);
M0_API uint64_t m0_allocation_count(void);
#ifdef __cplusplus
}
#endif
#endif
