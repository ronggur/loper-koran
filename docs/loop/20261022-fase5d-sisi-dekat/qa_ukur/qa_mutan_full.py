import subprocess, sys, os, re, time
os.chdir('/Users/ronggur/Works/Games/Loper-Koran/apps/loper-koran')
sys.path.insert(0, 'build')
exec(open('build/qa_mutan.py').read().split("ids = sys.argv")[0])
for i in ['Q2', 'Q12', 'Q13', 'Q17']:
    f, old, new, desc, runner, count = M[i]
    sub(f, old, new, count)
    try:
        t = time.time()
        p = subprocess.run(['godot', '--headless', '--script', 'res://tests/run_tests.gd'], capture_output=True, text=True, timeout=1800)
        out = p.stdout + p.stderr
        ring = re.findall(r'(\d+) lolos, (\d+) gagal', out)
        gagal = [l for l in out.splitlines() if l.startswith('GAGAL')][:2]
        print(i, desc, '=>', ring[-1] if ring else None, gagal, int(time.time() - t), 's', flush=True)
    finally:
        subprocess.run(['git', 'checkout', '--', f], check=True)
        print('  status:', [l for l in subprocess.run(['git', 'status', '--short'], capture_output=True, text=True).stdout.splitlines() if '.claude' not in l and 'qa1' not in l], flush=True)
