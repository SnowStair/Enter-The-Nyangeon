/* GPL-2.0-or-later. Only this C stack participates in setjmp recovery. */
#include <setjmp.h>
#include <stdint.h>
#include "SDL.h"
#include "m0_core.h"
#include "m0_memory.h"
#include "d_main.h"
#include "d_loop.h"
#include "doomstat.h"
#include "m_argv.h"
#include "m_misc.h"
#include "m_config.h"
#include "m_menu.h"
#include "i_video.h"
#include "i_sound.h"
#include "g_game.h"
#include "r_local.h"
#include "v_video.h"
#include "crispy.h"
#include "w_wad.h"
#include "p_local.h"
#include "f_finale.h"
#include "d_event.h"
#include "doomkeys.h"
#include "m1_save.h"
extern int m1_audio_start(void);
extern void m1_audio_update(void), m1_audio_pause(int), m1_audio_shutdown(void);
extern void m1_observer_world_begin(void), m1_observer_world_commit(void);
extern int m1_observer_ok(void);
extern const char *m1_observer_error(void);
extern void G_DoLoadLevel(void), G_DoReborn(int), G_DoNewGame(void);
extern gameaction_t gameaction;
extern void M0_RunTic(ticcmd_t *cmds);
extern void D_DoomMain(void);
extern void M0_CopyFrame(uint8_t *rgba);
extern boolean D_Display(void);
extern void M0_Shutdown(void);
static jmp_buf recovery;
static int guarded, active, attempted, requested_jump, host_paused, confirm_pending;
static uint64_t last_request,confirm_request;
static char control_result[2048]="{\"request_id\":\"0\",\"ok\":true,\"completed\":true,\"queued\":false}";
static char last_error[1024], config_dir[4096];
static char skill_arg[16],map_arg[16],episode_arg[16];
static char *args[32];
static uint8_t frame_cache[320*200*4];
static void refresh_frame(void){
    if(SCREENWIDTH!=320 || SCREENHEIGHT!=200)m0_fail("UNEXPECTED_FRAME_SIZE");
    /* Rendering updates native discovery flags. Run exactly at the simulation
     * boundary; public framebuffer reads only copy this cached result. */
    wipegamestate=gamestate;D_Display();M0_CopyFrame(frame_cache);
}
const char *m0_build_info(void){return "{\"abi\":2,\"data_schema\":2,\"save_schema\":1,\"core\":\"Crispy Doom 7.2-1\",\"commit\":\"35b49519fb4f0360ee1527e8cf0bdf0b6bbfeff2\",\"ticrate\":35,\"fixed_fraction_bits\":16,\"audio\":true,\"audio_backend\":\"SDL_mixer-OPL\",\"network\":false,\"render\":\"software-paletted-rgba\",\"lifecycle\":\"one-session-per-library-load\"}";}
const char *m0_error(void){return last_error;}
int m0_is_active(void){return active;}
int m1_is_paused(void){return host_paused;}
const char *m1_control_status(void){return control_result;}
const char *m0_config_dir(void){return config_dir;}
void m0_fail(const char *s){snprintf(last_error,sizeof(last_error),"%s",s);active=0;if(guarded)longjmp(recovery,1);abort();}
void m0_apply_config(void){
    crispy->hires=0;crispy->widescreen=0;crispy->uncapped=0;crispy->vsync=0;
    crispy->jump=requested_jump;crispy->freeaim=0;crispy->freelook=0;crispy->overunder=0;
    fullscreen=0;force_software_renderer=1;usemouse=0;
    M_SetVariable("use_joystick","0");
    snd_musicdevice=3;snd_sfxdevice=3;snd_samplerate=44100;snd_pitchshift=0;
    M_SetVariable("use_libsamplerate","0");
}
int m0_create(const char *iwad,const char *pwad,const char *savedir,int skill,int map,int jump){
    return m1_create(iwad,pwad,savedir,skill,0,map,jump);
}
int m1_create(const char *iwad,const char *pwad,const char *savedir,int skill,int episode,int map,int jump){
    int c=0;FILE *file;
    if(attempted){snprintf(last_error,sizeof(last_error),"RELOAD_REQUIRED: unload core DLL after destroy");return -1;}
    if(!iwad||!savedir||!*savedir||skill<1||skill>5||episode<0||episode>4||map<1||map>(episode?9:32)||jump<0||jump>2){snprintf(last_error,sizeof(last_error),"INVALID_CREATE_ARGUMENT");return -1;}
    file=M_fopen(iwad,"rb");if(!file){snprintf(last_error,sizeof(last_error),"IWAD_OPEN_FAILED: %s",iwad);return -1;}fclose(file);
    if(pwad&&*pwad){file=M_fopen(pwad,"rb");if(!file){snprintf(last_error,sizeof(last_error),"PWAD_OPEN_FAILED: %s",pwad);return -1;}fclose(file);}
    if(strlen(savedir)+64>=sizeof(config_dir)){snprintf(last_error,sizeof(last_error),"SAVE_PATH_TOO_LONG");return -1;}
    snprintf(config_dir,sizeof(config_dir),"%s/",savedir);requested_jump=jump;attempted=1;
    if(m1_save_identity(iwad,pwad,jump)<0){snprintf(last_error,sizeof(last_error),"RESOURCE_IDENTITY_FAILED");return -1;}
    snprintf(skill_arg,sizeof(skill_arg),"%d",skill);snprintf(map_arg,sizeof(map_arg),"%d",map);
    args[c++]="etndoom-crispy";args[c++]="-iwad";args[c++]=m0_strdup(iwad);
    if(pwad&&*pwad){args[c++]="-file";args[c++]=m0_strdup(pwad);}
    args[c++]="-warp";if(episode){snprintf(episode_arg,sizeof(episode_arg),"%d",episode);args[c++]=episode_arg;}args[c++]=map_arg;args[c++]="-skill";args[c++]=skill_arg;
    args[c++]="-noautoload";args[c++]="-nosideload";
    args[c++]="-nomusicpacks";args[c++]="-nogui";args[c++]="-window";
    args[c++]="-savedir";args[c++]=config_dir;args[c]=NULL;myargc=c;myargv=args;
    M_SetExeDir();crispy->sdlversion=m0_strdup("2.32.10");crispy->platform=SDL_GetPlatform();
    guarded=1;if(setjmp(recovery)){guarded=0;return -1;}
    if(!m1_observer_ok())m0_fail(m1_observer_error());
    SDL_SetHint(SDL_HINT_VIDEODRIVER,"dummy");SDL_SetHint(SDL_HINT_RENDER_DRIVER,"software");
    D_DoomMain();
    if((episode==0)!=(gamemode==commercial)||gameepisode!=(episode?episode:1)||gamemap!=map)m0_fail("RESOURCE_MAP_PROFILE_MISMATCH");
    if(m1_audio_start()<0)m0_fail("AUDIO_DEVICE_OPEN_FAILED");
    refresh_frame();active=1;guarded=0;last_error[0]=0;return 0;
}
int m0_step(int forward,int side,int turn,int buttons,int arti){
    ticcmd_t cmds[MAXPLAYERS];
    int completing_confirm=confirm_pending;
    if(!active){snprintf(last_error,sizeof(last_error),"NO_ACTIVE_SESSION");return -1;}
    if(host_paused){snprintf(last_error,sizeof(last_error),"SESSION_PAUSED");return -1;}
    if(forward<-50||forward>50||side<-50||side>50||turn<-32768||turn>32767||buttons<0||buttons>127||(arti!=0&&arti!=128)){
        snprintf(last_error,sizeof(last_error),"INVALID_COMMAND");return -1;
    }
    if(arti && !requested_jump){snprintf(last_error,sizeof(last_error),"JUMP_DISABLED");return -1;}
    memset(cmds,0,sizeof(cmds));cmds[0].forwardmove=forward;cmds[0].sidemove=side;cmds[0].angleturn=turn;cmds[0].buttons=buttons;cmds[0].arti=arti;
    if(confirm_pending){cmds[0].buttons|=BT_USE;confirm_pending=0;}
    guarded=1;if(setjmp(recovery)){guarded=0;return -1;}
    if(!m1_observer_ok())m0_fail(m1_observer_error());
    M_Ticker();M0_RunTic(cmds);gametic++;m1_audio_update();refresh_frame();
    if(!m1_observer_ok())m0_fail(m1_observer_error());
    if(completing_confirm)snprintf(control_result,sizeof(control_result),"{\"ok\":true,\"accepted\":true,\"completed\":true,\"queued\":false,\"request_id\":\"%llu\",\"world_epoch\":\"%llu\",\"core_gametic\":%d,\"code\":\"OK\"}",(unsigned long long)confirm_request,(unsigned long long)m1_world_epoch(),gametic);
    guarded=0;return 0;
}
static int valid_map(int episode,int map){
    char name[16];if(gamemode==commercial){if(episode!=0&&episode!=1)return 0;snprintf(name,sizeof(name),"MAP%02d",map);}
    else {if(episode<1||episode>4||map<1||map>9)return 0;snprintf(name,sizeof(name),"E%dM%d",episode,map);}
    return map>0&&map<=32&&W_CheckNumForName(name)>=0;
}
const char *m1_control(const char *action,int a,int b,int c,uint64_t request_id){
    int result=0,accepted=0,queued=0;
    uint64_t cancelled=0,previous_world=m1_world_epoch();
    const char *code="OK";
    if(!active)code="NO_ACTIVE_SESSION";
    else if(!action||!request_id||request_id<=last_request)code="INVALID_REQUEST_ID";
    else if(strcmp(action,"pause")&&strcmp(action,"new_game")&&strcmp(action,"restart_level")&&strcmp(action,"reborn")&&strcmp(action,"save")&&strcmp(action,"load")&&strcmp(action,"confirm"))code="UNKNOWN_ACTION";
    else {
        last_request=request_id;last_error[0]=0;accepted=1;
        guarded=1;
        if(setjmp(recovery)){guarded=0;code="CORE_FAILURE";goto done;}
        if(!m1_observer_ok())m0_fail(m1_observer_error());
        if(!strcmp(action,"pause")){
            if(a!=0&&a!=1)code="INVALID_PAUSE";
            else{host_paused=a;paused=0;if(confirm_pending)cancelled=confirm_request;confirm_pending=0;m1_audio_pause(a);}
        } else if(!strcmp(action,"new_game")){
            if(a<1||a>5||!valid_map(b,c))code="INVALID_NEW_GAME";
            else{G_DeferedInitNew(a-1,b?b:1,c);G_DoNewGame();if(confirm_pending)cancelled=confirm_request;confirm_pending=0;}
        } else if(!strcmp(action,"restart_level")||!strcmp(action,"reborn")){
            if(gamestate!=GS_LEVEL||gameaction!=ga_nothing)code="NO_ACTIVE_LEVEL";
            else if(!strcmp(action,"reborn")&&players[consoleplayer].playerstate!=PST_DEAD)code="PLAYER_NOT_DEAD";
            else{players[consoleplayer].playerstate=PST_REBORN;G_DoReborn(consoleplayer);G_DoLoadLevel();if(confirm_pending)cancelled=confirm_request;confirm_pending=0;}
        } else if(!strcmp(action,"save")){
            result=m1_save_slot(a,last_error,sizeof(last_error));if(result<0)code=last_error;
        } else if(!strcmp(action,"load")){
            result=m1_load_slot(a,last_error,sizeof(last_error));if(result<0)code=last_error;else{if(confirm_pending)cancelled=confirm_request;confirm_pending=0;}
        } else {
            if(host_paused)code="SESSION_PAUSED";
            else if(confirm_pending)code="CONTROL_PENDING";
            else if(gamestate==GS_INTERMISSION){players[consoleplayer].usedown=0;confirm_pending=1;confirm_request=request_id;queued=1;}
            else if(gamestate==GS_FINALE){event_t e;memset(&e,0,sizeof(e));e.type=ev_keydown;e.data1=KEY_ENTER;F_Responder(&e);players[consoleplayer].usedown=0;confirm_pending=1;confirm_request=request_id;queued=1;}
            else code="CONFIRM_NOT_AVAILABLE";
        }
        if(m1_world_epoch()!=previous_world)refresh_frame();
        m1_audio_pause(host_paused);if(!m1_observer_ok())m0_fail(m1_observer_error());guarded=0;
    }
done:
    /* Public diagnostic codes contain ASCII identifiers only; core text remains in m0_error. */
    snprintf(control_result,sizeof(control_result),"{\"ok\":%s,\"accepted\":%s,\"completed\":%s,\"queued\":%s,\"request_id\":\"%llu\",\"cancelled_request_id\":\"%llu\",\"world_epoch\":\"%llu\",\"core_gametic\":%d,\"paused\":%s,\"active\":%s,\"code\":\"%s\"}",!strcmp(code,"OK")?"true":"false",accepted?"true":"false",!strcmp(code,"OK")&&!queued?"true":"false",queued?"true":"false",(unsigned long long)request_id,(unsigned long long)cancelled,(unsigned long long)m1_world_epoch(),gametic,host_paused?"true":"false",active?"true":"false",code);
    return control_result;
}
int m0_width(void){return SCREENWIDTH;}
int m0_height(void){return SCREENHEIGHT;}
int m0_frame(uint8_t *rgba,int capacity){
    int needed=SCREENWIDTH*SCREENHEIGHT*4;
    if(!active){snprintf(last_error,sizeof(last_error),"NO_ACTIVE_SESSION");return -1;}
    if(!rgba||capacity<needed)return needed;
    memcpy(rgba,frame_cache,(size_t)needed);return needed;
}
void m0_destroy(void){
    active=0;guarded=1;
    if(!setjmp(recovery)){m1_audio_shutdown();M0_Shutdown();}
    guarded=0;m0_release_memory();
}
