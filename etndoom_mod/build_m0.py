"""构建 M0 的 PCK/物理原生库 ZIP；仅含本模组代码，不含 WAD 或本体资源。"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import zipfile

SOURCE = Path(__file__).resolve().parent
REPO = SOURCE.parent
MOD_ID = "etndoom_m0"
GODOT = "D:/Creating/Godot/Godot_v4.7.2-stable_win64_console.exe"


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def run(command, log, cwd=None, timeout=240):
    result = subprocess.run([str(x) for x in command], cwd=cwd, capture_output=True,
                            text=True, encoding="utf-8", errors="replace", timeout=timeout,
                            creationflags=0x08000000 if os.name == "nt" else 0)
    Path(log).write_text(result.stdout + result.stderr, encoding="utf-8")
    if result.returncode:
        raise RuntimeError(f"命令失败，详见 {log}: {result.stdout[-2000:]} {result.stderr[-2000:]}")
    return result.stdout + result.stderr


def build(godot=GODOT, output=None, native_dir=None, build_id=None):
    output = Path(output or SOURCE / "build/m0").resolve()
    native_dir = Path(native_dir or SOURCE / "native/build/bin").resolve()
    output.mkdir(parents=True, exist_ok=True)
    binaries = [native_dir / "etndoom_crispy_core.dll", native_dir / "SDL2.dll"]
    for path in binaries:
        if not path.is_file():
            raise FileNotFoundError(f"缺少已编译内核/依赖：{path}；请先运行 build_native.py")
    # M1 now owns native/build/bin. Never label an ABI 2 core as ABI 1 merely
    # because the historical packaging entry was used. Probe in a child so no
    # DLL remains resident in this build process; no game session is created.
    probe = subprocess.run([sys.executable, "-c",
        "import ctypes,json,os,sys; p=os.path.abspath(sys.argv[1]); "
        "cookie=os.add_dll_directory(os.path.dirname(p)); d=ctypes.CDLL(p); "
        "d.m0_build_info.restype=ctypes.c_char_p; print(d.m0_build_info().decode('utf-8'))",
        str(binaries[0])], capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=30)
    if probe.returncode:
        raise RuntimeError("不能核验 M0 内核 ABI：" + probe.stderr.strip())
    info = json.loads(probe.stdout.strip())
    if info.get("abi") != 1:
        raise RuntimeError("M0 构建仅接受 ABI 1 内核，实际 ABI=%s。当前 build_native.py 生成 M1；请使用 build_m1.py，或通过 --native-dir 指向已验收的 M0 原生目录。未改写旧 M0 产物。" % info.get("abi"))
    identity = hashlib.sha256()
    for path in [SOURCE / "gdextension/bridge.c", SOURCE / "gdextension/gdextension_interface.h", SOURCE / "entry/m0_entry.gd", *sorted((SOURCE / "m0").glob("*.gd")), *binaries]:
        identity.update(path.read_bytes())
    build_id = build_id or identity.hexdigest()[:20]
    if not build_id or any(c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_" for c in build_id):
        raise ValueError("build_id 仅接受字母、数字、连字符和下划线")
    bridge = output / "etndoom_m0_bridge.dll"
    command = [shutil.which("gcc") or "gcc", "-std=c11", "-O2", "-Wall", "-Wextra", "-shared", "-static-libgcc",
               f'-DM0_BRIDGE_BUILD="{build_id}"', "-o", bridge, SOURCE / "gdextension/bridge.c"]
    run(command, output / "bridge_build.log")
    native_manifest = {"schema": 1, "bridge_abi": 1, "core_abi": 1, "build_id": build_id,
                       "files": {path.name: sha256(path) for path in [bridge, *binaries]}}
    manifest = json.loads((SOURCE / "m0/mod.json").read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory(prefix="etndoom-m0-pack-") as directory:
        root = Path(directory)
        source = root / "source"
        (source / "entry").mkdir(parents=True)
        (source / "m0").mkdir()
        shutil.copy2(SOURCE / "entry/m0_entry.gd", source / "entry/m0_entry.gd")
        for path in sorted((SOURCE / "m0").glob("*.gd")):
            shutil.copy2(path, source / "m0" / path.name)
        (source / "build_identity.json").write_text(json.dumps(native_manifest, indent=2), encoding="utf-8")
        (root / "project.godot").write_text("config_version=5\n", encoding="utf-8")
        shutil.copy2(REPO / "mod_sdk/pack_mod.gd", root / "pack_mod.gd")
        pck = output / f"{MOD_ID}.pck"
        pack_command = [godot, "--headless", "--path", root, "--script", "res://pack_mod.gd", "--",
                        "--mod-source=" + source.as_posix(), "--out=" + pck.as_posix(), "--mod-id=" + MOD_ID]
        text = run(pack_command, output / "pck_build.log")
        if "ERROR:" in text or not pck.is_file():
            raise RuntimeError("PCK 构建失败：" + str(output / "pck_build.log"))
        archive = output / f"{MOD_ID}.zip"
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as pack:
            pack.writestr("mod.json", json.dumps(manifest, ensure_ascii=False, indent=2))
            pack.write(pck, pck.name)
            pack.writestr("native/manifest.json", json.dumps(native_manifest, indent=2))
            for path in [bridge, *binaries]:
                pack.write(path, "native/" + path.name)
            for path in sorted((SOURCE / "native/licenses").glob("*")):
                if path.is_file():
                    pack.write(path, "licenses/" + path.name)
            for path, name in [(SOURCE / "native/dependencies/SDL2-2.32.10/LICENSE.txt", "SDL2-LICENSE.txt"),
                               (SOURCE / "native/core_source/COPYING.md", "Crispy-COPYING.md")]:
                if not path.is_file():
                    raise FileNotFoundError(f"缺少必需许可证：{path}")
                pack.write(path, "licenses/" + name)
            # Godot 提供的接口头自身含 MIT 版权及许可；随包保留原文。
            pack.write(SOURCE / "gdextension/gdextension_interface.h", "licenses/godot_gdextension_interface.h")
            pack.writestr("licenses/LOCAL_VALIDATION.txt", "本包仅用于本地 M0 验证。商业 WAD 不包含在内。正式组合分发授权和对应源码交付须按 ETNDOOM 许可审计完成。\n")
    compiler = subprocess.check_output([command[0], "--version"], text=True, encoding="utf-8", errors="replace")
    lock = {"schema": 1, "build_id": build_id, "native": native_manifest, "compiler": compiler.splitlines()[0],
            "bridge_command": [str(x) for x in command], "gdextension_header_sha256": sha256(SOURCE / "gdextension/gdextension_interface.h"),
            "godot": str(godot), "godot_sha256": sha256(godot), "pck_sha256": sha256(pck), "zip_sha256": sha256(archive),
            "wad_included": False, "source_files": {str(p.relative_to(SOURCE)): sha256(p) for p in [SOURCE / "entry/m0_entry.gd", *sorted((SOURCE / "m0").glob("*.gd")), SOURCE / "gdextension/bridge.c"]}}
    (output / "build_lock.json").write_text(json.dumps(lock, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"M0 构建成功：{archive}，build_id={build_id}")
    return archive


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=GODOT)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--native-dir", type=Path)
    parser.add_argument("--build-id", help="用于 A/B 更新探针的显式构建标识")
    args = parser.parse_args()
    build(args.godot, args.output, args.native_dir, args.build_id)
