# bezier-easing

A MoonBit implementation of **Cubic Bezier easing**, aligned with the core algorithms and behavior of JavaScript's bezier-easing.

**Repository:** [https://github.com/cg-zhou/bezier-easing](https://github.com/cg-zhou/bezier-easing)

This library projects an input $x \in [0,1]$ onto a cubic bezier curve to obtain the corresponding $y$, suitable for animation interpolations (ease-in / ease-out / ease-in-out / custom curves).

## Features

- Numerical strategy consistent with the JS version: Sample Table + Newton-Raphson + Binary Subdivision.
- Balanced performance and precision (11 samples, 4 Newton iterations).
- Exact endpoints guaranteed for `x == 0` and `x == 1`.
- Fails immediately on invalid control point parameters (`x1` or `x2` not in `[0,1]`).

## Install

```sh
moon add cg-zhou/bezier-easing
```

## Quick Start

```moonbit
let easing = @bezier.bezier(0.25, 0.1, 0.25, 1.0)
let y0 = easing(0.0) // 0.0
let y1 = easing(0.5)
let y2 = easing(1.0) // 1.0
```

Equivalent to CSS `cubic-bezier(x1, y1, x2, y2)`.

## API

- `bezier(x1 : Double, y1 : Double, x2 : Double, y2 : Double) -> (Double) -> Double`

Description:
- `bezier` is the primary entry point, returning an easing function.

## Behavior & Constraints

- Requires control point X-coordinates to satisfy: `0 <= x1 <= 1` and `0 <= x2 <= 1`.
- If requirements are not met, the function will fail immediately (aligned with JS `throw` behavior).
- No additional clamping is performed on the easing input `x`, however `x == 0` and `x == 1` return exact endpoints.
- Returns an identity function for linear curves (`x1 == y1 && x2 == y2`).

## Precision Strategy

The implementation follows the same heuristic workflow as the JS version:

1. Precompute 11 sample points for initial guess estimation.
2. Use Newton-Raphson for fast convergence when slope is sufficient.
3. Fall back to binary subdivision for stability when slope is too small.

Constants:
- Newton iterations: `4`
- Newton min slope: `0.001`
- Subdivision precision: `1e-7`
- Subdivision max iterations: `10`

## Development

### Tests

```sh
moon test
```

### Benchmarks

```sh
moon bench
```

### Compare with JS

```sh
cd scripts && npm install && npm test
```

This script performs side-by-side comparison between MoonBit and JS outputs across multiple control points and samples.

## License

MIT
