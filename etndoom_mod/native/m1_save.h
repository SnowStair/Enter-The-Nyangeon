/* GPL-2.0-or-later. ABI-locked deterministic supplement to upstream saves. */
#ifndef ETN_M1_SAVE_H
#define ETN_M1_SAVE_H
int m1_save_identity(const char *iwad, const char *pwad, int jump);
int m1_save_slot(int slot, char *error, unsigned capacity);
int m1_load_slot(int slot, char *error, unsigned capacity);
#endif
