"""Two arms of an interleaved route-bench chain, round by round (s35, f35; s34 had s34_stats in the scratchpad).
    python -I bench\\pair_stats.py bench\\s35.out r35 n35        (arm B - arm A per round; rounds a b c d)
Reads the result lines bench-route-ls prints: per spot the looks' game fps / GPU ms and the 25 s walk's game fps / 1% low /
GPU ms / frames over 50 and 100 ms, and the ROUTE line (the mean of the 3 spots' looks)."""
import re, sys, statistics as st

path, A, B = sys.argv[1], sys.argv[2], sys.argv[3]
rounds = sys.argv[4] if len(sys.argv) > 4 else 'abcd'
spots = ['Kokiri', 'HyruleField', 'Town']
R = {}
for l in open(path, encoding='utf-8-sig').read().splitlines():
    m = re.search(r'\[(\w+)\] (Kokiri|HyruleField|Town): start (\d+) s \| game fps ([\d.]+) .*?GPU ([\d.]+) ms .*?>=50ms (\d+) >=100ms (\d+) .*?'
                  r'walk: game fps ([\d.]+) \| shown ([\d.]+) \(1% low ([\d.]+)\) \| GPU ([\d.]+) ms \| >=50ms (\d+) >=100ms (\d+)', l)
    if m:
        R[(m.group(1), m.group(2))] = dict(start=int(m.group(3)), fps=float(m.group(4)), gpu=float(m.group(5)), h50=int(m.group(6)),
                                           h100=int(m.group(7)), wfps=float(m.group(8)), wlow=float(m.group(10)), wgpu=float(m.group(11)),
                                           w50=int(m.group(12)), w100=int(m.group(13)))
    m = re.search(r'\[(\w+)\] ROUTE \(3 spots\): game fps ([\d.]+) \| 1% low ([\d.]+) \| GPU ([\d.]+) ms', l)
    if m:
        R[(m.group(1), 'ROUTE')] = dict(fps=float(m.group(2)), low=float(m.group(3)), gpu=float(m.group(4)))
have = [r for r in rounds if (A + r, 'ROUTE') in R and (B + r, 'ROUTE') in R]
if not have:
    sys.exit('no complete round yet')
def g(a, r, s, k): return R[(a + r, s)][k]
def sd(v): return st.stdev(v) if len(v) > 1 else 0.0
print(f'{path}: {B} against {A}, rounds {"".join(have)}')
print('ROUTE game fps / GPU ms per round')
for a in (A, B):
    f = [g(a, r, 'ROUTE', 'fps') for r in have]; gp = [g(a, r, 'ROUTE', 'gpu') for r in have]
    print(f'  {a}: fps {f} mean {st.mean(f):.2f} | GPU {gp} mean {st.mean(gp):.2f}')
d = [g(B, r, 'ROUTE', 'fps') - g(A, r, 'ROUTE', 'fps') for r in have]
dg = [g(B, r, 'ROUTE', 'gpu') - g(A, r, 'ROUTE', 'gpu') for r in have]
print(f'  {B}-{A}: fps {[round(v, 1) for v in d]} mean {st.mean(d):+.2f} (min {min(d):+.1f}, max {max(d):+.1f}, sd {sd(d):.2f}) '
      f'| GPU {[round(v, 2) for v in dg]} mean {st.mean(dg):+.2f}  -> {B} wins {sum(v > 0 for v in d)} of {len(d)} rounds')
print('WALKS (25 s): game fps (min-max), 1% low, GPU ms, frames >=50 / >=100 ms summed; mean of the rounds')
for s in spots:
    line = f'  {s:12s}'
    for a in (A, B):
        w = [g(a, r, s, 'wfps') for r in have]
        line += (f' | {a} {st.mean(w):.1f} ({min(w):.1f}-{max(w):.1f}) low {st.mean([g(a, r, s, "wlow") for r in have]):.1f} '
                 f'{st.mean([g(a, r, s, "wgpu") for r in have]):.2f} ms h {sum(g(a, r, s, "w50") for r in have)}/{sum(g(a, r, s, "w100") for r in have)}')
    print(line)
    dw = [g(B, r, s, 'wfps') - g(A, r, s, 'wfps') for r in have]
    print(f'      walk {B}-{A}: {[round(v, 1) for v in dw]} mean {st.mean(dw):+.2f}')
print('LOOKS per spot: game fps (min-max), GPU ms, frames >=50 / >=100 ms summed')
for s in spots:
    line = f'  {s:12s}'
    for a in (A, B):
        w = [g(a, r, s, 'fps') for r in have]
        line += (f' | {a} {st.mean(w):.1f} ({min(w):.1f}-{max(w):.1f}) {st.mean([g(a, r, s, "gpu") for r in have]):.2f} ms '
                 f'h {sum(g(a, r, s, "h50") for r in have)}/{sum(g(a, r, s, "h100") for r in have)}')
    dl = [g(B, r, s, 'fps') - g(A, r, s, 'fps') for r in have]
    print(line + f' | {B}-{A} {[round(v, 1) for v in dl]}')
for a in (A, B):
    v = [g(a, r, s, 'start') for r in have for s in spots]
    print(f'  {a} start s: {v} mean {st.mean(v):.0f}')
