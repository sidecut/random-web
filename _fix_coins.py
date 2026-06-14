#!/usr/bin/env python3
"""Fix corrupted --coin-heads and --coin-tails CSS variables in index.html."""
import re

# Read original file from git
with open('/tmp/orig_index.html') as f:
    orig = f.read()

# Extract the two coin variable lines from original
heads_orig = re.search(r'--coin-heads:\s*url\(data:image/png;base64,[^)]+\)', orig)
tails_orig = re.search(r'--coin-tails:\s*url\(data:image/png;base64,[^)]+\)', orig)

if not heads_orig or not tails_orig:
    print("ERROR: Could not extract originals from git")
    exit(1)

print(f"Original heads: {len(heads_orig.group())} chars")
print(f"Original tails: {len(tails_orig.group())} chars")

# Read current file
with open('index.html') as f:
    current = f.read()

# Find the corrupted lines in current
heads_curr = re.search(r'--coin-heads:\s*url\(data:image/png;base64,[^)]+\)', current)
tails_curr = re.search(r'--coin-tails:\s*url\(data:image/png;base64,[^)]+\)', current)

if not heads_curr or not tails_curr:
    print("ERROR: Could not find corrupted lines in current file")
    exit(1)

print(f"Current heads: {len(heads_curr.group())} chars")
print(f"Current tails: {len(tails_curr.group())} chars")

# Check if they're actually different
if heads_orig.group() == heads_curr.group():
    print("Heads already match — no change needed for heads")
else:
    print("Heads differ — replacing")

if tails_orig.group() == tails_curr.group():
    print("Tails already match — no change needed for tails")
else:
    print("Tails differ — replacing")

# Replace in current
fixed = current[:heads_curr.start()] + heads_orig.group() + current[heads_curr.end():]
# Re-find tails in the modified content (offsets may have shifted)
tails_curr2 = re.search(r'--coin-tails:\s*url\(data:image/png;base64,[^)]+\)', fixed)
if tails_curr2:
    fixed = fixed[:tails_curr2.start()] + tails_orig.group() + fixed[tails_curr2.end():]

with open('index.html', 'w') as f:
    f.write(fixed)

print("Done — index.html updated")
