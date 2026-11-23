/* GPL-2.0-or-later. Native SDL_mixer + Crispy OPL owns playback.
 * The fixed postmix ring is observation only and never advances simulation. */
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "SDL.h"
#include "SDL_mixer.h"
#include "doomstat.h"
#include "s_sound.h"
#include "i_sound.h"
#include "opl.h"
#include "m1_audio.h"
#include "m1_observer.h"

#define PCM_CAPACITY (262144)
#define CHANNEL_CAPACITY 32
typedef struct { uint64_t instance, origin; int active, resource, volume, separation, pitch, handle; } observed_channel;
static observed_channel channels[CHANNEL_CAPACITY];
static uint8_t pcm_ring[PCM_CAPACITY];
static int pcm_start, pcm_size, initialized, audio_paused, music_resource=-1, music_looping;
static uint64_t next_instance, pcm_bytes, nonzero_samples, dropped_bytes, callbacks, sound_starts, music_starts;
static int peak_sample;
static int output_sfx=127,output_music=127;
static SDL_mutex *pcm_mutex;
static char status_json[16384];
extern int M1_AudioModulesReady(void);

static void capture(void *unused, Uint8 *stream, int length)
{
    int i, offset, remaining;
    const Sint16 *samples=(const Sint16 *)stream;
    (void)unused;
    SDL_LockMutex(pcm_mutex);
    callbacks++; pcm_bytes+=(uint64_t)length;
    for(i=0;i<length/2;i++) {
        int sample=samples[i]; if(sample) nonzero_samples++;
        if(sample<0)sample=-sample;
        if(sample>peak_sample)peak_sample=sample;
    }
    if(length>PCM_CAPACITY) { dropped_bytes+=(uint64_t)(length-PCM_CAPACITY); stream+=length-PCM_CAPACITY;length=PCM_CAPACITY; }
    if(pcm_size+length>PCM_CAPACITY) {
        int drop=pcm_size+length-PCM_CAPACITY;
        pcm_start=(pcm_start+drop)%PCM_CAPACITY;pcm_size-=drop;dropped_bytes+=(uint64_t)drop;
    }
    offset=(pcm_start+pcm_size)%PCM_CAPACITY;
    remaining=PCM_CAPACITY-offset;if(remaining>length)remaining=length;
    memcpy(pcm_ring+offset,stream,(size_t)remaining);
    memcpy(pcm_ring,stream+remaining,(size_t)(length-remaining));
    pcm_size+=length;
    SDL_UnlockMutex(pcm_mutex);
}
int m1_audio_start(void)
{
    int frequency, count;Uint16 format;
    if(initialized)return 0;
    if(!M1_AudioModulesReady() || !S_MusicPlaying() || !Mix_QuerySpec(&frequency,&format,&count) || format!=AUDIO_S16SYS || count!=2)return -1;
    pcm_mutex=SDL_CreateMutex();if(!pcm_mutex)return -1;
    initialized=1;audio_paused=0;
    Mix_SetPostMix(capture,NULL);
    return 0;
}
void m1_audio_update(void)
{
    if(!initialized || audio_paused)return;
    if(gamestate==GS_LEVEL && players[displayplayer].mo)S_UpdateSounds(players[displayplayer].mo);
    else I_UpdateSound();
}
void m1_audio_pause(int pause_on)
{
    if(!initialized || audio_paused==!!pause_on)return;
    audio_paused=!!pause_on;
    /* Pause the actual device so the OPL callback clock and SFX both freeze. */
    if(audio_paused) { Mix_PauseAudio(1);S_PauseSound(); }
    else { S_ResumeSound();Mix_PauseAudio(0); }
    m1_observer_audio(audio_paused?4:5,-1,0,-1,0,0,0,0);
}
void m1_audio_shutdown(void)
{
    if(initialized) {
        /* SDL_mixer synchronizes removal with its callback before returning. */
        Mix_PauseAudio(1);Mix_SetPostMix(NULL,NULL);
        SDL_DestroyMutex(pcm_mutex);pcm_mutex=NULL;initialized=0;
    }
    /* Patched upstream shutdown is idempotent and unregisters OPL effects
     * before freeing its queue/mutexes, even with a shared mixer device. */
    I_ShutdownSound();
    memset(channels,0,sizeof(channels));music_resource=-1;pcm_size=0;
}
int m1_audio_set_volume(int sfx,int music)
{
    if(!initialized || sfx<0 || sfx>127 || music<0 || music>127)return -1;
    /* Output gain must not take S_StartSound's zero-volume early exit, which
     * would skip native pitch RNG and change the observable trajectory. */
    output_sfx=sfx;output_music=music;
    Mix_Volume(-1,sfx);
    OPL_Lock();I_SetMusicVolume((music*64)/127);OPL_Unlock();return 0;
}
int m1_audio_read(uint8_t *pcm,int capacity)
{
    int count,first;
    if(!initialized || capacity<0)return -1;
    SDL_LockMutex(pcm_mutex);
    count=pcm_size;
    if(pcm && capacity>0) {
        if(count>capacity)count=capacity;
        count-=count%4;
        first=PCM_CAPACITY-pcm_start;if(first>count)first=count;
        memcpy(pcm,pcm_ring+pcm_start,(size_t)first);memcpy(pcm+first,pcm_ring,(size_t)(count-first));
        pcm_start=(pcm_start+count)%PCM_CAPACITY;pcm_size-=count;
    }
    SDL_UnlockMutex(pcm_mutex);return count;
}
const char *m1_audio_status(void)
{
    int i,n=0,frequency=0,count=0,queued=0,peak=0;Uint16 format=0;
    uint64_t bytes=0,nonzero=0,dropped=0,callback_count=0;
    const char *driver=SDL_GetCurrentAudioDriver();
    if(initialized) {
        SDL_LockMutex(pcm_mutex);queued=pcm_size;peak=peak_sample;bytes=pcm_bytes;
        nonzero=nonzero_samples;dropped=dropped_bytes;callback_count=callbacks;SDL_UnlockMutex(pcm_mutex);
        Mix_QuerySpec(&frequency,&format,&count);
    }
    n=snprintf(status_json,sizeof(status_json),"{\"backend\":\"SDL_mixer-2.8.1/OPL\",\"device\":\"%s\",\"ready\":%s,\"paused\":%s,\"frequency\":%d,\"channels\":%d,\"format\":\"s16le\",\"capture_capacity\":%d,\"capture_queued\":%d,\"pcm_bytes\":\"%llu\",\"nonzero_samples\":\"%llu\",\"capture_dropped_bytes\":\"%llu\",\"callbacks\":\"%llu\",\"peak\":%d,\"sound_starts\":\"%llu\",\"music_starts\":\"%llu\",\"music_resource\":%d,\"music_looping\":%s,\"output_sfx\":%d,\"output_music\":%d,\"voices\":[",driver?driver:"none",initialized?"true":"false",audio_paused?"true":"false",frequency,count,PCM_CAPACITY,queued,(unsigned long long)bytes,(unsigned long long)nonzero,(unsigned long long)dropped,(unsigned long long)callback_count,peak,(unsigned long long)sound_starts,(unsigned long long)music_starts,music_resource,music_looping?"true":"false",output_sfx,output_music);
    for(i=0;i<CHANNEL_CAPACITY;i++) {
        observed_channel *c=&channels[i];
        n+=snprintf(status_json+n,sizeof(status_json)-(size_t)n,"%s{\"channel\":%d,\"instance\":\"%llu\",\"active\":%s,\"resource\":%d,\"origin\":\"%llu\",\"volume\":%d,\"separation\":%d,\"pitch\":%d}",i?",":"",i,(unsigned long long)c->instance,c->active?"true":"false",c->resource,(unsigned long long)c->origin,c->volume,c->separation,c->pitch);
    }
    snprintf(status_json+n,sizeof(status_json)-(size_t)n,"]}");return status_json;
}
const char *m1_audio_info(void){return m1_audio_status();}
void m1_audio_sound_start(int channel,int resource,const void *origin,int volume,int separation,int pitch,int handle)
{
    observed_channel *c;if(channel<0 || channel>=CHANNEL_CAPACITY)return;c=&channels[channel];
    c->instance=++next_instance;c->origin=m1_entity_id(origin);c->resource=resource;c->volume=volume;c->separation=separation;c->pitch=pitch;c->handle=handle;c->active=handle>=0;sound_starts++;
    m1_observer_audio(1,channel,c->instance,resource,c->origin,volume,separation,pitch);
}
void m1_audio_sound_stop(int channel)
{
    observed_channel *c;if(channel<0 || channel>=CHANNEL_CAPACITY)return;c=&channels[channel];
    if(c->active)m1_observer_audio(2,channel,c->instance,c->resource,c->origin,0,0,0);
    c->active=0;
}
void m1_audio_sound_position(int channel,const void *origin,int volume,int separation)
{
    observed_channel *c;if(channel<0 || channel>=CHANNEL_CAPACITY)return;c=&channels[channel];
    c->origin=m1_entity_id(origin);c->volume=volume;c->separation=separation;
}
void m1_audio_music_start(int resource,int looping)
{
    music_resource=resource;music_looping=looping;music_starts++;
    m1_observer_audio(3,-1,++next_instance,resource,0,looping,0,0);
}
void m1_audio_music_stop(void){music_resource=-1;music_looping=0;}
