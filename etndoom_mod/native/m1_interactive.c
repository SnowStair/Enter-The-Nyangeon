/* GPL-2.0-or-later. Raw events retain Crispy's own menu and input semantics. */
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "SDL.h"
#include "doomstat.h"
#include "doomkeys.h"
#include "d_event.h"
#include "d_main.h"
#include "m_config.h"
#include "m_menu.h"
#include "m_misc.h"
#include "crispy.h"
#include "i_video.h"
#include "i_sound.h"
#include "s_sound.h"
#include "r_local.h"
#include "p_local.h"
#include "w_wad.h"
#include "z_zone.h"
#include "m_crispy.h"
#include "m0_core.h"
#include "m1_save.h"
#include "m1_interactive.h"
extern int screenblocks,detailLevel,sfxVolume,musicVolume;
extern void AM_LevelInit(boolean reinit),EnableLoadingDisk(void),R_InitLightTables(void),R_InitSkyMap(void),P_SegLengths(boolean contrast_only);
extern void I_ReInitGraphics(int reinit);
static int enabled,quit_requested,executed;
static int host_width=16,host_height=9,host_fraction;
static char status[2048],menu_error[160];
int m1_interactive_enabled(void){return enabled;}
void m1_interactive_executed(int count){executed=count;}
void m1_interactive_clear(void){M1_ClearInput();}
void m1_interactive_enable(void){
    int old_channels=snd_channels,wanted_channels,i;
    if(enabled)return;
    enabled=1;
    /* Native defaults, overridden only by this isolated profile's cfg. */
    crispy->hires=1;crispy->widescreen=RATIO_MATCH_SCREEN;crispy->vsync=1;
    M_LoadDefaults();
    /* SDL is an offscreen renderer; the host owns the actual display/devices. */
    usemouse=0;fullscreen=0;force_software_renderer=1;
    M_SetVariable("use_joystick","0");
    snd_musicdevice=3;snd_sfxdevice=3;snd_samplerate=44100;
    wanted_channels=snd_channels;snd_channels=old_channels;
    if(wanted_channels!=8&&wanted_channels!=16&&wanted_channels!=32)wanted_channels=8;
    while(snd_channels!=wanted_channels)S_UpdateSndChannels(1);
    CheckCrispySingleplayer(true);
    I_ReInitGraphics(REINIT_FRAMEBUFFERS|REINIT_TEXTURES|REINIT_ASPECTRATIO);
    R_InitLightTables();R_InitSkyMap();P_SegLengths(true);R_SetViewSize(screenblocks,detailLevel);
    R_ExecuteSetViewSize();R_FillBackScreen();EnableLoadingDisk();AM_LevelInit(true);
    S_SetSfxVolume(sfxVolume*8);S_SetMusicVolume(musicVolume*8);S_UpdateStereoSeparation();
    I_SetPalette(W_CacheLumpName("PLAYPAL",PU_CACHE));
    for(i=0;i<MAXPLAYERS;i++)if(playeringame[i])players[i].so=Crispy_PlayerSO(i);
    /* Apply the loaded blood policy to actors created before interactive mode. */
    M_CrispyToggleColoredblood(0);M_CrispyToggleColoredblood(1);
    M1_ConfigLoaded();M1_ClearInput();
}
void m1_interactive_shutdown(void){if(enabled&&!M1_SaveDefaultsChecked())fprintf(stderr,"ETNDOOM: SETTINGS_WRITE_FAILED (%s)\n",m0_config_dir());}
void m1_interactive_post_render(void){
    if(enabled&&crispy->post_rendering_hook){void (*hook)(void)=crispy->post_rendering_hook;crispy->post_rendering_hook=NULL;hook();}
}
int M1_GetDisplayMode(int *width,int *height){*width=host_width;*height=host_height;return 1;}
int M1_FractionalTic(void){return host_fraction;}
void m1_interactive_quit(void){quit_requested=1;M1_ClearInput();}
void m1_interactive_event(int type,int a,int b,int c){
    event_t event;int was_menu=menuactive;
    if(type==3){M1_ClearInput();return;}
    if(type==4){
        if(a==host_width&&b==host_height)return;
        host_width=a;host_height=b;
        if(crispy->widescreen==RATIO_MATCH_SCREEN){
            I_ReInitGraphics(REINIT_FRAMEBUFFERS|REINIT_TEXTURES|REINIT_ASPECTRATIO);
            R_ExecuteSetViewSize();R_FillBackScreen();EnableLoadingDisk();AM_LevelInit(true);
        }
        return;
    }
    if(type==5){host_fraction=a;return;}
    memset(&event,0,sizeof(event));
    event.type=type==0?ev_keyup:type==1?ev_keydown:ev_mouse;
    event.data1=a;event.data2=b;event.data3=c;
    if(type==2)M1_UpdateMouseAccel(b,c);
    D_PostEvent(&event);D_ProcessEvents();
    /* Discard gameplay holds when ownership changes; retain menu settings. */
    if(was_menu!=menuactive)M1_ClearInput();
    if(was_menu&&!menuactive&&!M1_SaveDefaultsChecked())M1_MenuError("SETTINGS_WRITE_FAILED");
}
const char *m1_ui_status(void){
    snprintf(status,sizeof(status),"{\"ok\":true,\"interactive\":%s,\"menu_active\":%s,\"native_paused\":%s,\"quit_requested\":%s,\"executed\":%d,\"settings\":true,\"save_slots\":64,\"uncapped\":%s,\"fps_limit\":%d,\"vsync\":%s,\"smooth_scaling\":%s,\"aspect_ratio_correct\":%s,\"screen_width\":%d,\"screen_height\":%d,\"jump\":%d,\"freeaim\":%d,\"overunder\":%d}",enabled?"true":"false",menuactive?"true":"false",paused?"true":"false",quit_requested?"true":"false",executed,crispy->uncapped?"true":"false",crispy->fpslimit,crispy->vsync?"true":"false",M_GetIntVariable("smooth_pixel_scaling")?"true":"false",M_GetIntVariable("aspect_ratio_correct")?"true":"false",SCREENWIDTH,SCREENHEIGHT,crispy->jump,crispy->freeaim,crispy->overunder);
    return status;
}
static int menu_result(int result){if(result<0)M1_MenuError(menu_error);return result==0;}
int m1_menu_save(int slot,const char *description){return menu_result(m1_save_slot_named(slot,description,menu_error,sizeof(menu_error)));}
int m1_menu_load(int slot){int result=m1_load_slot(slot,menu_error,sizeof(menu_error));if(!result)M1_ClearInput();return menu_result(result);}
const char *m1_menu_save_path(int slot){return m1_save_path(slot);}
int m1_menu_save_description(int slot,char *description,int capacity){return m1_save_description(slot,description,capacity);}
