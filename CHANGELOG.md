# Changelog

## 0.63.2
**Português**
- **Corrigido:** o botão **"Abrir tudo"** (categoria Abríveis) agora fica bloqueado com **banco, banco de guilda, troca, correio ou casa de leilões** abertos. Antes, nesses contextos, os recipientes eram **depositados/anexados em cadeia** em vez de abertos. No vendedor já era bloqueado; a proteção foi estendida a todos os contextos.

**English**
- **Fixed:** the **"Open all"** button (Openables category) is now blocked while the **bank, guild bank, trade, mail or auction house** is open. In those contexts, containers were being **deposited/attached in a chain** instead of opened. It was already blocked at the merchant; the protection now covers every context.

**Español**
- **Corregido:** el botón **"Abrir todo"** (categoría Abribles) ahora queda bloqueado con el **banco, banco del clan, intercambio, correo o casa de subastas** abiertos. En esos contextos, los recipientes se **depositaban/adjuntaban en cadena** en lugar de abrirse. En el vendedor ya estaba bloqueado; la protección ahora cubre todos los contextos.

## 0.63.1
**Português**
- **Novo:** o destaque dos itens mais valiosos agora funciona também no **Banco** (aberto ou visto de longe).
- **Novo:** na janela dos mais valiosos, **passar o mouse** numa linha dá um flash no item e **clicar** dá um destaque bem mais forte, pra achar o item na bolsa.
- **Corrigido:** itens **vinculados** (que não vão pra Casa de Leilões) não entram mais no destaque de valor.

**English**
- **New:** the valuable-items highlight now works in the **Bank** too (open or viewed from afar).
- **New:** in the most-valuable window, **hovering** a row flashes the item and **clicking** gives a much stronger highlight to find it in the bag.
- **Fixed:** **bound** items (that can't go to the Auction House) no longer appear in the value highlight.

**Español**
- **Nuevo:** el destacado de objetos valiosos ahora también funciona en el **Banco** (abierto o visto de lejos).
- **Nuevo:** en la ventana de más valiosos, **pasar el ratón** por una fila destella el objeto y **hacer clic** da un resaltado mucho más fuerte para encontrarlo en la bolsa.
- **Corregido:** los objetos **vinculados** (que no van a la Casa de Subastas) ya no aparecen en el destacado de valor.

## 0.63.0
**Português**
- **Novo:** janela **Mais valiosos** presa no topo da bolsa. Ao ligar o destaque de itens valiosos, ela lista os itens mais caros em ordem — com posição, ícone, nome colorido pela qualidade e valor de mercado. **Clique numa linha** para o item piscar na bolsa. Some quando o destaque é desligado, sem o KrononMarket ou na visão de banco à distância.
- **Melhorado:** as **moedas douradas** agora jorram de **todos** os itens destacados (não só o mais caro).

**English**
- **New:** **Most valuable** panel pinned to the top of the bag. When you turn on the valuable-items highlight, it lists your priciest items in order — with rank, icon, quality-colored name and market value. **Click a row** to flash that item in the bag. Hidden when the highlight is off, without KrononMarket, or in the remote bank view.
- **Improved:** the **gold coins** now pour from **all** highlighted items (not just the most valuable one).

**Español**
- **Nuevo:** panel **Más valiosos** fijado en la parte superior de la bolsa. Al activar el resalte de objetos valiosos, lista tus objetos más caros en orden — con posición, icono, nombre coloreado por calidad y valor de mercado. **Haz clic en una fila** para que el objeto parpadee en la bolsa. Se oculta cuando el resalte está apagado, sin KrononMarket o en la vista de banco a distancia.
- **Mejorado:** las **monedas doradas** ahora brotan de **todos** los objetos resaltados (no solo del más caro).

## 0.62.2
**Português**
- **Novo:** o botão de **destacar itens valiosos** agora mostra o estado: **ligado** = moeda dourada acesa, brilho pulsante e moedas saindo do botão; **desligado** = moeda acinzentada e parada. Fácil saber se está ativo.

**English**
- **New:** the **highlight valuable items** button now shows its state: **on** = bright gold coin, pulsing glow and coins popping out; **off** = grayed-out, still coin. Easy to tell if it's active.

**Español**
- **Nuevo:** el botón de **destacar objetos valiosos** ahora muestra su estado: **activado** = moneda dorada brillante, resplandor y monedas saliendo; **desactivado** = moneda en gris y quieta. Fácil saber si está activo.

## 0.62.1
**Português**
- **Novo:** o **título** do cabeçalho se ajusta ao espaço conforme você redimensiona a janela: `KrononBags` → `KBags` → `KB` → (vazio) quando há poucas colunas, liberando espaço sem sobrepor os ícones.
- **Melhorado:** o ícone de **Histórico** agora fica junto dos demais controles (à esquerda do botão de valor) e acompanha o redimensionamento.

**English**
- **New:** the header **title** adapts to the space as you resize the window: `KrononBags` → `KBags` → `KB` → (empty) when there are few columns, freeing space without overlapping the icons.
- **Improved:** the **History** icon now sits with the other controls (left of the value button) and follows resizing.

**Español**
- **Nuevo:** el **título** del encabezado se ajusta al espacio al redimensionar la ventana: `KrononBags` → `KBags` → `KB` → (vacío) cuando hay pocas columnas, liberando espacio sin superponer los iconos.
- **Mejorado:** el icono de **Historial** ahora va con los demás controles (a la izquierda del botón de valor) y sigue el redimensionamiento.

## 0.61.2
**Português**
- **Corrigido:** conflito com o **Masque** que mostrava uma exclamação (textura de missão) em **todos** os itens. A integração com o Masque foi removida — o KrononBags usa o visual próprio dele.

**English**
- **Fixed:** conflict with **Masque** that showed an exclamation mark (quest texture) on **every** item. The Masque integration was removed — KrononBags uses its own icon styling.

**Español**
- **Corregido:** conflicto con **Masque** que mostraba una exclamación (textura de misión) en **todos** los objetos. Se eliminó la integración con Masque — KrononBags usa su propio estilo de iconos.

## 0.61.1
**Português**
- **Corrigido:** avisos de Lua repetidos do `Bindings.xml` (`Unrecognized XML`). O arquivo de atalhos é carregado automaticamente pelo jogo e não deve constar no `.toc` — a referência duplicada foi removida. Os atalhos de teclado continuam funcionando.

**English**
- **Fixed:** repeated Lua warnings from `Bindings.xml` (`Unrecognized XML`). The key bindings file is auto-loaded by the game and must not be listed in the `.toc` — the duplicate reference was removed. Keybindings keep working.

**Español**
- **Corregido:** advertencias de Lua repetidas de `Bindings.xml` (`Unrecognized XML`). El archivo de atajos lo carga el juego automáticamente y no debe figurar en el `.toc` — se eliminó la referencia duplicada. Los atajos siguen funcionando.

## 0.61.0
**Português**
- **Novo:** opção **Top 1** no menu do botão de ouro — agora dá pra destacar só o item mais valioso (**1 / 5 / 10 / 15 / 20**).
- **Novo:** **moedas jorrando** do item mais caro — o item de maior valor (top-1) ganha, além da borda dourada, uma animação leve de moedas saindo dele.
- **Melhorado:** **brilho graduado** no destaque — o item mais caro recebe a cor dourada cheia e os seguintes vão clareando, deixando claro qual é o mais valioso.
- **Melhorado:** o **tour guiado** agora inclui um passo apontando o botão de ouro (só com o **KrononMarket**).
- **Corrigido:** **falso positivo de aparência** — itens cujo visual de transmog você **já tem por outra peça/fonte** não aparecem mais na categoria **Aparência não coletada** nem ganham o selo. Agora a checagem olha a **aparência inteira** (qualquer fonte coletada), não só a peça específica. Em dúvida, erra pra menos: nunca marca à toa.

**English**
- **New:** **Top 1** option in the gold button menu — you can now highlight only your single most valuable item (**1 / 5 / 10 / 15 / 20**).
- **New:** **coins spraying** from the priciest item — the highest-value item (top-1) gets a light animation of coins flowing out of it, on top of the golden border.
- **Improved:** **graduated glow** on the highlight — the priciest item gets the full golden color and the following ones fade lighter, making it clear which one is the most valuable.
- **Improved:** the **guided tour** now includes a step pointing to the gold button (only with **KrononMarket**).
- **Fixed:** **appearance false positive** — gear whose transmog look you **already own from another piece/source** no longer shows up in the **Uncollected appearance** category or gets the seal. The check now looks at the **whole appearance** (any collected source), not just the specific piece. When unsure, it errs on the safe side: it never flags by mistake.

**Español**
- **Nuevo:** opción **Top 1** en el menú del botón de oro — ahora puedes destacar solo el objeto más valioso (**1 / 5 / 10 / 15 / 20**).
- **Nuevo:** **monedas brotando** del objeto más caro — el objeto de mayor valor (top-1) recibe, además del borde dorado, una animación ligera de monedas saliendo de él.
- **Mejorado:** **brillo graduado** en el resaltado — el objeto más caro recibe el color dorado pleno y los siguientes se van aclarando, dejando claro cuál es el más valioso.
- **Mejorado:** el **tour guiado** ahora incluye un paso que señala el botón de oro (solo con **KrononMarket**).
- **Corregido:** **falso positivo de apariencia** — las piezas cuyo aspecto de transfiguración **ya tienes por otra pieza/fuente** ya no aparecen en la categoría **Apariencia no coleccionada** ni reciben el sello. Ahora la comprobación mira la **apariencia completa** (cualquier fuente coleccionada), no solo la pieza específica. En caso de duda, se equivoca por defecto: nunca marca por error.

## 0.60.0
**Português**
- **Novo:** botão **Destacar itens mais valiosos** (ícone de ouro no topo da janela) — realça com uma **borda dourada pulsante** os itens mais caros da sua bolsa pela Casa de Leilões do **KrononMarket**. **Clique-esquerdo** liga/desliga; **clique-direito** abre um menu pra escolher quantos destacar (**5 / 10 / 15 / 20**). O valor de cada item é preço × quantidade; só os escolhidos ganham a borda, o resto fica normal.
- Integração 100% **opcional**: o botão só aparece com o **KrononMarket** instalado; sem ele, nada muda. Na visualização do banco de longe (cache) não há destaque.

**English**
- **New:** **Highlight most valuable items** button (gold icon at the top of the window) — marks the priciest items in your bag with a **pulsing golden border**, using the **KrononMarket** auction data. **Left-click** toggles it on/off; **right-click** opens a menu to choose how many to highlight (**5 / 10 / 15 / 20**). Each item's value is price × quantity; only the chosen ones get the border, the rest stay normal.
- 100% **optional** integration: the button only appears with **KrononMarket** installed; without it, nothing changes. There is no highlight in the remote (cached) bank view.

**Español**
- **Nuevo:** botón **Destacar objetos más valiosos** (icono de oro en la parte superior de la ventana) — resalta con un **borde dorado pulsante** los objetos más caros de tu bolsa, usando los datos de la Casa de Subastas de **KrononMarket**. **Clic izquierdo** lo activa/desactiva; **clic derecho** abre un menú para elegir cuántos destacar (**5 / 10 / 15 / 20**). El valor de cada objeto es precio × cantidad; solo los elegidos reciben el borde, el resto queda normal.
- Integración 100% **opcional**: el botón solo aparece con **KrononMarket** instalado; sin él, nada cambia. En la vista del banco remoto (caché) no hay resaltado.

## 0.59.0
**Português**
- **Novo:** categoria **Aparência não coletada** no topo — agrupa automaticamente as peças equipáveis cujo visual de transmog você ainda não aprendeu, em destaque acima das demais categorias. Liga/desliga em *Comportamento* (ligada por padrão); só aparece quando há itens assim.
- **Novo:** categoria **Mascotes** própria — mascotes (pets de batalha) agora têm a sua categoria, separadas das **Montarias**.
- **Novo:** ordenação **Valor na AH** — ordena os itens pelo valor de mercado total (preço × quantidade), do maior pro menor. Aparece no menu *Ordenar por* apenas com o **KrononMarket** instalado.

**English**
- **New:** **Uncollected appearance** category at the top — automatically groups equippable gear whose transmog appearance you have not learned yet, highlighted above the other categories. Toggle in *Behavior* (on by default); only shows when such items exist.
- **New:** dedicated **Pets** category — battle pets now get their own category, separate from **Mounts**.
- **New:** **Auction value** sorting — orders items by total market value (price × quantity), highest first. Appears in the *Sort by* menu only when **KrononMarket** is installed.

**Español**
- **Nuevo:** categoría **Apariencia no coleccionada** en la parte superior — agrupa automáticamente las piezas equipables cuyo aspecto de transfiguración aún no has aprendido, destacada por encima de las demás categorías. Se activa/desactiva en *Comportamiento* (activada por defecto); solo aparece cuando hay objetos así.
- **Nuevo:** categoría **Mascotas** propia — las mascotas (mascotas de combate) ahora tienen su propia categoría, separadas de las **Monturas**.
- **Nuevo:** ordenación **Valor en la subasta** — ordena los objetos por el valor de mercado total (precio × cantidad), de mayor a menor. Aparece en el menú *Ordenar por* solo con **KrononMarket** instalado.

## 0.58.0
**Português**
- **Corrigido:** **usar item da bolsa** voltou a funcionar — decorações de moradia, pedra de regresso, brinquedos e poções que conjuram não dão mais o erro "Ação bloqueada" (ADDON_ACTION_FORBIDDEN) ao clicar com o botão direito. A bolsa de cada item agora é lida do jeito seguro da Blizzard, sem contaminar a ação protegida.
- Vender no vendedor, equipar, abrir contêineres, arrastar itens e a proteção de favoritos continuam funcionando como antes.

**English**
- **Fixed:** **using a bag item** works again — housing decorations, hearthstone, toys and potions that cast a spell no longer trigger the "Action blocked" error (ADDON_ACTION_FORBIDDEN) on right-click. Each item's bag is now read the safe Blizzard way, without tainting the protected action.
- Selling at a vendor, equipping, opening containers, dragging items and favorite protection keep working as before.

**Español**
- **Corregido:** **usar un objeto de la bolsa** vuelve a funcionar — las decoraciones de vivienda, la piedra de regreso, los juguetes y las pociones que lanzan un hechizo ya no provocan el error "Acción bloqueada" (ADDON_ACTION_FORBIDDEN) al hacer clic derecho. La bolsa de cada objeto ahora se lee de la forma segura de Blizzard, sin contaminar la acción protegida.
- Vender al vendedor, equipar, abrir contenedores, arrastrar objetos y la protección de favoritos siguen funcionando como antes.

## 0.57.0
**Português**
- **Novo:** **tour guiado ampliado** — o botão "i" agora destaca também a busca global **Onde está?**, o botão de **Configurações** (engrenagem) e, quando os addons estão instalados, os indicadores do **KrononAlts** (Personagens) e do **KrononMarket** (Valor de mercado).
- **Corrigido:** a **borda do tour nas abas** (Mochila/Banco/Brigada) agora envolve as três abas de forma justa, em vez de cobrir só um cantinho.

**English**
- **New:** **expanded guided tour** — the "i" button now also highlights the **Where is it?** global search, the **Settings** (gear) button and, when the addons are installed, the **KrononAlts** (Characters) and **KrononMarket** (Market value) indicators.
- **Fixed:** the **tour border on the tabs** (Bags/Bank/Warband) now hugs the three tabs neatly, instead of covering only a small corner.

**Español**
- **Nuevo:** **tour guiado ampliado** — el botón "i" ahora también resalta la búsqueda global **¿Dónde está?**, el botón de **Configuración** (engranaje) y, cuando los addons están instalados, los indicadores de **KrononAlts** (Personajes) y **KrononMarket** (Valor de mercado).
- **Corregido:** el **borde del tour en las pestañas** (Bolsas/Banco/Banda de guerra) ahora abraza las tres pestañas de forma ajustada, en lugar de cubrir solo una esquina.

## 0.56.0
**Português**
- **Novo:** **seta de upgrade** no ícone — itens equipáveis com nível de item maior que o atualmente equipado no mesmo espaço (anéis, joias e armas de dois espaços comparam com o de menor ilvl) ganham uma seta verde no canto inferior-direito.
- **Novo:** **selo de aparência não coletada** — peças cujo visual de transmog você ainda não aprendeu recebem um pequeno ícone na borda superior do ícone.
- **Novo:** **valor da bolsa no rodapé** — soma o valor de mercado de tudo na bolsa (via KrononMarket) e mostra o total; aparece só com o KrononMarket instalado.
- **Novo:** opções **Seta de upgrade**, **Aparência não coletada** (seção *Ícones*) e **Valor da bolsa no rodapé** (seção *Ecossistema Kronon*), todas ligadas por padrão.
- **Novo:** **API pública** `KrononBags.Toggle()` e `KrononBags.Open()` para outros addons do ecossistema abrirem a bolsa.

**English**
- **New:** **upgrade arrow** on the icon — equippable items with a higher item level than what you currently have equipped in the same slot (rings, trinkets and two-slot weapons compare against the lower ilvl) get a green arrow in the bottom-right corner.
- **New:** **uncollected appearance seal** — gear whose transmog appearance you have not learned yet gets a small icon on the top edge of the icon.
- **New:** **bag value in the footer** — sums the market value of everything in your bag (via KrononMarket) and shows the total; appears only when KrononMarket is installed.
- **New:** **Upgrade arrow**, **Uncollected appearance** (*Icons* section) and **Bag value in footer** (*Kronon ecosystem* section) options, all on by default.
- **New:** **public API** `KrononBags.Toggle()` and `KrononBags.Open()` so other ecosystem addons can open the bag.

**Español**
- **Nuevo:** **flecha de mejora** en el icono — los objetos equipables con un nivel de objeto mayor que el equipado actualmente en la misma ranura (anillos, abalorios y armas de dos ranuras comparan con el de menor ilvl) reciben una flecha verde en la esquina inferior derecha.
- **Nuevo:** **sello de apariencia no obtenida** — las piezas cuyo aspecto de transfiguración aún no has aprendido reciben un pequeño icono en el borde superior del icono.
- **Nuevo:** **valor de la bolsa en el pie** — suma el valor de mercado de todo lo que hay en la bolsa (vía KrononMarket) y muestra el total; aparece solo con KrononMarket instalado.
- **Nuevo:** opciones **Flecha de mejora**, **Apariencia no obtenida** (sección *Iconos*) y **Valor de la bolsa en el pie** (sección *Ecosistema Kronon*), todas activadas por defecto.
- **Nuevo:** **API pública** `KrononBags.Toggle()` y `KrononBags.Open()` para que otros addons del ecosistema abran la bolsa.

## 0.55.0
**Português**
- **Novo:** **hub do ecossistema Kronon** — indicador clicável do **KrononAlts** no rodapé mostra um resumo dos seus alts (Grandes Cofres prontos ou a próxima ação); o tooltip detalha personagens, cofres prontos e 3/3/3, e clicar abre a janela do KrononAlts.
- **Novo:** **tendência de preço** no tooltip do item (via KrononMarket) — logo abaixo do valor de mercado, mostra se o item está **acima**, **abaixo** ou **estável** em relação à média.
- **Novo:** opção **Indicador do KrononAlts** na seção *Ecossistema Kronon* das configurações (ligada por padrão).
- **Mantido:** ambas as integrações são **100% opcionais** — sem o KrononAlts ou o KrononMarket o comportamento é idêntico ao anterior.

**English**
- **New:** **Kronon ecosystem hub** — a clickable **KrononAlts** indicator in the footer shows a summary of your alts (ready Great Vaults or the next action); the tooltip details characters, ready vaults and 3/3/3, and clicking opens the KrononAlts window.
- **New:** **price trend** on the item tooltip (via KrononMarket) — right below the market value, it shows whether the item is **above**, **below** or **stable** versus the average.
- **New:** **KrononAlts indicator** option in the *Kronon ecosystem* section of the settings (on by default).
- **Kept:** both integrations are **100% optional** — without KrononAlts or KrononMarket the behavior is identical to before.

**Español**
- **Nuevo:** **hub del ecosistema Kronon** — un indicador clicable de **KrononAlts** en el pie muestra un resumen de tus alts (Cámaras del Tesoro listas o la próxima acción); el tooltip detalla personajes, cámaras listas y 3/3/3, y al hacer clic se abre la ventana de KrononAlts.
- **Nuevo:** **tendencia de precio** en el tooltip del objeto (vía KrononMarket) — justo bajo el valor de mercado, indica si el objeto está **sobre**, **bajo** o **estable** respecto a la media.
- **Nuevo:** opción **Indicador de KrononAlts** en la sección *Ecosistema Kronon* de los ajustes (activada por defecto).
- **Mantenido:** ambas integraciones son **100% opcionales** — sin KrononAlts o KrononMarket el comportamiento es idéntico al anterior.

## 0.54.0
**Português**
- **Novo:** janela de **configurações redesenhada** — visual profissional estilo DBM/SkillCapped, com sidebar de categorias (ícone + realce azul na ativa), painel rolável e seções com cabeçalho dourado.
- **Novo:** **busca de opção** no topo da sidebar e botão **Restaurar padrões** no rodapé.
- **Novo:** os botões agora são **interruptores** (verde ligado / cinza desligado) e cada opção tem uma descrição curta; opções dependentes acinzentam quando o item-pai está desligado.
- **Melhorado:** a janela **lembra posição, tamanho e a última categoria aberta**, e pode ser redimensionada.
- **Mantido:** todas as opções, o preview de tema ao vivo e o gerenciador de categorias continuam idênticos.

**English**
- **New:** **redesigned settings window** — professional DBM/SkillCapped-style look, with a category sidebar (icon + blue highlight on the active one), a scrollable panel and sections with golden headers.
- **New:** **option search** at the top of the sidebar and a **Restore defaults** button at the bottom.
- **New:** toggles are now **switches** (green on / gray off) and each option has a short description; dependent options gray out when their parent is off.
- **Improved:** the window now **remembers its position, size and last open category**, and can be resized.
- **Kept:** every option, the live theme preview and the category manager remain identical.

**Español**
- **Nuevo:** **ventana de ajustes rediseñada** — aspecto profesional estilo DBM/SkillCapped, con barra lateral de categorías (icono + resalte azul en la activa), panel desplazable y secciones con encabezado dorado.
- **Nuevo:** **búsqueda de opción** en la parte superior de la barra lateral y botón **Restaurar valores** abajo.
- **Nuevo:** los botones ahora son **interruptores** (verde activado / gris desactivado) y cada opción tiene una descripción corta; las opciones dependientes se atenúan cuando su opción superior está desactivada.
- **Mejorado:** la ventana ahora **recuerda su posición, tamaño y última categoría abierta**, y se puede redimensionar.
- **Mantenido:** todas las opciones, la vista previa de tema en vivo y el gestor de categorías siguen idénticos.

## 0.53.0
**Português**
- **Corrigido:** erro crônico ao **comprar aba no banco** (`ADDON_ACTION_FORBIDDEN: PurchaseBankTab`). A supressão do banco nativo não contamina mais o caminho de compra — comprar aba volta a funcionar sem precisar de `/reload`.

**English**
- **Fixed:** chronic error when **purchasing a bank tab** (`ADDON_ACTION_FORBIDDEN: PurchaseBankTab`). Hiding the native bank no longer taints the purchase path — buying a tab works again without needing `/reload`.

**Español**
- **Corregido:** error crónico al **comprar una pestaña del banco** (`ADDON_ACTION_FORBIDDEN: PurchaseBankTab`). Ocultar el banco nativo ya no contamina la compra — comprar pestaña vuelve a funcionar sin necesidad de `/reload`.

## 0.52.1
**Português**
- **Corrigido:** aviso de Lua dos atalhos de teclado (`Bindings.xml`) — os atalhos seguem funcionando, sem mais o aviso no log.

**English**
- **Fixed:** Lua warning from the key bindings (`Bindings.xml`) — shortcuts keep working, with no more warning in the log.

**Español**
- **Corregido:** advertencia de Lua de los atajos de teclado (`Bindings.xml`) — los atajos siguen funcionando, sin más advertencia en el registro.

## 0.52.0
**Português**
- **Novo:** progresso da varredura do KrononMarket no rodapé da janela — mostra "Varrendo a Casa de Leilões... NN%" enquanto o preço de mercado está sendo atualizado e some sozinho ao terminar.
- **Melhorado:** integração opcional — sem o KrononMarket o comportamento é idêntico ao anterior.

**English**
- **New:** KrononMarket scan progress in the window footer — shows "Scanning the Auction House... NN%" while market prices are being refreshed and disappears on its own when done.
- **Improved:** optional integration — without KrononMarket the behavior is identical to before.

**Español**
- **Nuevo:** progreso del escaneo de KrononMarket en el pie de la ventana — muestra "Escaneando la Casa de Subastas... NN%" mientras se actualizan los precios de mercado y desaparece solo al terminar.
- **Mejorado:** integración opcional — sin KrononMarket el comportamiento es idéntico al anterior.

## 0.51.0
**Português**
- **Novo:** busca global cross-character — botão "Onde está?" mostra em qual personagem, banco ou Brigada um item está, usando os snapshots já salvos (só-leitura).
- **Novo:** atalhos de teclado nativos (menu Teclas → KrononBags): abrir/fechar a janela, focar a busca e alternar grade/categorias.
- **Melhorado:** o tooltip de contagem agora também mostra **Seu banco** (além dos alts e da Brigada).

**English**
- **New:** cross-character global search — a "Where is it?" button shows which character, bank or Warband holds an item, using the already-saved snapshots (read-only).
- **New:** native key bindings (Key Bindings menu → KrononBags): open/close the window, focus the search box, and toggle grid/categories.
- **Improved:** the count tooltip now also shows **Your bank** (in addition to alts and Warband).

**Español**
- **Nuevo:** búsqueda global entre personajes — el botón "¿Dónde está?" muestra en qué personaje, banco o Banda de guerra está un objeto, usando los snapshots ya guardados (solo lectura).
- **Nuevo:** atajos de teclado nativos (menú Teclas → KrononBags): abrir/cerrar la ventana, enfocar la búsqueda y alternar cuadrícula/categorías.
- **Mejorado:** el tooltip de conteo ahora también muestra **Tu banco** (además de los alts y la Banda de guerra).

## 0.50.0
**Português**
- **Corrigido:** a versão de interface declarada voltou para **12.0.7** (a 12.1.0 anterior foi engano e fazia o addon aparecer como "Incompatível").
- **Novo:** os addons Kronon agora aparecem agrupados sob "Kronon" na lista de addons do jogo.

**English**
- **Fixed:** the declared interface version is back to **12.0.7** (the previous 12.1.0 was a mistake that made the addon show as "Out of date").
- **New:** Kronon addons now appear grouped under "Kronon" in the game's addon list.

**Español**
- **Corregido:** la versión de interfaz declarada volvió a **12.0.7** (la 12.1.0 anterior fue un error que hacía aparecer el addon como "Incompatible").
- **Nuevo:** los addons Kronon ahora aparecen agrupados bajo "Kronon" en la lista de addons del juego.

## 0.49.0
**Português**
- **Melhorado:** o addon passa a usar a biblioteca **KrononLib** (i18n compartilhado do ecossistema Kronon). Sem mudanças visíveis — mesmas traduções, base interna unificada.

**English**
- **Improved:** the addon now uses the **KrononLib** library (shared i18n from the Kronon ecosystem). No visible changes — same translations, unified internal base.

**Español**
- **Mejorado:** el addon ahora usa la biblioteca **KrononLib** (i18n compartido del ecosistema Kronon). Sin cambios visibles — mismas traducciones, base interna unificada.

## 0.48.0
**Português**
- Compatível com o patch **12.1.0** (Midnight).

**English**
- Compatible with patch **12.1.0** (Midnight).

**Español**
- Compatible con el parche **12.1.0** (Midnight).

## 0.47.0
**Português**
- **Novo:** o valor de mercado agora usa o **KrononMarket** (do ecossistema Kronon) como fonte preferida.
- **Alternativa:** **Auctionator** e **TSM** continuam como fontes alternativas; **preço de venda** como fallback.

**English**
- **New:** market value now uses **KrononMarket** (from the Kronon ecosystem) as the preferred source.
- **Fallback:** **Auctionator** and **TSM** remain as alternative sources; **vendor sell price** as fallback.

**Español**
- **Nuevo:** el valor de mercado ahora usa **KrononMarket** (del ecosistema Kronon) como fuente preferida.
- **Alternativa:** **Auctionator** y **TSM** siguen como fuentes alternativas; **precio de venta** como reserva.

## 0.46.0
**Português**
- **Corrigido:** comprar aba do banco com **"Substituir banco"** ligado não dá mais erro (era um taint causado ao tocar o banco no login).
- **Novo:** botão **"Comprar aba"** na janela do banco — compre abas sem desligar a substituição.

**English**
- **Fixed:** buying a bank tab with **"Replace bank"** on no longer errors (it was taint from touching the bank at login).
- **New:** **"Buy tab"** button in the bank window — buy tabs without turning off the replacement.

**Español**
- **Corregido:** comprar una pestaña del banco con **"Reemplazar banco"** activado ya no da error (era un taint por tocar el banco al iniciar sesión).
- **Nuevo:** botón **"Comprar pestaña"** en la ventana del banco — compra pestañas sin desactivar el reemplazo.

## 0.45.0
**Português**
- **Novo:** categoria **Montarias** — separa as montarias das demais categorias.
- **Busca** agora reconhece a palavra-chave **montaria** (também **mount**/**montura**).

**English**
- **New:** **Mounts** category — keeps mounts in their own group.
- **Search** now recognizes the **mount** keyword (also **montaria**/**montura**).

**Español**
- **Nuevo:** categoría **Monturas** — separa las monturas del resto.
- La **búsqueda** ahora reconoce la palabra clave **montura** (también **montaria**/**mount**).

## 0.44.0
**Português**
- **Melhorado:** os **temas de cor** agora mudam também a **cor de destaque** — cabeçalhos de categoria, título da janela, "Vazio" e sub-grupos — não só o fundo.
- **Corrigido:** o **seletor de tema** fica **desativado** quando a **Moldura Blizzard** está ligada (o tema de cor não se aplica à moldura nativa).

**English**
- **Improved:** **color themes** now also change the **accent color** — category headers, window title, "Empty" and sub-groups — not just the background.
- **Fixed:** the **theme picker** is now **disabled** while the **Blizzard frame** is on (color themes don't apply to the native frame).

**Español**
- **Mejorado:** los **temas de color** ahora también cambian el **color de acento** — encabezados de categoría, título de la ventana, "Vacío" y subgrupos — no solo el fondo.
- **Corregido:** el **selector de tema** ahora se **desactiva** cuando el **Marco Blizzard** está activado (los temas de color no se aplican al marco nativo).

## 0.43.0
**Português**
- **Melhorado:** janela de **configuração reorganizada** com **sub-títulos de grupo** e espaçamento mais claro.
- **Comportamento** agora dividido em **Janela**, **Organização**, **Busca** e **Proteção & Alts**.
- **Aparência** separa **Janela** (moldura, opacidade, colunas) do **Tema** de cor.

**English**
- **Improved:** **settings window reorganized** with **group sub-headings** and clearer spacing.
- **Behavior** now split into **Window**, **Organization**, **Search** and **Protection & Alts**.
- **Appearance** separates **Window** (frame, opacity, columns) from the color **Theme**.

**Español**
- **Mejorado:** **ventana de ajustes reorganizada** con **subtítulos de grupo** y espaciado más claro.
- **Comportamiento** ahora dividido en **Ventana**, **Organización**, **Búsqueda** y **Protección y Alts**.
- **Apariencia** separa **Ventana** (marco, opacidad, columnas) del **Tema** de color.

## 0.42.0
**Português**
- **Novo:** **temas de cor** — Escuro, Ardósia, Dourado, Kronon, Druida e Rubi.
- Escolha num **menu suspenso** com **pré-visualização ao vivo**: passe o mouse pra ver antes de aplicar.
- Substitui a antiga opção "Cores Blizzard"; a "Moldura Blizzard" continua separada.

**English**
- **New:** **color themes** — Dark, Slate, Gold, Kronon, Druid and Ruby.
- Pick from a **dropdown** with **live preview**: hover to see it before applying.
- Replaces the old "Blizzard colors" option; "Blizzard frame" stays separate.

**Español**
- **Nuevo:** **temas de color** — Oscuro, Pizarra, Dorado, Kronon, Druida y Rubí.
- Elige en un **menú desplegable** con **vista previa en vivo**: pasa el ratón para verlo antes de aplicar.
- Reemplaza la antigua opción "Colores Blizzard"; el "Marco Blizzard" sigue aparte.

## 0.41.0
**Português**
- **Melhorado:** o painel de **Histórico** agora mostra o **tooltip do item** ao passar o mouse (como no inventário).
- **Novo:** nome **colorido por qualidade** e **borda de qualidade** no ícone.
- **Novo:** **Shift-clique** numa linha **linka o item no chat**.
- Realce de hover por linha e visual mais polido.

**English**
- **Improved:** the **History** panel now shows the **item tooltip** on hover (like in your bags).
- **New:** name **colored by quality** and a **quality border** on the icon.
- **New:** **Shift-click** a row to **link the item in chat**.
- Per-row hover highlight and a more polished look.

**Español**
- **Mejorado:** el panel de **Historial** ahora muestra el **tooltip del objeto** al pasar el ratón (como en las bolsas).
- **Nuevo:** nombre **coloreado por calidad** y **borde de calidad** en el icono.
- **Nuevo:** **Shift-clic** en una fila para **enlazar el objeto en el chat**.
- Resaltado al pasar el ratón por fila y un aspecto más pulido.

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
