# Category Cards Implementation Plan

## Goal
Replace the current chip-based category selection in the search overlay with scrollable cards featuring shadow animation on selection, respecting the color palette.

## Implementation Steps

### 1. Replace FilterChip with Card-based widgets
- Change from `Wrap` with `FilterChip` to `GridView` or `ListView` with `Card` widgets
- Each category will be a visually distinct card

### 2. Add Selection Animation
- Shadow elevation increase when selected
- Border color change when selected
- Scale animation on tap/selection
- Checkmark icon for selected state

### 3. Use Color Palette
- Unselected: color4 (0xFF7A6284)
- Selected: color0 (0xFFC080DD)
- Background: color2 (0xFF38263F)
- Text: White

### 4. Layout Changes
- Use `GridView.builder` with responsive crossAxisCount
- Scrollable cards container
- Appropriate spacing between cards

## Files to Modify
- `frontend/lib/home_screen.dart` - Update search overlay section

## Plan Confirmed
✅ No post counts needed
✅ Shadow animation on selection
✅ Respect color palette
✅ Scrollable cards

