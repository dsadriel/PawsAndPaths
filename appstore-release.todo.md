# App Store Release - Paws & Paths

## Todo


### Release & Submission Orchestration (asc-release-flow)
  - due: 2026-10-27
  - tags: [build, archive, asc-release-flow, submission]
  - priority: high
  - workload: Normal
  - defaultExpanded: true
  - steps:
      - [ ] Build and archive IPA using xcodebuild
      - [ ] Validate readiness with asc validate --app APP_ID --version 1.0 --platform IOS
      - [ ] Stage version with asc release stage or publish with asc publish appstore
      - [ ] Test build on physical device via TestFlight
      - [ ] Submit for App Store review with asc review submit --confirm
    ```md
    Execute release build, readiness gate, TestFlight deployment, and final review submission using the asc-release-flow skill.
    ```

## In Progress

### Legal, Privacy & Support Pages (GitHub Pages)
  - due: 2026-10-24
  - tags: [legal, privacy, support, github-pages, compliance]
  - priority: high
  - workload: Easy
  - defaultExpanded: true
  - steps:
      - [x] Create dedicated GitHub Pages website under docs/ (index.html, privacy.html, support.html)
      - [x] Generate PrivacyInfo.xcprivacy manifest file in Xcode project
      - [ ] Connect GitHub remote repository and enable GitHub Pages on /docs folder
      - [ ] Complete App Privacy declarations questionnaire in App Store Connect
    ```md
    Prepare mandatory compliance pages for Apple review hosted on GitHub Pages: privacy policy, support URL, and data privacy declaration.
    ```

## Blocked

## Done

### Audio and Sensory Polish
  - due: 2026-10-25
  - tags: [audio, sfx, haptics, polish]
  - priority: medium
  - workload: Normal
  - defaultExpanded: false
  - steps:
      - [x] Add cozy wooden tile click sound effect on placement
      - [x] Add line/row completion gentle chime sound effect
      - [x] Add victory fanfare/cat purr audio on level completion
      - [x] Pair sound playback with existing HapticManager triggers
    ```md
    Integrate audio effects to achieve the 50% cozy sensory experience promised in the game concept briefing.
    ```

### Identity & Xcode Configuration
  - due: 2026-10-23
  - tags: [xcode, config, signing, branding]
  - priority: high
  - workload: Easy
  - defaultExpanded: false
  - steps:
      - [x] Set commercial name: "Paws & Paths: Cozy Nonogram"
      - [x] Configure CFBundleDisplayName to "Paws & Paths"
      - [x] Change PRODUCT_BUNDLE_IDENTIFIER to "br.com.dsadriel.PawsAndPaths"
      - [x] Lower IPHONEOS_DEPLOYMENT_TARGET from 18.6 to 17.0
      - [x] Lock TARGETED_DEVICE_FAMILY to "1" (iPhone) for focused v1.0
    ```md
    Update Xcode build settings, bundle identifiers, and target definitions to align with App Store requirements and the user's publisher profile.
    ```

### App Icon Generation & Setup
  - due: 2026-10-23
  - tags: [assets, icon, appicon, design]
  - priority: high
  - workload: Normal
  - defaultExpanded: false
  - steps:
      - [x] Generate 1024x1024 px App Icon featuring the kitten mascot and cozy meadow/yarn palette
      - [x] Create AppIcon.appiconset inside Nonogram/Assets.xcassets with Contents.json
      - [x] Enable ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon in project.pbxproj
      - [x] Verify icon renders correctly on dark/light home screens without alpha transparency
    ```md
    Create the official 1024x1024 App Store icon, place it in the asset catalog, and configure build settings.
    ```

### App Store Copy & ASO Metadata
  - due: 2026-10-25
  - tags: [aso, marketing, copy, localization]
  - priority: high
  - workload: Normal
  - defaultExpanded: false
  - steps:
      - [x] Finalize Title (<= 30 chars): "Paws & Paths: Cozy Nonogram"
      - [x] Finalize Subtitle (<= 30 chars): "Caminhos, puzzles e gatinhos"
      - [x] Write rich Portuguese App Store Description with key bullet points
      - [x] Write English App Store Description and localized metadata
      - [x] Set 100-character keyword list optimized for search ranking
      - [x] Select primary category (Games > Puzzle) and secondary (Games > Casual)
      - [x] Store canonical metadata under ./metadata following asc-metadata-sync
    ```md
    Craft high-converting metadata, titles, descriptions, and ASO keywords in Portuguese and English.
    ```

### Automated Screenshots Pipeline (asc-shots-pipeline)
  - due: 2026-10-26
  - tags: [screenshots, marketing, automation, asc-shots-pipeline]
  - priority: high
  - workload: Normal
  - defaultExpanded: false
  - steps:
      - [x] Configure .asc/shots.settings.json and .asc/screenshots.json
      - [x] Capture raw screenshots (-screen map, -screen game, -screen victory, -screen hintOverlay)
      - [x] Frame screenshots with asc screenshots frame --device iphone-17-pro-max
      - [x] Generate review set with asc screenshots review-generate and approve
      - [x] Upload screenshots to App Store Connect using asc screenshots upload / apply
    ```md
    Capture, frame, and upload marketing screenshots to App Store Connect using the asc-shots-pipeline workflow.
    ```

### App Store Connect App Registration
  - due: 2026-10-24
  - tags: [asc, provisioning, app-store]
  - priority: high
  - workload: Easy
  - defaultExpanded: false
  - steps:
      - [x] Register App ID br.com.dsadriel.PawsAndPaths in Apple Developer Portal
      - [x] Create app record in App Store Connect with primary locale (PT-BR or EN-US)
      - [x] Assign SKU br.com.dsadriel.PawsAndPaths
    ```md
    Establish the app record on App Store Connect and ensure proper provisioning profile pairing.
    ```
