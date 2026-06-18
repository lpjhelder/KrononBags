# KrononBags

Bag unificada para World of Warcraft retail (Midnight / 12.0.x), feita do zero com a API pública — parte do ecossistema de addons da guilda **Kronon**.

## Recursos
- Bolsa unificada com botões nativos (usar / equipar / abrir / vender).
- **Banco e Banco da Brigada (warband)**: abas Mochila / Banco / Brigada na mesma janela, substituindo o banco nativo. Botão de depositar automático.
- **Banco consultável de qualquer lugar**: o conteúdo do Banco e da Brigada é salvo quando você abre o banco e fica consultável de longe (só leitura), com a hora do último retrato. Comando `/kb banco`.
- Categorias ordenáveis: prontas (Favoritos, Pedra-chave, Equipamento, Consumíveis, Reagentes, Materiais, Missão, Lixo) + categorias suas. Arraste um item pro cabeçalho de uma categoria pra atribuí-lo (ou pra Favoritos).
- **Categorias dinâmicas por regra** (ex: `ilvl>200 & boe`), **ordenação** configurável (ilvl/qualidade/nome/tipo/recentes) e **empilhar** itens iguais.
- Agrupa PvP/PvE pelos Conjuntos de Equipamento do jogo, com botão "Equipar".
- No ícone: item level, **borda colorida por raridade**, selo de vínculo (BoE/Warband), destaque de item novo, cooldown, borda de missão, **seta de upgrade (Pawn)** e **estrela de qualidade de reagente (T1-T3)**.
- Favoritar pela estrela (protege de venda). Rodapé com ouro, currencies, slots livres e valor do lixo. **Botão "Vender lixo"** no vendedor.
- **Auto-vender lixo** e **auto-reparar** ao abrir o vendedor (reparo usa fundos da guilda quando disponível; cada um liga/desliga na config).
- **Busca avançada**: `ilvl>200`, `q:epico`, `tipo:armadura`, palavras (`boe`, `wb`, `missao`, `lixo`, `equip`…) e operadores `& | !` com parênteses. Modo "realçar" (escurece o resto) ou "esconder".
- Modo grade, seções recolhíveis e organizar automático. Posição da janela lembrada por personagem.
- **Compatível com controle (ConsolePort)**: a janela se registra no cursor de interface e a grade de itens é navegável na ordem certa pelo direcional (a estrela e a barra de rolagem ficam fora da navegação pra não atrapalhar).
- Altura máxima com **barra de rolagem** (roda do mouse ou barra) — não estoura a tela mesmo com banco/inventário cheios. Alça no canto inferior direito redimensiona colunas e altura.
- Seção "Recém-obtidos" no topo: os itens novos ficam ali (o brilho some ao passar o mouse, mas o item permanece) até você clicar em **Distribuir** no cabeçalho, que manda tudo pras categorias certas. Clique-direito no cabeçalho de uma categoria: recolher/expandir todas, favoritar a categoria, guardar tudo no banco.
- **Export/Import de categorias** (Layout Oficial da Guilda) na config. **Contagem de itens nos alts** no tooltip. **Prontidão de Raide/M+** (`/kb pronto`).
- Carga assíncrona dos itens (ilvl/vínculo corretos mesmo logo após login, com cache frio).
- Dois visuais na config: Escuro ou estilo Blizzard.

Substitui a bag do jogo: a tecla B, os ícones das bolsas e qualquer atalho de bag abrem o KrononBags (desligável na config).

## Comandos
- `/kb` — abre/fecha a bag.
- `/kb config` — configurações.
- `/kb grade` — alterna a visão em grade.
- `/kb organizar` — organiza automático.
- `/kb pronto` — painel de Prontidão de Raide/M+.
- `/kb banco` — consulta o banco/Brigada salvos (de qualquer lugar).

## Publicação
Tag no git (`git tag vX.Y.Z && git push --tags`) → GitHub Actions empacota e publica no CurseForge automaticamente (BigWigs Packager).

Discord da guilda: https://discord.gg/yFdQsFewN3
