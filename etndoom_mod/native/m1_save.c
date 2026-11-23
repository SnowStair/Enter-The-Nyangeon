/* GPL-2.0-or-later. Upstream archive + ABI-locked, pointer-free supplement.
 * The supplement preserves fixed precision, thinker and block-link order.
 * A slot is one checksummed container, replaced atomically only after close.
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <bcrypt.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "doomstat.h"
#include "d_loop.h"
#include "p_local.h"
#include "p_saveg.h"
#include "p_extsaveg.h"
#include "g_game.h"
#include "m_misc.h"
#include "r_state.h"
#include "s_musinfo.h"
#include "w_wad.h"
#include "m0_core.h"
#include "m0_memory.h"
#include "m1_save.h"
extern int rndindex,prndindex,crndindex,demostarttic,oldleveltime;
extern int numtextures;
extern int m1_brain_easy;
extern gameaction_t gameaction;
extern void G_DoLoadGame(void),T_FireFlicker(fireflicker_t *);
extern void m1_observer_world_begin(void),m1_observer_world_commit(void);
#define SAVE_MAX (64u*1024u*1024u)
#define THINK_MAX 100000
typedef struct {
    char magic[8];uint32_t schema,header_size,payload_size,supplement_size;
    uint8_t resource[64],core[32],digest[32];
    int32_t jump,skill,episode,map;
} envelope_t;
typedef struct {
    int32_t sectors,sides,lines,blocks,thinkers,mobjs,subsectors,buttons;
    int32_t gametic,leveltime,totalleveltimes,rng[3],demostarttic,oldleveltime;
    int32_t validcount,brain_easy;
    player_t player;
    musinfo_t music;
    wbstartstruct_t intermission;
    int32_t fast_tics[S_SARG_PAIN2-S_SARG_RUN1+1];
    int32_t projectile_speed[3];
} supplement_t;
typedef struct {uint32_t kind,ordinal;} order_t;
static uint8_t resource_identity[64],core_identity[32];
static int rules_jump;
static int sha(const void *data,size_t size,uint8_t out[32]){
    BCRYPT_ALG_HANDLE alg=NULL;BCRYPT_HASH_HANDLE hash=NULL;int ok=0;
    if(BCryptOpenAlgorithmProvider(&alg,BCRYPT_SHA256_ALGORITHM,NULL,0)<0)return 0;
    if(BCryptCreateHash(alg,&hash,NULL,0,NULL,0,0)>=0 &&
       BCryptHashData(hash,(PUCHAR)data,(ULONG)size,0)>=0 &&
       BCryptFinishHash(hash,out,32,0)>=0)ok=1;
    if(hash)BCryptDestroyHash(hash);BCryptCloseAlgorithmProvider(alg,0);return ok;
}
static uint8_t *read_file(const char *path,size_t *size){
    FILE *f=M_fopen(path,"rb");long n;uint8_t *p;
    if(!f)return NULL;if(fseek(f,0,SEEK_END)||((n=ftell(f))<0)||n>SAVE_MAX){fclose(f);return NULL;}
    rewind(f);p=malloc(n?n:1);if(!p){fclose(f);return NULL;}
    if(fread(p,1,n,f)!=(size_t)n){free(p);fclose(f);return NULL;}fclose(f);*size=n;return p;
}
static int file_sha(const char *path,uint8_t out[32]){size_t n;uint8_t *p=read_file(path,&n);int ok;if(!p)return 0;ok=sha(p,n,out);free(p);return ok;}
int m1_save_identity(const char *iwad,const char *pwad,int jump){
    HMODULE module;wchar_t wide[4096];char path[16384];rules_jump=jump;
    memset(resource_identity,0,sizeof(resource_identity));
    if(!file_sha(iwad,resource_identity)||(pwad&&*pwad&&!file_sha(pwad,resource_identity+32)))return -1;
    if(!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS|GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,(LPCWSTR)&m1_save_identity,&module))return -1;
    if(!GetModuleFileNameW(module,wide,4096)||!WideCharToMultiByte(CP_UTF8,0,wide,-1,path,sizeof(path),NULL,NULL))return -1;
    return file_sha(path,core_identity)?0:-1;
}
static int kind(thinker_t *th){int i;
    if(th->function.acp1==(actionf_p1)P_MobjThinker)return 1;
    if(th->function.acp1==(actionf_p1)T_MoveFloor)return 2;
    if(th->function.acp1==(actionf_p1)T_VerticalDoor)return 3;
    if(th->function.acp1==(actionf_p1)T_MoveCeiling)return 4;
    if(th->function.acp1==(actionf_p1)T_PlatRaise)return 5;
    if(th->function.acp1==(actionf_p1)T_LightFlash)return 6;
    if(th->function.acp1==(actionf_p1)T_StrobeFlash)return 7;
    if(th->function.acp1==(actionf_p1)T_Glow)return 8;
    if(th->function.acp1==(actionf_p1)T_FireFlicker)return 9;
    if(th->function.acv==(actionf_v)-1)return 0;
    if(!th->function.acv){for(i=0;i<MAXCEILINGS;i++)if((thinker_t*)activeceilings[i]==th)return 4;for(i=0;i<MAXPLATS;i++)if((thinker_t*)activeplats[i]==th)return 5;}
    return -1;
}
static int index_of(thinker_t **list,int n,const void *ptr){int i;if(!ptr)return 0;for(i=0;i<n;i++)if(list[i]==ptr)return i+1;return 0;}
static void *pointer_at(thinker_t **list,int n,intptr_t index){if(index<0||index>n)m0_fail("SAVE_REFERENCE_INVALID");return index?list[index-1]:NULL;}
static size_t supplement_bytes(const supplement_t *s){
    if(s->sectors<0||s->sides<0||s->lines<0||s->blocks<0||s->thinkers<0||s->mobjs<0||s->thinkers>THINK_MAX||s->mobjs>s->thinkers||s->buttons<MAXBUTTONS||s->buttons>THINK_MAX||(s->buttons&(s->buttons-1)))return 0;
    return sizeof(*s)+(size_t)s->thinkers*sizeof(order_t)+(size_t)s->mobjs*sizeof(mobj_t)+(size_t)s->sectors*sizeof(sector_t)+(size_t)s->sides*sizeof(side_t)+(size_t)s->lines*4*sizeof(int32_t)+(size_t)s->blocks*sizeof(int32_t)+(MAXPLATS+MAXCEILINGS)*sizeof(int32_t)+(size_t)s->buttons*sizeof(button_t)+(size_t)(numtextures+numflats)*sizeof(int32_t);
}
static uint8_t *capture(size_t *length,char *error,unsigned cap){
    thinker_t *th,**all;int n=0,nm=0,i,j,k,counts[10]={0};supplement_t s;uint8_t *buffer,*p;
    memset(&s,0,sizeof(s));
    for(th=thinkercap.next;th!=&thinkercap;th=th->next){k=kind(th);if(k<0){snprintf(error,cap,"SAVE_UNSUPPORTED_THINKER");return NULL;}if(k){n++;if(k==1)nm++;}}
    if(n>THINK_MAX){snprintf(error,cap,"SAVE_CAPACITY");return NULL;}
    all=malloc((n+1)*sizeof(*all));if(!all){snprintf(error,cap,"SAVE_ALLOC_FAILED");return NULL;}for(th=thinkercap.next,i=0;th!=&thinkercap;th=th->next)if(kind(th))all[i++]=th;
    s.sectors=numsectors;s.sides=numsides;s.lines=numlines;s.blocks=bmapwidth*bmapheight;s.thinkers=n;s.mobjs=nm;s.subsectors=numsubsectors;s.buttons=maxbuttons;s.brain_easy=m1_brain_easy;
    s.gametic=gametic;s.leveltime=leveltime;s.totalleveltimes=totalleveltimes;s.rng[0]=rndindex;s.rng[1]=prndindex;s.rng[2]=crndindex;s.demostarttic=demostarttic;s.oldleveltime=oldleveltime;s.validcount=validcount;
    s.player=players[consoleplayer];s.player.mo=(void*)(intptr_t)index_of(all,n,s.player.mo);s.player.attacker=(void*)(intptr_t)index_of(all,n,s.player.attacker);
    s.player.message=NULL;s.player.centermessage=NULL;s.player.so=NULL;
    for(i=0;i<NUMPSPRITES;i++)s.player.psprites[i].state=(void*)(intptr_t)(s.player.psprites[i].state?s.player.psprites[i].state-states+1:0);
    s.music=musinfo;s.music.mapthing=(void*)(intptr_t)index_of(all,n,musinfo.mapthing);s.music.lastmapthing=(void*)(intptr_t)index_of(all,n,musinfo.lastmapthing);
    s.intermission=wminfo;
    for(i=S_SARG_RUN1;i<=S_SARG_PAIN2;i++)s.fast_tics[i-S_SARG_RUN1]=states[i].tics;
    s.projectile_speed[0]=mobjinfo[MT_BRUISERSHOT].speed;s.projectile_speed[1]=mobjinfo[MT_HEADSHOT].speed;s.projectile_speed[2]=mobjinfo[MT_TROOPSHOT].speed;
    *length=supplement_bytes(&s);if(!*length||*length>SAVE_MAX){free(all);snprintf(error,cap,"SAVE_CAPACITY");return NULL;}
    buffer=malloc(*length);if(!buffer){free(all);snprintf(error,cap,"SAVE_ALLOC_FAILED");return NULL;}p=buffer;memcpy(p,&s,sizeof(s));p+=sizeof(s);
    for(i=0;i<n;i++){order_t o;k=kind(all[i]);o.kind=k;o.ordinal=counts[k]++;memcpy(p,&o,sizeof(o));p+=sizeof(o);}
    for(i=0;i<n;i++)if(kind(all[i])==1){mobj_t m=*(mobj_t*)all[i];
        memset(&m.thinker,0,sizeof(m.thinker));
        m.snext=(void*)(intptr_t)index_of(all,n,m.snext);m.sprev=(void*)(intptr_t)index_of(all,n,m.sprev);m.bnext=(void*)(intptr_t)index_of(all,n,m.bnext);m.bprev=(void*)(intptr_t)index_of(all,n,m.bprev);
        m.target=(void*)(intptr_t)index_of(all,n,m.target);m.tracer=(void*)(intptr_t)index_of(all,n,m.tracer);
        m.subsector=(void*)(intptr_t)(m.subsector-subsectors);m.info=NULL;m.state=(void*)(intptr_t)(m.state-states);m.player=(void*)(intptr_t)(m.player?m.player-players+1:0);
        memcpy(p,&m,sizeof(m));p+=sizeof(m);
    }
    for(i=0;i<numsectors;i++){sector_t sec=sectors[i];sec.soundtarget=(void*)(intptr_t)index_of(all,n,sec.soundtarget);sec.thinglist=(void*)(intptr_t)index_of(all,n,sec.thinglist);sec.specialdata=(void*)(intptr_t)index_of(all,n,sec.specialdata);sec.lines=NULL;memset(&sec.soundorg.thinker,0,sizeof(thinker_t));memcpy(p,&sec,sizeof(sec));p+=sizeof(sec);}
    for(i=0;i<numsides;i++){side_t si=sides[i];si.sector=(void*)(intptr_t)(si.sector-sectors);memcpy(p,&si,sizeof(si));p+=sizeof(si);}
    for(i=0;i<numlines;i++){int32_t row[4]={lines[i].flags,lines[i].special,lines[i].tag,lines[i].validcount};memcpy(p,row,sizeof(row));p+=sizeof(row);}
    for(i=0;i<s.blocks;i++){int32_t ix=index_of(all,n,blocklinks[i]);memcpy(p,&ix,4);p+=4;}
    for(i=0;i<MAXPLATS;i++){int32_t ix=index_of(all,n,activeplats[i]);memcpy(p,&ix,4);p+=4;}
    for(i=0;i<MAXCEILINGS;i++){int32_t ix=index_of(all,n,activeceilings[i]);memcpy(p,&ix,4);p+=4;}
    for(i=0;i<maxbuttons;i++){button_t b=buttonlist[i];b.soundorg=(void*)(intptr_t)(b.line?(b.soundorg==&b.line->soundorg?1:2):0);b.line=(void*)(intptr_t)(b.line?b.line-lines+1:0);memcpy(p,&b,sizeof(b));p+=sizeof(b);}
    for(j=0;j<2;j++){int count=j?numflats:numtextures;int *values=j?flattranslation:texturetranslation;memcpy(p,values,count*4);p+=count*4;}
    free(all);return buffer;
}
static void restore(uint8_t *buffer,size_t length){
    supplement_t s;uint8_t *p=buffer;thinker_t *th,**loaded,**ordered;order_t *order;int i,j,n=0,counts[10]={0};
    memcpy(&s,p,sizeof(s));p+=sizeof(s);
    if(supplement_bytes(&s)!=length||s.sectors!=numsectors||s.sides!=numsides||s.lines!=numlines||s.subsectors!=numsubsectors||s.blocks!=bmapwidth*bmapheight)m0_fail("SAVE_WORLD_SHAPE_MISMATCH");
    loaded=malloc((s.thinkers+1)*sizeof(*loaded));ordered=malloc((s.thinkers+1)*sizeof(*ordered));
    if(!loaded||!ordered)m0_fail("SAVE_ALLOC_FAILED");
    for(th=thinkercap.next;th!=&thinkercap;th=th->next){if(n>=s.thinkers)m0_fail("SAVE_THINKER_COUNT_MISMATCH");loaded[n++]=th;}
    if(n!=s.thinkers)m0_fail("SAVE_THINKER_COUNT_MISMATCH");
    order=(order_t*)p;p+=n*sizeof(order_t);
    for(i=0;i<n;i++){unsigned ordinal=0;ordered[i]=NULL;for(j=0;j<n;j++)if(kind(loaded[j])==(int)order[i].kind){if(ordinal++==order[i].ordinal){ordered[i]=loaded[j];break;}}if(!ordered[i])m0_fail("SAVE_THINKER_ORDER_INVALID");}
    for(i=0;i<n;i++){th=ordered[i];th->prev=i?ordered[i-1]:&thinkercap;th->next=i+1<n?ordered[i+1]:&thinkercap;}
    thinkercap.next=n?ordered[0]:&thinkercap;thinkercap.prev=n?ordered[n-1]:&thinkercap;
    for(i=0;i<n;i++)if(order[i].kind==1){mobj_t m;thinker_t links=*ordered[i];memcpy(&m,p,sizeof(m));p+=sizeof(m);
        m.thinker=links;m.snext=pointer_at(ordered,n,(intptr_t)m.snext);m.sprev=pointer_at(ordered,n,(intptr_t)m.sprev);m.bnext=pointer_at(ordered,n,(intptr_t)m.bnext);m.bprev=pointer_at(ordered,n,(intptr_t)m.bprev);
        m.target=pointer_at(ordered,n,(intptr_t)m.target);m.tracer=pointer_at(ordered,n,(intptr_t)m.tracer);m.subsector=&subsectors[(intptr_t)m.subsector];m.info=&mobjinfo[m.type];m.state=&states[(intptr_t)m.state];m.player=(intptr_t)m.player?&players[(intptr_t)m.player-1]:NULL;
        *(mobj_t*)ordered[i]=m;
    }
    for(i=0;i<numsectors;i++){sector_t sec;line_t **line_array=sectors[i].lines;memcpy(&sec,p,sizeof(sec));p+=sizeof(sec);sec.lines=line_array;sec.soundtarget=pointer_at(ordered,n,(intptr_t)sec.soundtarget);sec.thinglist=pointer_at(ordered,n,(intptr_t)sec.thinglist);sec.specialdata=pointer_at(ordered,n,(intptr_t)sec.specialdata);sectors[i]=sec;}
    for(i=0;i<numsides;i++){side_t si;memcpy(&si,p,sizeof(si));p+=sizeof(si);si.sector=&sectors[(intptr_t)si.sector];sides[i]=si;}
    for(i=0;i<numlines;i++){int32_t row[4];memcpy(row,p,sizeof(row));p+=sizeof(row);lines[i].flags=row[0];lines[i].special=row[1];lines[i].tag=row[2];lines[i].validcount=row[3];}
    for(i=0;i<s.blocks;i++){int32_t ix;memcpy(&ix,p,4);p+=4;blocklinks[i]=pointer_at(ordered,n,ix);}
    for(i=0;i<MAXPLATS;i++){int32_t ix;memcpy(&ix,p,4);p+=4;activeplats[i]=pointer_at(ordered,n,ix);}
    for(i=0;i<MAXCEILINGS;i++){int32_t ix;memcpy(&ix,p,4);p+=4;activeceilings[i]=pointer_at(ordered,n,ix);}
    buttonlist=realloc(buttonlist,(s.buttons?s.buttons:1)*sizeof(*buttonlist));if(!buttonlist)m0_fail("SAVE_BUTTON_ALLOC_FAILED");maxbuttons=s.buttons;
    for(i=0;i<maxbuttons;i++){button_t b;intptr_t source;memcpy(&b,p,sizeof(b));p+=sizeof(b);source=(intptr_t)b.soundorg;b.line=(intptr_t)b.line?&lines[(intptr_t)b.line-1]:NULL;b.soundorg=source==1?&b.line->soundorg:source==2?&b.line->frontsector->soundorg:NULL;buttonlist[i]=b;}
    for(j=0;j<2;j++){int count=j?numflats:numtextures;int *values=j?flattranslation:texturetranslation;memcpy(values,p,count*4);p+=count*4;}
    s.player.mo=pointer_at(ordered,n,(intptr_t)s.player.mo);s.player.attacker=pointer_at(ordered,n,(intptr_t)s.player.attacker);s.player.so=players[consoleplayer].so;
    for(i=0;i<NUMPSPRITES;i++)s.player.psprites[i].state=(intptr_t)s.player.psprites[i].state?&states[(intptr_t)s.player.psprites[i].state-1]:NULL;
    players[consoleplayer]=s.player;
    s.music.mapthing=pointer_at(ordered,n,(intptr_t)s.music.mapthing);s.music.lastmapthing=pointer_at(ordered,n,(intptr_t)s.music.lastmapthing);musinfo=s.music;
    wminfo=s.intermission;
    for(i=S_SARG_RUN1;i<=S_SARG_PAIN2;i++)states[i].tics=s.fast_tics[i-S_SARG_RUN1];
    mobjinfo[MT_BRUISERSHOT].speed=s.projectile_speed[0];mobjinfo[MT_HEADSHOT].speed=s.projectile_speed[1];mobjinfo[MT_TROOPSHOT].speed=s.projectile_speed[2];
    gametic=s.gametic;leveltime=s.leveltime;totalleveltimes=s.totalleveltimes;rndindex=s.rng[0];prndindex=s.rng[1];crndindex=s.rng[2];demostarttic=s.demostarttic;oldleveltime=s.oldleveltime;validcount=s.validcount;m1_brain_easy=s.brain_easy;
    free(loaded);free(ordered);
}
static int paths(int slot,char *path,char *temporary,char *raw){
    if(slot<0||slot>7)return 0;
    snprintf(path,4096,"%sm1-slot-%d.etns",m0_config_dir(),slot);
    snprintf(temporary,4096,"%sm1-slot-%d.tmp",m0_config_dir(),slot);
    snprintf(raw,4096,"%sm1-transaction.dsg",m0_config_dir());return 1;
}
static int atomic_replace(const char *source,const char *dest){wchar_t a[4096],b[4096];return MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,source,-1,a,4096)&&MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,dest,-1,b,4096)&&MoveFileExW(a,b,MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH);}
static int ref_valid(intptr_t ix,const order_t *order,int n,int expected){return ix>=0&&ix<=n&&(!ix||!expected||order[ix-1].kind==(unsigned)expected);}
/* Validate every supplemental pointer index before entering the destructive load.
 * Content hashes detect damaged native payloads before upstream deserialization.
 */
static int preflight(uint8_t *buffer,size_t size){
    supplement_t s;uint8_t *p=buffer;order_t *order;int counts[10]={0},i,j;
    if(size<sizeof(s))return 0;memcpy(&s,p,sizeof(s));p+=sizeof(s);
    if(supplement_bytes(&s)!=size||s.subsectors<1||s.subsectors>1000000||s.gametic<0||s.leveltime<0)return 0;
    for(i=0;i<3;i++)if(s.rng[i]<0||s.rng[i]>255)return 0;
    order=(order_t*)p;p+=s.thinkers*sizeof(order_t);
    for(i=0;i<s.thinkers;i++){unsigned k=order[i].kind;if(k<1||k>9||order[i].ordinal!=(unsigned)counts[k]++)return 0;}
    if(counts[1]!=s.mobjs)return 0;
#define REF(value,expected) if(!ref_valid((intptr_t)(value),order,s.thinkers,expected))return 0
    REF(s.player.mo,1);REF(s.player.attacker,1);REF(s.music.mapthing,1);REF(s.music.lastmapthing,1);
    if(!s.player.mo||s.player.message||s.player.centermessage||s.player.so)return 0;
    for(i=0;i<NUMPSPRITES;i++)if((intptr_t)s.player.psprites[i].state<0||(intptr_t)s.player.psprites[i].state>NUMSTATES)return 0;
    for(i=0;i<s.mobjs;i++){mobj_t m;memcpy(&m,p,sizeof(m));p+=sizeof(m);REF(m.target,1);REF(m.tracer,1);REF(m.snext,1);REF(m.sprev,1);REF(m.bnext,1);REF(m.bprev,1);
        if((intptr_t)m.subsector<0||(intptr_t)m.subsector>=s.subsectors||(intptr_t)m.state<0||(intptr_t)m.state>=NUMSTATES||m.type<0||m.type>=NUMMOBJTYPES||(intptr_t)m.player<0||(intptr_t)m.player>MAXPLAYERS||m.info)return 0;
    }
    for(i=0;i<s.sectors;i++){sector_t sec;memcpy(&sec,p,sizeof(sec));p+=sizeof(sec);REF(sec.soundtarget,1);REF(sec.thinglist,1);REF(sec.specialdata,0);if(sec.lines||sec.linecount<0||sec.linecount>s.lines)return 0;}
    for(i=0;i<s.sides;i++){side_t si;memcpy(&si,p,sizeof(si));p+=sizeof(si);if((intptr_t)si.sector<0||(intptr_t)si.sector>=s.sectors)return 0;}
    p+=s.lines*4*sizeof(int32_t);
    for(j=0;j<3;j++){int count=j==0?s.blocks:j==1?MAXPLATS:MAXCEILINGS;int expected=j==0?1:j==1?5:4;for(i=0;i<count;i++){int32_t ix;memcpy(&ix,p,4);p+=4;REF(ix,expected);}}
    if(s.brain_easy!=0&&s.brain_easy!=1)return 0;
    for(i=0;i<s.buttons;i++){button_t b;memcpy(&b,p,sizeof(b));p+=sizeof(b);if((intptr_t)b.line<0||(intptr_t)b.line>s.lines||(intptr_t)b.soundorg<0||(intptr_t)b.soundorg>2||b.btimer<0||(b.btimer&&(!b.line||b.where<top||b.where>bottom))||(!b.line&&b.soundorg))return 0;}
#undef REF
    return 1;
}
int m1_save_slot(int slot,char *error,unsigned cap){
    char path[4096],temporary[4096],raw[4096];uint8_t *supp=NULL,*payload=NULL,*whole=NULL;size_t sn,pn;envelope_t h;FILE *f;int ok=0;
    if(!paths(slot,path,temporary,raw)){snprintf(error,cap,"INVALID_SLOT");return -1;}
    if(gamestate!=GS_LEVEL||gameaction!=ga_nothing||!players[consoleplayer].mo||players[consoleplayer].playerstate!=PST_LIVE||players[consoleplayer].health<=0){snprintf(error,cap,"SAVE_STATE_NOT_ALLOWED");return -1;}
    supp=capture(&sn,error,cap);if(!supp)return -1;
    save_stream=M_fopen(raw,"wb");if(!save_stream){snprintf(error,cap,"SAVE_WRITE_FAILED");goto end;}
    savegame_error=false;P_WriteSaveGameHeader("ETNDOOM M1");P_ArchivePlayers();P_ArchiveWorld();P_ArchiveThinkers();P_ArchiveSpecials();P_WriteSaveGameEOF();P_WriteExtendedSaveGameData();
    ok=!ferror(save_stream);if(fclose(save_stream))ok=0;save_stream=NULL;if(!ok){snprintf(error,cap,"SAVE_WRITE_FAILED");goto end;}
    payload=read_file(raw,&pn);if(!payload||pn+sn+sizeof(h)>SAVE_MAX){snprintf(error,cap,"SAVE_CAPACITY");ok=0;goto end;}
    memset(&h,0,sizeof(h));memcpy(h.magic,"ETNM1SV",8);h.schema=1;h.header_size=sizeof(h);h.payload_size=pn;h.supplement_size=sn;memcpy(h.resource,resource_identity,64);memcpy(h.core,core_identity,32);h.jump=rules_jump;h.skill=gameskill;h.episode=gameepisode;h.map=gamemap;
    whole=malloc(sizeof(h)+pn+sn);if(!whole){snprintf(error,cap,"SAVE_ALLOC_FAILED");ok=0;goto end;}memcpy(whole,&h,sizeof(h));memcpy(whole+sizeof(h),payload,pn);memcpy(whole+sizeof(h)+pn,supp,sn);if(!sha(whole,sizeof(h)+pn+sn,h.digest)){snprintf(error,cap,"SAVE_HASH_FAILED");ok=0;goto end;}memcpy(whole,&h,sizeof(h));
    f=M_fopen(temporary,"wb");if(!f){snprintf(error,cap,"SAVE_WRITE_FAILED");ok=0;goto end;}
    ok=fwrite(whole,1,sizeof(h)+pn+sn,f)==sizeof(h)+pn+sn;if(fflush(f)||ferror(f))ok=0;if(fclose(f))ok=0;
    if(!ok||!atomic_replace(temporary,path)){snprintf(error,cap,"SAVE_COMMIT_FAILED");ok=0;}else error[0]=0;
end:
    free(supp);free(payload);free(whole);M_remove(raw);if(!ok)M_remove(temporary);return ok?0:-1;
}
int m1_load_slot(int slot,char *error,unsigned cap){
    char path[4096],temporary[4096],raw[4096],mapname[16],version[VERSIONSIZE];size_t n;uint8_t *whole,digest[32];envelope_t h;FILE *f;int ok;
    if(!paths(slot,path,temporary,raw)){snprintf(error,cap,"INVALID_SLOT");return -1;}
    whole=read_file(path,&n);if(!whole){snprintf(error,cap,"SAVE_OPEN_FAILED");return -1;}
    if(n<sizeof(h)){snprintf(error,cap,"SAVE_CONTAINER_INVALID");goto reject;}
    memcpy(&h,whole,sizeof(h));
    if(memcmp(h.magic,"ETNM1SV",8)||h.schema!=1||h.header_size!=sizeof(h)||h.payload_size<64||h.supplement_size<sizeof(supplement_t)||(uint64_t)sizeof(h)+h.payload_size+h.supplement_size!=n){snprintf(error,cap,"SAVE_CONTAINER_INVALID");goto reject;}
    memset(((envelope_t*)whole)->digest,0,32);if(!sha(whole,n,digest)||memcmp(digest,h.digest,32)){snprintf(error,cap,"SAVE_HASH_MISMATCH");goto reject;}
    if(memcmp(h.resource,resource_identity,64)||memcmp(h.core,core_identity,32)||h.jump!=rules_jump){snprintf(error,cap,"SAVE_IDENTITY_MISMATCH");goto reject;}
    if(h.skill<0||h.skill>4||h.episode<1||h.episode>4||h.map<1||h.map>32||!preflight(whole+sizeof(h)+h.payload_size,h.supplement_size)){snprintf(error,cap,"SAVE_SUPPLEMENT_INVALID");goto reject;}
    memset(version,0,sizeof(version));snprintf(version,sizeof(version),"version %i",G_VanillaVersionCode());
    if(memcmp(whole+sizeof(h)+SAVESTRINGSIZE,version,VERSIONSIZE)||whole[sizeof(h)+40]!=h.skill||whole[sizeof(h)+41]!=h.episode||whole[sizeof(h)+42]!=h.map||whole[sizeof(h)+43]!=1||whole[sizeof(h)+44]||whole[sizeof(h)+45]||whole[sizeof(h)+46]){snprintf(error,cap,"SAVE_NATIVE_HEADER_INVALID");goto reject;}
    if(gamemode==commercial){if(h.episode!=1){snprintf(error,cap,"SAVE_MAP_INVALID");goto reject;}snprintf(mapname,sizeof(mapname),"MAP%02d",h.map);}
    else{if(h.map>9){snprintf(error,cap,"SAVE_MAP_INVALID");goto reject;}snprintf(mapname,sizeof(mapname),"E%dM%d",h.episode,h.map);}
    if(W_CheckNumForName(mapname)<0){snprintf(error,cap,"SAVE_MAP_INVALID");goto reject;}
    f=M_fopen(raw,"wb");if(!f){snprintf(error,cap,"SAVE_RESTORE_WRITE_FAILED");goto reject;}
    ok=fwrite(whole+sizeof(h),1,h.payload_size,f)==h.payload_size;if(fclose(f))ok=0;if(!ok){snprintf(error,cap,"SAVE_RESTORE_WRITE_FAILED");M_remove(raw);goto reject;}
    m1_observer_world_begin();G_LoadGame(raw);startloadgame=0;G_DoLoadGame();
    if(gamestate!=GS_LEVEL||gameepisode!=h.episode||gamemap!=h.map||gameskill!=h.skill)m0_fail("SAVE_RESTORE_FAILED");
    restore(whole+sizeof(h)+h.payload_size,h.supplement_size);m1_observer_world_commit();
    free(whole);M_remove(raw);error[0]=0;return 0;
reject:
    free(whole);return -1;
}
