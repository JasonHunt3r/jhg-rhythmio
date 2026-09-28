#!/bin/bash
# Check the docs' own rules (CLAUDE.md, "The docs"). Run at the end of
# every session; it prints each problem and exits 1 if there are any.
#
#   tools/docs-check.sh
#
# 1. spec/status.md is at most 200 lines (the rule is 150; 200 is the alarm).
# 2. status.md has at most 15 lines that start with a date: dated stories
#    belong in spec/history/.
# 3. Every `spec/...` path named in a live doc (spec/*.md, CLAUDE.md, the
#    repo's skills) exists. spec/history/ is skipped: it's left as written,
#    and its old paths (and verbatim/'s relative links) are expected to break.
# 4. Every doc in CLAUDE.md's table exists, and every spec/*.md is in it.
set -uo pipefail
cd "$(dirname "$0")/.."

problems=0
fail() { echo "docs-check: $*"; problems=$((problems + 1)); }

# 1. status.md's length.
lines=$(wc -l < spec/status.md | tr -d ' ')
[ "$lines" -le 200 ] || fail "spec/status.md is $lines lines (rule: 150)"

# 2. Dated stories in status.md: a line whose first words are a date, or a
#    bold or bulleted lead-in carrying one ("**Built 2026-09-27** — ...").
dated=$(grep -cE '^[[:space:]]*([-*0-9.]+[[:space:]]+)?(\*\*)?[^|`]{0,40}\b20[0-9]{2}-[0-9]{2}-[0-9]{2}\b' spec/status.md || true)
[ "$dated" -le 15 ] || fail "spec/status.md has $dated lines starting with a date; move the stories to spec/history/"

# 3. Paths named in live docs.
live_docs=$(ls spec/*.md CLAUDE.md .claude/skills/*/SKILL.md 2>/dev/null)
missing=$(mktemp)
for doc in $live_docs; do
    grep -oE '`spec/[A-Za-z0-9._/*-]+`' "$doc" | tr -d '`' | sort -u | while read -r path; do
        path="${path%[.,:;]}"
        # A glob (spec/history/2026-09-23-crash-hunt*.md) needs one match.
        if [[ "$path" == *"*"* ]]; then
            compgen -G "$path" > /dev/null || echo "docs-check: $doc names $path, which matches nothing"
        elif [ ! -e "$path" ]; then
            echo "docs-check: $doc names $path, which doesn't exist"
        fi
    done
done > "$missing"
if [ -s "$missing" ]; then
    cat "$missing"
    problems=$((problems + $(wc -l < "$missing")))
fi
rm -f "$missing"

# 4. CLAUDE.md's table against spec/.
table=$(grep -oE '^\| `spec/[^`]+`' CLAUDE.md | sed -E 's/^\| `//; s/`$//')
for path in $table; do
    [ -e "$path" ] || fail "CLAUDE.md's table names $path, which doesn't exist"
done
for f in spec/*.md; do
    echo "$table" | grep -qx "$f" || fail "$f isn't in CLAUDE.md's docs table"
done

if [ "$problems" -gt 0 ]; then
    echo "docs-check: $problems problem(s)"
    exit 1
fi
echo "docs-check: ok"
