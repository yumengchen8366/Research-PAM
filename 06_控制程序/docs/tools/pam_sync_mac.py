#!/usr/bin/env python3
# pam_sync_mac.py  -  Mac version of pam_sync.ps1: two-way sync of the PAM project through the private GitHub repo.
#
# Run it when you START and when you FINISH working on the Mac:
#   double-click sync_pam.command in the project folder
#   or:  python3 docs/tools/pam_sync_mac.py [--import-sidebar] [--no-push] [--no-pull]
# First time on this Mac (after git clone):
#   python3 docs/tools/pam_sync_mac.py --setup --git-name "<name>" --git-email "<email>"
#
# Steps (same as pam_sync.ps1)
#   1. copy this Mac's Claude transcripts, attached photos and sidebar entries INTO the repo (claude/...)
#   2. commit
#   3. fetch from GitHub and merge
#   4. copy transcripts and photos from the repo INTO ~/.claude on this Mac
#      --import-sidebar: also add the sessions to the Claude desktop-app sidebar (quit the app first)
#   5. push
#
# Memory is not copied: ~/.claude/projects/<project>/memory is a symlink to claude/memory (made by --setup).
#
# Why this is not a line-by-line port of pam_sync.ps1
#   The repo stores Claude data with the lab PC's paths (C:\Users\2031\...). On a Mac they become /Users/<you>/...,
#   and that rewrite is not exactly reversible (e.g. doubly escaped paths, mixed separators). So this script
#   never converts a whole file back: it remembers what the two sides looked like at the last sync and, when
#   a transcript has only grown (the normal case), appends just the NEW lines (converted) to the repo copy.
#   The Windows PCs then see "old file + new lines", which pam_sync.ps1 accepts as a continuation.
#
# State: ~/Library/Application Support/PAM_sync/git_state_<slug>.json
# Python 3.8+ standard library only (the python3 that comes with Xcode Command Line Tools is fine).

import argparse
import datetime
import hashlib
import json
import os
import re
import shutil
import socket
import subprocess
import sys

MAX_BYTES = 90 * 1024 * 1024                    # GitHub refuses files over 100 MB
TEXT_EXT = {'.jsonl', '.json', '.md', '.txt', '.js'}

# The lab PC's paths, as stored in the repo
CANON_HOME = 'C:\\Users\\2031'
CANON_DESKTOP = 'C:\\Users\\2031\\Desktop'
CANON_PROJECT = 'C:\\Users\\2031\\Desktop\\PAM_controlProgram'

REPO = os.path.realpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
HOME = os.path.expanduser('~')
DESKTOP = os.path.join(HOME, 'Desktop')
STAMP = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
PC = (socket.gethostname().split('.')[0] or 'mac')


def slug(p):                                     # Claude Code's per-project folder name
    return re.sub(r'[^A-Za-z0-9]', '-', p)


LOCAL_SLUG = slug(REPO)
CANON_SLUG = slug(CANON_PROJECT)

RED, YELLOW, GREEN, RESET = '\033[31m', '\033[33m', '\033[32m', '\033[0m'


def say(msg, color=''):
    print(color + msg + (RESET if color else ''), flush=True)


# ---------- git ----------
def git(*args):
    r = subprocess.run(['git', '-C', REPO] + list(args), stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return r.returncode, r.stdout.decode('utf-8', 'replace').splitlines()


def show(lines):
    for l in lines:
        if l.strip():
            print('    ' + l)


# ---------- path rewriting ----------
# Inside .json/.jsonl a Windows path is written with doubled backslashes (C:\\Users\\2031), elsewhere plain.
# A Mac path looks the same in both, so the direction Mac -> repo must pick the spelling by file type.
# A match must not continue with a letter/digit/_ (so /Users/me never matches /Users/meg).
def path_map(pairs, spelling):
    m = {}
    for a, b in pairs:
        if a == b:
            continue
        if spelling in ('json', 'both'):
            m[a.replace('\\', '\\\\')] = b.replace('\\', '\\\\')
        if spelling in ('plain', 'both'):
            m[a] = b
    keys = sorted(m, key=len, reverse=True)
    pat = re.compile('(?:' + '|'.join(re.escape(k) for k in keys) + ')(?![A-Za-z0-9_])') if keys else None
    return m, pat


_to_local = [(CANON_PROJECT, REPO), (CANON_DESKTOP, DESKTOP), (CANON_HOME, HOME), (CANON_SLUG, LOCAL_SLUG)]
_to_repo = [(REPO, CANON_PROJECT), (DESKTOP, CANON_DESKTOP), (HOME, CANON_HOME), (LOCAL_SLUG, CANON_SLUG)]
TO_LOCAL = {'json': path_map(_to_local, 'json'), 'plain': path_map(_to_local, 'plain')}
TO_REPO = {'json': path_map(_to_repo, 'json'), 'plain': path_map(_to_repo, 'plain')}


def spelling(path):
    return 'json' if os.path.splitext(path)[1].lower() in ('.json', '.jsonl') else 'plain'


def convert(b, pm):
    m, pat = pm
    if pat is None:
        return b
    t = b.decode('utf-8', 'surrogateescape')
    n = pat.sub(lambda x: m[x.group(0)], t)
    return b if n == t else n.encode('utf-8', 'surrogateescape')


def h(b):
    return hashlib.sha256(b).hexdigest()


def complete_lines(b):                           # a transcript may be half-written right now
    i = b.rfind(b'\n')
    return b[:i + 1]


def read(p):
    try:
        with open(p, 'rb') as f:
            return f.read()
    except FileNotFoundError:
        return None


def write(p, b):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    tmp = p + '.pamsync_tmp'
    with open(tmp, 'wb') as f:
        f.write(b)
    os.replace(tmp, p)


# ---------- what this Mac synced last time ----------
STATE_FILE = os.path.join(HOME, 'Library', 'Application Support', 'PAM_sync', 'git_state_%s.json' % LOCAL_SLUG)
state = {}                                       # key -> {"r": repo hash, "rn": repo length, "l": local hash, "n": local length}


def load_state():
    global state
    try:
        with open(STATE_FILE, 'r', encoding='utf-8') as f:
            state = json.load(f)
    except (FileNotFoundError, ValueError):
        state = {}


def save_state():
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE + '.tmp', 'w', encoding='utf-8') as f:
        json.dump(state, f)
    os.replace(STATE_FILE + '.tmp', STATE_FILE)


def remember(key, R, L):
    state[key] = {'r': h(R), 'rn': len(R), 'l': h(L), 'n': len(L)}


def starts_with(b, n, hx):                       # first n bytes of b hash to hx?
    return len(b) >= n and h(b[:n]) == hx


stats = {'exported': 0, 'imported': 0, 'conflicts': 0, 'too big': 0, 'failed': 0}


def sync_file(key, local_path, repo_path, direction, rewrite):
    """key = path inside the repo (claude/...). direction = 'export' (Mac -> repo) or 'import' (repo -> Mac)."""
    ext = os.path.splitext(local_path)[1].lower()
    is_text = rewrite and ext in TEXT_EXT
    sp = spelling(local_path)
    to_repo = (lambda b: convert(b, TO_REPO[sp])) if is_text else (lambda b: b)
    to_local = (lambda b: convert(b, TO_LOCAL[sp])) if is_text else (lambda b: b)
    L = read(local_path)
    if L is not None and ext == '.jsonl':
        L = complete_lines(L)
    R = read(repo_path)
    s = state.get(key)

    if direction == 'export':
        if L is None:
            return
        if s and h(L) == s['l']:
            return                                               # unchanged on this Mac
        if len(L) > MAX_BYTES:
            stats['too big'] += 1
            say('  TOO BIG for GitHub, not synced: ' + local_path, YELLOW)
            return
        if R is None:
            new = to_repo(L)
        elif s and h(R) == s['r']:                               # repo unchanged since last sync
            if starts_with(L, s['n'], s['l']):
                new = R + to_repo(L[s['n']:])                    # normal case: transcript grew
            else:
                new = to_repo(L)                                 # rewritten (e.g. a title file)
        elif not s:                                              # first sync of this file
            full = to_repo(L)
            if full == R:
                remember(key, R, L)
                return
            if full.startswith(R):
                new = full
            elif R.startswith(full):
                return                                           # repo is newer: import handles it
            else:
                new = None
        else:
            new = None                                           # changed here AND elsewhere
        if new is None:
            c = os.path.join(REPO, 'claude', 'conflicts', PC, key[len('claude/'):])
            write(c, to_repo(L))
            stats['conflicts'] += 1
            say('  CONFLICT (changed on this Mac AND elsewhere): ' + key, YELLOW)
            say('    kept both: this Mac\'s copy is also saved as ' + c, YELLOW)
            return
        write(repo_path, new)
        remember(key, new, L)
        stats['exported'] += 1
        return

    # import
    if R is None:
        return
    if s and h(R) == s['r']:
        return                                                   # repo unchanged
    if L is None:
        new = to_local(R)
    elif s and h(L) == s['l']:                                   # Mac copy unchanged since last sync
        if starts_with(R, s['rn'], s['r']):
            new = L + to_local(R[s['rn']:])                      # grew elsewhere: add the new lines only
        else:
            new = to_local(R)
    elif not s:
        full = to_repo(L)
        if full == R:
            remember(key, R, L)
            return
        if R.startswith(full):
            new = L + to_local(R[len(full):])
        else:
            return                                               # keep the Mac copy (export reported it)
    else:
        return                                                   # changed on both sides: export reported it
    write(local_path, new)
    remember(key, R, new)
    stats['imported'] += 1


def rel_files(root, skip_top=()):
    res = []
    if not os.path.isdir(root):
        return res
    for d, dirs, files in os.walk(root):
        rd = os.path.relpath(d, root)
        if rd == '.':
            dirs[:] = [x for x in dirs if not any(re.fullmatch(p.replace('*', '.*'), x) for p in skip_top)]
        for f in files:
            if f.endswith('.pamsync_tmp') or f == '.DS_Store':
                continue
            res.append(f if rd == '.' else os.path.join(rd, f))
    return res


LOCAL_PROJ = os.path.join(HOME, '.claude', 'projects', LOCAL_SLUG)
LOCAL_UP = os.path.join(HOME, '.claude', 'uploads')
REPO_TR = os.path.join(REPO, 'claude', 'transcripts')
REPO_UP = os.path.join(REPO, 'claude', 'uploads')
REPO_SIDE = os.path.join(REPO, 'claude', 'desktop-sessions')


def sync_all(direction):
    if direction == 'export':
        rels = rel_files(LOCAL_PROJ, ('memory', 'memory_before_git_*'))
    else:
        rels = rel_files(REPO_TR)
    for rel in rels:
        key = 'claude/transcripts/' + rel.replace(os.sep, '/')
        try:
            sync_file(key, os.path.join(LOCAL_PROJ, rel), os.path.join(REPO_TR, rel), direction, True)
        except Exception as e:
            stats['failed'] += 1
            say('  FAILED: %s - %s' % (rel, e), RED)
    ids = set()
    for d in (LOCAL_PROJ, REPO_TR):
        if os.path.isdir(d):
            ids.update(f[:-6] for f in os.listdir(d) if f.endswith('.jsonl'))
    for i in sorted(ids):
        root = os.path.join(LOCAL_UP if direction == 'export' else REPO_UP, i)
        for rel in rel_files(root):
            r2 = os.path.join(i, rel)
            key = 'claude/uploads/' + r2.replace(os.sep, '/')
            try:
                sync_file(key, os.path.join(LOCAL_UP, r2), os.path.join(REPO_UP, r2), direction, False)
            except Exception as e:
                stats['failed'] += 1
                say('  FAILED: %s - %s' % (r2, e), RED)


# ---------- desktop-app sidebar entries (claude-code-sessions/<account>/<org>/local_*.json) ----------
APP_DATA = os.path.join(HOME, 'Library', 'Application Support', 'Claude')
SESS_ROOT = os.path.join(APP_DATA, 'claude-code-sessions')


def session_dirs():
    res = []
    if os.path.isdir(SESS_ROOT):
        for a in sorted(os.listdir(SESS_ROOT)):
            pa = os.path.join(SESS_ROOT, a)
            if os.path.isdir(pa):
                res += [os.path.join(pa, o) for o in sorted(os.listdir(pa)) if os.path.isdir(os.path.join(pa, o))]
    return res


def activity(text):
    m = re.search(r'"lastActivityAt"\s*:\s*(\d+)', text)
    return int(m.group(1)) if m else 0


def this_project(text):
    try:
        cwd = json.loads(text).get('cwd') or ''
    except ValueError:
        return False
    cwd = cwd.rstrip('/')
    return cwd == REPO or cwd.startswith(REPO + '/')


def export_sidebar():
    if not os.path.isdir(SESS_ROOT):
        say('  (Claude desktop app data not found; sidebar entries skipped)', YELLOW)
        return
    best = {}
    for d in session_dirs():
        for n in os.listdir(d):
            if not (n.startswith('local_') and n.endswith('.json')):
                continue
            t = read(os.path.join(d, n)).decode('utf-8', 'surrogateescape')
            if not this_project(t):
                continue
            if n not in best or activity(t) > activity(best[n]):
                best[n] = t
    for n, t in best.items():
        rp = os.path.join(REPO_SIDE, n)
        old = read(rp)
        if old is not None and activity(old.decode('utf-8', 'surrogateescape')) >= activity(t):
            continue
        write(rp, convert(t.encode('utf-8', 'surrogateescape'), TO_REPO['json']))
        stats['exported'] += 1


def import_sidebar(folder):
    if not os.path.isdir(REPO_SIDE):
        say('  (no sidebar entries in the repo yet)')
        return
    if subprocess.run(['pgrep', '-x', 'Claude'], stdout=subprocess.DEVNULL).returncode == 0:
        say('  The Claude app is running: sidebar NOT updated. Quit it (Claude menu -> Quit, or Cmd+Q), then run sync_pam_sidebar.command', YELLOW)
        return
    target = folder
    if not target:
        newest, nt = None, -1.0
        for d in session_dirs():
            t = max([os.path.getmtime(d)] + [os.path.getmtime(os.path.join(d, f)) for f in os.listdir(d)])
            if t > nt:
                newest, nt = d, t
        if not newest:
            say('  No account folder yet: sign in to the Claude app, open the Code tab once, quit, run again.', YELLOW)
            return
        target = newest
    say('  into ' + target)
    say('  (the account folder the app used most recently; if that is the wrong account, pass --sidebar-folder <folder>)')
    n = 0
    for f in sorted(os.listdir(REPO_SIDE)):
        if not (f.startswith('local_') and f.endswith('.json')):
            continue
        t = convert(read(os.path.join(REPO_SIDE, f)), TO_LOCAL['json']).decode('utf-8', 'surrogateescape')
        t = re.sub(r'"bridgeSessionIds"\s*:\s*\[[^\]]*\]', '"bridgeSessionIds":[]', t)   # Remote Control links belong to the old account
        lp = os.path.join(target, f)
        old = read(lp)
        if old is not None and activity(old.decode('utf-8', 'surrogateescape')) >= activity(t):
            continue
        write(lp, t.encode('utf-8', 'surrogateescape'))
        n += 1
    say('  %d sidebar entries added or updated.' % n)


# ---------- one-time setup ----------
def setup(name, email):
    say('Project: ' + REPO)
    say('== 1. git settings ==')
    for k, v in (('core.autocrlf', 'false'), ('core.quotepath', 'false'), ('core.precomposeunicode', 'true'),
                 ('core.filemode', 'false'), ('http.postBuffer', '524288000')):
        git('config', k, v)
    if name:
        git('config', 'user.name', name)
    if email:
        git('config', 'user.email', email)
    say('  ok')
    say('== 2. Claude memory ==')
    real = os.path.join(REPO, 'claude', 'memory')
    link = os.path.join(LOCAL_PROJ, 'memory')
    os.makedirs(real, exist_ok=True)
    if os.path.islink(link):
        if os.path.realpath(link) == os.path.realpath(real):
            say('  ok        ' + link)
        else:
            say('  WARNING   %s is a link to %s, not to %s - left alone' % (link, os.path.realpath(link), real), YELLOW)
    else:
        if os.path.exists(link):
            bak = link + '_before_git_' + STAMP
            os.rename(link, bak)
            say('  RENAMED   %s -> %s  (compare and merge by hand)' % (link, bak), YELLOW)
        os.makedirs(LOCAL_PROJ, exist_ok=True)
        os.symlink(real, link)
        say('  SYMLINK   %s -> %s' % (link, real))
    for f in ('sync_pam.command', 'sync_pam_sidebar.command'):
        p = os.path.join(REPO, f)
        if os.path.exists(p):
            os.chmod(p, 0o755)
    rc, out = git('config', 'user.name')
    if not ''.join(out).strip():
        say('  NOTE: no git user name/email yet; run again with --git-name and --git-email', YELLOW)
    say('')
    say('Setup done. From now on: double-click sync_pam.command when you start AND when you finish working.', GREEN)


# ================= run =================
def run(a):
    say('PAM sync on %s   repo: %s' % (PC, REPO))
    rc, unmerged = git('diff', '--name-only', '--diff-filter=U')
    if unmerged:
        for p in unmerged:
            say('    ' + p, RED)
        raise RuntimeError('an earlier merge still has unresolved conflicts (files above). Fix them first, or: git merge --abort')

    load_state()
    say('== 1. Claude data of this Mac -> repo ==')
    sync_all('export')
    try:
        export_sidebar()
    except Exception as e:
        stats['failed'] += 1
        say('  sidebar export FAILED: %s' % e, RED)
    save_state()

    say('== 2. commit ==')
    excl = os.path.join(REPO, '.git', 'info', 'exclude')
    rc, st = git('-c', 'core.quotepath=false', 'status', '--porcelain', '-uall')
    for l in st:
        if len(l) < 4:
            continue
        code, p = l[:2], l[3:]
        if ' -> ' in p:
            p = p.split(' -> ')[1]
        p = p.strip('"')
        fp = os.path.join(REPO, p)
        if not os.path.isfile(fp) or os.path.getsize(fp) <= MAX_BYTES:
            continue
        if code != '??':
            raise RuntimeError(p + ' is over 90 MB and already in git: GitHub would refuse the push. Ask Claude how to move it out.')
        os.makedirs(os.path.dirname(excl), exist_ok=True)
        with open(excl, 'a', encoding='utf-8') as f:
            f.write('/' + p + '\n')
        stats['too big'] += 1
        say('  TOO BIG for GitHub, kept on this Mac only (copy it by OneDrive/USB): ' + p, YELLOW)
    rc, out = git('add', '-A')
    if rc:
        show(out)
        raise RuntimeError('git add failed (see above)')
    rc, changes = git('status', '--porcelain')
    if changes:
        say('  %d changed files' % len(changes))
        rc, out = git('commit', '-q', '-m', 'sync from %s %s' % (PC, datetime.datetime.now().strftime('%Y-%m-%d %H:%M')))
        show(out)
        if rc:
            raise RuntimeError('git commit failed')
    else:
        say('  nothing new on this Mac')

    rc, out = git('rev-parse', '--abbrev-ref', 'HEAD')
    branch = out[0] if out else 'main'
    rc, remotes = git('remote')
    has_remote = 'origin' in remotes
    if not has_remote:
        say('  (no GitHub remote: committed locally only)', YELLOW)

    say('== 3. fetch + merge from GitHub ==')
    if has_remote and not a.no_pull:
        rc, out = git('fetch', 'origin')
        show(out)
        if rc:
            raise RuntimeError('git fetch failed (offline? not signed in to GitHub?)')
        rc, _ = git('rev-parse', '--verify', '-q', 'origin/' + branch)
        if rc == 0:
            rc, out = git('merge', '--no-edit', 'origin/' + branch)
            show(out)
            if rc:
                rc2, conf = git('-c', 'core.quotepath=false', 'diff', '--name-only', '--diff-filter=U')
                other = []
                for p in conf:
                    if p.startswith('claude/'):
                        # Claude data changed on both machines: keep this Mac's version, save the other one beside it
                        save = os.path.join(REPO, 'claude', 'conflicts', 'merge_' + STAMP, p[len('claude/'):])
                        rc3, _ = git('checkout', '--theirs', '--', p)
                        if rc3 == 0:
                            write(save, read(os.path.join(REPO, p)))
                        git('checkout', '--ours', '--', p)
                        git('add', '--', p)
                        stats['conflicts'] += 1
                        say('  CONFLICT in %s : kept this Mac\'s version, the other one saved to %s' % (p, save), YELLOW)
                    else:
                        other.append(p)
                if other:
                    say('  MERGE CONFLICT in these files (changed on both computers):', RED)
                    for p in other:
                        say('    ' + p, RED)
                    say('  Fix them (or ask Claude: "resolve the git merge conflicts"), then run this again.', RED)
                    say('  To cancel the merge instead:  git merge --abort', RED)
                    raise RuntimeError('merge stopped at the conflicts listed above (nothing was pushed)')
                git('add', '-A')
                rc, out = git('commit', '-q', '--no-edit')
                show(out)
                if rc:
                    raise RuntimeError('git commit after merge failed')
        else:
            say('  (GitHub repo is still empty)')
    else:
        say('  skipped')

    say('== 4. repo -> Claude data of this Mac ==')
    sync_all('import')
    save_state()
    if a.import_sidebar:
        import_sidebar(a.sidebar_folder)
    else:
        say('  (sidebar not touched; to show the sessions in the app sidebar: quit Claude, run sync_pam_sidebar.command)')

    say('== 5. push to GitHub ==')
    if has_remote and not a.no_push:
        rc, out = git('push', '-u', 'origin', branch)
        show(out)
        if rc:
            raise RuntimeError('git push failed (see above)')
    else:
        say('  skipped')


def main():
    ap = argparse.ArgumentParser(description='Two-way sync of the PAM project with GitHub (Mac).')
    ap.add_argument('--setup', action='store_true', help='one-time setup on this Mac (safe to run again)')
    ap.add_argument('--git-name', default='')
    ap.add_argument('--git-email', default='')
    ap.add_argument('--import-sidebar', action='store_true')
    ap.add_argument('--sidebar-folder', default='')
    ap.add_argument('--no-push', action='store_true')
    ap.add_argument('--no-pull', action='store_true', help='offline: only commit locally')
    a = ap.parse_args()

    if shutil.which('git') is None:
        say('Git is not installed. Run:  xcode-select --install   then run this again.', RED)
        return 1
    if not os.path.isdir(os.path.join(REPO, '.git')):
        say(REPO + ' is not a git repository. Clone it first (see docs/tools/README_git_sync.md).', RED)
        return 1
    if a.setup:
        setup(a.git_name, a.git_email)
        return 0
    code = 0
    try:
        run(a)
    except Exception as e:
        code = 1
        say('ERROR: %s' % e, RED)
    finally:
        try:
            save_state()
        except Exception as e:
            say('Could not save the sync record: %s' % e, RED)
        print('')
        msg = 'Claude files: ' + ', '.join('%s %d' % (k, v) for k, v in stats.items())
        say(('Done. ' if code == 0 else 'NOT finished. ') + msg, GREEN if code == 0 else RED)
    return code


if __name__ == '__main__':
    sys.exit(main())
