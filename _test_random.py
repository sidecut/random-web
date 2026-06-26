import os, struct, math

# Chi-square critical value for df=99 buckets at p=0.999 — a CSPRNG should
# land below this with overwhelming probability. Hardcoded so the test has
# no scipy/numpy dependency.
CHI2_CRIT_DF99_P999 = 149.45

# Coin-toss z-score limit at p=0.999 for a two-sided normal test.
Z_CRIT_P999 = 3.2905


def chi_square(counts, total):
    """Sum of (observed - expected)^2 / expected across observed buckets.

    Missing buckets contribute 0 to the count but expected must include every
    possible value in the range, otherwise df collapses and the test is weak.
    """
    observed_total = sum(counts.values())
    expected = total / len(counts) if counts else 0
    if expected == 0:
        return 0.0
    chi2 = 0.0
    for c in counts.values():
        chi2 += (c - expected) ** 2 / expected
    # Add contribution from any unobserved buckets (count = 0).
    missing = len(counts) - len([c for c in counts.values() if c > 0])
    if missing > 0:
        chi2 += missing * expected  # (0 - expected)^2 / expected = expected
    return chi2


def z_score_proportion(successes, trials):
    """Two-sided z-score for a binomial proportion vs 0.5."""
    if trials == 0:
        return 0.0
    p = successes / trials
    return (p - 0.5) / math.sqrt(0.25 / trials)


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
N = 100_000
counts, rejects = simulate_random_int(1, 100, N)
vals = list(counts.values())
print(f'Bounds 1-100, {N // 1000}k iterations')
print(f'  Expected per value: ~{N // 100}')
print(f'  Min: {min(vals)}, Max: {max(vals)}, Avg: {sum(vals)/len(vals):.1f}')
print(f'  Rejects: {rejects}')

chi2 = chi_square(counts, N)
print(f'  Chi-square (df=99): {chi2:.2f} (crit {CHI2_CRIT_DF99_P999})')
if chi2 < CHI2_CRIT_DF99_P999:
    print('  PASS')
else:
    print('  CHECK — distribution deviates from uniform')

# Coin toss distribution
n = 1_000_000
heads = sum(1 for b in os.urandom(n) if (b & 1) == 0)
tails = n - heads
print(f'\nCoin toss (even bit = heads), 1M iterations')
print(f'  Heads: {heads} ({heads / n * 100:.3f}%)')
print(f'  Tails: {tails} ({tails / n * 100:.3f}%)')

z = z_score_proportion(heads, n)
print(f'  z-score vs 0.5: {z:+.3f} (|z| crit {Z_CRIT_P999})')
if abs(z) < Z_CRIT_P999:
    print('  PASS')
else:
    print('  CHECK — coin bias exceeds tolerance')
