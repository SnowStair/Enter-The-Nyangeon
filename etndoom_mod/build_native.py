"""从锁定源码构建 M1 内核与独立上游参考程序，不使用其它工作区。"""
from __future__ import annotations
import argparse, hashlib, importlib.util, json, shutil, subprocess, tarfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
NATIVE = ROOT / "native"
SOURCE = ROOT / "vendor/crispy-doom-35b49519.tar.gz"
SOURCE_SHA = "3e15a65dbb3602447465dd543eef8892c834e7ab026149fa3ded92caa8096b46"
SDL_ARCHIVE = NATIVE / "downloads/SDL2-devel-2.32.10-mingw.tar.gz"
SDL_SHA = "83a5d74012311edc3c0d40ea6faecbe57ad692aa033fa5dc273cc937e3938ff2"
MIXER_ARCHIVE = ROOT / "vendor/SDL2_mixer-devel-2.8.1-mingw.tar.gz"
MIXER_SHA = "b6c98eecd308aa9922ede0aac466bb5dea6c3e9b9b59dd496009f778c90d83d7"

def digest(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()

def replace(p: Path, old: str, new: str, count: int = 1) -> None:
    text = p.read_text(encoding="utf-8")
    if text.count(old) != count:
        raise RuntimeError(f"补丁锚点不匹配: {p}: {old!r}, {text.count(old)} != {count}")
    p.write_text(text.replace(old, new), encoding="utf-8", newline="\n")

def prepare_source(reference: bool, workspace: Path = NATIVE) -> Path:
    if digest(SOURCE) != SOURCE_SHA:
        raise RuntimeError("Crispy 源码包 SHA-256 不匹配")
    dest = workspace / ("reference_source" if reference else "core_source")
    dest.mkdir(exist_ok=True)
    with tarfile.open(SOURCE) as archive:
        archive.extractall(dest, filter="data")
    main = dest / "src/doom/d_main.c"
    replace(dest / "src/i_sound.c", '#include "config.h"', '#include "config.h"\n#include "SDL.h"')
    replace(dest / "src/i_sound.c", '    M_SetMusicPackDir();', '    /* M1 forbids external music-pack discovery. */\n    nomusicpacks = true;')
    replace(dest / "src/i_video.c", '#include "config.h"', '#include "config.h"\n#include <math.h>')
    # 两端冻结同一配置/许可清单，不读取用户 Crispy 配置或额外资源。
    replace(main, '    M_LoadDefaults();', '    /* M0: deterministic isolated configuration; no user defaults. */\n    m0_apply_config();')
    replace(main, '        M_SetConfigDir(NULL);', '        M_SetConfigDir(m0_config_dir());')
    replace(main, '    I_AtExit(M_SaveDefaults, true);', '    /* M0 does not write upstream configuration. */')
    replace(main, '#include "config.h"', '#include "config.h"\nextern void m0_apply_config(void);\nextern const char *m0_config_dir(void);')
    if reference:
        # 保留绘图与 S_StartSound 的原调用。仅关闭擦屏动画，避免其 M_Random
        # 与显示帧数耦合；不能用 nodrawers，因为它还会跳过声音 pitch RNG。
        replace(main, '        if ((wipe = D_Display ()))', '        wipegamestate = gamestate; /* M0 reference: no transition wipes. */\n        if ((wipe = D_Display ()))')
        replace(main, '    TryRunTics();\n\n    V_RestoreBuffer();', '    m0_reference_initial();\n    TryRunTics();\n\n    V_RestoreBuffer();')
        replace(main, 'extern void m0_apply_config(void);', 'extern void m0_apply_config(void);\nextern void m0_reference_initial(void);')
        loop = dest / "src/d_loop.c"
        replace(loop, '    loop_interface->BuildTiccmd(&cmd, maketic);', '    loop_interface->BuildTiccmd(&cmd, maketic);\n    m0_reference_command(&cmd, maketic);')
        replace(loop, '#include "d_loop.h"', '#include "d_loop.h"\nextern void m0_reference_command(ticcmd_t *, int);\nextern void m0_reference_observe(void);')
        replace(loop, '\t    gametic++;', '\t    gametic++;\n            m0_reference_observe();')
        replace(main, '    while (1)\n    {\n        D_RunFrame();\n    }', '    while (1)\n    {\n        D_RunFrame();\n    }')
    else:
        # 保留 init/游戏全流程；不进入独占 wall-clock 循环或补一个隐藏 tic。
        replace(main, '    TryRunTics();\n\n    V_RestoreBuffer();', '    /* Host supplies every tic explicitly. */\n\n    V_RestoreBuffer();')
        replace(main, '    D_StartGameLoop();', '    /* Host owns the clock. */')
        replace(main, '    while (1)\n    {\n        D_RunFrame();\n    }', '    return; /* M0 library initialization boundary. */')
        replace(main, '    NetUpdate ();         // send out any new accumulation', '    /* Rendering cannot sample input or advance the command clock. */')
        net = dest / "src/doom/d_net.c"
        with net.open("a", encoding="utf-8") as f:
            f.write('\nvoid M0_RunTic(ticcmd_t *cmds) { RunTic(cmds, playeringame); }\n')
        video = dest / "src/i_video.c"
        with video.open("a", encoding="utf-8") as f:
            f.write('''
void M0_CopyFrame(unsigned char *rgba) {
    int i;
    for(i=0;i<SCREENWIDTH*SCREENHEIGHT;i++) {
        SDL_Color c=palette[I_VideoBuffer[i]];
        rgba[4*i]=c.r;rgba[4*i+1]=c.g;rgba[4*i+2]=c.b;rgba[4*i+3]=255;
    }
}
''')
        system = dest / "src/i_system.c"
        text = system.read_text(encoding="utf-8")
        start = text.index('void I_Quit (void)')
        end = text.index('//\n// I_Realloc', start)
        text = text[:start] + '''void M0_Shutdown(void) {
    atexit_listentry_t *entry=exit_funcs;
    while(entry) { if(entry->run_on_error) entry->func(); entry=entry->next; }
    exit_funcs=NULL;
    SDL_Quit();
}
void I_Quit(void) { m0_fail("CORE_QUIT_REQUESTED"); }
void I_Error(const char *error, ...) {
    char msg[1024];va_list a;va_start(a,error);vsnprintf(msg,sizeof(msg),error,a);va_end(a);
    m0_fail(msg);
}

''' + text[end:]
        system.write_text(text, encoding="utf-8", newline="\n")
    # Each patch module owns validated upstream anchors; generated trees are
    # rebuilt from the locked archive and are never the source of truth.
    for name in ("m1_observer_patches", "m1_audio_patches", "m1_save_patches"):
        spec = importlib.util.spec_from_file_location(name, NATIVE / f"{name}.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        module.apply(dest, reference, replace)
    return dest

def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--reference", action="store_true")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--jobs", type=int, default=8)
    parser.add_argument("--build-root", type=Path, help="独立构建/解压根；保留现有产物，适用于干净构建验证")
    args=parser.parse_args()
    workspace=args.build_root.resolve() if args.build_root else NATIVE
    workspace.mkdir(parents=True,exist_ok=True)
    if not SDL_ARCHIVE.exists():
        raise SystemExit("缺少 SDL2 开发包，请从 https://www.libsdl.org/release/SDL2-devel-2.32.10-mingw.tar.gz 下载至 native/downloads/。")
    if digest(SDL_ARCHIVE) != SDL_SHA:
        raise SystemExit("SDL2 开发包 SHA-256 不匹配")
    if not MIXER_ARCHIVE.exists() or digest(MIXER_ARCHIVE) != MIXER_SHA:
        raise SystemExit("SDL2_mixer 固定开发包缺失或 SHA-256 不匹配")
    dependencies=workspace/"dependencies"
    dependencies.mkdir(exist_ok=True)
    if not (dependencies/"SDL2-2.32.10/x86_64-w64-mingw32/lib/cmake/SDL2/sdl2-config.cmake").exists():
        with tarfile.open(SDL_ARCHIVE) as archive:
            archive.extractall(dependencies, filter="data")
    sdl=dependencies/"SDL2-2.32.10/x86_64-w64-mingw32"
    mixer=dependencies/"SDL2_mixer-2.8.1/x86_64-w64-mingw32"
    if not (mixer/"lib/cmake/SDL2_mixer/sdl2_mixer-config.cmake").exists():
        with tarfile.open(MIXER_ARCHIVE) as archive:
            archive.extractall(dependencies, filter="data")
    for reference in ([False,True] if args.all else [args.reference]):
        src=prepare_source(reference,workspace)
        build=workspace/("reference_build" if reference else "build")
        build.mkdir(exist_ok=True)
        commands=[
            ["cmake","-S",str(NATIVE),"-B",str(build),"-G","Ninja",f"-DM0_SOURCE={src.as_posix()}",f"-DCMAKE_PREFIX_PATH={sdl.as_posix()};{mixer.as_posix()}",f"-DM0_REFERENCE={'ON' if reference else 'OFF'}","-DCMAKE_POLICY_VERSION_MINIMUM=3.5"],
            ["cmake","--build",str(build),"--target","crispy-doom" if reference else "etndoom_crispy_core","-j",str(args.jobs)]]
        with (build/"build.log").open("w",encoding="utf-8") as log:
            for command in commands:
                log.write(json.dumps(command)+"\n");log.flush()
                result=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT)
                if result.returncode:
                    print((build/"build.log").read_text(encoding="utf-8",errors="replace")[-10000:])
                    raise SystemExit(result.returncode)
        shutil.copy2(sdl/"bin/SDL2.dll",build/"bin/SDL2.dll")
        shutil.copy2(mixer/"bin/SDL2_mixer.dll",build/"bin/SDL2_mixer.dll")
        artifact=build/"bin"/("crispy-doom.exe" if reference else "etndoom_crispy_core.dll")
        lock={"core_commit":"35b49519fb4f0360ee1527e8cf0bdf0b6bbfeff2","core_source_sha256":SOURCE_SHA,"sdl_version":"2.32.10","sdl_archive_sha256":digest(SDL_ARCHIVE),"sdl_dll_sha256":digest(build/"bin/SDL2.dll"),"artifact_sha256":digest(artifact),"commands":commands,"reference":reference,"compiler":subprocess.check_output(["gcc","--version"],text=True).splitlines()[0],"patch_driver_sha256":digest(Path(__file__)),"native_sources":{p.name:digest(p) for p in NATIVE.iterdir() if p.is_file()}}
        lock.update({"abi":2,"audio_backend":"SDL_mixer-2.8.1/OPL","sdl_mixer_archive_sha256":MIXER_SHA,"sdl_mixer_dll_sha256":digest(build/"bin/SDL2_mixer.dll")})
        (build/"build-lock.json").write_text(json.dumps(lock,ensure_ascii=False,indent=2),encoding="utf-8")
        print(artifact)

if __name__=="__main__":main()
