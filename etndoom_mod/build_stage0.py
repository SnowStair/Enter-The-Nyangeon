"""通过 SDK PCKPacker 构建 Stage0 ZIP；仅打包明确白名单，不含商业 IWAD。"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile

SOURCE = Path(__file__).resolve().parent
REPO = SOURCE.parent
MOD_ID = "etndoom_stage0"


def build(godot, output=None):
    output = Path(output or SOURCE / "build").resolve()
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="etndoom-pack-") as directory:
        root = Path(directory)
        source = root / "source"
        source.mkdir()
        for relative in ["mod.json", "wad/MAP01.wad", "wad/MAP01_BackWall.wad",
                         "wad/MAP01_FrontWall.wad", "wad/MAP01_Texture.wad", "wad/MAP01_HTest.wad"]:
            target = source / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(SOURCE / relative, target)
        for folder, suffixes in [("entry", {".gd"}), ("stage0", {".gd", ".tscn"}),
                                 ("stage03", {".gd", ".tscn", ".gdshader"})]:
            for item in (SOURCE / folder).rglob("*"):
                if item.suffix in suffixes:
                    target = source / item.relative_to(SOURCE)
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(item, target)
        (root / "project.godot").write_text("config_version=5\n", encoding="utf-8")
        shutil.copy2(REPO / "mod_sdk/pack_mod.gd", root / "pack_mod.gd")
        env = os.environ.copy()
        for key in ["APPDATA", "LOCALAPPDATA", "XDG_DATA_HOME"]:
            env[key] = str(root / key)
            Path(env[key]).mkdir()
        pck = output / (MOD_ID + ".pck")
        command = [str(godot), "--headless", "--path", str(root), "--script", "res://pack_mod.gd", "--",
                   "--mod-source=" + source.as_posix(), "--out=" + pck.as_posix(), "--mod-id=" + MOD_ID]
        result = subprocess.run(command, env=env, capture_output=True, text=True, encoding="utf-8",
                                errors="replace", timeout=60, creationflags=0x08000000 if os.name == "nt" else 0)
        (output / "build.log").write_text(result.stdout + result.stderr, encoding="utf-8")
        if result.returncode or "ERROR:" in result.stdout + result.stderr or not pck.is_file():
            raise RuntimeError(result.stdout + result.stderr)
        archive = output / (MOD_ID + ".zip")
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as pack:
            pack.write(SOURCE / "mod.json", "mod.json")
            pack.write(pck, pck.name)
        manifest = json.loads((SOURCE / "mod.json").read_text(encoding="utf-8"))
        print(f"构建成功：{archive}，版本 {manifest['version']}；未打包 DOOM2.WAD")
        return archive


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    build(args.godot, args.output)
