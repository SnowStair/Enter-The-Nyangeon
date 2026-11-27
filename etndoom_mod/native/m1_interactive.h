/* GPL-2.0-or-later. Host-driven Crispy interactive frontend. */
#ifndef ETN_M1_INTERACTIVE_H
#define ETN_M1_INTERACTIVE_H
int m1_interactive_enabled(void);
void m1_interactive_enable(void);
void m1_interactive_shutdown(void);
void m1_interactive_event(int type, int a, int b, int c);
void m1_interactive_executed(int count);
void m1_interactive_post_render(void);
void m1_interactive_quit(void);
void m1_interactive_clear(void);
int m1_menu_save(int slot, const char *description);
int m1_menu_load(int slot);
const char *m1_menu_save_path(int slot);
int m1_menu_save_description(int slot, char *description, int capacity);
void M1_ClearInput(void);
void M1_UpdateMouseAccel(int x, int y);
void M1_ConfigLoaded(void);
void M1_MenuError(const char *error);
int M1_GetDisplayMode(int *width, int *height);
int M1_FractionalTic(void);
int M1_SaveDefaultsChecked(void);
#endif
