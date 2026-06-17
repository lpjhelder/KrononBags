# Changelog

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
