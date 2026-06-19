# Changelog

## 0.40.0
**Português**
- **Melhorado:** com o tutorial aberto, todos os controles ganham uma **borda suave** (mostra a que cada "i" se refere).
- Ao passar o mouse num "i", a borda daquele controle fica **mais viva** e aparece a **dica**.

**English**
- **Improved:** with the tutorial open, every control gets a **soft border** (shows what each "i" points to).
- Hovering an "i" makes that control's border **brighter** and shows the **tip**.

**Español**
- **Mejorado:** con el tutorial abierto, todos los controles tienen un **borde suave** (muestra a qué se refiere cada "i").
- Al pasar el ratón por una "i", el borde de ese control se vuelve **más vivo** y aparece el **consejo**.

## 0.39.0
**Português**
- **Corrigido:** vender lixo (automático e manual) agora respeita a proteção. Itens cinza **favoritados** ou em **categoria protegida** não são mais vendidos.
- **Melhorado:** a venda de lixo varre as bolsas e confere cada item antes de vender, em vez de usar a venda em massa do jogo.

**English**
- **Fixed:** selling junk (automatic and manual) now respects protection. Gray items that are **favorited** or in a **protected category** are no longer sold.
- **Improved:** junk selling scans your bags and checks each item before selling, instead of using the game's bulk sell.

**Español**
- **Corregido:** vender basura (automático y manual) ahora respeta la protección. Los objetos grises **marcados como favoritos** o en una **categoría protegida** ya no se venden.
- **Mejorado:** la venta de basura recorre las bolsas y comprueba cada objeto antes de venderlo, en lugar de usar la venta masiva del juego.

## 0.38.0
**Português**
- **Corrigido:** comprar aba de banco com "substituir banco" ligado dava erro (ADDON_ACTION_FORBIDDEN no PurchaseBankTab). O banco nativo agora é escondido sem reparentar, então a compra de aba volta a funcionar.

**English**
- **Fixed:** buying a bank tab with "replace bank" enabled threw an error (ADDON_ACTION_FORBIDDEN on PurchaseBankTab). The native bank is now hidden without reparenting, so buying tabs works again.

**Español**
- **Corregido:** comprar una pestaña de banco con "reemplazar banco" activado daba error (ADDON_ACTION_FORBIDDEN en PurchaseBankTab). El banco nativo ahora se oculta sin reparentar, así que comprar pestañas vuelve a funcionar.

## 0.37.0
**Português**
- **Tutorial repaginado:** o botão de ajuda virou um **"i"**.
- **Novo:** ao clicar no "i", marcadores aparecem ao lado de cada controle.
- Passe o mouse num marcador pra **destacar o controle** e ver a dica num **balão** (estilo do tutorial do jogo).
- Não escurece a tela nem trava a bag — clique de novo (ou ESC) pra esconder.

**English**
- **Revamped tutorial:** the help button is now an **"i"**.
- **New:** click the "i" and markers appear next to each control.
- Hover a marker to **highlight that control** and read the tip in a **callout** (just like the in-game tutorial).
- It doesn't dim the screen or lock the bag — click again (or ESC) to hide.

**Español**
- **Tutorial renovado:** el botón de ayuda ahora es una **"i"**.
- **Nuevo:** al hacer clic en la "i", aparecen marcadores junto a cada control.
- Pasa el ratón por un marcador para **resaltar ese control** y ver el consejo en un **globo** (como el tutorial del juego).
- No oscurece la pantalla ni bloquea la bolsa — haz clic de nuevo (o ESC) para ocultar.

## 0.36.0
**Português**
- **Corrigido:** favoritar e proteger agora diferenciam variações do mesmo item (ilvl, raridade, qualidade). Um item de mesmo nome mas ilvl/raridade diferente não é mais marcado junto.
- **Conjunto de Equipamento** casa a peça exata do conjunto, não qualquer item de mesmo nome.
- Nota: favoritos antigos continuam valendo; pra um item antigo passar a diferenciar, desfavorite e favorite de novo.

**English**
- **Fixed:** favoriting and selling protection now tell apart variants of the same item (ilvl, rarity, quality). An item with the same name but different ilvl/rarity is no longer flagged along with it.
- **Equipment Set** matches the exact set piece, not just any item with the same name.
- Note: old favorites still work; to make an old item variant-aware, unfavorite it and favorite it again.

**Español**
- **Corregido:** marcar como favorito y proteger ahora distinguen variantes del mismo objeto (nivel de objeto, rareza, calidad). Un objeto con el mismo nombre pero distinto nivel/rareza ya no se marca junto.
- **Conjunto de equipo** coincide con la pieza exacta del conjunto, no con cualquier objeto del mismo nombre.
- Nota: los favoritos antiguos siguen vigentes; para que un objeto antiguo distinga variantes, quítalo de favoritos y vuelve a marcarlo.

## 0.35.0
**Português**
- **Sub-grupos compactos** — ao agrupar por expansão, os grupos passam a fluir lado a lado em vez de ocupar uma linha cada um.
- Liga/desliga na aba Comportamento da configuração.

**English**
- **Compact expansion groups** — when grouping by expansion, groups now flow side by side instead of taking one row each.
- Toggle it in the Behavior tab of the settings.

**Español**
- **Subgrupos compactos** — al agrupar por expansión, los grupos ahora fluyen lado a lado en vez de ocupar una fila cada uno.
- Actívalo o desactívalo en la pestaña Comportamiento de la configuración.

## 0.34.0
**Português**
- **Botão "Transferir" virou ícone** — ícone contextual com tooltip (moeda = vender no vendedor; bolsa = depositar no banco).
- **Corrigido:** erro de Lua ao passar o mouse em itens do banco consultado de longe (RemoveNewItem com slot inválido).

**English**
- **"Transfer" button is now an icon** — contextual icon with tooltip (coin = sell at a vendor; bag = deposit at the bank).
- **Fixed:** Lua error when hovering items in the remotely-viewed bank (RemoveNewItem with an invalid slot).

**Español**
- **El botón "Transferir" ahora es un icono** — icono contextual con tooltip (moneda = vender; bolsa = depositar).
- **Corregido:** error de Lua al pasar el ratón por objetos del banco consultado a distancia (RemoveNewItem con espacio inválido).

## 0.33.0
**Português**
- Configuração em ABAS — as opções agora ficam numa barra lateral (Aparência, Ícones, Comportamento, Vendedor, Banco, Categorias, Sobre); clique na aba para ver só o que importa.
- Altura fixa — a janela tem tamanho fixo que cabe em qualquer resolução, sem mais estouro de tela.
- Lista de categorias com rolagem — a aba Categorias rola por dentro; os controles (nova categoria, presets, exportar/importar) ficam fixos no topo.

**English**
- Settings in TABS — options now live in a left sidebar (Appearance, Icons, Behavior, Vendor, Bank, Categories, About); click a tab to see only what matters.
- Fixed height — the window has a fixed size that fits any resolution, no more screen overflow.
- Scrollable category list — the Categories tab scrolls internally; the controls (new category, presets, export/import) stay pinned at the top.

**Español**
- Ajustes en PESTAÑAS — las opciones ahora están en una barra lateral (Apariencia, Iconos, Comportamiento, Vendedor, Banco, Categorías, Acerca de); haz clic en una pestaña para ver solo lo que importa.
- Altura fija — la ventana tiene un tamaño fijo que cabe en cualquier resolución, sin más desbordamiento de pantalla.
- Lista de categorías con desplazamiento — la pestaña Categorías se desplaza por dentro; los controles (nueva categoría, presets, exportar/importar) quedan fijos arriba.

## 0.32.0
**Português**
- **Comparar com o equipado** — no tooltip de uma peça de equipamento aparece a comparação com o que você já tem no mesmo slot: diferença de item level e o delta dos atributos secundários (crítico, aceleração, maestria, versatilidade).
- **Anel, berloque e arma** — quando há duas peças equipadas no slot, a comparação usa a de menor item level (a que você provavelmente trocaria).
- **Upgrade do Pawn** — se o Pawn estiver instalado, mostra também a porcentagem de melhoria pela sua escala. Sem o Pawn, a linha simplesmente não aparece.

**English**
- **Compare with equipped** — the tooltip of a gear piece now shows the comparison with what you already have in the same slot: item level difference and the secondary-stat delta (crit, haste, mastery, versatility).
- **Ring, trinket and weapon** — when two pieces are equipped in the slot, the comparison uses the lower item level one (the piece you would likely swap).
- **Pawn upgrade** — if Pawn is installed, it also shows the upgrade percentage for your scale. Without Pawn, the line simply does not appear.

**Español**
- **Comparar con lo equipado** — el tooltip de una pieza de equipo ahora muestra la comparación con lo que ya tienes en la misma ranura: diferencia de nivel de objeto y el delta de los atributos secundarios (crítico, celeridad, maestría, versatilidad).
- **Anillo, abalorio y arma** — cuando hay dos piezas equipadas en la ranura, la comparación usa la de menor nivel de objeto (la que probablemente cambiarías).
- **Mejora de Pawn** — si Pawn está instalado, también muestra el porcentaje de mejora según tu escala. Sin Pawn, la línea simplemente no aparece.

## 0.31.0
**Português**
- **Valor pela Auction House** — o tooltip do item passa a mostrar o valor de mercado (menor preço na AH) usando o Auctionator ou o TSM, com fallback pro preço de venda quando não há cotação.
- **Total por categoria** — o cabeçalho de cada categoria soma o valor de mercado dos itens dela (só aparece com Auctionator ou TSM instalado).
- **Requisito** — o valor de mercado precisa do Auctionator ou do TradeSkillMaster instalado; sem eles, aparece só o preço de venda ao vendedor.

**English**
- **Auction House value** — the item tooltip now shows the market value (lowest AH price) using Auctionator or TSM, falling back to the vendor sell price when there is no listing.
- **Per-category total** — each category header sums the market value of its items (only shown with Auctionator or TSM installed).
- **Requirement** — market value needs Auctionator or TradeSkillMaster installed; without them, only the vendor sell price is shown.

**Español**
- **Valor por la Casa de Subastas** — el tooltip del objeto ahora muestra el valor de mercado (precio más bajo en la CA) usando Auctionator o TSM, con respaldo al precio de venta cuando no hay oferta.
- **Total por categoría** — el encabezado de cada categoría suma el valor de mercado de sus objetos (solo aparece con Auctionator o TSM instalado).
- **Requisito** — el valor de mercado necesita Auctionator o TradeSkillMaster instalado; sin ellos, solo se muestra el precio de venta al vendedor.

## 0.30.0
**Português**
- **Histórico de entradas/saídas** — um botão de relógio no cabeçalho abre um painel com o que entrou (+N) e saiu (−N) da mochila recentemente, com o horário de cada mudança.
- **Sempre rastreando** — as mudanças são registradas em segundo plano; o painel só mostra o resultado (ícone, nome e a quantidade colorida em verde/vermelho).

**English**
- **In/out history** — a clock button in the header opens a panel showing what came into (+N) and left (−N) your backpack recently, with the time of each change.
- **Always tracking** — changes are recorded in the background; the panel just shows the result (icon, name and the amount colored green/red).

**Español**
- **Historial de entradas/salidas** — un botón de reloj en el encabezado abre un panel con lo que entró (+N) y salió (−N) de la mochila recientemente, con la hora de cada cambio.
- **Siempre rastreando** — los cambios se registran en segundo plano; el panel solo muestra el resultado (icono, nombre y la cantidad coloreada en verde/rojo).

## 0.29.0
**Português**
- **Construtor de busca visual** — um botão "Filtrar" ao lado da caixa de busca abre um painel onde você monta o filtro em passos (campo, condição e valor), com explicação no hover de cada parte.
- **Sem decorar sintaxe** — escolha "Item level / maior que / 200", "Qualidade / é / Épico" ou "Tipo / Equipamento" e clique Aplicar; o painel gera a busca pronta pra você.
- **Várias condições** — adicione quantas linhas quiser, marque "NÃO" pra excluir e junte tudo com "Todos (E)" ou "Qualquer (OU)".

**English**
- **Visual search builder** — a "Filter" button next to the search box opens a panel where you assemble the filter in steps (field, condition and value), with a hover explanation for each part.
- **No syntax to memorize** — pick "Item level / greater than / 200", "Quality / is / Epic" or "Type / Gear" and hit Apply; the panel builds the search for you.
- **Multiple conditions** — add as many rows as you want, check "NOT" to exclude, and join them with "Match all (AND)" or "Match any (OR)".

**Español**
- **Constructor de búsqueda visual** — un botón "Filtrar" junto al cuadro de búsqueda abre un panel donde armas el filtro por pasos (campo, condición y valor), con explicación al pasar el ratón por cada parte.
- **Sin memorizar sintaxis** — elige "Nivel de objeto / mayor que / 200", "Calidad / es / Épico" o "Tipo / Equipo" y pulsa Aplicar; el panel construye la búsqueda por ti.
- **Varias condiciones** — añade tantas filas como quieras, marca "NO" para excluir y únelas con "Todos (Y)" o "Cualquiera (O)".

## 0.28.0
**Português**
- **Bordas e ícones nítidos** — a janela e a área de rolagem agora alinham seus tamanhos à grade de pixels real, deixando bordas e ícones mais limpos em qualquer escala de interface.
- **Ouro por personagem no rodapé** — passe o mouse sobre o ouro pra ver um painel com o ouro de cada personagem (cor da classe), o Banco da Brigada quando disponível e o total geral.

**English**
- **Crisp borders and icons** — the window and the scroll area now snap their sizes to the real pixel grid, giving cleaner borders and icons at any UI scale.
- **Gold per character in the footer** — hover the gold to see a panel with each character's gold (class-colored), the Warband bank when available, and the grand total.

**Español**
- **Bordes e iconos nítidos** — la ventana y el área de desplazamiento ahora ajustan sus tamaños a la rejilla de píxeles real, con bordes e iconos más limpios en cualquier escala de interfaz.
- **Oro por personaje en el pie** — pasa el ratón por el oro para ver un panel con el oro de cada personaje (color de clase), el Banco de la banda de guerra cuando esté disponible y el total general.

## 0.27.1
**Português**
- **Corrigido: seta de upgrade do Pawn** — a seta verde voltou a aparecer no ícone (a função do Pawn que usávamos foi descontinuada; agora usamos o ponto de entrada atual).

**English**
- **Fixed: Pawn upgrade arrow** — the green arrow shows on the icon again (the Pawn function we used was discontinued; now using the current entry point).

**Español**
- **Corregido: flecha de mejora de Pawn** — la flecha verde vuelve a aparecer en el icono (la función de Pawn que usábamos fue descontinuada; ahora usamos el punto de entrada actual).

## 0.27.0
**Português**
- **Agrupar por expansão** — uma opção nova que, dentro de cada categoria, sub-agrupa os itens pela expansão de origem, com um sub-cabeçalho por expansão (a mais nova primeiro). Desligada por padrão; liga em Configurações → Comportamento.

**English**
- **Group by expansion** — a new option that, inside each category, sub-groups items by their source expansion, with a sub-header per expansion (newest first). Off by default; enable in Settings → Behavior.

**Español**
- **Agrupar por expansión** — una nueva opción que, dentro de cada categoría, subagrupa los objetos por su expansión de origen, con un subencabezado por expansión (la más nueva primero). Desactivada por defecto; actívala en Ajustes → Comportamiento.

## 0.26.0
**Português**
- **Trilha de upgrade no ícone** — o equipamento mostra o rank de melhoria no canto inferior do ícone (ex: H4/6, dourado quando completo). Liga/desliga em Configurações → Ícones.
- **Suporte a Masque** — se você tiver o Masque instalado, os ícones das bags ganham a skin escolhida automaticamente (sem Masque, nada muda).

**English**
- **Upgrade track on the icon** — gear shows its upgrade rank at the bottom of the icon (e.g. H4/6, gold when maxed). Toggle in Settings → Icons.
- **Masque support** — if you have Masque installed, the bag icons pick up your chosen skin automatically (without Masque, nothing changes).

**Español**
- **Nivel de mejora en el icono** — el equipo muestra su rango de mejora en la esquina inferior del icono (p. ej. H4/6, dorado al estar al máximo). Actívalo en Ajustes → Iconos.
- **Compatibilidad con Masque** — si tienes Masque instalado, los iconos de las bolsas adoptan tu skin elegida automáticamente (sin Masque, nada cambia).

## 0.25.0
**Português**
- **Barra de modos de visualização** — botões de Categorias e Grade fixos à esquerda da janela, com selo no modo ativo.
- **Tutorial guiado no "?"** — o botão de ajuda agora abre um tour passo-a-passo que destaca cada controle (pula o que não está visível).

**English**
- **View mode bar** — Categories and Grid buttons docked to the left of the window, with a marker on the active mode.
- **Guided tutorial on "?"** — the help button now opens a step-by-step tour that highlights each control (skips whatever isn't visible).

**Español**
- **Barra de modos de vista** — botones de Categorías y Cuadrícula fijos a la izquierda de la ventana, con un sello en el modo activo.
- **Tutorial guiado en "?"** — el botón de ayuda ahora abre un tour paso a paso que resalta cada control (omite lo que no está visible).

## 0.24.0
**Português**
- **Configuração em 7 seções** — Aparência, Ícones, Comportamento, Vendedor, Banco, Categorias e Sobre, com rótulos mais claros.
- **Tooltip em cada opção** — passe o mouse sobre checkbox, slider ou botão pra ver uma explicação curta.

**English**
- **Settings in 7 sections** — Appearance, Icons, Behavior, Merchant, Bank, Categories and About, with clearer labels.
- **Tooltip on every option** — hover any checkbox, slider or button to see a short explanation.

**Español**
- **Configuración en 7 secciones** — Apariencia, Iconos, Comportamiento, Vendedor, Banco, Categorías y Acerca de, con etiquetas más claras.
- **Tooltip en cada opción** — pasa el ratón sobre cualquier casilla, deslizador o botón para ver una breve explicación.

## 0.23.0
**Português**
- **Transferir pela busca** — no vendedor vende (com confirmação) e no banco deposita tudo que bate com a busca atual, num clique.
- **Categoria "Abríveis"** — botão "Abrir tudo" agrupa recipientes de loot e abre todos de uma vez (pula os trancados).

**English**
- **Transfer by search** — at the merchant sells (with confirmation) and at the bank deposits everything matching the current search, in one click.
- **"Openable" category** — "Open all" button groups loot containers and opens them all at once (skips locked ones).

**Español**
- **Transferir por búsqueda** — en el vendedor vende (con confirmación) y en el banco deposita todo lo que coincide con la búsqueda actual, en un clic.
- **Categoría "Abribles"** — el botón "Abrir todo" agrupa contenedores de botín y los abre todos a la vez (omite los bloqueados).

## 0.22.0
**Português**
- **Abas em ícone** — Mochila/Banco/Brigada viraram ícones com o nome no tooltip.
- **Botão de ajuda "?"** — painel explicando categorias, busca, favoritos, banco, organizar e controle.
- **Botão de limpar busca** — apaga o termo atual num clique.

**English**
- **Icon tabs** — Bags/Bank/Warband became icons with the name in the tooltip.
- **Help button "?"** — panel explaining categories, search, favorites, bank, organize and controller.
- **Clear search button** — wipes the current term in one click.

**Español**
- **Pestañas en icono** — Mochila/Banco/Banda de guerra ahora son iconos con el nombre en el tooltip.
- **Botón de ayuda "?"** — panel que explica categorías, búsqueda, favoritos, banco, organizar y mando.
- **Botón de limpiar búsqueda** — borra el término actual en un clic.

## 0.21.0
**Português**
- **Suporte a idiomas (PT-BR / Inglês / Espanhol)** — a interface segue automaticamente o idioma do cliente do WoW; config, tooltips, menus, abas, painel de Prontidão e mensagens traduzidos. Suas categorias, favoritos e atribuições continuam intactos.
- **Corrigido: navegação por controle (ConsolePort), parte 3** — todos os itens agora ficam sob um pai único (igual às Bolsas Combinadas nativas), virando uma grade contígua de verdade que não pula seções ao descer.

**English**
- **Language support (PT-BR / English / Spanish)** — the UI automatically follows the WoW client language; settings, tooltips, menus, tabs, Readiness panel and messages translated. Your categories, favorites and assignments stay intact.
- **Fixed: controller navigation (ConsolePort), part 3** — all items now sit under a single parent (like the native Combined Bags), forming a truly contiguous grid that no longer skips sections when moving down.

**Español**
- **Soporte de idiomas (PT-BR / Inglés / Español)** — la interfaz sigue automáticamente el idioma del cliente de WoW; configuración, tooltips, menús, pestañas, panel de Preparación y mensajes traducidos. Tus categorías, favoritos y asignaciones quedan intactos.
- **Corregido: navegación con mando (ConsolePort), parte 3** — todos los objetos ahora están bajo un único padre (como las Bolsas Combinadas nativas), formando una cuadrícula realmente contigua que ya no salta secciones al bajar.

## 0.20.1
**Português**
- **Corrigido: navegação por controle (ConsolePort), parte 2** — cabeçalhos de categoria e os botões "Equipar"/"Distribuir" saíram da navegação por controle; o cursor passa a enxergar só a grade de itens (esquerda/direita/cima/baixo previsíveis). No mouse tudo segue igual.

**English**
- **Fixed: controller navigation (ConsolePort), part 2** — category headers and the "Equip"/"Distribute" buttons were pulled out of controller navigation; the cursor now sees only the item grid (predictable left/right/up/down). Mouse behavior unchanged.

**Español**
- **Corregido: navegación con mando (ConsolePort), parte 2** — los encabezados de categoría y los botones "Equipar"/"Distribuir" salieron de la navegación con mando; el cursor ahora solo ve la cuadrícula de objetos (izquierda/derecha/arriba/abajo predecibles). Con ratón todo sigue igual.

## 0.20.0
**Português**
- **Itens do Gerenciador de Equipamento viram favoritos automáticos** — toda peça de um Conjunto de Equipamento ganha estrela azulada e fica protegida de venda; sincroniza sozinho (tirou do conjunto, deixa de ser favorito).
- **Auto-vender lixo e auto-reparar** — ao abrir o vendedor, vende todos os cinzas e repara tudo, tentando os fundos da guilda primeiro e caindo pro seu ouro só se precisar. Liga/desliga em `/kb config`.
- **Corrigido: navegação por controle (ConsolePort)** — estrela de favoritar e barra de rolagem saíram da navegação; a grade fica limpa e o cursor anda na ordem certa, seção por seção, com rolagem automática.

**English**
- **Equipment Manager items become automatic favorites** — every piece in an Equipment Set gets a bluish star and is sell-protected; it syncs on its own (remove it from the set and it stops being a favorite).
- **Auto-sell junk and auto-repair** — when you open a merchant, it sells all greys and repairs everything, trying guild funds first and falling back to your gold only if needed. Toggle in `/kb config`.
- **Fixed: controller navigation (ConsolePort)** — the favorite star and scrollbar were pulled out of navigation; the grid stays clean and the cursor moves in the right order, section by section, with automatic scrolling.

**Español**
- **Los objetos del Gestor de Equipo se vuelven favoritos automáticos** — cada pieza de un Equipo recibe una estrella azulada y queda protegida de venta; se sincroniza solo (quítala del equipo y deja de ser favorito).
- **Auto-vender basura y auto-reparar** — al abrir un vendedor, vende todos los grises y repara todo, probando primero los fondos del hermandad y recurriendo a tu oro solo si hace falta. Activa/desactiva en `/kb config`.
- **Corregido: navegación con mando (ConsolePort)** — la estrella de favorito y la barra de desplazamiento salieron de la navegación; la cuadrícula queda limpia y el cursor avanza en el orden correcto, sección por sección, con desplazamiento automático.

## 0.19.0
**Português**
- **Banco consultável de qualquer lugar** — veja o conteúdo do Banco e do Banco da Brigada sem estar no banco; o KrononBags salva um retrato a cada visita (com a hora da captura). É só consulta: pra mover é preciso ir até o banco. Comando: `/kb banco`.

**English**
- **Bank viewable from anywhere** — see your Bank and Warband Bank contents without being at the bank; KrononBags saves a snapshot each visit (with the capture time). View only: to move items you must go to the bank. Command: `/kb banco`.

**Español**
- **Banco consultable desde cualquier lugar** — mira el contenido del Banco y del Banco de la banda de guerra sin estar en el banco; KrononBags guarda una captura en cada visita (con la hora). Solo consulta: para mover hay que ir al banco. Comando: `/kb banco`.

## 0.18.0
**Português**
- **Borda colorida por raridade** no ícone — incomum/raro/épico/lendário ganham borda na cor da raridade, lixo fica cinza, comum sem borda. Liga/desliga em `/kb config`.
- **Realçar busca** — em vez de esconder, escurece os itens que não batem e mantém os que batem acesos. Modo "esconder" continua disponível na config.

**English**
- **Rarity-colored border** on the icon — uncommon/rare/epic/legendary get a border in the rarity color, junk goes grey, common has none. Toggle in `/kb config`.
- **Search highlight** — instead of hiding, it dims items that don't match and keeps matches lit. The "hide" mode is still available in settings.

**Español**
- **Borde de color por rareza** en el icono — poco común/raro/épico/legendario reciben borde del color de la rareza, la basura queda gris, lo común sin borde. Activa/desactiva en `/kb config`.
- **Resaltar búsqueda** — en lugar de ocultar, oscurece los objetos que no coinciden y mantiene encendidos los que sí. El modo "ocultar" sigue disponible en la configuración.

## 0.17.0
**Português**
- **"Recém-obtidos" agora segura os itens** — o item fica na seção (o brilho some ao olhar) até você clicar em "Distribuir", no cabeçalho; aí cada item vai pra sua categoria de uma vez. Dá pra arrastar um item de volta pro cabeçalho. A lista é lembrada entre sessões.

**English**
- **"Recently obtained" now holds items** — the item stays in the section (the glow fades when you look) until you click "Distribute" in the header; then each item goes to its category at once. You can drag an item back onto the header. The list is remembered between sessions.

**Español**
- **"Recién obtenidos" ahora retiene los objetos** — el objeto permanece en la sección (el brillo desaparece al mirar) hasta que pulsas "Distribuir" en el encabezado; entonces cada objeto va a su categoría de golpe. Puedes arrastrar un objeto de vuelta al encabezado. La lista se recuerda entre sesiones.

## 0.16.0
**Português**
- **Categorias dinâmicas por regra** — clique em "Regra" (na config) e defina uma busca (ex: `ilvl>200 & boe`, `tipo:armadura`); a categoria se preenche e atualiza sozinha. Mesma sintaxe da busca.
- **Ordenação configurável** — Item level, Qualidade, Nome, Tipo ou Recentes (config → "Ordenar por").
- **Empilhar itens iguais** — junta stacks do mesmo item num ícone só com a contagem somada.

**English**
- **Rule-based dynamic categories** — click "Rule" (in settings) and set a search (e.g. `ilvl>200 & boe`, `tipo:armadura`); the category fills and updates on its own. Same search syntax.
- **Configurable sorting** — Item level, Quality, Name, Type or Recent (settings → "Sort by").
- **Stack identical items** — merges stacks of the same item into one icon with the combined count.

**Español**
- **Categorías dinámicas por regla** — pulsa "Regla" (en la configuración) y define una búsqueda (ej: `ilvl>200 & boe`, `tipo:armadura`); la categoría se llena y se actualiza sola. Misma sintaxis de búsqueda.
- **Orden configurable** — Item level, Calidad, Nombre, Tipo o Recientes (configuración → "Ordenar por").
- **Apilar objetos iguales** — junta los montones del mismo objeto en un solo icono con el recuento sumado.

## 0.15.0
**Português**
- **Arrastar item pra categoria** — solte um item no cabeçalho de uma categoria pra movê-lo ali. Soltar em "Favoritos" favorita; soltar em "Diversos" volta pro automático. O cabeçalho destaca ao passar por cima.

**English**
- **Drag item onto a category** — drop an item on a category header to move it there. Dropping on "Favorites" favorites it; dropping on "Misc" returns it to automatic. The header highlights on hover.

**Español**
- **Arrastrar objeto a una categoría** — suelta un objeto en el encabezado de una categoría para moverlo allí. Soltar en "Favoritos" lo marca como favorito; soltar en "Varios" lo devuelve al automático. El encabezado se resalta al pasar por encima.

## 0.14.0
**Português**
- **Substitui a bag do jogo** — a tecla B, os ícones das bolsas e qualquer atalho de bag abrem o KrononBags; as bolsas padrão somem. ESC fecha. Desligue em `/kb config` → "Substituir a bag do jogo".

**English**
- **Replaces the game's bags** — the B key, the bag icons and any bag shortcut open KrononBags; the default bags disappear. ESC closes. Disable in `/kb config` → "Replace the game's bags".

**Español**
- **Reemplaza las bolsas del juego** — la tecla B, los iconos de las bolsas y cualquier atajo de bolsa abren KrononBags; las bolsas estándar desaparecen. ESC cierra. Desactiva en `/kb config` → "Reemplazar las bolsas del juego".

## 0.13.0
**Português**
- **Altura máxima + barra de rolagem** — o conteúdo rola dentro de uma área com altura limitada (essencial pro banco gigante e o inventário cheio). Rola com a roda ou pela barra à direita.
- **Alça controla a altura** — a alça do canto inferior direito agora ajusta a altura (além das colunas): arraste pra definir quanto aparece antes de rolar.

**English**
- **Max height + scrollbar** — content scrolls inside a height-limited area (essential for the huge bank and a full inventory). Scroll with the wheel or the bar on the right.
- **Handle controls height** — the bottom-right handle now adjusts height (besides columns): drag to set how much shows before scrolling.

**Español**
- **Altura máxima + barra de desplazamiento** — el contenido se desplaza dentro de un área de altura limitada (esencial para el banco gigante y el inventario lleno). Desplázate con la rueda o con la barra de la derecha.
- **El tirador controla la altura** — el tirador de la esquina inferior derecha ahora ajusta la altura (además de las columnas): arrastra para definir cuánto se muestra antes de desplazar.

## 0.12.2
**Português**
- **Alça de redimensionar** — no canto inferior direito, arraste pra mudar quantas colunas o inventário mostra (6 a 28); reflui ao soltar. O slider "Colunas" acompanha a mesma faixa.
- **Corrigido: seta de upgrade do Pawn** — usa a seta nativa do botão quando existe (antes o ícone podia ficar invisível).

**English**
- **Resize handle** — at the bottom-right corner, drag to change how many columns the inventory shows (6 to 28); reflows on release. The "Columns" slider follows the same range.
- **Fixed: Pawn upgrade arrow** — uses the button's native arrow when present (before, the icon could be invisible).

**Español**
- **Tirador de redimensión** — en la esquina inferior derecha, arrastra para cambiar cuántas columnas muestra el inventario (6 a 28); se reorganiza al soltar. El deslizador "Columnas" sigue el mismo rango.
- **Corregido: flecha de mejora de Pawn** — usa la flecha nativa del botón cuando existe (antes el icono podía quedar invisible).

## 0.12.0
**Português**
- **Export/Import de categorias** — botões "Exportar" (gera um código) e "Importar" (cola e mescla com as suas). Base pra padronizar o setup da guilda.
- **Prontidão de Raide/M+** (`/kb pronto`) — painel que mostra durabilidade, frascos/poções/comida/pedra de vida/runas na mochila e o nível da pedra-chave; verde = ok, vermelho = falta.
- **Contagem de itens nos alts** no tooltip — veja quanto seus outros personagens têm (e o Banco da Brigada). Liga/desliga na config; dados capturados ao deslogar e ao usar o banco.

**English**
- **Category Export/Import** — "Export" (generates a code) and "Import" (paste and merge with yours) buttons. A base for standardizing the guild setup.
- **Raid/M+ Readiness** (`/kb pronto`) — panel showing durability, flasks/potions/food/healthstone/runes in your bags and the keystone level; green = ok, red = missing.
- **Alt item count** in the tooltip — see how much your other characters have (and the Warband Bank). Toggle in settings; data captured on logout and when using the bank.

**Español**
- **Exportar/Importar categorías** — botones "Exportar" (genera un código) e "Importar" (pega y fusiona con las tuyas). Base para estandarizar la configuración del hermandad.
- **Preparación de Banda/M+** (`/kb pronto`) — panel que muestra durabilidad, frascos/pociones/comida/piedra de salud/runas en la mochila y el nivel de la piedra angular; verde = ok, rojo = falta.
- **Recuento de objetos en los alts** en el tooltip — mira cuánto tienen tus otros personajes (y el Banco de la banda de guerra). Activa/desactiva en la configuración; datos capturados al cerrar sesión y al usar el banco.

## 0.11.0
**Português**
- **Seção "Recém-obtidos"** no topo — itens recém-pegos aparecem juntos e migram pras categorias normais quando você passa o mouse.
- **Ações em massa por categoria** (clique-direito no cabeçalho) — recolher/expandir todas, favoritar/desfavoritar a categoria inteira e, no banco, "Guardar tudo no banco".

**English**
- **"Recently obtained" section** at the top — newly picked items show together and migrate to normal categories when you hover them.
- **Bulk actions per category** (right-click the header) — collapse/expand all, favorite/unfavorite the whole category and, at the bank, "Deposit everything".

**Español**
- **Sección "Recién obtenidos"** arriba — los objetos recién recogidos aparecen juntos y migran a las categorías normales cuando pasas el ratón.
- **Acciones masivas por categoría** (clic derecho en el encabezado) — contraer/expandir todas, marcar/desmarcar la categoría entera y, en el banco, "Guardar todo en el banco".

## 0.10.0
**Português**
- **Vender lixo num clique** — botão no vendedor (modo Mochila) usa a venda nativa do jogo. Atenção: vende todos os cinzas, inclusive cinza favoritado.
- **Busca avançada** — busque por `ilvl>200`, `ilvl:200-300`, `q:epico`, `tipo:armadura`, `id:12345` e palavras (`boe`, `wb`, `vinculado`, `missao`, `lixo`, `equip`, `consumivel`, `novo`, `favorito`). Operadores `&`, `|`, `!` e parênteses.
- **Seta de upgrade do Pawn** no ícone (se tiver o addon Pawn).
- **Estrela de qualidade de reagente** (T1/T2/T3) nos materiais de profissão.
- **Posição da janela por personagem** — lembra onde você deixou a bag em cada char.
- **Novos comandos** — `/kb grade` (visão em grade) e `/kb organizar` (organiza automático).

**English**
- **Sell junk in one click** — button at the merchant (Bags mode) uses the game's native sell. Note: sells all greys, including favorited greys.
- **Advanced search** — search by `ilvl>200`, `ilvl:200-300`, `q:epico`, `tipo:armadura`, `id:12345` and keywords (`boe`, `wb`, `vinculado`, `missao`, `lixo`, `equip`, `consumivel`, `novo`, `favorito`). Operators `&`, `|`, `!` and parentheses.
- **Pawn upgrade arrow** on the icon (if you have the Pawn addon).
- **Reagent quality star** (T1/T2/T3) on profession materials.
- **Per-character window position** — remembers where you left the bag on each char.
- **New commands** — `/kb grade` (grid view) and `/kb organizar` (auto organize).

**Español**
- **Vender basura en un clic** — botón en el vendedor (modo Mochila) usa la venta nativa del juego. Atención: vende todos los grises, incluso los grises favoritos.
- **Búsqueda avanzada** — busca por `ilvl>200`, `ilvl:200-300`, `q:epico`, `tipo:armadura`, `id:12345` y palabras (`boe`, `wb`, `vinculado`, `missao`, `lixo`, `equip`, `consumivel`, `novo`, `favorito`). Operadores `&`, `|`, `!` y paréntesis.
- **Flecha de mejora de Pawn** en el icono (si tienes el addon Pawn).
- **Estrella de calidad de reactivo** (T1/T2/T3) en los materiales de profesión.
- **Posición de la ventana por personaje** — recuerda dónde dejaste la bolsa en cada personaje.
- **Nuevos comandos** — `/kb grade` (vista en cuadrícula) y `/kb organizar` (organiza automático).

## 0.9.0
**Português**
- **Banco e Banco da Brigada (Warband)** — a janela substitui o banco nativo: ao abrir aparecem as abas Mochila/Banco/Brigada, com as mesmas categorias, selos e ações. Botão "Depositar itens" guarda o que está marcado.
- **Carga assíncrona de itens** — item level, vínculo (BoE/Warband) e qualidade aparecem corretos mesmo logo após o login ou troca de zona (usa `ContinuableContainer`).
- **Nova opção: Substituir banco / Brigada** (ligada por padrão) — desligue se preferir o banco nativo da Blizzard.

**English**
- **Bank and Warband Bank** — the window replaces the native bank: on opening it shows the Bags/Bank/Warband tabs, with the same categories, marks and actions. The "Deposit items" button stores what's flagged.
- **Asynchronous item loading** — item level, binding (BoE/Warband) and quality show correctly even right after login or a zone change (uses `ContinuableContainer`).
- **New option: Replace bank / Warband** (on by default) — turn it off if you prefer Blizzard's native bank.

**Español**
- **Banco y Banco de la banda de guerra (Warband)** — la ventana reemplaza el banco nativo: al abrir muestra las pestañas Mochila/Banco/Banda de guerra, con las mismas categorías, marcas y acciones. El botón "Depositar objetos" guarda lo marcado.
- **Carga asíncrona de objetos** — item level, vínculo (BoE/Warband) y calidad aparecen correctos incluso justo tras iniciar sesión o cambiar de zona (usa `ContinuableContainer`).
- **Nueva opción: Reemplazar banco / Banda de guerra** (activada por defecto) — desactívala si prefieres el banco nativo de Blizzard.

## 0.8.5
**Português**
- **Identidade Kronon** — logo no cabeçalho e na config, créditos e Discord da guilda.
- **Dois visuais** — Escuro (atual) e moldura estilo Blizzard, selecionáveis na config.
- **Pacote rápido no ícone** — item level (cor por raridade ou branco), selos BoE/Warband, item novo, cooldown, borda de missão e valor do lixo no rodapé.
- **Botões de item nativos** — usar/equipar/abrir/vender funcionam com segurança (sem taint).
- **Categorias** — ordenáveis, seção de Reagentes, preset de Pedra-chave, seções recolhíveis e organizar automático.

**English**
- **Kronon identity** — logo in the header and settings, credits and guild Discord.
- **Two looks** — Dark (current) and a Blizzard-style frame, selectable in settings.
- **Quick info on the icon** — item level (rarity color or white), BoE/Warband marks, new item, cooldown, quest border and junk value in the footer.
- **Native item buttons** — use/equip/open/sell work safely (no taint).
- **Categories** — sortable, Reagents section, Keystone preset, collapsible sections and auto organize.

**Español**
- **Identidad Kronon** — logo en el encabezado y la configuración, créditos y Discord del hermandad.
- **Dos estilos** — Oscuro (actual) y marco estilo Blizzard, seleccionables en la configuración.
- **Información rápida en el icono** — item level (color por rareza o blanco), marcas BoE/Warband, objeto nuevo, reutilización, borde de misión y valor de la basura en el pie.
- **Botones de objeto nativos** — usar/equipar/abrir/vender funcionan con seguridad (sin taint).
- **Categorías** — ordenables, sección de Reactivos, preajuste de Piedra angular, secciones plegables y organizar automático.
