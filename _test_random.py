import os, struct

def simulate_random_int(min_val, max_val, iterations=100_000):
    range_size = max_val - min_val + 1
    max_uint32 = 0xFFFFFFFF
    max_valid = max_uint32 - (max_uint32 % range_size)
    counts, rejects = {}, 0
    for _ in range(iterations):
        while True:
            val = struct.unpack('<I', os.urandom(4))[0]
            if val < max_valid:
                result = min_val + (val % range_size)
                counts[result] = counts.get(result, 0) + 1
                break
            rejects += 1
    return counts, rejects

# Test 1-100
counts, rejects = simulate_random_int(1, 100, 100_000)
vals = counts.values()
print(f'Bounds 1-100, 100k iterations')
print(f'  Expected per value: ~1000')
print(f'  Min: {min(vals)}, Max: {max(vals)}, Avg: {sum(vals)/len(vals):.1f}')
print(f'  Rejects: {rejects}')
print(f'  PASS' if max(vals)/min(vals) < 1.25 else '  CHECK')

# Coin toss distribution
n = 1_000_000
heads = sum(1 for b in os.urandom(n) if (b & 1) == 0)
tails = n - heads
print(f'\nCoin toss (even bit = heads), 1M iterations')
print(f'  Heads: {heads} ({heads/n*100:.3f}%)')
print(f'  Tails: {tails} ({tails/n*100:.3f}%)')
print(f'  PASS' if abs(heads/n - 0.5) < 0.003 else '  CHECK')
