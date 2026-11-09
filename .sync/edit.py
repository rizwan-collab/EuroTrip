import sys
lines = open(sys.argv[1], encoding='utf-8').read().replace('\r\n', '\n').split('\n')
f = None; mode = None; old = []; new = []; edits = []
for ln in lines:
    if ln.startswith('@@@FILE '): f = ln[8:].strip()
    elif ln == '@@@OLD': mode = 'o'; old = []
    elif ln == '@@@NEW': mode = 'n'; new = []
    elif ln == '@@@END': edits.append((f, '\n'.join(old), '\n'.join(new))); mode = None
    elif mode == 'o': old.append(ln)
    elif mode == 'n': new.append(ln)
if not edits: sys.exit('no edits found')
for f, o, n in edits:
    s = open(f, encoding='utf-8').read()
    c = s.count(o)
    if c != 1: sys.exit('edit matched %d times in %s: %r' % (c, f, o[:80]))
    open(f, 'w', encoding='utf-8').write(s.replace(o, n))
print('applied %d edits' % len(edits))
