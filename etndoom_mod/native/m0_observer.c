/* GPL-2.0-or-later. Read-only observation shared by the reference and embedded core. */
#include <stdio.h>
#include <stdarg.h>
#include <stdint.h>
#include <string.h>
#include "doomstat.h"
#include "p_local.h"
#include "r_state.h"
#include "r_sky.h"
#include "w_wad.h"
#include "i_swap.h"
#include "m0_core.h"
#include "m1_observer.h"
extern int rndindex,prndindex,crndindex,numtextures,numflats,skyflatnum;
extern gameaction_t gameaction;
extern int finalestage;
extern unsigned int finalecount;
extern int M1_IntermissionStage(void);
extern int M1_TextureInfo(int,char*,int*,int*);
extern int M1_TexturePatch(int,int,int*,int*);
extern void T_FireFlicker(fireflicker_t*);
#define SNAP_CAP (16u*1024u*1024u)
#define MAP_CAP (32u*1024u*1024u)
#define RESOURCE_CAP (16u*1024u*1024u)
#define EVENT_CAP 8192
#define ID_CAP 131072
static char snapshot_buffer[SNAP_CAP],map_buffer[MAP_CAP],resource_buffer[RESOURCE_CAP],event_buffer[4u*1024u*1024u];
typedef struct {const void *ptr;uint64_t id;} identity_t;
typedef struct {uint64_t seq,world,id,instance;int tic,type,kind,x,y,z,channel;} event_t;
static identity_t identities[ID_CAP];
static event_t events[EVENT_CAP];
static uint64_t world_epoch,next_entity,next_event,acked_event;
static int world_depth,world_ready,event_head,event_count,observer_failed;
static const char *observer_error="";
static int append(char *buf,size_t cap,size_t *len,const char *fmt,...){
    va_list a;int n;if(*len>=cap)return 0;
    va_start(a,fmt);n=vsnprintf(buf+*len,cap-*len,fmt,a);va_end(a);
    if(n<0||(size_t)n>=cap-*len){*len=cap;return 0;}*len+=(size_t)n;return 1;
}
static void quoted(char *buf,size_t cap,size_t *n,const char *s,size_t max){
    size_t i;append(buf,cap,n,"\"");
    for(i=0;i<max && s[i];i++) {unsigned char c=(unsigned char)s[i];if(c=='"'||c=='\\')append(buf,cap,n,"\\%c",c);else if(c<32||c>=127)append(buf,cap,n,"\\u%04x",c);else append(buf,cap,n,"%c",c);}
    append(buf,cap,n,"\"");
}
static int active(void){
#ifdef ETN_M0_CORE
    extern int m0_is_active(void);return m0_is_active();
#else
    return 1;
#endif
}
static size_t identity_slot(const void *p){return (((uintptr_t)p>>4)*UINT64_C(11400714819323198485))&(ID_CAP-1);}
uint64_t m1_entity_id(const void *p){size_t i,k;if(!p)return 0;i=identity_slot(p);for(k=0;k<ID_CAP;k++,i=(i+1)&(ID_CAP-1)){if(!identities[i].ptr)return 0;if(identities[i].ptr==p)return identities[i].id;}return 0;}
int m1_observer_ok(void){return !observer_failed;}
const char *m1_observer_error(void){return observer_error;}
static void fail(const char *code){observer_failed=1;observer_error=code;}
static void record_event(int type,const mobj_t *mo,uint64_t id){
    event_t *e;
    if(world_depth)return;
    if(event_count==EVENT_CAP){fail("EVENT_CAPACITY");return;}
    e=&events[(event_head+event_count++)%EVENT_CAP];
    e->seq=++next_event;e->world=world_epoch;e->tic=gametic;e->type=type;e->id=id;
    e->instance=0;e->channel=-1;e->kind=mo?mo->type:0;e->x=mo?mo->x:0;e->y=mo?mo->y:0;e->z=mo?mo->z:0;
}
void m1_observer_spawn(void *object){
    size_t i=identity_slot(object),k,tomb=ID_CAP;
    if(!object)return;
    for(k=0;k<ID_CAP;k++,i=(i+1)&(ID_CAP-1)){
        if(identities[i].ptr==object)return;
        if(identities[i].ptr==(void*)1 && tomb==ID_CAP)tomb=i;
        if(!identities[i].ptr){if(tomb!=ID_CAP)i=tomb;identities[i].ptr=object;identities[i].id=++next_entity;record_event(1,object,next_entity);return;}
    }
    if(tomb!=ID_CAP){identities[tomb].ptr=object;identities[tomb].id=++next_entity;record_event(1,object,next_entity);return;}
    fail("ENTITY_ID_CAPACITY");
}
void m1_observer_remove(void *object){
    size_t i=identity_slot(object),k;
    for(k=0;k<ID_CAP;k++,i=(i+1)&(ID_CAP-1)){if(!identities[i].ptr)return;if(identities[i].ptr==object){record_event(2,object,identities[i].id);identities[i].ptr=(void*)1;identities[i].id=0;return;}}
}
void m1_observer_teleport(void *object){record_event(3,object,m1_entity_id(object));}
void m1_observer_audio(int type,int channel,uint64_t instance,int resource,uint64_t origin,int a,int b,int c){
    event_t *e;
    if(world_depth || type<1 || type>5)return;
    if(event_count==EVENT_CAP){fail("EVENT_CAPACITY");return;}
    e=&events[(event_head+event_count++)%EVENT_CAP];
    e->seq=++next_event;e->world=world_epoch;e->tic=gametic;e->type=type+3;e->id=origin;
    e->instance=instance;e->channel=channel;e->kind=resource;e->x=a;e->y=b;e->z=c;
}
uint64_t m1_world_epoch(void){return world_epoch;}
void m1_observer_reset_events(void){event_head=event_count=0;acked_event=next_event;}
void m1_observer_world_begin(void){if(world_depth++==0){world_ready=0;memset(identities,0,sizeof(identities));next_entity=0;m1_observer_reset_events();}}
void m1_observer_world_commit(void){if(world_depth<=0){fail("WORLD_COMMIT_WITHOUT_BEGIN");return;}if(--world_depth==0){world_epoch++;world_ready=1;record_event(0,NULL,0);}}
const char *m1_events(void){
    size_t n=0;int i;static const char *types[]={"world_rebuilt","entity_spawn","entity_remove","entity_teleport","sound_start","sound_stop","music","audio_pause","audio_resume"};
    append(event_buffer,sizeof(event_buffer),&n,"{\"schema\":2,\"capacity\":%d,\"failed\":%s,\"acknowledged\":\"%llu\",\"last_sequence\":\"%llu\",\"events\":[",EVENT_CAP,observer_failed?"true":"false",(unsigned long long)acked_event,(unsigned long long)next_event);
    for(i=0;i<event_count;i++){event_t *e=&events[(event_head+i)%EVENT_CAP];append(event_buffer,sizeof(event_buffer),&n,"%s{\"sequence\":\"%llu\",\"world_epoch\":\"%llu\",\"tic\":%d,\"type\":\"%s\",\"entity_id\":\"%llu\",\"entity_type\":%d,\"position\":[%d,%d,%d],\"channel\":%d,\"voice_generation\":\"%llu\",\"resource\":%d,\"parameters\":[%d,%d,%d]}",i?",":"",(unsigned long long)e->seq,(unsigned long long)e->world,e->tic,types[e->type],(unsigned long long)e->id,e->kind,e->x,e->y,e->z,e->channel,(unsigned long long)e->instance,e->kind,e->x,e->y,e->z);}
    append(event_buffer,sizeof(event_buffer),&n,"]}");return n>=sizeof(event_buffer)?"{\"error\":\"EVENT_SERIALIZATION_CAPACITY\"}":event_buffer;
}
int m1_ack_events(uint64_t seq){if(seq<acked_event||seq>next_event)return -1;while(event_count && events[event_head].seq<=seq){event_head=(event_head+1)%EVENT_CAP;event_count--;}acked_event=seq;return 0;}
static void ints(char *buf,size_t cap,size_t *n,const int *values,int count){int i;append(buf,cap,n,"[");for(i=0;i<count;i++)append(buf,cap,n,"%s%d",i?",":"",values[i]);append(buf,cap,n,"]");}
static void specials(char *buf,size_t cap,size_t *n){
    thinker_t *th;int first=1,order=0,i;
    append(buf,cap,n,"[");
    for(th=thinkercap.next;th!=&thinkercap;th=th->next,order++){
        const char *kind=NULL;int v[16],c=0;unsigned int invalid=0;
        if(th->function.acp1==(actionf_p1)T_VerticalDoor){vldoor_t *d=(void*)th;kind="door";int a[]={d->sector-sectors,d->type,(d->direction==1||d->direction==2)?d->topheight:0,d->speed,d->direction,(d->direction==1||d->direction==2)?d->topwait:0,(d->direction==0||d->direction==2)?d->topcountdown:0};if(d->direction!=1&&d->direction!=2)invalid|=(1u<<2)|(1u<<5);if(d->direction!=0&&d->direction!=2)invalid|=1u<<6;c=7;memcpy(v,a,sizeof(a));}
        else if(th->function.acp1==(actionf_p1)T_MoveFloor){floormove_t *d=(void*)th;kind="floor";int a[]={d->sector-sectors,d->type,d->crush,d->direction,(d->type==lowerAndChange||d->type==donutRaise)?d->newspecial:0,(d->type==lowerAndChange||d->type==donutRaise)?d->texture:0,d->floordestheight,d->speed};if(d->type!=lowerAndChange&&d->type!=donutRaise)invalid|=(1u<<4)|(1u<<5);c=8;memcpy(v,a,sizeof(a));}
        else if(th->function.acp1==(actionf_p1)T_MoveCeiling){ceiling_t *d=(void*)th;kind="ceiling";int a[]={d->sector-sectors,d->type,d->type!=raiseToHighest?d->bottomheight:0,(d->type!=lowerToFloor&&d->type!=lowerAndCrush)?d->topheight:0,d->speed,d->crush,d->direction,d->tag,d->direction==0?d->olddirection:0};if(d->type==raiseToHighest)invalid|=1u<<2;if(d->type==lowerToFloor||d->type==lowerAndCrush)invalid|=1u<<3;if(d->direction!=0)invalid|=1u<<8;c=9;memcpy(v,a,sizeof(a));}
        else if(th->function.acp1==(actionf_p1)T_PlatRaise){plat_t *d=(void*)th;kind="plat";int a[]={d->sector-sectors,d->speed,(d->type!=raiseAndChange&&d->type!=raiseToNearestAndChange)?d->low:0,d->high,d->wait,(d->status==waiting||(d->status==in_stasis&&d->oldstatus==waiting))?d->count:0,d->status,d->status==in_stasis?d->oldstatus:0,d->crush,d->tag,d->type};if(d->type==raiseAndChange||d->type==raiseToNearestAndChange)invalid|=1u<<2;if(d->status!=waiting&&!(d->status==in_stasis&&d->oldstatus==waiting))invalid|=1u<<5;if(d->status!=in_stasis)invalid|=1u<<7;c=11;memcpy(v,a,sizeof(a));}
        else if(th->function.acp1==(actionf_p1)T_FireFlicker){fireflicker_t *d=(void*)th;kind="fireflicker";int a[]={d->sector-sectors,d->count,d->maxlight,d->minlight};c=4;memcpy(v,a,sizeof(a));}
        else if(th->function.acp1==(actionf_p1)T_LightFlash){lightflash_t *d=(void*)th;kind="lightflash";int a[]={d->sector-sectors,d->count,d->maxlight,d->minlight,d->maxtime,d->mintime};c=6;memcpy(v,a,sizeof(a));}
        else if(th->function.acp1==(actionf_p1)T_StrobeFlash){strobe_t *d=(void*)th;kind="strobe";int a[]={d->sector-sectors,d->count,d->minlight,d->maxlight,d->darktime,d->brighttime};c=6;memcpy(v,a,sizeof(a));}
        else if(th->function.acp1==(actionf_p1)T_Glow){glow_t *d=(void*)th;kind="glow";int a[]={d->sector-sectors,d->minlight,d->maxlight,d->direction};c=4;memcpy(v,a,sizeof(a));}
        else if(th->function.acp1!=(actionf_p1)P_MobjThinker){kind=th->function.acv==(actionf_v)-1?"pending_remove":"inactive_or_other";}
        if(kind){append(buf,cap,n,"%s{\"order\":%d,\"kind\":\"%s\",\"valid_mask\":%u,\"values\":",first?"":",",order,kind,((1u<<c)-1)&~invalid);ints(buf,cap,n,v,c);append(buf,cap,n,"}");first=0;}
    }
    for(i=0;i<MAXPLATS;i++)if(activeplats[i]&&!activeplats[i]->thinker.function.acp1){plat_t *d=activeplats[i];append(buf,cap,n,"%s{\"kind\":\"plat_stasis\",\"valid_mask\":%u,\"values\":[%td,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d]}",first?"":",",2047u&~((d->type==raiseAndChange||d->type==raiseToNearestAndChange)?4u:0u)&~(d->oldstatus!=waiting?32u:0u),d->sector-sectors,d->speed,(d->type!=raiseAndChange&&d->type!=raiseToNearestAndChange)?d->low:0,d->high,d->wait,d->oldstatus==waiting?d->count:0,d->status,d->oldstatus,d->crush,d->tag,d->type);first=0;}
    for(i=0;i<MAXCEILINGS;i++)if(activeceilings[i]&&!activeceilings[i]->thinker.function.acp1){ceiling_t *d=activeceilings[i];append(buf,cap,n,"%s{\"kind\":\"ceiling_stasis\",\"valid_mask\":%u,\"values\":[%td,%d,%d,%d,%d,%d,%d,%d,%d]}",first?"":",",511u&~(d->type==raiseToHighest?4u:0u)&~((d->type==lowerToFloor||d->type==lowerAndCrush)?8u:0u),d->sector-sectors,d->type,d->type!=raiseToHighest?d->bottomheight:0,(d->type!=lowerToFloor&&d->type!=lowerAndCrush)?d->topheight:0,d->speed,d->crush,d->direction,d->tag,d->olddirection);first=0;}
    append(buf,cap,n,"]");
}
const char *m0_snapshot(void){
    size_t n=0;int i,count=0,order=0,first=1,valid=world_ready && !world_depth && gamestate==GS_LEVEL;thinker_t *th;player_t *p=&players[consoleplayer];mobj_t *mo=valid?p->mo:NULL;
    if(!active())return "{\"error\":\"NO_ACTIVE_SESSION\"}";
    if(valid)for(th=thinkercap.next;th!=&thinkercap;th=th->next)if(th->function.acp1==(actionf_p1)P_MobjThinker)count++;
#define S(...) append(snapshot_buffer,sizeof(snapshot_buffer),&n,__VA_ARGS__)
    S("{\"schema\":2,\"world_epoch\":\"%llu\",\"world_valid\":%s,\"observer_failed\":%s,\"tic\":%d,\"leveltime\":%d,\"gamestate\":%d,\"gameaction\":%d,\"gamemode\":%d,\"gamemission\":%d,\"map\":%d,\"episode\":%d,\"skill\":%d,\"paused\":%s,\"rng\":[%d,%d,%d],\"entity_count\":%d,\"player\":{",(unsigned long long)world_epoch,valid?"true":"false",observer_failed?"true":"false",gametic,leveltime,gamestate,gameaction,gamemode,gamemission,gamemap,gameepisode,gameskill,paused?"true":"false",rndindex,prndindex,crndindex,count);
    S("\"entity_id\":\"%llu\",\"health\":%d,\"armor\":%d,\"armor_type\":%d,\"weapon\":%d,\"pending_weapon\":%d,\"state\":%d,\"backpack\":%s,\"damage_count\":%d,\"bonus_count\":%d,\"attacker_id\":\"%llu\",\"kill_count\":%d,\"item_count\":%d,\"secret_count\":%d,\"did_secret\":%s,\"attack_down\":%d,\"use_down\":%d,\"refire\":%d,\"jump_tics\":%u,\"viewheight\":%d,\"deltaviewheight\":%d,\"bob\":%d,\"weapons\":",(unsigned long long)m1_entity_id(mo),p->health,p->armorpoints,p->armortype,p->readyweapon,p->pendingweapon,p->playerstate,p->backpack?"true":"false",p->damagecount,p->bonuscount,(unsigned long long)(valid?m1_entity_id(p->attacker):0),p->killcount,p->itemcount,p->secretcount,p->didsecret?"true":"false",p->attackdown,p->usedown,p->refire,p->jumpTics,p->viewheight,p->deltaviewheight,p->bob);
    ints(snapshot_buffer,sizeof(snapshot_buffer),&n,p->weaponowned,NUMWEAPONS);S(",\"ammo\":");ints(snapshot_buffer,sizeof(snapshot_buffer),&n,p->ammo,NUMAMMO);S(",\"maxammo\":");ints(snapshot_buffer,sizeof(snapshot_buffer),&n,p->maxammo,NUMAMMO);S(",\"powers\":");ints(snapshot_buffer,sizeof(snapshot_buffer),&n,p->powers,NUMPOWERS+3);
    S(",\"cards\":[");for(i=0;i<NUMCARDS;i++)S("%s%d",i?",":"",p->cards[i]);S("],\"psprites\":[");for(i=0;i<NUMPSPRITES;i++)S("%s[%td,%d,%d,%d]",i?",":"",p->psprites[i].state?p->psprites[i].state-states:-1,p->psprites[i].tics,p->psprites[i].sx,p->psprites[i].sy);S("]");
    if(mo)S(",\"x\":%d,\"y\":%d,\"z\":%d,\"momx\":%d,\"momy\":%d,\"momz\":%d,\"angle\":%u",mo->x,mo->y,mo->z,mo->momx,mo->momy,mo->momz,mo->angle);
#ifdef ETN_M0_CORE
    extern const char *m1_control_status(void);
    S("},\"control\":%s,\"host_paused\":%s",m1_control_status(),m1_is_paused()?"true":"false");
#else
    S("},\"control\":null,\"host_paused\":false");
#endif
    S(",\"flow\":{\"intermission_stage\":%d,\"finale_stage\":%d,\"finale_count\":%u,\"episode\":%d,\"last\":%d,\"next\":%d,\"did_secret\":%s,\"max_kills\":%d,\"max_items\":%d,\"max_secrets\":%d,\"par_time\":%d,\"total_times\":%d,\"player_statistics\":[%d,%d,%d,%d]},\"entities\":[",gamestate==GS_INTERMISSION?M1_IntermissionStage():-1,gamestate==GS_FINALE?finalestage:-1,gamestate==GS_FINALE?finalecount:0,wminfo.epsd,wminfo.last,wminfo.next,wminfo.didsecret?"true":"false",wminfo.maxkills,wminfo.maxitems,wminfo.maxsecret,wminfo.partime,wminfo.totaltimes,wminfo.plyr[consoleplayer].skills,wminfo.plyr[consoleplayer].sitems,wminfo.plyr[consoleplayer].ssecret,wminfo.plyr[consoleplayer].stime);
    if(valid)for(th=thinkercap.next;th!=&thinkercap;th=th->next,order++)if(th->function.acp1==(actionf_p1)P_MobjThinker){mobj_t *m=(void*)th;
        S("%s{\"id\":\"%llu\",\"order\":%d,\"type\":%d,\"state\":%td,\"tics\":%d,\"x\":%d,\"y\":%d,\"z\":%d,\"momx\":%d,\"momy\":%d,\"momz\":%d,\"angle\":%u,\"radius\":%d,\"height\":%d,\"floorz\":%d,\"ceilingz\":%d,\"sprite\":%d,\"frame\":%d,\"flags\":%u,\"health\":%d,\"sector\":%td,\"target_id\":\"%llu\",\"tracer_id\":\"%llu\",\"movedir\":%d,\"movecount\":%d,\"reactiontime\":%d,\"threshold\":%d,\"lastlook\":%d,\"interpolate\":%s}",first?"":",",(unsigned long long)m1_entity_id(m),order,m->type,m->state?m->state-states:-1,m->tics,m->x,m->y,m->z,m->momx,m->momy,m->momz,m->angle,m->radius,m->height,m->floorz,m->ceilingz,m->sprite,m->frame,(unsigned int)m->flags,m->health,m->subsector?m->subsector->sector-sectors:-1,(unsigned long long)m1_entity_id(m->target),(unsigned long long)m1_entity_id(m->tracer),m->movedir,m->movecount,m->reactiontime,m->threshold,m->lastlook,m->interp?"true":"false");first=0;
    }
    S("],\"sectors\":[");if(valid)for(i=0;i<numsectors;i++)S("%s[%d,%d,%d,%d,%d,%d,%d,%d,%d]",i?",":"",sectors[i].floorheight,sectors[i].ceilingheight,sectors[i].lightlevel,sectors[i].floorpic,sectors[i].ceilingpic,sectors[i].special,sectors[i].tag,sectors[i].sky,sectors[i].oldspecial);
    S("],\"sector_sound_targets\":[");if(valid)for(i=0;i<numsectors;i++)S("%s\"%llu\"",i?",":"",(unsigned long long)m1_entity_id(sectors[i].soundtarget));
    S("],\"sides\":[");if(valid)for(i=0;i<numsides;i++)S("%s[%d,%d,%d,%d,%d]",i?",":"",sides[i].textureoffset,sides[i].rowoffset,sides[i].toptexture,sides[i].bottomtexture,sides[i].midtexture);
    S("],\"lines\":[");if(valid)for(i=0;i<numlines;i++)S("%s[%d,%d,%d]",i?",":"",lines[i].flags,lines[i].special,lines[i].tag);
    S("],\"specials\":");if(valid)specials(snapshot_buffer,sizeof(snapshot_buffer),&n);else S("[]");
    S(",\"buttons\":[");first=1;if(valid)for(i=0;i<maxbuttons;i++)if(buttonlist[i].btimer){button_t *b=&buttonlist[i];S("%s[%td,%d,%d,%d]",first?"":",",b->line-lines,b->where,b->btexture,b->btimer);first=0;}
    S("],\"texture_translation\":");ints(snapshot_buffer,sizeof(snapshot_buffer),&n,texturetranslation,numtextures);S(",\"flat_translation\":");ints(snapshot_buffer,sizeof(snapshot_buffer),&n,flattranslation,numflats);S("}");
#undef S
    return n>=sizeof(snapshot_buffer)?"{\"error\":\"SNAPSHOT_CAPACITY\"}":snapshot_buffer;
}
const char *m0_map(void){
    size_t n=0;int i,j,k;
    if(!active())return "{\"error\":\"NO_ACTIVE_SESSION\"}";
    if(!world_ready || world_depth || gamestate!=GS_LEVEL)return "{\"schema\":2,\"world_valid\":false}";
#define M(...) append(map_buffer,sizeof(map_buffer),&n,__VA_ARGS__)
    M("{\"schema\":2,\"world_valid\":true,\"world_epoch\":\"%llu\",\"map\":%d,\"episode\":%d,\"fixed_fraction_bits\":16,\"sky_flat\":%d,\"sky_texture\":%d,\"vertices\":[",(unsigned long long)world_epoch,gamemap,gameepisode,skyflatnum,skytexture);
    for(i=0;i<numvertexes;i++)M("%s[%d,%d]",i?",":"",vertexes[i].x,vertexes[i].y);
    M("],\"lines\":[");for(i=0;i<numlines;i++)M("%s[%td,%td,%d,%d,%d,%d,%d]",i?",":"",lines[i].v1-vertexes,lines[i].v2-vertexes,lines[i].flags,lines[i].special,lines[i].tag,lines[i].sidenum[0],lines[i].sidenum[1]);
    M("],\"sides\":[");for(i=0;i<numsides;i++)M("%s[%td,%d,%d,%d,%d,%d]",i?",":"",sides[i].sector-sectors,sides[i].textureoffset,sides[i].rowoffset,sides[i].toptexture,sides[i].bottomtexture,sides[i].midtexture);
    M("],\"sectors\":[");for(i=0;i<numsectors;i++)M("%s[%d,%d,%d,%d,%d,%d,%d,%d]",i?",":"",sectors[i].floorheight,sectors[i].ceilingheight,sectors[i].floorpic,sectors[i].ceilingpic,sectors[i].lightlevel,sectors[i].special,sectors[i].tag,sectors[i].sky);
    M("],\"segs\":[");for(i=0;i<numsegs;i++)M("%s[%td,%td,%td,%td,%td,%td,%d,%u]",i?",":"",segs[i].v1-vertexes,segs[i].v2-vertexes,segs[i].linedef?segs[i].linedef-lines:-1,segs[i].sidedef?segs[i].sidedef-sides:-1,segs[i].frontsector?segs[i].frontsector-sectors:-1,segs[i].backsector?segs[i].backsector-sectors:-1,segs[i].offset,segs[i].angle);
    M("],\"subsectors\":[");for(i=0;i<numsubsectors;i++)M("%s[%td,%d,%d]",i?",":"",subsectors[i].sector-sectors,subsectors[i].firstline,subsectors[i].numlines);
    M("],\"bsp_subsector_bit\":2147483648,\"nodes\":[");for(i=0;i<numnodes;i++){M("%s[%d,%d,%d,%d,%u,%u,[",i?",":"",nodes[i].x,nodes[i].y,nodes[i].dx,nodes[i].dy,(unsigned)nodes[i].children[0],(unsigned)nodes[i].children[1]);for(j=0;j<2;j++)for(k=0;k<4;k++)M("%s%d",j||k?",":"",nodes[i].bbox[j][k]);M("]]");}M("]}");
#undef M
    return n>=sizeof(map_buffer)?"{\"error\":\"MAP_CAPACITY\"}":map_buffer;
}
int m1_resource_read(int kind,int index,int offset,uint8_t *out,int capacity){
    lumpinfo_t *l;size_t take,got;
    if(!active()||kind!=0||index<0||(unsigned)index>=numlumps||offset<0||capacity<0||capacity>1048576)return -1;
    l=lumpinfo[index];if(offset>l->size||(!out&&capacity))return -1;
    take=(size_t)(l->size-offset);if(take>(size_t)capacity)take=capacity;if(!take)return 0;
    if(!l->wad_file || l->position<0 || (uint64_t)l->position+(uint64_t)offset+take>l->wad_file->length)return -2;
    if(l->wad_file->mapped){memcpy(out,l->wad_file->mapped+l->position+offset,take);return (int)take;}
    got=W_Read(l->wad_file,(unsigned int)l->position+(unsigned)offset,out,take);return got==take?(int)got:-2;
}
static int patch_info(int lump,int *w,int *h,int *x,int *y){uint8_t b[8];if(m1_resource_read(0,lump,0,b,8)!=8)return 0;*w=(int16_t)(b[0]|b[1]<<8);*h=(int16_t)(b[2]|b[3]<<8);*x=(int16_t)(b[4]|b[5]<<8);*y=(int16_t)(b[6]|b[7]<<8);return *w>0&&*h>0;}
const char *m1_resources(void){
    size_t n=0;int i,j,k,width,height,x,y,count,lump;char name[9];
    if(!active())return "{\"error\":\"NO_ACTIVE_SESSION\"}";
#define R(...) append(resource_buffer,sizeof(resource_buffer),&n,__VA_ARGS__)
    R("{\"schema\":2,\"read_kind\":0,\"max_read_bytes\":1048576,\"palette_lump\":%d,\"colormap_lump\":%d,\"lumps\":[",W_CheckNumForName("PLAYPAL"),W_CheckNumForName("COLORMAP"));
    for(i=0;(unsigned)i<numlumps;i++){R("%s{\"id\":%d,\"length\":%d,\"name\":",i?",":"",i,lumpinfo[i]->size);quoted(resource_buffer,sizeof(resource_buffer),&n,lumpinfo[i]->name,8);R(",\"iwad\":%s}",W_IsIWADLump(lumpinfo[i])?"true":"false");}
    R("],\"textures\":[");for(i=0;i<numtextures;i++){count=M1_TextureInfo(i,name,&width,&height);R("%s{\"id\":%d,\"name\":",i?",":"",i);quoted(resource_buffer,sizeof(resource_buffer),&n,name,8);R(",\"width\":%d,\"height\":%d,\"format\":\"doom-patch-composition\",\"translated_id\":%d,\"patches\":[",width,height,texturetranslation[i]);for(j=0;j<count;j++){lump=M1_TexturePatch(i,j,&x,&y);R("%s[%d,%d,%d]",j?",":"",x,y,lump);}R("]}");}
    R("],\"flats\":[");for(i=0;i<numflats;i++){int length=lumpinfo[firstflat+i]->size;int decodable=length>=4096;R("%s{\"id\":%d,\"lump\":%d,\"length\":%d,\"width\":%d,\"height\":%d,\"decodable\":%s,\"format\":\"%s\",\"translated_id\":%d}",i?",":"",i,firstflat+i,length,decodable?64:0,decodable?64:0,decodable?"true":"false",decodable?"palette-index8-row-major":(length==0?"namespace-marker":"unsupported-flat-bytes"),flattranslation[i]);}
    R("],\"sprites\":[");for(i=0;i<numsprites;i++){R("%s{\"id\":%d,\"frames\":[",i?",":"",i);for(j=0;j<sprites[i].numframes;j++){spriteframe_t *f=&sprites[i].spriteframes[j];R("%s{\"frame\":%d,\"rotate\":%d,\"rotations\":[",j?",":"",j,f->rotate);for(k=0;k<(f->rotate==2?16:8);k++){lump=f->lump[k]+firstspritelump;width=height=x=y=0;patch_info(lump,&width,&height,&x,&y);R("%s{\"lump\":%d,\"flip\":%d,\"width\":%d,\"height\":%d,\"left_offset\":%d,\"top_offset\":%d,\"format\":\"doom-patch-columns\"}",k?",":"",lump,f->flip[k],width,height,x,y);}R("]}");}R("]}");}
    R("],\"states\":[");for(i=0;i<NUMSTATES;i++)R("%s[%d,%d,%d,%d,%d,%d]",i?",":"",states[i].sprite,states[i].frame,states[i].tics,states[i].nextstate,states[i].misc1,states[i].misc2);R("]}");
#undef R
    return n>=sizeof(resource_buffer)?"{\"error\":\"RESOURCE_CAPACITY\"}":resource_buffer;
}
