---
name: Deep Network UI
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#393939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#cfc4c5'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#988e90'
  outline-variant: '#4c4546'
  surface-tint: '#c6c6c6'
  primary: '#c6c6c6'
  on-primary: '#303030'
  primary-container: '#000000'
  on-primary-container: '#757575'
  inverse-primary: '#5e5e5e'
  secondary: '#c6c6c7'
  on-secondary: '#2f3131'
  secondary-container: '#454747'
  on-secondary-container: '#b4b5b5'
  tertiary: '#c6c6c6'
  on-tertiary: '#303030'
  tertiary-container: '#000000'
  on-tertiary-container: '#757575'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e2e2e2'
  primary-fixed-dim: '#c6c6c6'
  on-primary-fixed: '#1b1b1b'
  on-primary-fixed-variant: '#474747'
  secondary-fixed: '#e2e2e2'
  secondary-fixed-dim: '#c6c6c7'
  on-secondary-fixed: '#1a1c1c'
  on-secondary-fixed-variant: '#454747'
  tertiary-fixed: '#e2e2e2'
  tertiary-fixed-dim: '#c6c6c6'
  on-tertiary-fixed: '#1b1b1b'
  on-tertiary-fixed-variant: '#474747'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 16px
  md: 24px
  lg: 48px
  xl: 80px
  container-max: 1280px
  gutter: 24px
---

## Brand & Style

The design system is engineered for **COV (Control de Operaciones y Ventas)**, targeting a high-end professional audience that demands both data precision and aesthetic sophistication. The brand personality is tech-forward, authoritative, and futuristic.

The visual direction merges **Minimalism** with **Glassmorphism**. By using a pure black foundation, we create a "limitless" canvas where high-contrast typography and vibrant mesh gradients act as focal points. The interface evokes a premium software feel—reminiscent of high-performance developer tools and modern fintech platforms—utilizing frosted glass layers to maintain depth without cluttering the dark workspace.

## Colors

This design system utilizes a "Void Black" base to maximize the vibrance of the accent salmon and the supporting node-inspired purples.

- **Surface:** The primary background is `#000000`. Secondary surfaces use a slightly lighter `#121212` to create subtle separation.
- **Accent:** `#FF7A8A` (Salmon) is reserved exclusively for interactive elements, primary actions, and status indicators.
- **Mesh Gradients:** Incorporate deep purples (`#8A4FFF`) and magentas to simulate the organic connectivity of the COV logo. Use these sparingly as background glows or within high-profile header cards.
- **Glass Effects:** Use semi-transparent white overlays (`rgba(255, 255, 255, 0.04)`) with high backdrop-blur values (20px+) to create the glassmorphic effect.

## Typography

**Plus Jakarta Sans** is the sole typeface, providing a geometric yet warm feel that balances the "tech" nature of the product. 

- **Weight Usage:** Use Bold (700) for primary headlines to create a strong visual anchor against the black background. Use Medium (500) for labels to ensure legibility.
- **Hierarchy:** High-contrast sizing is essential. Ensure body text is never pure white; use a slightly muted off-white (`#E0E0E0`) to reduce eye strain, while keeping titles pure white (`#FFFFFF`).
- **Responsive:** On mobile devices, scale down the primary headlines to 28px to prevent excessive line-breaking.

## Layout & Spacing

The layout follows a **Fluid Grid** model with generous whitespace to maintain a premium feel.

- **Desktop:** 12-column grid with 24px gutters. Use wide margins (80px+) to center content and create a focused editorial look.
- **Mobile:** 4-column grid with 16px margins. Elements should be full-width or side-by-side (2 columns) for maximum touch area.
- **Rhythm:** All spacing (padding, margin, gaps) must be multiples of 4px. Use `md` (24px) for standard component internal padding and `lg` (48px) for section vertical spacing.

## Elevation & Depth

In a pure black environment, depth is not created with shadows, but through **light and opacity**.

- **Tiers:**
  - **Level 0 (Floor):** Pure Black `#000000`.
  - **Level 1 (Cards):** Frosted glass surface. `background: rgba(255, 255, 255, 0.03)`, `backdrop-filter: blur(24px)`. Include a 1px border with a `glass_stroke` gradient to define the edge.
  - **Level 2 (Modals/Popovers):** Higher opacity glass `rgba(255, 255, 255, 0.08)` with a subtle outer glow using the accent color at 10% opacity.
- **Interactions:** Use "Inner Glows" rather than "Drop Shadows" to make buttons appear as though they are emitting light rather than sitting on top of a surface.

## Shapes

The shape language is consistently **Rounded**.

- **Standard Elements:** Buttons and small input fields use `0.5rem` (8px).
- **Cards & Containers:** Large containers and glassmorphic cards must use `1rem` (16px) or `1.5rem` (24px) to emphasize the soft, modern aesthetic.
- **Full Pill:** Use for tags, chips, and specific toggle switches to contrast against the more structured rectangular cards.

## Components

- **Buttons:** 
  - *Primary:* Solid `#FF7A8A` with pure white text. 24px horizontal padding.
  - *Secondary:* Glassmorphic background with a white border.
- **Input Fields:** Pure black background with a 1px `rgba(255, 255, 255, 0.1)` border. Focus state should shift the border color to the accent Salmon.
- **Cards:** The signature component of this system. Must include the `backdrop-filter: blur(20px)` and a subtle gradient border.
- **Status Chips:** Use small, pill-shaped tags. For operational status, use the Salmon accent for "Active" and a muted purple for "Inactive".
- **Data Visualizations:** Charts and graphs should utilize the node colors from the logo (Magenta to Purple gradients) with thin, high-contrast lines.
- **Navigation:** A sleek, top-fixed glass bar or a minimal left-hand rail that uses high-contrast icons and Salmon-colored active states.