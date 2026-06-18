# Changelog

## 0.20.1
- **Navegação por controle (ConsolePort), parte 2.** A v0.20.0 ainda pulava seção ao descer e não ia pra célula vizinha ao lado. O motivo: os **cabeçalhos de categoria são de largura total**, e o cursor geométrico do ConsolePort os enxergava como candidato em quase toda direção. Agora os cabeçalhos (e os botões "Equipar" e "Distribuir") ficam **fora da navegação por controle** — o cursor passa a enxergar só a grade de itens, que vira uma grade uniforme de verdade (esquerda/direita/cima/baixo previsíveis). No mouse, recolher/Equipar/Distribuir continuam funcionando normalmente.

## 0.20.0
- **Itens do Gerenciador de Equipamento viram favoritos automáticos.** Toda peça salva num Conjunto de Equipamento agora aparece com a estrela (em tom azulado, pra diferenciar do favorito manual) e fica **protegida de venda automaticamente** — mesmo com a opção "Proteger itens" desligada. Sincroniza sozinho: tirou do conjunto, deixa de ser favorito. Não dá pra desfavoritar pela estrela (é automático); tire o item do conjunto pra liberar.
- **Auto-vender lixo e auto-reparar.** Ao abrir um vendedor, o KrononBags pode vender todos os itens cinza e reparar tudo automaticamente — tentando os **fundos da guilda** primeiro (se você tiver permissão e houver saldo) e caindo pro seu ouro só se precisar. Avisa no chat quanto gastou e de onde. Liga/desliga cada um em `/kb config` (ambos ligados por padrão).
- **Navegação por controle (ConsolePort) consertada.** Antes, mover entre os itens com o direcional pulava seções e não seguia a ordem. O motivo: cada item tinha a estrela de favoritar sobreposta no canto, e o ConsolePort a tratava como um item navegável concorrente — centenas de "nós" extras grudados nos itens bagunçavam o cálculo de vizinho mais próximo. Agora a estrela e a barra de rolagem ficam fora da navegação por controle (não muda nada no mouse), a grade de itens fica limpa e o cursor anda na ordem certa, seção por seção, com rolagem automática do conteúdo. A janela também passa a se registrar direto no cursor do ConsolePort.

## 0.19.0
- **Banco consultável de qualquer lugar.** Agora dá pra ver o que você tem guardado no **Banco** e no **Banco da Brigada** sem estar no banco — o KrononBags salva um retrato do conteúdo toda vez que você abre o banco. As abas Banco/Brigada ficam disponíveis na janela mesmo longe do banco, mostrando o último estado salvo (com a hora da captura). É **só consulta**: pra mover/sacar é preciso ir até o banco (o jogo não deixa de longe). Comando novo: `/kb banco`.

## 0.18.0
- **Borda colorida por raridade** no ícone: incomum/raro/épico/lendário ganham borda na cor da raridade, lixo fica com borda cinza (comum/branco fica sem borda, pra não poluir). Leitura visual bem mais rápida. Liga/desliga em `/kb config`.
- **Realçar busca.** Ao buscar, em vez de esconder o que não bate, o KrononBags **escurece** os itens que não batem e mantém os que batem acesos — você não perde a noção de onde as coisas estão. Pode voltar pro modo "esconder" na config.

## 0.17.0
- **"Recém-obtidos" agora segura os itens.** Antes o item saía da seção assim que você passava o mouse. Agora ele **fica** em Recém-obtidos (o brilho some quando você olha, mas o item permanece) até você clicar no botão **Distribuir**, no cabeçalho da seção — aí cada item vai pra sua categoria certa de uma vez. Dá pra arrastar um item pro cabeçalho "Recém-obtidos" pra recolocá-lo lá. A lista de recém-obtidos é lembrada entre sessões.

## 0.16.0
- **Categorias dinâmicas por regra.** Numa categoria sua, clique em **Regra** (na config) e defina uma busca (ex: `ilvl>200 & boe`, `tipo:armadura`, `q:epico`) — a categoria se preenche e atualiza sozinha. Mesma sintaxe da busca.
- **Ordenação configurável** dentro da categoria: Item level, Qualidade, Nome, Tipo ou Recentes (config → "Ordenar por").
- **Empilhar itens iguais** (opção na config): junta stacks do mesmo item num ícone só com a contagem somada. O tooltip avisa que a ação afeta 1 stack.

## 0.15.0
- **Arrastar item pra categoria.** Pegue um item e solte no cabeçalho de uma categoria pra jogá-lo ali (categoria sua ou pré-pronta). Soltar em **Favoritos** favorita; soltar em **Diversos** tira da categoria (volta pro automático). O cabeçalho destaca ao passar por cima.

## 0.14.0
- **Substitui a bag do jogo.** Agora a tecla B, clicar nos ícones das bolsas e qualquer atalho de bag abrem o KrononBags — as bolsas padrão não aparecem mais. Funciona pra qualquer forma de abrir (não só o B). ESC fecha a janela. Dá pra desligar em `/kb config` → "Substituir a bag do jogo".

## 0.13.0
- **Altura máxima + barra de rolagem.** A janela não cresce mais sem limite: o conteúdo (categorias, itens e a seção "Vazio") agora rola dentro de uma área com altura limitada. Essencial pro banco gigante (em abas × 98 slots) e pro inventário cheio, que antes estouravam a tela. Rola com a roda do mouse ou pela barra à direita.
- A **alça do canto inferior direito** agora controla também a **altura** (além das colunas): arraste pra definir quanto aparece antes de rolar.

## 0.12.2
- **Alça de redimensionar** no canto inferior direito: arraste pra mudar quantas colunas o inventário mostra (6 a 28) — ele reflui os slots ao soltar. O slider "Colunas" agora acompanha a mesma faixa.
- Correção da **seta de upgrade do Pawn** (usa a seta nativa do botão quando existe; antes o ícone podia ficar invisível).

## 0.12.0
- **Export/Import de categorias** (Layout Oficial da Guilda): na config, botões **Exportar** (gera um código pra copiar) e **Importar** (cola um código e mescla com as suas categorias). Base pra padronizar o setup da guilda.
- **Prontidão de Raide/M+** (`/kb pronto`): painel que mostra, num relance, durabilidade do equipado, quantos frascos/poções/comida/pedra de vida/runas você tem na mochila e o nível da pedra-chave — verde = ok, vermelho = falta.
- **Contagem de itens nos alts** no tooltip: passe o mouse num item e veja quanto seus outros personagens têm dele (e quanto tem no Banco da Brigada). Liga/desliga na config. Os dados são capturados ao deslogar e ao usar o banco.

## 0.11.0
- **Seção "Recém-obtidos"** no topo: itens recém-pegos aparecem juntos numa categoria própria e migram pras categorias normais quando você passa o mouse (deixam de ser "novos").
- **Ações em massa por categoria** (clique-direito no cabeçalho da seção): recolher/expandir todas, favoritar/desfavoritar a categoria inteira e, no banco, "Guardar tudo no banco".

## 0.10.0
- **Vender lixo** num clique: botão aparece no vendedor (modo Mochila) e usa a venda nativa do jogo (`C_MerchantFrame.SellAllJunkItems`). Atenção: vende todos os cinzas, inclusive cinza favoritado.
- **Busca avançada.** Além do nome, agora dá pra buscar por: `ilvl>200`, `ilvl:200-300`, `q:epico`, `tipo:armadura`, `id:12345`, e palavras `boe`, `wb`, `vinculado`, `missao`, `lixo`, `equip`, `consumivel`, `novo`, `favorito`. Operadores `&` (e), `|` (ou), `!` (não) e parênteses. Sem operador entre termos = E. Passe o mouse na caixa de busca pra ver a sintaxe.
- **Seta de upgrade do Pawn** no ícone (se você tiver o addon Pawn instalado).
- **Estrela de qualidade de reagente** (T1/T2/T3) no ícone dos materiais de profissão.
- **Posição da janela por personagem** — lembra onde você deixou a bag em cada char.
- Novos comandos: `/kb grade` (alterna a visão em grade) e `/kb organizar` (organiza automático).

## 0.9.0
- **Banco e Banco da Brigada (warband).** A janela agora substitui o banco nativo: ao abrir o banco aparecem as abas **Mochila / Banco / Brigada**, cada uma mostrando os itens com as mesmas categorias, selos e ações (sacar/guardar pelo clique). Botão **Depositar itens** guarda automaticamente o que está marcado pra depósito.
- **Carga assíncrona de itens.** Item level, vínculo (BoE/Warband) e qualidade agora aparecem corretos mesmo logo após o login ou troca de zona, quando o cliente ainda não cacheou os itens (importante pro banco, que tem muitos itens). Usa `ContinuableContainer`.
- Nova opção na config: **Substituir banco / Brigada** (ligada por padrão). Desligue se preferir o banco nativo da Blizzard.

## 0.8.5
- Logo da Kronon no cabeçalho e na config, créditos e Discord da guilda.
- Dois visuais selecionáveis na config: Escuro (atual) e moldura estilo Blizzard.
- Pacote rápido no ícone: item level (cor por raridade ou branco), selos BoE/Warband, item novo, cooldown, borda de missão e valor do lixo no rodapé.
- Botões de item nativos: usar / equipar / abrir / vender funcionam com segurança (sem taint).
- Categorias ordenáveis, seção de Reagentes, preset de Pedra-chave, seções recolhíveis e organizar automático.
