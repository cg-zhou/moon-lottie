import type * as MoonBit from "./moonbit.d.ts";

export function get_in_point(player: any): MoonBit.Double;

export function update_player(player: any,
                              frame: MoonBit.Double): MoonBit.Unit;

export function get_version(player: any): MoonBit.String;

export function get_fps(player: any): MoonBit.Double;

export function get_height(player: any): MoonBit.Int;

export function get_width(player: any): MoonBit.Int;

export function get_frame_count(player: any): MoonBit.Double;

export function update_player_with_speed(player: any,
                                         frame: MoonBit.Double,
                                         speed: MoonBit.Double): MoonBit.Double;

export function create_player_from_js(): MoonBit.UnboxedOption<any>;
