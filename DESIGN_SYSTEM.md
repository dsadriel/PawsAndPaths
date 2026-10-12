# Design System — *Paws & Paths*

> Direção: **Cozy Cartoon Flat**
> Ilustração = charme de `image copy 4.png` + simplicidade de `image.png`.
> UI = linguagem madeira + creme de `image copy 3.png`, renderizada em *soft flat*.
> Implementação em código: [`Theme.swift`](Nonogram/DesignSystem/Theme.swift).

---

## 1. Princípios

1. **Aconchego tátil** — tudo parece um objeto físico macio (madeira, papel, argila) que dá vontade de apertar.
2. **Legibilidade primeiro** — o tabuleiro é sagrado: contraste alto, zero decoração dentro do grid.
3. **Uma camada base, muitos mundos** — a UI é fixa (marca); cada tema troca só cenário, trilho e acento.
4. **Código para sistemas, IA para personagens** — UI e trilhos são procedurais (SwiftUI); mascotes, props, cenários e capas são ilustrados.

## 2. Linguagem visual

| Aspecto | Regra |
|---|---|
| Render | Flat com cel-shade de **2 tons** (base + sombra) + highlight pequeno. Sem texturas realistas. |
| Contorno | **Fino, colorido** — tom escuro da própria cor (nunca preto). UI: 2pt. Ilustração: ~1.5–2% da largura. |
| Formas | Arredondadas, "fofas", tipo brinquedo de argila. Nada pontiagudo. |
| Profundidade (UI) | **Lábio inferior sólido** (4–6pt) na cor escura do componente. Sem drop shadow difuso grande. |
| Perspectiva | Tabuleiro: top-down ortogonal. Cenário/props: 3/4 frontal-superior. |
| Luz | Vem de cima-esquerda. Sombra sempre embaixo-direita. |

## 3. Cores

### 3.1 Base (fixa em todos os mundos)

| Token | Hex | Uso |
|---|---|---|
| `wood.light` | `#D9935C` | Topo/brilho de madeira |
| `wood.base` | `#B86B3C` | Molduras, header ribbons |
| `wood.dark` | `#8A4A26` | Lábio de madeira |
| `wood.outline` | `#6B3518` | Contorno de madeira |
| `cream.surface` | `#FFF6E5` | Fundo de painel |
| `cream.panel` | `#FBE9C8` | Cartões dentro de painel |
| `cream.inset` | `#F2D8AE` | Campos rebaixados, trilha de progress bar |
| `cream.outline` | `#D9B98A` | Contorno de creme |
| `ink.primary` | `#5A3420` | Texto principal (marrom, nunca preto) |
| `ink.secondary` | `#8C6448` | Texto secundário, pistas satisfeitas |
| `ink.inverse` | `#FFFFFF` | Texto sobre botões coloridos |

### 3.2 Ações (botões / feedback)

| Token | Face | Lábio | Uso |
|---|---|---|---|
| `action.primary` (verde) | `#7BC74D` | `#4E9632` | Play, OK, confirmar, sucesso |
| `action.secondary` (azul) | `#4CB8E8` | `#2E86B8` | Navegação, info |
| `action.danger` (coral) | `#EE6A4E` | `#B8442E` | Fechar, apagar (suave, nunca agressivo) |
| `action.reward` (ouro) | `#F7C548` | `#C9922A` | Moeda, estrelas, compra |
| `action.disabled` | `#C9BFB5` | `#9A9087` | Bloqueado |

### 3.3 Tema de mundo (6 tokens trocáveis)

| Token | Meadow (gatinho) | Winter (raposa) | Autumn (ouriço) |
|---|---|---|---|
| `sky` | `#BFE6F2` | `#D6E8F7` | `#FBE3C2` |
| `ground` | `#8CC97A` | `#EEF4FA` | `#E0A35A` |
| `board` | `#B9D89A` | `#CFE0EE` | `#E9C48F` |
| `boardCell` | `#E4F0CF` | `#F7FBFF` | `#FBEBD3` |
| `track` | `#C98B55` | `#7FA9CF` | `#B5653A` |
| `accent` | `#F28FA8` | `#E86F51` | `#D9883A` |

> Regra: `boardCell` vs `track` precisa ter contraste ≥ 3:1. Valide ao criar tema novo.

## 4. Tipografia

| Estilo | Fonte | Tamanho/Peso | Uso |
|---|---|---|---|
| `display` | Fredoka | 34 / Bold | "Nível concluído!" |
| `title` | Fredoka | 24 / SemiBold | Header de painel (no ribbon) |
| `headline` | Fredoka | 18 / SemiBold | Botões |
| `clue` | Fredoka | 15–20 / SemiBold, **monospacedDigit** | Pistas do Nonogram (escala com o grid) |
| `body` | Nunito | 16 / SemiBold | Texto corrido |
| `caption` | Nunito | 13 / Bold | Labels, contadores |

- Fallback automático: `.system(design: .rounded)` se a fonte não estiver no bundle.
- Títulos em botões/ribbons: branco com **contorno/sombra de 1.5pt** na cor do lábio (como copy 3).

## 5. Grid, espaçamento e forma

- **Espaçamento** (base 4): `xxs 4 · xs 8 · sm 12 · md 16 · lg 24 · xl 32 · xxl 48`.
- **Raio**: `sm 10` (chips, células) · `md 16` (botões) · `lg 24` (painéis) · `pill`.
- **Lábio**: `4pt` (pequenos) · `6pt` (botões/painéis).
- **Contorno UI**: `2pt`.
- **Toque mínimo**: 44×44pt. Célula do grid: mín. 28pt (10×10 em iPhone mini).

## 6. Componentes

| Componente | Anatomia |
|---|---|
| **ChunkyButton** | Face colorida + lábio inferior escuro + contorno 2pt escuro + highlight interno no topo (faixa 30% branca a 25%). Pressionado: face desce = altura do lábio. |
| **WoodPanel** | Moldura `wood.base` com lábio `wood.dark`, miolo `cream.surface` com raio interno = raio − 8. Opcional: **ribbon** de madeira no topo com folhinhas laterais (asset). |
| **CreamCard** | `cream.panel` + contorno `cream.outline`, sem lábio. Para listas dentro de painéis. |
| **CounterPill** | Pill `cream.inset` com ícone ilustrado sobreposto à esquerda + botão "+" circular à direita. |
| **ProgressBar** | Trilha de madeira (`wood.base`, inset) + preenchimento colorido com lábio interno + highlight. |
| **IconButton** | Círculo chunky (lábio 4pt) com ícone SF Symbol `.bold` branco. |
| **Toggle** | Pill creme + knob chunky colorido (verde ON / cinza OFF). |
| **ClueCell** | Fredoka monospaced, `ink.primary`; satisfeita → `ink.secondary` 50% + leve scale 0.95. |
| **BoardFrame** | `board` com raio `lg`, contorno escuro do próprio tom, células `boardCell` com gap de 2pt. |

## 7. Movimento & feedback

| Evento | Animação | Haptic |
|---|---|---|
| Press de botão | Lábio colapsa, `spring(response: 0.25, dampingFraction: 0.6)` | `.soft` light |
| Pintar célula | Pop scale 0.85→1.0, 0.18s | `.rigid` 0.4 |
| Linha completa | Pistas pulam em onda (stagger 30ms) | `.success` leve |
| Vitória | Board "boing" + mascote corre + confete em cores de `accent` | padrão custom |
| Painel abre | Scale 0.9→1 + fade, spring 0.35 | — |

- Nunca usar shake de erro agressivo; erros = leve wobble horizontal 2pt.
- Respeitar **Reduce Motion**: troca springs por fade.

## 8. Acessibilidade

- Texto ≥ 4.5:1 contra o fundo; pistas ≥ 7:1.
- Estados do grid não dependem só de cor (cruz = ícone ✕, caminho = trilho desenhado).
- Suporte a Dynamic Type nas telas fora do tabuleiro.

## 9. Assets ilustrados

Ver [PROMPT_SYSTEM.md](PROMPT_SYSTEM.md). Âncoras aprovadas de estilo ficam em [`design-refs/anchors/`](design-refs/anchors/).
