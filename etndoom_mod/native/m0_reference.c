/* GPL-2.0-or-later. Reference retains upstream TryRunTics/RunTic. */
#include <stdio.h>
#include <stdlib.h>
#include "SDL.h"
#include "crispy.h"
#include "m_argv.h"
#include "m_config.h"
#include "i_video.h"
#include "d_ticcmd.h"
#include "d_loop.h"
#include "doomstat.h"
#include "m0_core.h"
#include "m1_audio.h"
#include "m1_observer.h"
#include "i_sound.h"
static FILE *trajectory;
static FILE *commands;
static int mode,limit=350,jump;
extern boolean D_Display(void);
const char *m0_config_dir(void){int p=M_CheckParmWithArgs("-savedir",1);return p?myargv[p+1]:"./";}
void m0_apply_config(void){
    int p=M_CheckParmWithArgs("-m0-input",1);mode=p?atoi(myargv[p+1]):0;
    p=M_CheckParmWithArgs("-m0-tics",1);if(p)limit=atoi(myargv[p+1]);
    p=M_CheckParmWithArgs("-m0-jump",1);if(p)jump=atoi(myargv[p+1]);
    p=M_CheckParmWithArgs("-m0-trace",1);if(!p)exit(2);
    trajectory=fopen(myargv[p+1],"w");if(!trajectory)exit(3);
    p=M_CheckParmWithArgs("-m0-commands",1);if(p){commands=fopen(myargv[p+1],"r");if(!commands)exit(4);}
    crispy->hires=0;crispy->widescreen=0;crispy->uncapped=0;crispy->vsync=0;
    crispy->jump=jump;crispy->freeaim=0;crispy->freelook=0;crispy->overunder=0;
    fullscreen=0;force_software_renderer=1;usemouse=0;singletics=1;
    M_SetVariable("use_joystick","0");
    snd_musicdevice=3;snd_sfxdevice=3;snd_samplerate=44100;snd_pitchshift=0;
    M_SetVariable("use_libsamplerate","0");
    SDL_SetHint(SDL_HINT_VIDEODRIVER,"dummy");SDL_SetHint(SDL_HINT_RENDER_DRIVER,"software");
}
void m0_reference_command(ticcmd_t *cmd,int tic){
    memset(cmd,0,sizeof(*cmd));
    if(commands){
        int f,s,t,b,a;
        if(fscanf(commands,"%d %d %d %d %d",&f,&s,&t,&b,&a)!=5)exit(5);
        cmd->forwardmove=f;cmd->sidemove=s;cmd->angleturn=t;cmd->buttons=b;cmd->arti=a;
        return;
    }
    if(mode==1){
        if(tic<140)cmd->forwardmove=50;
        else if(tic<210)cmd->sidemove=40;
        else if(tic<280){cmd->forwardmove=25;cmd->angleturn=640;}
        else cmd->forwardmove=-25;
    }
    if(mode==2){cmd->forwardmove=25;if(tic==5)cmd->arti=128;}
}
void m0_reference_observe(void){
    m1_audio_update();
    wipegamestate=gamestate;D_Display();
    fputs(m0_snapshot(),trajectory);fputc('\n',trajectory);
    /* This independent consumer drains its observation stream every tic. */
    m1_observer_reset_events();
    if(gametic>=limit){fclose(trajectory);trajectory=NULL;exit(0);}
}
void m0_reference_initial(void){
    int p=M_CheckParmWithArgs("-m0-trace",1);
    char name[4096];FILE *f;
    if(m1_audio_start()<0){fprintf(stderr,"M1_REFERENCE_AUDIO_DEVICE_OPEN_FAILED\n");exit(7);}
    wipegamestate=gamestate;D_Display();
    snprintf(name,sizeof(name),"%s.initial.json",myargv[p+1]);
    f=fopen(name,"w");if(!f)exit(6);fputs(m0_snapshot(),f);fclose(f);
}
