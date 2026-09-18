#!/usr/bin/env python3
"""Build a self-contained Cloudflare Pages site from a clean checkout."""
import gzip
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import tarfile
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / '.web-tools'
OUT = ROOT / 'build/web'
VERSION = '4.7.2'
LFS_VERSION = '3.8.0'
LIMIT = 25 * 1024 * 1024
CHUNK = 20 * 1024 * 1024


def download(url, destination):
    print(f'Downloading {destination.name}', flush=True)
    temporary = destination.with_suffix(destination.suffix + '.download')
    with urllib.request.urlopen(url) as response, temporary.open('wb') as target:
        shutil.copyfileobj(response, target)
    temporary.replace(destination)


def godot_archive(name):
    base = f'https://github.com/godotengine/godot/releases/download/{VERSION}-stable/'
    sums = CACHE / 'SHA512-SUMS.txt'
    if not sums.exists():
        download(base + sums.name, sums)
    destination = CACHE / name
    if not destination.exists():
        download(base + name, destination)
    expected = next(line.split()[0] for line in sums.read_text().splitlines()
                    if line.split()[-1].lstrip('*') == name)
    with destination.open('rb') as source:
        digest = hashlib.sha512()
        for block in iter(lambda: source.read(1024 * 1024), b''):
            digest.update(block)
    if digest.hexdigest() != expected:
        destination.unlink()
        raise RuntimeError(f'Checksum mismatch for {name}; run again to re-download')
    return destination


def prepare_tools():
    CACHE.mkdir(exist_ok=True)
    # Pages build images may not include Git LFS. Install a project-local binary.
    if subprocess.run(['git', 'lfs', 'version'], stdout=subprocess.DEVNULL,
                      stderr=subprocess.DEVNULL).returncode:
        if platform.system() != 'Linux' or platform.machine() not in ('x86_64', 'AMD64'):
            raise RuntimeError('Install Git LFS before building on this platform')
        archive = CACHE / 'git-lfs.tar.gz'
        download(f'https://github.com/git-lfs/git-lfs/releases/download/v{LFS_VERSION}/'
                 f'git-lfs-linux-amd64-v{LFS_VERSION}.tar.gz', archive)
        with tarfile.open(archive) as source:
            member = next(m for m in source.getmembers() if m.name.endswith('/git-lfs'))
            with source.extractfile(member) as binary, (CACHE / 'git-lfs').open('wb') as target:
                shutil.copyfileobj(binary, target)
        (CACHE / 'git-lfs').chmod(0o755)
        os.environ['PATH'] = str(CACHE) + os.pathsep + os.environ['PATH']
    subprocess.run(['git', 'lfs', 'pull', '--include=assets/**', '--exclude='], cwd=ROOT, check=True)
    # Refuse to export pointers as if they were models.
    for asset in (ROOT / 'assets').rglob('*.glb'):
        with asset.open('rb') as source:
            if source.read(40).startswith(b'version https://git-lfs.github.com'):
                raise RuntimeError(f'Git LFS did not download {asset.relative_to(ROOT)}')
    executable = os.environ.get('GODOT_BIN')
    if not executable:
        if platform.system() != 'Linux' or platform.machine() not in ('x86_64', 'AMD64'):
            raise RuntimeError('Set GODOT_BIN to your Godot 4.7.2 executable on this platform')
        name = f'Godot_v{VERSION}-stable_linux.x86_64'
        executable = str(CACHE / name)
        if not Path(executable).exists():
            with zipfile.ZipFile(godot_archive(name + '.zip')) as source:
                (CACHE / name).write_bytes(source.read(name))
            Path(executable).chmod(0o755)
    version = subprocess.check_output([executable, '--version'], text=True).strip()
    if not version.startswith(VERSION + '.stable'):
        raise RuntimeError(f'Expected Godot {VERSION}.stable, got {version}')
    template = CACHE / 'web_nothreads_release.zip'
    if not template.exists():
        with zipfile.ZipFile(godot_archive(f'Godot_v{VERSION}-stable_export_templates.tpz')) as source:
            template.write_bytes(source.read('templates/web_nothreads_release.zip'))
    return executable


def package_site():
    pack = OUT / 'index.pck'
    manifest = {'size': pack.stat().st_size, 'chunks': []}
    pieces = OUT / 'pack'
    pieces.mkdir()
    with pack.open('rb') as source:
        for index, block in enumerate(iter(lambda: source.read(CHUNK), b'')):
            filename = f'pack/{index:03d}.bin'
            (OUT / filename).write_bytes(gzip.compress(block, compresslevel=9, mtime=0))
            manifest['chunks'].append({'url': filename, 'size': len(block),
                                       'sha256': hashlib.sha256(block).hexdigest()})
    (OUT / 'pack.json').write_text(json.dumps(manifest))
    pack.unlink()
    wasm = OUT / 'index.wasm'
    wasm.write_bytes(gzip.compress(wasm.read_bytes(), compresslevel=9, mtime=0))
    for name in ('_headers', 'loader.js', '404.html'):
        shutil.copyfile(ROOT / 'web' / name, OUT / name)
    for path in OUT.rglob('*'):
        if path.is_file() and path.stat().st_size > LIMIT:
            raise RuntimeError(f'{path.name} exceeds Cloudflare Pages 25 MiB limit')
    total = sum(p.stat().st_size for p in OUT.rglob('*') if p.is_file())
    print(f'Pages site ready: {OUT} ({total / 1024**2:.1f} MiB; {len(manifest["chunks"])} pack pieces)')


def main():
    executable = prepare_tools()
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT.parent / '.gdignore').touch()
    # Only remove our generated output, never source assets or saves.
    shutil.rmtree(OUT)
    OUT.mkdir()
    for args in (['--editor', '--import'], ['--export-release', 'Web']):
        result = subprocess.run([executable, '--headless', '--path', str(ROOT), *args],
                                text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (ROOT / 'build' / ('import.log' if '--import' in args else 'export.log')).write_text(result.stdout)
        if result.returncode or 'SCRIPT ERROR:' in result.stdout or 'ERROR:' in result.stdout:
            print(result.stdout)
            raise RuntimeError('Godot import/export failed; see build/*.log')
    package_site()


if __name__ == '__main__':
    main()
