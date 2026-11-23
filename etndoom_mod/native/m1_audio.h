#ifndef ETN_M1_AUDIO_H
#define ETN_M1_AUDIO_H
#include <stdint.h>
#include "m0_core.h"
int m1_audio_start(void);
void m1_audio_update(void);
void m1_audio_pause(int pause_on);
void m1_audio_shutdown(void);
M0_API const char *m1_audio_status(void);
M0_API const char *m1_audio_info(void);
M0_API int m1_audio_read(uint8_t *pcm, int capacity);
M0_API int m1_audio_set_volume(int sfx, int music);
void m1_audio_sound_start(int channel, int resource, const void *origin, int volume, int separation, int pitch, int handle);
void m1_audio_sound_stop(int channel);
void m1_audio_sound_position(int channel, const void *origin, int volume, int separation);
void m1_audio_music_start(int resource, int looping);
void m1_audio_music_stop(void);
#endif
