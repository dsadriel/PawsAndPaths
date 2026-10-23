# Project Paws & Paths

## Todo

## In Progress

## Blocked

## Done

### Visual Autotiling and Theme Packs
  - due: 2026-10-30
  - tags: [visuals, themes, cozy]
  - priority: medium
  - workload: Normal
  - defaultExpanded: false
  - steps:
      - [x] Implement decorative track autotiling curves and junctions
      - [x] Add cozy background palettes and theme asset packs
      - [x] Add sound effects and ambient cozy chimes
    ```md
    Polish graphics with illustrated autotiling rail assets, theme DLC expansions, and background ambiance.
    ```

### Campaign Progression & Duolingo Map
  - due: 2026-10-22
  - tags: [campaign, map, progression, navigation]
  - priority: high
  - workload: Normal
  - defaultExpanded: true
  - steps:
      - [x] Implement CampaignLevel and CampaignChapter data models
      - [x] Create CampaignProgressManager for star ratings and unlock persistence
      - [x] Build WindingRoadShape for smooth S-curve Bezier road geometry
      - [x] Build LevelNodeView with 3-star ratings, current mascot indicator, and lock states
      - [x] Build CampaignMapView with scrollable journey and level launch flow
      - [x] Integrate GameView with campaign progression on level completion
    ```md
    Implement an interactive Duolingo-style winding level progression map with stepping stone nodes, star ratings, mascot token, and progression persistence.
    ```

### Mascot Path Runner & Juice
  - due: 2026-10-25
  - tags: [animation, juice, feedback]
  - priority: low
  - workload: Easy
  - defaultExpanded: false
  - steps:
      - [x] Add waypoint path traversal animation for the kitten mascot
      - [x] Add celebratory confetti particle burst on victory
    ```md
    Animate the kitten walking tile-by-tile along the solved path to the yarn ball upon level completion.
    ```

### Core Models and Engine Architecture
  - due: 2026-10-15
  - tags: [core, models, architecture]
  - priority: high
  - workload: Normal
  - defaultExpanded: true
  - steps:
      - [x] Create GridPosition and CellState data structures
      - [x] Build PuzzleLevel model supporting arbitrary NxM grids and seeds
      - [x] Setup deterministic PRNG for reproducible puzzle seeds
    ```md
    Define clean, extensible domain models for the board grid, cell states, puzzle levels, and random seed handling.
    ```

### Procedural Generation and Linear Solver
  - due: 2026-10-18
  - tags: [generator, solver, algorithms]
  - priority: high
  - workload: Hard
  - defaultExpanded: true
  - steps:
      - [x] Implement forward path generation connecting start to goal
      - [x] Implement constraint mapper for row and column Nonogram clues
      - [x] Build deterministic linear deduction solver to guarantee zero-guess solvability
      - [x] Add automated verification tests
    ```md
    Develop the algorithmic pipeline: random-walk forward path carving, clue extraction, and human-like linear line solving to certify 100% solvable puzzles without guesswork.
    ```

### Grid Touch Interaction and Game Loop
  - due: 2026-10-20
  - tags: [ui, interaction, gestures]
  - priority: high
  - workload: Normal
  - defaultExpanded: true
  - steps:
      - [x] Implement NonogramGameViewModel managing grid state and input modes
      - [x] Build interactive NxM grid supporting single-tap and drag-painting
      - [x] Add floating mode pill to toggle between Path and Cross
      - [x] Implement auto-dimming of satisfied row/col clues and victory detection
    ```md
    Provide responsive and fluid touch controls for marking paths and crosses, with zero-stress feedback and dynamic clue satisfaction.
    ```
