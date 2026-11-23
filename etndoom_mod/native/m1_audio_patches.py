"""M1 上游音频接入：保留选声/OPL语义，补观测与可卸载生命周期。"""
def apply(dest, reference, replace):
    if reference:
        replace(dest / "src/doom/d_main.c", '        S_UpdateSounds (players[displayplayer].mo);// move positional sounds', '        /* M1: serviced once per tic before the independent trace snapshot. */')
        replace(dest / "src/doom/d_main.c", '        if ((wipe = D_Display ()))', '        if ((wipe = false)) /* M1: per-tic observer already rendered. */')
    # E3's ending formerly fired a pistol from its drawer. Keep the six native
    # sound cues on the same canonical tics, independent of framebuffer reads.
    finale = dest / "src/doom/f_finale.c"
    replace(finale, '    finalecount++;', '''    finalecount++;
    if (finalestage == F_STAGE_ARTSCREEN && gameepisode == 3
        && finalecount >= 1185 && finalecount <= 1210
        && (finalecount - 1180) % 5 == 0)
        S_StartSound(NULL, sfx_pistol);''')
    replace(finale, '    static int\tlaststage;\n', '')
    replace(finale, '\tlaststage = 0;\n', '')
    replace(finale, '''    if (stage > laststage)
    {
\tS_StartSound (NULL, sfx_pistol);
\tlaststage = stage;
    }
''', '')
    # Machine environment must not silently change the frozen OPL backend.
    replace(dest / "opl/opl.c", '    driver_name = getenv("OPL_DRIVER");', '    driver_name = "SDL"; /* M1: fixed software synthesizer. */')
    replace(dest / "src/i_oplmusic.c", '    dmxoption = getenv("DMXOPTION");', '    dmxoption = ""; /* M1: frozen OPL2 configuration. */')
    replace(dest / "src/i_oplmusic.c", '#include "m_misc.h"', '#include "m_misc.h"\nextern const char *m0_config_dir(void);')
    replace(dest / "src/i_oplmusic.c", '    filename = M_TempFile("doom.mid");', '    filename = M_StringJoin(m0_config_dir(), "/.m1-music.mid", NULL);')
    sound = dest / "src/doom/s_sound.c"
    replace(sound, '#include "s_sound.h"', '#include "s_sound.h"\n#include "m1_audio.h"')
    replace(sound, '        c->sfxinfo->usefulness--;', '        m1_audio_sound_stop(cnum);\n        c->sfxinfo->usefulness--;')
    replace(sound, '    channels[cnum].handle = I_StartSound(sfx, cnum, volume, sep, channels[cnum].pitch);', '    channels[cnum].handle = I_StartSound(sfx, cnum, volume, sep, channels[cnum].pitch);\n    m1_audio_sound_start(cnum, sfx->lumpnum, origin, volume, sep, pitch, channels[cnum].handle);')
    replace(sound, '                        I_UpdateSoundParams(c->handle, volume, sep);', '                        I_UpdateSoundParams(c->handle, volume, sep);\n                        m1_audio_sound_position(cnum, c->origin, volume, sep);')
    replace(sound, '    mus_playing = music;', '    mus_playing = music;\n    m1_audio_music_start(music->lumpnum, looping);', 2)
    replace(sound, '        mus_playing = NULL;', '        mus_playing = NULL;\n        m1_audio_music_stop();')
    # Button restoration is the only active StartSoundOnce call with the
    # frozen soundfull=0 configuration. Device wall time must not decide
    # whether the call consumes pitch RNG. Retain duplicate suppression for
    # multiple switch textures on one origin within this P_UpdateSpecials.
    # Delay clearing expired slots until the scan ends, so earlier origins
    # remain available without persistent state or allocation.
    special = dest / "src/doom/p_spec.c"
    replace(special, '''\t    if (!buttonlist[i].btimer)
\t    {
\t\tswitch(buttonlist[i].where)''', '''\t    if (!buttonlist[i].btimer)
\t    {
                int m1_previous_button;
                boolean m1_emit_button_sound = true;
                if (crispy->soundfix)
                    for (m1_previous_button = 0; m1_previous_button < i; m1_previous_button++)
                        if (buttonlist[m1_previous_button].line
                            && !buttonlist[m1_previous_button].btimer
                            && buttonlist[m1_previous_button].soundorg == buttonlist[i].soundorg
                            && (!buttonlist[m1_previous_button].line->backsector
                                || !buttonlist[m1_previous_button].line->backsector->specialdata))
                            m1_emit_button_sound = false;
\t\tswitch(buttonlist[i].where)''')
    replace(special, 'S_StartSoundOnce(buttonlist[i].soundorg,sfx_swtchn);', 'if (m1_emit_button_sound) S_StartSound(buttonlist[i].soundorg,sfx_swtchn);')
    replace(special, 'S_StartSoundOnce(&buttonlist[i].soundorg,sfx_swtchn);', 'S_StartSound(&buttonlist[i].soundorg,sfx_swtchn);')
    replace(special, '\t\tmemset(&buttonlist[i],0,sizeof(button_t));', '\t\t/* M1: clear expired slots after duplicate-origin inspection. */')
    replace(special, '    // [crispy] Snow\n', '''    for (i = 0; i < maxbuttons; i++)
        if (!buttonlist[i].btimer)
            memset(&buttonlist[i], 0, sizeof(button_t));

    // [crispy] Snow
''')
    # Upstream closes the shared device before destroying OPL and does not
    # unregister its postmix effect. A DLL must remove every callback first.
    system = dest / "src/i_sound.c"
    text = system.read_text(encoding="utf-8")
    begin=text.index('void I_ShutdownSound(void)');end=text.index('int I_GetSfxLumpNum',begin)
    text=text[:begin]+'''void I_ShutdownSound(void)
{
    if (music_packs_active) { music_pack_module.Shutdown(); music_packs_active=false; }
    if (music_module != NULL) { music_module->Shutdown(); music_module=NULL; }
    active_music_module=NULL;
    if (sound_module != NULL) { sound_module->Shutdown(); sound_module=NULL; }
}
int M1_AudioModulesReady(void) { return sound_module != NULL && music_module != NULL; }

'''+text[end:]
    system.write_text(text,encoding="utf-8",newline="\n")
    opl=dest / "opl/opl_sdl.c"
    replace(opl,'    Mix_HookMusic(NULL, NULL);','    Mix_UnregisterEffect(MIX_CHANNEL_POST, OPL_Mix_Callback);\n    Mix_HookMusic(NULL, NULL);')
    replace(opl,'        OPL_Queue_Destroy(callback_queue);\n        free(mix_buffer);','        /* Shared and privately owned mixers release buffers below. */')
    replace(opl,'    if (callback_mutex != NULL)','    if (callback_queue != NULL) { OPL_Queue_Destroy(callback_queue); callback_queue=NULL; }\n    free(mix_buffer); mix_buffer=NULL;\n\n    if (callback_mutex != NULL)')
