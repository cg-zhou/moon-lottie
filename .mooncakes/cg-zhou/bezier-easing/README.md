# bezier-easing

A MoonBit implementation of Cubic Bezier easing, perfectly aligned with the core algorithms and behavior of JavaScript's [bezier-easing](https://github.com/gre/bezier-easing).

It projects an input $x \in [0,1]$ onto a cubic bezier curve to obtain the corresponding $y$, making it ideal for animation interpolations such as ease-in, ease-out, or custom curves.

## Features

- MoonBit-native cubic-bezier easing function
- Algorithm aligned with JS `bezier-easing`
  - sample table precomputation
  - Newton-Raphson iteration
  - binary subdivision fallback
- Exact endpoint handling for `x == 0` and `x == 1`
- JS compatibility verification script included

## Install

```sh
moon add cg-zhou/bezier-easing
```

## Quick Example

```moonbit
let easing = @bezier.bezier(0.25, 0.1, 0.25, 1.0)
let y = easing(0.5)
```

## Development

```sh
moon test
moon bench
cd scripts && npm install && npm test
```

## Documentation

- `README.md`: repository overview (this file)
- `README.mbt.md`: MoonBit package documentation for publishing

## License

MIT
