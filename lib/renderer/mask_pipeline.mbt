///| Whether a mask mode can participate in the SVG-style composite pipeline.
///| `None` is treated as supported so mixed stacks containing disabled masks can
///| still use the composite path while simply skipping those entries.
fn mask_mode_supported_by_composite(mode : @model.MaskMode) -> Bool {
  match mode {
    @model.MaskMode::Add | @model.MaskMode::LegacyAdd |
    @model.MaskMode::Subtract | @model.MaskMode::Intersect |
    @model.MaskMode::None => true
    _ => false
  }
}

///| Returns true when every mask in the layer can be executed by the composite
///| renderer path instead of falling back to the legacy clip approximation.
pub fn layer_masks_support_composite(masks : Array[@model.Mask]) -> Bool {
  for mask in masks {
    if not(mask_mode_supported_by_composite(mask.mode)) {
      return false
    }
  }
  true
}

///| lottie-web/SVG only keeps masks on the clipPath fast path when they are
///| plain non-inverted additive masks with a static 100% opacity. Any other
///| supported stack needs the SVG-style composite pipeline instead.
fn mask_opacity_can_use_clip_fast_path(
  opacity : @model.LottieProperty[Double],
) -> Bool {
  match opacity.expression {
    Some(_) => false
    None =>
      match opacity.value {
        @model.PropertyValue::Static(value) => value == 100.0
        @model.PropertyValue::Animated(_) => false
      }
  }
}

///| lottie-web/SVG only keeps masks on the clipPath fast path when expansion
///| is a literal zero. Animated or expression-driven expansion always uses
///| `<mask>` semantics instead of clipPath.
fn mask_expansion_can_use_clip_fast_path(
  expansion : @model.LottieProperty[Double],
) -> Bool {
  match expansion.expression {
    Some(_) => false
    None =>
      match expansion.value {
        @model.PropertyValue::Static(value) => value == 0.0
        @model.PropertyValue::Animated(_) => false
      }
  }
}

///| Returns true only for the narrow lottie-web/SVG clipPath fast path:
///| additive masks with no inversion, a static 100% opacity, and literal zero
///| expansion.
fn mask_can_use_clip_fast_path(mask : @model.Mask) -> Bool {
  match mask.mode {
    @model.MaskMode::None => true
    @model.MaskMode::Add =>
      not(mask.inverted) &&
      mask_opacity_can_use_clip_fast_path(mask.opacity) &&
      mask_expansion_can_use_clip_fast_path(mask.expansion)
    @model.MaskMode::LegacyAdd => false
    _ => false
  }
}

///| Mixed stacks, inverted masks, additive masks with non-static/non-100
///| opacity, and any mask using expansion all need the SVG-style composite
///| pipeline instead of clip-only approximation.
pub fn layer_masks_require_composite(masks : Array[@model.Mask]) -> Bool {
  for mask in masks {
    if not(mask_can_use_clip_fast_path(mask)) {
      return true
    }
  }
  false
}

///| Renderer op code for additive mask accumulation.
let mask_compose_add = 1

///| Renderer op code for subtractive mask accumulation.
let mask_compose_subtract = 2

///| Renderer op code for intersecting mask accumulation.
let mask_compose_intersect = 3

///|
pub fn mask_mode_to_composite_code(mode : @model.MaskMode) -> Int {
  match mode {
    @model.MaskMode::Add => mask_compose_add
    @model.MaskMode::LegacyAdd => mask_compose_add
    @model.MaskMode::Subtract => mask_compose_subtract
    @model.MaskMode::Intersect => mask_compose_intersect
    _ => 0
  }
}
