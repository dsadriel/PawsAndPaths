# Prompt System — geração de assets (*Paws & Paths*)

> Ferramenta principal: **Gemini / Imagen** (geração) + **Nano Banana** (edição com imagem de referência).
> Estilo: **Cozy Cartoon Flat** — ver [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md).

---

## 1. Como montar um prompt

```
[TIPO DE ASSET] + [SUJEITO] + [POSE/COMPOSIÇÃO] + {STYLE_CORE} + {PALETA DO MUNDO} + {SAÍDA} + {NEGATIVOS}
```

Sempre anexe **1–2 âncoras** de [`design-refs/anchors/`](design-refs/anchors/) como referência de estilo ao usar Nano Banana:

| Âncora | Use para |
|---|---|
| `anchor_props_sheet.jpg` | ⭐ Âncora principal: props, ícones, moedas, itens-objetivo |
| `anchor_kitten_mascot.jpg` | Todos os mascotes (proporção chibi, olhos, blush) |
| `anchor_meadow_scene.jpg` | Fundos/cenários de mundo |

Frase de abertura com referência:
> *"Using the attached image as a strict style reference (same line weight, shading, proportions and level of detail), create…"*

## 2. Blocos reutilizáveis

### `{STYLE_CORE}`
```
Style: cozy cartoon flat vector illustration for a mobile puzzle game. Soft rounded chunky shapes like clay toys. Cel-shading with exactly two tones per color (base fill + one slightly darker shadow tone) plus one small soft highlight. Thin clean outline drawn in a darker shade of each shape's own fill color — never black outlines. Light comes from the top-left. No gradients, no texture, no noise, no realistic lighting.
```

### `{MASCOT_CORE}`
```
Chibi proportions: big head about 50% of total height, tiny round body, short stubby limbs. Simple solid dark-brown dot eyes with a single white sparkle, soft pink round blush cheeks, tiny nose, no visible mouth in neutral pose. Friendly, calm, cozy expression.
```

### `{SAÍDA}` (variações)
| Caso | Texto |
|---|---|
| Sprite isolado | `Single centered subject, generous padding, plain solid flat magenta background (#FF00FF) for easy removal, no ground shadow, no text.` |
| Sheet | `Evenly spaced grid of isolated items, same scale, plain solid flat light cream background (#FFF6E5), no ground shadows, no text.` |
| Fundo de tela | `Vertical 9:16 composition, full-bleed, no text, no characters, no UI.` |

> Use **magenta** como chroma-key em sprites (não verde/creme: os mundos usam muito verde e creme). Remover fundo com `rembg` ou Pixelmator e revisar a borda do contorno.

### `{NEGATIVOS}`
```
Avoid: black outlines, thick uniform outlines, 3D render, glossy plastic, photorealism, gradients, painterly brush texture, anime big eyes, sharp spiky shapes, text, watermark, signature, drop shadow on background.
```

### `{PALETA}` por mundo
| Mundo | Frase |
|---|---|
| Meadow (gatinho) | `Palette: fresh leaf greens, warm wood browns, cream, soft yarn pink accent, pastel sky blue.` |
| Lago (patinha) | `Palette: moss green, calm teal water, lily-pad green, soft yellow accent, cream.` |
| Coruja | `Palette: deep twilight blue, warm lantern yellow accent, bark brown, lavender.` |
| Inverno (raposa) | `Palette: snow white, icy pale blue, warm fox orange accent, pine green.` |
| Cachorro | `Palette: grassy green, warm terracotta, bone cream accent, sky blue.` |
| Formiga | `Palette: big-leaf greens, soil brown, ladybug red accent, sunlit yellow.` |
| Coelho | `Palette: garden green, carrot orange accent, soil brown, soft pink.` |
| Tartaruga | `Palette: tropical turquoise, sand beige, lettuce green accent, coral.` |
| Ouriço | `Palette: autumn amber, golden yellow, rust orange accent, chestnut brown.` |
| Hamster | `Palette: candy pastel tubes (mint, peach, lilac), warm sawdust beige, sunflower yellow accent.` |

## 3. Templates por tipo de asset

### 3.1 Mascote — character sheet
```
Character sheet of a cute chibi {ANIMAL} mascot for a cozy mobile puzzle game. {COLORAÇÃO DO ANIMAL}. {MASCOT_CORE} Show three poses in a row, same scale: 1) idle sitting front view, 2) walking side view facing right, 3) happy jumping with small hearts. {STYLE_CORE} {PALETA} {SAÍDA: Sheet} {NEGATIVOS}
```

### 3.2 Mascote — pose isolada (para animação/Rive)
```
Using the attached mascot sheet as strict character reference, draw the same {ANIMAL} in pose: {POSE}. Keep identical colors, proportions, eye style and line weight. {SAÍDA: Sprite isolado} {NEGATIVOS}
```
Poses padrão: `idle`, `blink`, `walk_1`, `walk_2`, `thinking (looking down at a puzzle, paw on chin)`, `celebrate`, `sleep`.

> Para Rive: peça a pose **neutra frontal com membros separados do corpo** e recorte em partes (cabeça, corpo, cauda, patas) manualmente.

### 3.3 Item-objetivo (fim do caminho)
```
Single prop for a cozy mobile puzzle game: {OBJETO} (the goal the {ANIMAL} wants to reach). 3/4 front-top view, chunky and readable at small size (64px). {STYLE_CORE} {PALETA} {SAÍDA: Sprite isolado} {NEGATIVOS}
```
Exemplos: novelo rosa, toca na neve, ossinho, folha, cenoura, alface, galho com ninho, tigela de leite.

### 3.4 Props de cenário (sheet 3×3)
```
Prop sheet for a cozy mobile puzzle game, 3x3 grid of isolated objects, 3/4 front-top view: {LISTA DE 9 OBJETOS}. {STYLE_CORE} {PALETA} {SAÍDA: Sheet} {NEGATIVOS}
```

### 3.5 Fundo de mundo (tela de jogo)
```
Vertical mobile game background, world "{MUNDO}". Front 3/4 view. Top 20%: {CÉU}. Upper area: {HORIZONTE}. Middle 60%: a large calm empty area of flat {CHÃO}, intentionally clear for the puzzle board overlay — uncluttered. Edges framing the clear area: {PROPS DE BORDA}. Bottom band: {RODAPÉ}. {STYLE_CORE} {PALETA} {SAÍDA: Fundo de tela} {NEGATIVOS}
```

### 3.6 Fundo do mapa de campanha (tile vertical repetível)
```
Seamless vertically tileable background for a level-select map, world "{MUNDO}". Top-down slightly tilted view of {TERRENO}, scattered small {PROPS}, a soft empty winding band through the middle where a road will be drawn by code. Top and bottom edges must match seamlessly. {STYLE_CORE} {PALETA} {SAÍDA: Fundo de tela} {NEGATIVOS}
```

### 3.7 Capa de tema (loja / seleção de mundo)
```
Square cover illustration for a world pack in a cozy mobile puzzle game: the chibi {ANIMAL} (match attached reference) happily next to {OBJETIVO}, in a small {CENÁRIO} vignette, composed inside a rounded square with soft margins. Warm and inviting, hero composition. {STYLE_CORE} {PALETA} No text. {NEGATIVOS}
```

### 3.8 Ícones ilustrados (moedas, dicas, recompensas)
```
Single game icon: {OBJETO}, front view slightly tilted, bold silhouette readable at 32px, chunky with a darker bottom edge for depth. {STYLE_CORE} {SAÍDA: Sprite isolado} {NEGATIVOS}
```
Itens: moeda-semente dourada, estrela, vaga-lume de dica, cadeado de madeira, presente, coração.

### 3.9 Ornamentos de UI (os únicos PNGs da UI)
```
UI ornament for a wooden game panel header: {ORNAMENTO}, symmetrical pair, flat front view. {STYLE_CORE} {SAÍDA: Sprite isolado} {NEGATIVOS}
```
Itens: par de folhinhas para as pontas do ribbon, pregos/rebites, flor de canto.

### 3.10 Ícone do app
```
iOS app icon, square full-bleed (no rounded corners, no border), the chibi kitten (match attached reference) peeking over a wooden board with a yarn trail path forming a simple grid behind it. Strong centered silhouette, readable at 60px. {STYLE_CORE} Palette: warm cream background, wood brown, soft pink. No text. {NEGATIVOS}
```

## 4. Workflow de produção

1. **Gerar** com o template + âncora anexada (gere 4 variações).
2. **Selecionar** a que mais se parece com a âncora (traço, sombra, proporção), não a "mais bonita".
3. **Limpar**: remover fundo, cortar com 8% de padding, exportar PNG.
4. **Exportar** para `Assets.xcassets` em `@2x`/`@3x` (sprites: 3x = 384px para mascote em 128pt).
5. **Nomear**: `{tipo}_{mundo}_{nome}_{variação}` → ex.: `mascot_meadow_kitten_idle`, `prop_winter_pine_01`, `bg_meadow_game`.
6. **Promover a âncora**: o primeiro asset aprovado de cada mundo vira âncora do mundo em `design-refs/anchors/{mundo}/`.

## 5. Checklist de QA de um asset

- [ ] Contorno colorido (nenhum preto puro)
- [ ] Só 2 tons por cor + highlight pequeno
- [ ] Luz de cima-esquerda
- [ ] Mascote: olhos de ponto, blush, cabeça ~50%
- [ ] Legível no tamanho real (teste a 1× no device)
- [ ] Sem texto, marca d'água ou artefato de borda
- [ ] Paleta compatível com os tokens do mundo em `Theme.swift`
