"""M1 只读观察补丁；所有替换由主构建器校验锚点。"""
def apply(dest, reference, replace):
    doom = dest / "src/doom"
    for filename in ("p_tick.c", "p_setup.c", "p_telept.c", "p_mobj.c", "p_saveg.c"):
        path = doom / filename
        text = path.read_text(encoding="utf-8")
        path.write_text('#include "m1_observer.h"\n' + text, encoding="utf-8", newline="\n")
    replace(doom / "p_mobj.c", "    P_AddThinker (&mobj->thinker);", "    P_AddThinker (&mobj->thinker);\n    m1_observer_spawn(mobj);")
    replace(doom / "p_saveg.c", "\t    P_AddThinker (&mobj->thinker);", "\t    P_AddThinker (&mobj->thinker);\n            m1_observer_spawn(mobj);")
    replace(doom / "p_tick.c", "  // FIXME: NOP.", "  if (thinker->function.acp1 == (actionf_p1)P_MobjThinker) m1_observer_remove(thinker);\n  // FIXME: NOP.")
    replace(doom / "p_setup.c", "    totalkills = totalitems = totalsecret = wminfo.maxfrags = 0;", "    m1_observer_world_begin();\n    totalkills = totalitems = totalsecret = wminfo.maxfrags = 0;")
    replace(doom / "p_setup.c", '    //printf ("free memory: 0x%x\\n", Z_FreeMemory());', '    m1_observer_world_commit();\n    //printf ("free memory: 0x%x\\n", Z_FreeMemory());')
    replace(doom / "p_telept.c", "\t\tthing->momx = thing->momy = thing->momz = 0;", "\t\tthing->momx = thing->momy = thing->momz = 0;\n                m1_observer_teleport(thing);")
    with (doom / "r_data.c").open("a", encoding="utf-8") as f:
        f.write('''
/* M1: export the resolved native texture composition, without a second WAD parser. */
int M1_TextureInfo(int index, char name[9], int *width, int *height) {
    if(index<0 || index>=numtextures) return -1;
    memcpy(name,textures[index]->name,8); name[8]=0;
    *width=textures[index]->width; *height=textures[index]->height;
    return textures[index]->patchcount;
}
int M1_TexturePatch(int index,int patch,int *x,int *y) {
    if(index<0 || index>=numtextures || patch<0 || patch>=textures[index]->patchcount) return -1;
    *x=textures[index]->patches[patch].originx; *y=textures[index]->patches[patch].originy;
    return textures[index]->patches[patch].patch;
}
''')
    with (doom / "wi_stuff.c").open("a", encoding="utf-8") as f:
        f.write('\nint M1_IntermissionStage(void) { return state; }\n')
