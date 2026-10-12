# Briefing de Produto: *Project Paws & Paths* (Nome provisório)

## 1. Visão Geral e Conceito

Um jogo mobile **cozy (aconchegante)** de lógica estilo *Nonogram*, onde o jogador não revela imagens estáticas e abstratas, mas sim **caminhos de trilhos, canos e rotas de resgate** que permitem a um animalzinho completar sua jornada até um objetivo fofo (um gatinho chegando ao novelo, uma raposinha voltando à toca, etc.).

* **Plataforma:** iOS (foco mobile, retrato).
* **Público-Alvo:** Jogadores casuais, fãs de quebra-cabeças relaxantes (estilo *A Little to the Left*, *Nonogram*, *Tsuki Odyssey*).
* **Pilares de Experiência:** Zero estresse (sem cronômetro ou vidas limitadas), feedback tátil e sonoro recompensador, e progressão visual satisfatória.

---

## 2. Especificações de Design e UX/UI

### Direção Visual & Estética

* **Estilo de Arte:** Flat vector minimalista e aconchegante, inspirado em dioramas isométricos limpos ou arte 2D acolhedora. Cantos arredondados, paletas de cores pastéis/quentes (tons de outono, tons terrosos suaves, azuis e verdes calmantes).
* **Interface (UI):** Sem excesso de poluição visual. Sem barras de energia agressivas. A interface simula elementos físicos de um ateliê de artesanato ou de um diário de campo.

### Feedback Sensorial (O "Juice" Cozy)

* **Tátil (Haptics):** Cliques suaves (utilizando *CoreHaptics* no iOS) que simulam o encaixe de peças de madeira ou cerâmica.
* **Sonoro (SFX):** Efeitos de sinos de vento, carrilhões suaves ao completar linhas corretas, e sons orgânicos (ronrons sutis, água correndo, folhas secas pisadas) quando a fase é concluída.
* **Animações de Conclusão:** Ao fechar o último trilho, o tabuleiro "toca" e uma animação curta e charmosa acontece (ex: o animalzinho corre pelo caminho revelado e ganha uma animação de comemoração).

---

## 3. Arquitetura Técnica & Lógica de Jogo

### Pipeline de Geração Procedural de Nonograms de Caminho

Diferente de um Nonogram tradicional (gerado de imagens pixeladas aleatórias), o gerador procedural deste jogo precisa garantir **redes conexas válidas e solução única lógica**:

1. **Fase 1 - Esqueleto do Caminho (Forward Generation):**
* O algoritmo começa em uma grade vazia ($N \times N$, ex: $10 \times 10$) e traça um caminho válido (ou uma rede ramificada de canos/trilhos) conectando um ponto de partida (o animal) a um ponto de chegada (o destino).


2. **Fase 2 - Extração de Pistas (Constraint Mapping):**
* A matriz do caminho gerado é convertida nas restrições numéricas tradicionais de Nonogram nas margens (linhas e colunas), indicando os blocos contínuos de trilho.


3. **Fase 3 - Validação de Solubilidade Lógica (The Solver Check):**
* Um script validador simula a resolução humana usando apenas dedução lógica linear (cruzamento de pistas).
* *Critério de Aceitação:* Se a fase exigir "chutes" ou adivinhação em qualquer ponto, o gerador a descarta ou adiciona automaticamente dicas fixas iniciais (revelando nós-chave) até que a curva de dedução seja limpa e relaxante.



### Stack Tecnológica Sugerida

* **Engine / Framework:** Swift/SwiftUI (focado nativo em iOS para máxima fluidez de animações e haptics).
* **Gerenciamento de Estado & Dados:** SwiftData
* **Animações:** RiveRuntime ou Lottie para os mascotes e reações animadas fluidas na interface.

---

## 4. Estratégia de Conteúdo e Monetização

### Campanha e Progressão por Temas (In-App Packs)

O jogo base acompanha um mundo principal gratuito (ex: *O Gatinho e o Novelo de Lã* com 30 fases). Os demais temas funcionam como expansões temáticas colecionáveis:

1. A Patinha e o Caminho do Lago
2. A Corujinha e o Galho Secreto
3. A Raposinha e a Toca de Inverno
4. O Cachorrinho e o Ossinho Escondido
5. A Formiguinha e a Folha de Carona
6. O Coelhinho e a Horta de Cenouras
7. A Tartaruga e a Alface na Ilha
8. O Ouriço e o Caminho de Folhas Secas
9. O Hamster e o Labirinto de Tubos

### Modelo de Negócios (Free-to-Play Ético)

* **Moeda Gratuita ("Sementes/Estrelas"):** Obtidas ao resolver Nonograms diários ou refazer fases. Permitem desbloquear temas secundários ao longo do tempo (engajamento de longo prazo).
* **Pacotes Premium (DLCs Temáticas):** Compra única barata (ex: R$ 9,90 por tema) que desbloqueia instantaneamente o mundo temático, acompanhado de uma trilha sonora exclusiva e um avatar especial para o perfil do jogador. Sem anúncios forçados que quebrem o clima relaxante.