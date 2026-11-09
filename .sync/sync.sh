# Applies new hub updates from the "EuroTrip Hub Sync" Drive folder, then publishes.
# File types: pNNNN.patch (git diff), fNNNN.b64 (base64 tar.gz of full files),
# eNNNN.txt (find/replace blocks: @@@FILE name / @@@OLD / text / @@@NEW / text / @@@END).
set -euo pipefail
mkdir -p .sync
SEQ=$(cat .sync/seq 2>/dev/null || echo 0)
curl -fsSL "https://drive.google.com/embeddedfolderview?id=$FOLDER" -o /tmp/list.html
python3 - "$SEQ" > /tmp/todo.txt <<'PY'
import re, sys
seq = int(sys.argv[1])
h = open('/tmp/list.html', encoding='utf-8').read()
items = re.findall(r'/file/d/([\w-]+)/view.*?flip-entry-title">([^<]+)<', h, re.S)
out = {}
for fid, name in items:
    m = re.fullmatch(r'([pfe])(\d{4})\.(patch|b64|txt)', name.strip())
    if m and int(m.group(2)) > seq:
        out[int(m.group(2))] = (m.group(1), fid)
for n in sorted(out):
    print(n, *out[n])
PY
[ -s /tmp/todo.txt ] || exit 0
cat /tmp/todo.txt
while read -r N KIND FID; do
  curl -fsSL "https://drive.google.com/uc?export=download&id=$FID" -o /tmp/upd
  case "$KIND" in
    p) git apply --whitespace=nowarn /tmp/upd ;;
    f) base64 -d /tmp/upd | tar xz ;;
    e) python3 .sync/edit.py /tmp/upd ;;
  esac
  grep -q '</html>' europe_trip_planner.html
  grep -q 'var BUILD = "' europe_trip_planner.html
  echo "$N" > .sync/seq
done < /tmp/todo.txt
git add -A
git commit -qm "Drive sync to update $(cat .sync/seq)"
git push -q
echo "Published update $(cat .sync/seq)"
