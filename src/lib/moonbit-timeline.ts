// MoonBit Timeline Functions
// Import MoonBit module using the mbt: prefix
// @ts-ignore - MoonBit virtual module
import * as timeline from 'mbt:lifelog/mbt/timeline'

export const clamp = timeline.clamp
export const calculateMinutesFromMidnight = timeline.calculate_minutes_from_midnight
export const computeBandPosition = timeline.compute_band_position
export const calculateHorizontalScroll = timeline.calculate_horizontal_scroll
export const formatTime = timeline.format_time

// Type definitions for the MoonBit functions
export type ComputeBandResult = readonly [number, number]
