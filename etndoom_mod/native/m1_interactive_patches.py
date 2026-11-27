"""Crispy 原生交互适配；只应用于宿主核心，不改变独立参考。"""
from pathlib import Path


def apply(dest: Path, reference: bool, replace) -> None:
    if reference:
        return
    menu = dest / "src/doom/m_menu.c"
    replace(menu, '#include "doomdef.h"', '#include "doomdef.h"\n#include "m1_interactive.h"')
    replace(menu, '        int retval;\n        M_StringCopy(name, P_SaveGameFile(i), sizeof(name));', '''        int retval;
        if (m1_interactive_enabled()) {
            retval = m1_menu_save_description(savepage*8+i, savegamestrings[i], SAVESTRINGSIZE);
            if (!retval) M_StringCopy(savegamestrings[i], EMPTYSTRING, SAVESTRINGSIZE);
            LoadMenu[i].status = retval;
            continue;
        }
        M_StringCopy(name, P_SaveGameFile(i), sizeof(name));''')
    replace(menu, 'void M_LoadSelect(int choice)\n{', '''void M_LoadSelect(int choice)
{
    if (m1_interactive_enabled()) {
        if (m1_menu_load(savepage*8+choice)) {
            SaveDef.lastOn = choice; M_ClearMenus();
            if (quickSaveSlot == -2) quickSaveSlot = choice;
        }
        return;
    }''')
    replace(menu, '    G_SaveGame (slot,savegamestrings[slot]);', '''    if (m1_interactive_enabled()) {
        if (!m1_menu_save(savepage*8+slot,savegamestrings[slot])) return;
    } else G_SaveGame (slot,savegamestrings[slot]);''')
    replace(menu, '    // [crispy] play quit sound only if the ENDOOM screen is also shown', '''    if (m1_interactive_enabled()) { m1_interactive_quit(); return; }
    // [crispy] play quit sound only if the ENDOOM screen is also shown''')
    replace(menu, '\t\tremove(name);', '\t\tM_remove(name);')
    replace(menu, 'crispy->vsync, !force_software_renderer);', 'crispy->vsync, m1_interactive_enabled() || !force_software_renderer);')
    replace(menu, 'smooth_pixel_scaling, !force_software_renderer);', 'smooth_pixel_scaling, m1_interactive_enabled() || !force_software_renderer);')
    with menu.open("a", encoding="utf-8") as f:
        f.write('''
void M1_MenuError(const char *error) { M_StartMessage(error, NULL, false); }
void M1_ConfigLoaded(void) { screenSize=screenblocks-3; M_SetDefaultDifficulty(); }
''')
    save = dest / "src/doom/p_saveg.c"
    replace(save, '#include "dstrings.h"', '#include "dstrings.h"\n#include "m1_interactive.h"')
    replace(save, 'char *P_SaveGameFile(int slot)\n{', '''char *P_SaveGameFile(int slot)
{
    if (m1_interactive_enabled()) return (char *)m1_menu_save_path(savepage*8+slot);''')
    game = dest / "src/doom/g_game.c"
    with game.open("a", encoding="utf-8") as f:
        f.write('''
/* Host focus/menu boundaries must not retain native held keys or mouse carry. */
void M1_ClearInput(void) {
    memset(gamekeydown,0,sizeof(gamekeydown));
    memset(mousearray,0,sizeof(mousearray));memset(joyarray,0,sizeof(joyarray));
    mousex=mousey=joyxmove=joyymove=joystrafemove=joylook=0;
    memset(&localview,0,sizeof(localview));memset(&carry,0,sizeof(carry));
    memset(&prevcarry,0,sizeof(prevcarry));memset(&basecmd,0,sizeof(basecmd));
    turnheld=lookheld=next_weapon=0;sendpause=sendsave=false;
    dclicktime=dclickstate=dclicks=dclicktime2=dclickstate2=dclicks2=0;
    newfastmouse=false;
}
''')
    with (dest / "src/i_input.c").open("a", encoding="utf-8") as f:
        f.write('\nvoid M1_UpdateMouseAccel(int x,int y) { UpdateMouseAccel(x,y); }\n')
    video = dest / "src/i_video.c"
    replace(video, '#include "config.h"', '#include "config.h"\n#include "m1_interactive.h"')
    replace(video, 'fractionaltic = I_GetFracRealTime();', 'fractionaltic = m1_interactive_enabled() ? M1_FractionalTic() : I_GetFracRealTime();')
    replace(video, 'if (SDL_GetCurrentDisplayMode(video_display, &mode) == 0)', 'if (m1_interactive_enabled() ? M1_GetDisplayMode(&mode.w, &mode.h) : SDL_GetCurrentDisplayMode(video_display, &mode) == 0)')
    status_bar = dest / "src/doom/st_stuff.c"
    replace(status_bar, '#include "doomdef.h"', '#include "doomdef.h"\n#include "m1_interactive.h"')
    replace(status_bar, 'void ST_refreshBackground(boolean force)\n{', '''void ST_refreshBackground(boolean force)
{
    /* Host resizing can replace the framebuffer without advancing a tic. */
    if (force && m1_interactive_enabled()) st_firsttime = true;''')
    config = dest / "src/m_config.c"
    replace(config, 'static void SaveDefaultCollection(default_collection_t *collection)', 'static int m1_config_write_error;\n\nstatic void SaveDefaultCollection(default_collection_t *collection)')
    replace(config, '    if (!f)\n\treturn; // can\'t write the file, but don\'t complain', '    if (!f) { m1_config_write_error=1; return; }')
    replace(config, '    fclose (f);\n}\n\n// Parses integer values', '    if (fflush(f) || ferror(f)) m1_config_write_error=1;\n    if (fclose(f)) m1_config_write_error=1;\n}\n\n// Parses integer values')
    with config.open("a", encoding="utf-8") as f:
        f.write('\nint M1_SaveDefaultsChecked(void) { m1_config_write_error=0; M_SaveDefaults(); return !m1_config_write_error; }\n')
    screenshot = dest / "src/v_video.c"
    replace(screenshot, '    char lbmname[16]; // haleyjd 20110213: BUG FIX - 12 is too small!', '    char lbmname[4096], base_name[32]; /* Keep screenshots in the isolated profile. */')
    replace(screenshot, '        M_snprintf(lbmname, sizeof(lbmname), format, i, ext);', '        M_snprintf(base_name, sizeof(base_name), format, i, ext);\n        M_snprintf(lbmname, sizeof(lbmname), "%s%s", m0_config_dir(), base_name);')
    crispy = dest / "src/doom/m_crispy.c"
    replace(crispy, '#include "crispy.h"', '#include "crispy.h"\n#include "m1_interactive.h"')
    replace(crispy, '    if (force_software_renderer)\n    {\n\treturn;\n    }', '''    if (m1_interactive_enabled()) { crispy->vsync=!crispy->vsync; return; }
    if (force_software_renderer)
    {
\treturn;
    }''')
