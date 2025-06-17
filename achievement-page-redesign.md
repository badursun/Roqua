# 🎯 Modern Achievement Page - Implementation Plan

## 📋 Requirements Analysis

### 🔄 Existing Features to Preserve (from AchievementPageView.swift)
**Header Components:**
- Trophy icon with gradient background and shadow
- Award count display with icon (`Award X/Y`)
- Achievement/Award tab system with active indicator
- Adaptive background gradients

**Card Features:**
- Achievement icon with `AchievementIconView.medium(achievement)`
  - **SF Symbol support** via `iconName` property
  - **Custom image support** via `imageName` property with `isCustomImage` detection
  - **Adaptive sizing** with medal frame calculations (20px→32px, 30px→50px, etc.)
  - **Circular clipping** for custom images with shadow effects
- Rarity-based color gradients and badges
- Status text (Completed/Next)
- Progress percentage calculation
- 2-line title with `lineLimit(2)` and `minimumScaleFactor(0.8)`
- Shadow effects and rounded corners
- Unlocked state indicators

**Achievement Detail Sheet:**
- Large medal with outer ring and inner gradients
- Mystery achievement support with sparkle effects
- Progress tracking with remaining count
- Rarity-specific colors and text
- Date formatting for unlocked achievements

**Filter System:**
- `AchievementFilter` enum with "Hepsi"/"Kazanılanlar"
- Icon-based filter representation
- Achievement categorization and filtering logic

**Color Computations:**
- Rarity-based gradients (common→legendary)
- Adaptive dark/light mode backgrounds
- Border and shadow color calculations
- Status-specific progress colors

### 🎨 Color System
**Dark Mode Colors:**
- Background: `#130E20`
- Card Background: `#1F2142`
- Main Text: `#FFFFFF`
- Muted Text: `#8D91A7`
- Progress Bar: `#EB901F → #FFFF45`

**Light Mode Colors:**
- Background: `#F8F9FA`
- Card Background: `#FFFFFF`
- Main Text: `#1A1A1A`
- Muted Text: `#6C757D`
- Progress Bar: `#EB901F → #FFFF45`

### 🏗️ Layout Structure
1. **Navigation**: Back button only, no title
2. **Header**: Achievement title + trophy + stats
3. **Filter Tabs**: Achievement/Award (filter functionality, not TabView)
4. **Grid**: 2x2 uniform cards, 15px gaps
5. **Cards**: Title (2-line fixed) + Icon (55px+) + Badge + Progress
6. **Scroll**: Full page scrollable

## 🚀 Implementation Steps

### Step 1: Color System Setup
**File:** `Roqua/Extensions/Color+App.swift`
- Create adaptive color extension
- Define all app colors with dark/light mode support
- Implement progress gradient colors

### Step 2: Achievement Card Component
**File:** `Roqua/Views/Components/UniformAchievementCard.swift`
- Fixed dimensions for uniform layout
- 2-line title with fixed height (`lineLimit(2)`, `minimumScaleFactor(0.8)`)
- 55px+ icon size using `AchievementIconView.medium(achievement)`
- Badge positioning (consistent across cards) with rarity names
- Progress bar at bottom with percentage display
- Monochrome state for unlocked achievements
- 20px internal padding
- Rarity-based gradient backgrounds (common→legendary)
- Status text (Completed/Next)
- Shadow effects with adaptive colors

### Step 3: Header Component
**File:** `Roqua/Views/Components/AchievementHeader.swift`
- Trophy icon with gradient background (orange→yellow) and shadow
- Award count display (`Award X/Y`) with star icon
- Filter tabs (Achievement/Award) with active state indicators
- Active filter indicator with progress colors
- State management for filter selection
- Preserve existing `AchievementFilter` enum structure
- Achievement manager integration for live stats

### Step 4: Grid Layout System
**File:** `Roqua/Views/ModernAchievementPageView.swift`
- 2x2 LazyVGrid with 15px spacing
- Proper horizontal padding for stack compatibility
- ScrollView container for full page scroll
- Navigation bar customization (back button only)

### Step 5: Filter Logic Integration
- Achievement/Award filter functionality using existing `AchievementFilter` enum
- Maintain existing categorization and sorting from `AchievementPageView.swift`
- Filter state binding between header and main view
- Preserve `filteredAchievements` computed property logic
- Achievement manager integration for progress tracking
- Detail sheet integration with existing `AchievementDetailSheet`

### Step 6: Dark/Light Mode Testing
- Test all color combinations
- Verify adaptive behavior
- Ensure contrast ratios are proper

## 📏 Design Specifications

### Card Specifications
- **Dimensions**: Uniform across all cards
- **Icon Size**: Minimum 55px
- **Title**: 2 lines, fixed height
- **Padding**: 20px internal
- **Gap**: 15px between cards
- **Badge**: Consistent positioning
- **Progress**: Bottom aligned, full width

### Layout Specifications
- **Grid**: 2 columns, flexible rows
- **Spacing**: 15px horizontal/vertical gaps
- **Margins**: Compatible with view stack padding
- **Scroll**: Vertical, full page height

### Color Specifications
- **Adaptive**: Automatic dark/light mode switching
- **Contrast**: WCAG compliant text contrast
- **Progress**: Gradient from orange to yellow
- **States**: Active, inactive, monochrome (unlocked)

## ✅ Success Criteria
- [ ] All cards have identical dimensions and layout
- [ ] Icons are minimum 55px and properly scaled
- [ ] Titles are exactly 2 lines with consistent height
- [ ] 15px gaps between all cards
- [ ] 20px internal card padding
- [ ] Filter tabs work as filters, not navigation
- [ ] Monochrome state for unlocked achievements
- [ ] Full page scroll functionality
- [ ] Back button only in navigation
- [ ] Perfect dark/light mode color adaptation
- [ ] Maintains existing achievement categorization
- [ ] Compatible with existing AchievementPageView.swift structure

## 🔄 Implementation Order
1. Color system foundation
2. Card component (most critical)
3. Header with filter tabs
4. Grid layout integration
5. Filter logic connection
6. Testing and refinement

---

**Ready to start implementation?** 