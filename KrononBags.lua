-- KrononBags - bag unificada (v0.3)
-- Categorias ORDENÁVEIS (presets com filtro + customizadas), conjuntos de
-- equipamento (PvP/PvE), ordenar por ilvl, favoritos e proteção de venda.
-- Header estilo Blizzard com botão de organizar automático. Comando: /kb
-- Clique ESQUERDO = menu | Clique DIREITO = equipar/usar | Alt+clique = favoritar
local ADDON_NAME = ...

-- ---------------- Estado ----------------
local DB
local UI, CFG
local goldText, currencyText, freeBox, freeNum, reagentBox, reagentNum, emptyHeader
local Refresh, RenderGrid, OnEnter, AcquireButton, Categorize, GetIlvl, Toggle, CreateUI, OpenItemMenu, ResolveCat
local ToggleFavorite -- usada em OpenItemMenu (definida acima da implementação)
local ApplyOpacity, CreateConfig, ToggleConfig, UpdateMoney, UpdateTabs, UpdateModeBar, SearchMatcher, RefreshConfigCats
local CreateFilterBuilder
local KB_THEMES, KB_Accent, KB_AccentHex -- temas de cor + accent (definidos antes da janela; usados em headers/sub-headers/título)

-- Histórico de entradas/saídas (rastreio sempre ligado; painel opt-in pelo botão de relógio)
local RenderHistory          -- definida dentro de CreateUI (acessa o pool/painel)
local kbHistory = {}         -- eventos recentes, mais novo no índice 1 (cap 50)
local kbLastCounts = {}      -- itemID -> contagem total nas bolsas (último snapshot)
local kbLastLink = {}        -- itemID -> link representativo (pra itens que saíram das bolsas)
local kbHistInit = false     -- o 1º snapshot só calibra (não despeja o inventário inteiro)

local BAGS = { 0, 1, 2, 3, 4, 5 } -- mochila + 4 bolsas + bolsa de reagentes
local COLS = 14
local COLS_MIN, COLS_MAX = 6, 28 -- faixa de colunas (slider + redimensionar pela alça)
local SBW    = 16  -- largura reservada pra barra de rolagem à direita
local BTN    = 37
local PAD    = 4   -- espaço ENTRE itens
local MARGIN = 10  -- distância da borda da janela
local search = ""

-- ---------------- Idiomas (i18n) ----------------
-- Detecção automática pelo idioma do cliente. EN é a base (todas as chaves);
-- ptBR e esES sobrescrevem. Fallback do metatable: chave inexistente devolve a
-- própria chave (nunca quebra a UI).
local KB_PREFIX = "|cfff0d98cKrononBags|r: "
local LOCALE = (GetLocale and GetLocale()) or "enUS"
local L = setmetatable({}, { __index = function(_, k) return k end })

local EN = {
  -- categorias (rótulo de exibição; o nome interno continua pt-BR)
  CAT_NEW = "Newly acquired", CAT_FAVORITES = "Favorites", CAT_KEYSTONE = "Keystone",
  CAT_EQUIP = "Gear", CAT_CONSUMABLE = "Consumables", CAT_REAGENT = "Reagents",
  CAT_TRADE = "Trade Goods", CAT_QUEST = "Quest", CAT_JUNK = "Junk", CAT_MISC = "Miscellaneous",
  -- genéricos
  ITEM = "Item", CATEGORY = "Category",
  -- botões
  BTN_EQUIP = "Equip", BTN_DISTRIBUTE = "Distribute", BTN_CREATE = "Create",
  BTN_CANCEL = "Cancel", BTN_SAVE = "Save", BTN_CLOSE = "Close", BTN_IMPORT = "Import",
  BTN_EXPORT = "Export", BTN_DELETE = "Delete", BTN_RULE = "Rule", BTN_PRESET = "Preset…",
  BTN_SELL_JUNK = "Sell Junk", BTN_DEPOSIT = "Deposit Items",
  -- v0.23.0: transferir pela busca + categoria Abríveis
  CAT_OPENABLE = "Openable", CAT_MOUNTS = "Mounts",
  BTN_OPEN_ALL = "Open all",
  TIP_TRANSFER_SELL_TITLE = "Sell filtered",
  TIP_TRANSFER_SELL_BODY = "Sell all items matching the current search (asks to confirm).",
  TIP_TRANSFER_DEPOSIT_TITLE = "Deposit filtered",
  TIP_TRANSFER_DEPOSIT_BODY = "Deposit all items matching the current search into the bank.",
  TIP_OPEN_ALL = "Open all loot containers (skips locked ones).",
  MSG_TRANSFER_SOLD = "Sold %d item(s) matching the search.",
  MSG_TRANSFER_DEPOSITED = "Deposited %d item(s) matching the search.",
  CONFIRM_TRANSFER_SELL = "Sell %d item(s) matching the search?",
  -- abas
  TAB_BAGS = "Backpack", TAB_BANK = "Bank", TAB_WARBAND = "Warband",
  -- menu de item
  MENU_PICKUP = "Move (pick up item)", MENU_MOVE_TO_CAT = "Move to category",
  MENU_CREATE_CAT_HINT = "(create a category in the settings)", MENU_NEW_CAT = "New category…",
  MENU_REMOVE_FROM_CAT = "Remove from category",
  MENU_FAVORITE = "Favorite (protect from selling)", MENU_UNFAVORITE = "Unfavorite (allow selling)",
  -- menu de categoria
  MENU_EXPAND_THIS = "Expand this", MENU_COLLAPSE_THIS = "Collapse this",
  MENU_COLLAPSE_ALL = "Collapse all", MENU_EXPAND_ALL = "Expand all",
  MENU_FAV_ALL = "Favorite all (protect from selling)", MENU_UNFAV_ALL = "Unfavorite all",
  MENU_DEPOSIT_ALL = "Deposit all to bank",
  -- tooltips de item / estrela
  TIP_CACHED_STORED = "📦 Stored in the bank (preview)",
  TIP_CACHED_GOTOBANK = "Go to the bank to move/withdraw.",
  TIP_RIGHT_ACTIONS = "Right: use / equip / open / sell",
  TIP_LEFT_PICKUP = "Left: pick up / drag",
  TIP_STAR = "Star: click = favorite  |  right = menu",
  TIP_STACKED = "Visual stack — use/sell affects 1 stack",
  TIP_STAR_AUTOFAV = "Automatic favorite — it's in an Equipment Set (protected from selling)",
  TIP_STAR_ACTIONS = "Left: favorite (protect from selling)\nRight: menu (move to category)",
  -- tooltips de cabeçalho de categoria
  TIP_DROP_HERE = "Drop here: put item in this category",
  TIP_LEFT_EXPAND = "Left: expand", TIP_LEFT_COLLAPSE = "Left: collapse",
  TIP_HEADER_ACTIONS = "Right: actions  ·  drag an item here to categorize",
  TIP_DISTRIBUTE_TITLE = "Distribute newly acquired",
  TIP_DISTRIBUTE_BODY = "Empties this section: each item goes to its category.",
  -- tooltips dos controles da janela
  TIP_CONFIG = "Settings", TIP_SEARCH_TITLE = "Advanced search",
  TIP_SEARCH_L1 = "name  ·  ilvl>200  ·  ilvl:200-300  ·  q:epic  ·  type:armor",
  TIP_SEARCH_L2 = "words: boe, wb, bound, quest, junk, equip, consumable, new, favorite",
  TIP_SEARCH_L3 = "operators:  & (and)   | (or)   ! (not)   ( )",
  TIP_AUTOSORT = "Auto-sort",
  TIP_SELLJUNK_TITLE = "Sell all gray items (junk)",
  TIP_SELLJUNK_BODY = "Uses the game's native selling. Careful: favorited gray items are sold too.",
  TIP_VIEW_CATS = "View by categories", TIP_VIEW_GRID = "View all slots (grid)",
  TIP_DEPOSIT = "Automatically deposits the items marked for deposit in this bank",
  TIP_GRIP = "Drag to change columns and height",
  -- vazio / banner de cache
  EMPTY = "Empty", EMPTY_BANK_FREE = "%d free slot(s) in the bank", JUNK_LABEL = "Junk",
  CACHE_BANNER = "📦 Preview — you are not at the bank", CACHE_SAVED = " · saved %s",
  -- popups
  POPUP_NEWCAT = "New category name:",
  POPUP_RULE = "Category rule (search that fills it automatically).\nE.g.: ilvl>200 & boe   |   type:armor   |   q:epic\nLeave empty to make it a manual category.",
  POPUP_EXPORT = "Copy the code (Ctrl+C) and share it:",
  POPUP_IMPORT = "Paste the category code (merges with yours):",
  -- mensagens de chat (sem o prefixo, que é concatenado)
  MSG_BANK_FULL = "bank full.",
  MSG_EQUIPSET_AUTOFAV = "Equipment Set item — automatically favorited/protected (remove it from the set to release).",
  MSG_NO_EQUIP_COMBAT = "can't swap equipment in combat.",
  MSG_CATS_IMPORTED = "categories imported.",
  MSG_IMPORT_FAILED = "import failed (%s).",
  MSG_SELLJUNK_UNAVAIL = "sell junk function is unavailable in this version.",
  MSG_RELOAD_VISUAL = "type |cffffff00/reload|r to apply the new look.",
  MSG_RELOAD_BANK = "type |cffffff00/reload|r to apply the bank swap.",
  MSG_RELOAD_BAG = "type |cffffff00/reload|r to apply the bag swap.",
  MSG_REPAIR_GUILD = "repaired with guild funds (%s).",
  MSG_REPAIR_SELF = "repaired for %s.",
  MSG_REPAIR_NOGOLD = "not enough gold to repair (%s).",
  MSG_OPEN_BANK_ONCE = "open the bank once to be able to check it from afar.",
  -- erros de import
  IMP_ERR_EMPTY = "empty", IMP_ERR_FORMAT = "invalid format", IMP_ERR_NOCATS = "no categories",
  -- config: seções
  SEC_APPEARANCE = "Appearance", SEC_BEHAVIOR = "Behavior", SEC_CATEGORIES = "Categories",
  SEC_ICONS = "Icons", SEC_VENDOR = "Vendor", SEC_BANK = "Bank", SEC_ABOUT = "About",
  -- config: opções
  OPT_BLIZZ_FRAME = "Blizzard frame", OPT_BLIZZ_COLORS = "Blizzard colors (dark)",
  THEME_LABEL = "Theme",
  -- config: rótulos de grupo (sub-títulos)
  GRP_WINDOW = "Window", GRP_ORGANIZE = "Organization", GRP_SEARCH = "Search", GRP_PROTECT = "Protection & Alts",
  THEME_DARK = "Dark", THEME_SLATE = "Slate", THEME_GOLD = "Gold", THEME_KRONON = "Kronon", THEME_DRUID = "Druid", THEME_RUBY = "Ruby",
  THEME_NEEDS_DARK = "Turn off the Blizzard frame to use color themes.",
  OPT_SHOW_ILVL = "Show item level", OPT_ILVL_RARITY = "Color item level by rarity",
  OPT_GEAR_TRACK = "Show upgrade track",
  OPT_PROTECT = "Protect items (don't sell)", OPT_AUTOOPEN = "Open at vendor/bank",
  OPT_BANK_REPLACE = "Replace bank / Warband", OPT_ALT_COUNTS = "Alt counts (tooltip)",
  OPT_REPLACE_BAGS = "Replace the game's bags (B key)", OPT_STACK = "Stack identical items",
  OPT_QUAL_BORDER = "Colored border (rarity)", OPT_SEARCH_HL = "Highlight search",
  OPT_AUTOSELL = "Auto-sell junk", OPT_AUTOREPAIR = "Auto-repair",
  OPT_OPACITY = "Background opacity: %d%%", OPT_COLS = "Columns (items per row): %d",
  -- config: tooltips das opções
  TIP_OPT_BLIZZ_FRAME = "Use WoW's native frame instead of the dark KrononBags look.",
  TIP_OPT_BLIZZ_COLORS = "Use Blizzard's default color scheme.",
  TIP_OPT_SHOW_ILVL = "Show item level on gear in the icon corner.",
  TIP_OPT_GEAR_TRACK = "Show the gear upgrade track on the icon (e.g. Hero 4/6).",
  TIP_OPT_ILVL_RARITY = "On: item level in the rarity color. Off: item level in white.",
  TIP_OPT_QUAL_BORDER = "Colored border on the icon by rarity (junk = gray; common = no border).",
  TIP_OPT_AUTOOPEN = "Open KrononBags automatically at a vendor or bank.",
  TIP_OPT_REPLACE_BAGS = "The B key and bag buttons open KrononBags. Needs /reload.",
  TIP_OPT_STACK = "Merge stacks of the same item into one icon, summing the count.",
  TIP_OPT_SEARCH_HL = "When searching, dim non-matching items instead of hiding them.",
  TIP_OPT_PROTECT = "Protect items that are in a category from being sold.",
  TIP_OPT_ALT_COUNTS = "In the item tooltip, show how many your other characters have.",
  TIP_OPT_AUTOSELL = "Sell all gray items automatically when you open a vendor.",
  TIP_OPT_AUTOREPAIR = "Repair everything at a vendor (uses guild funds when possible).",
  TIP_OPT_BANK_REPLACE = "Replace the native bank and Warband bank with KrononBags. Needs /reload. (To buy bank tabs, turn this off + /reload.)",
  TIP_OPT_OPACITY = "Window transparency.",
  TIP_OPT_COLS = "How many item columns the window shows.",
  TIP_OPT_SORT = "How items are ordered inside each category.",
  -- v0.27.0: sub-grupos por expansão
  OPT_NEST_EXPANSION = "Group by expansion",
  TIP_OPT_NEST_EXPANSION = "Inside each category, sub-group items by their expansion.",
  OPT_COMPACT_EXPAC = "Compact expansion groups",
  TIP_OPT_COMPACT_EXPAC = "When grouping by expansion, flow groups side by side instead of one per row.",
  EXPAC_UNKNOWN = "Other",
  -- config: ordenação
  SORT_ILVL = "Item level", SORT_QUALITY = "Quality", SORT_NAME = "Name",
  SORT_TYPE = "Type", SORT_RECENT = "Recent", SORT_BY = "Sort by: ", SORT_MENU_TITLE = "Sort items by",
  -- config: categorias
  CAT_HINT = "Order (top → bottom) = order in the inventory. ▲▼ moves, Delete removes.",
  TAG_PRESET = "(preset)", TAG_RULE = "(rule)", TAG_CUSTOM = "(yours)",
  PRESET_MENU_TITLE = "Add preset category", PRESET_ALL_ADDED = "(all already added)",
  CONFIG_TITLE = "KrononBags — Settings",
  -- painel de prontidão
  READY_TITLE = "Readiness", READY_HINT = "Supplies counted in the backpack",
  READY_DURABILITY = "Durability", READY_FLASK = "Flask", READY_POTION = "Potion",
  READY_FOOD = "Food", READY_HEALTHSTONE = "Healthstone", READY_RUNE = "Rune/enchant",
  READY_KEYSTONE = "M+ Keystone", READY_MISSING = "missing", READY_NONE = "none",
  -- tooltip de contagem nos alts
  WARBAND_LABEL = "Warband",
  -- valor pela Auction House (tooltip + total por categoria)
  MARKET_VALUE = "Market (AH)", SELL_VALUE = "Sell price",
  -- painel de ouro por personagem (hover no rodapé)
  GOLD_PANEL_TITLE = "Gold per character", GOLD_WARBAND = "Warband bank", GOLD_TOTAL = "Total",
  -- ajuda / limpar busca
  TIP_HELP = "Tips — click to show/hide",
  TIP_SEARCH_CLEAR = "Clear search",
  HELP_TITLE = "KrononBags — Help",
  HELP_CATEGORIES = "Categories: items sort automatically. Drag an item onto a category header to assign it; drop on Favorites to protect, on Misc to reset.",
  HELP_SEARCH = "Search: name, ilvl>200, q:epic, type:armor, words (boe, wb, quest, junk, equip, new, fav) with & | ! and ( ).",
  HELP_FAVORITES = "Favorites: click the star to protect an item from selling. Equipment Manager gear is auto-protected (blue star).",
  HELP_BANK = "Bank/Warband: tabs appear at the bank, and the content stays viewable from anywhere (last snapshot). Command: /kb banco.",
  HELP_SORT = "Sort: the broom button auto-organizes your bags. Auto-sell junk and auto-repair run at vendors (toggle in options).",
  HELP_CONTROLLER = "Controller: full ConsolePort support — move across the item grid with the D-pad.",
  HELP_COMMANDS = "Commands: /kb, /kb config, /kb grade, /kb organizar, /kb pronto, /kb banco.",
  -- v0.25.0: barra de modos de visualização + tour guiado
  MODE_CATEGORIES = "Categories", MODE_GRID = "Grid",
  TUT_NEXT = "Next", TUT_PREV = "Back", TUT_CLOSE = "Close",
  TUT_SEARCH_TITLE = "Search",
  TUT_SEARCH_BODY = "Search by name, ilvl>200, q:epic, type:armor — with & | ! and ( ).",
  TUT_MODES_TITLE = "View modes",
  TUT_MODES_BODY = "Switch between Categories and Grid view here.",
  TUT_SORT_TITLE = "Organize",
  TUT_SORT_BODY = "Auto-organizes your bags in one click.",
  TUT_TABS_TITLE = "Tabs",
  TUT_TABS_BODY = "Bags, Bank and Warband — the bank tabs appear at the bank.",
  TUT_HELP_TITLE = "Help",
  TUT_HELP_BODY = "Reopen this tour anytime from this button.",
  TUT_CATEGORIES_TITLE = "Categories",
  TUT_CATEGORIES_BODY = "Items auto-sort into categories. Drag an item onto a category header to assign it; right-click the header for actions.",
  TUT_FOOTER_TITLE = "Footer",
  TUT_FOOTER_BODY = "Gold, currencies and free slots show here.",
  TUT_FILTER_TITLE = "Search builder",
  TUT_FILTER_BODY = "Build a search visually — pick fields and it writes the query for you.",
  TUT_HISTORY_TITLE = "History",
  TUT_HISTORY_BODY = "See what recently came in and out of your bags.",
  -- v0.29.0: construtor de busca modular
  FILTER_BTN = "Filter", FILTER_TITLE = "Search builder",
  FILTER_ADD = "Add filter", FILTER_APPLY = "Apply", FILTER_CLEAR = "Clear",
  FILTER_ALL = "Match all (AND)", FILTER_ANY = "Match any (OR)", FILTER_NOT = "NOT",
  FIELD_ILVL = "Item level", FIELD_QUALITY = "Quality", FIELD_TYPE = "Type",
  FIELD_BIND = "Bind", FIELD_FLAG = "Marker", FIELD_NAME = "Name",
  COND_GT = "greater than", COND_LT = "less than", COND_GE = "at least", COND_LE = "at most",
  COND_EQ = "equal to", COND_BETWEEN = "between", COND_IS = "is", COND_ATLEAST = "at least",
  FTYPE_EQUIP = "Gear", FTYPE_CONSUM = "Consumable", FTYPE_QUEST = "Quest", FTYPE_JUNK = "Junk",
  FBIND_BOE = "BoE", FBIND_BOU = "BoU", FBIND_WB = "Warband", FBIND_BOUND = "Soulbound",
  FFLAG_NEW = "New", FFLAG_FAV = "Favorite",
  FILTER_HINT = "Pick a field, set the value, Apply. It builds the search for you.",
  FTIP_ILVL = "Filters by item level.", FTIP_QUALITY = "Filters by item quality.",
  FTIP_TYPE = "Filters by item type.", FTIP_BIND = "Filters by bind type.",
  FTIP_FLAG = "Filters by marker (new / favorite).", FTIP_NAME = "Filters by part of the name.",
  FTIP_COND = "How to compare the value.", FTIP_BETWEEN = "Between two values.",
  FTIP_NOT = "Excludes what matches.", FTIP_REMOVE = "Remove this filter.",
  FTIP_VALUE = "Set the value to match.",
  -- v0.30.0: histórico de entradas/saídas
  HIST_BTN = "History", HIST_TITLE = "Recent changes", HIST_EMPTY = "No recent changes",
  HIST_HINT = "Shift-click to link in chat",
  -- v0.32.0: comparação com o equipado no tooltip
  CMP_HEADER = "vs. equipped", CMP_PAWN = "Pawn upgrade",
}

local PT = {
  CAT_NEW = "Recém-obtidos", CAT_FAVORITES = "Favoritos", CAT_KEYSTONE = "Pedra-chave",
  CAT_EQUIP = "Equipamento", CAT_CONSUMABLE = "Consumíveis", CAT_REAGENT = "Reagentes",
  CAT_TRADE = "Materiais", CAT_QUEST = "Missão", CAT_JUNK = "Lixo", CAT_MISC = "Diversos",
  ITEM = "Item", CATEGORY = "Categoria",
  BTN_EQUIP = "Equipar", BTN_DISTRIBUTE = "Distribuir", BTN_CREATE = "Criar",
  BTN_CANCEL = "Cancelar", BTN_SAVE = "Salvar", BTN_CLOSE = "Fechar", BTN_IMPORT = "Importar",
  BTN_EXPORT = "Exportar", BTN_DELETE = "Excluir", BTN_RULE = "Regra", BTN_PRESET = "Pré-pronta…",
  BTN_SELL_JUNK = "Vender lixo", BTN_DEPOSIT = "Depositar itens",
  CAT_OPENABLE = "Abríveis", CAT_MOUNTS = "Montarias",
  BTN_OPEN_ALL = "Abrir tudo",
  TIP_TRANSFER_SELL_TITLE = "Vender filtrados",
  TIP_TRANSFER_SELL_BODY = "Vende todos os itens que batem com a busca atual (pede confirmação).",
  TIP_TRANSFER_DEPOSIT_TITLE = "Depositar filtrados",
  TIP_TRANSFER_DEPOSIT_BODY = "Deposita no banco todos os itens que batem com a busca atual.",
  TIP_OPEN_ALL = "Abre todos os recipientes de loot (pula os trancados).",
  MSG_TRANSFER_SOLD = "Vendido(s) %d item(ns) que batem com a busca.",
  MSG_TRANSFER_DEPOSITED = "Depositado(s) %d item(ns) que batem com a busca.",
  CONFIRM_TRANSFER_SELL = "Vender %d item(ns) que batem com a busca?",
  TAB_BAGS = "Mochila", TAB_BANK = "Banco", TAB_WARBAND = "Brigada",
  MENU_PICKUP = "Mover (pegar item)", MENU_MOVE_TO_CAT = "Mover para categoria",
  MENU_CREATE_CAT_HINT = "(crie uma categoria na config)", MENU_NEW_CAT = "Nova categoria…",
  MENU_REMOVE_FROM_CAT = "Tirar da categoria",
  MENU_FAVORITE = "Favoritar (protege de venda)", MENU_UNFAVORITE = "Desfavoritar (libera venda)",
  MENU_EXPAND_THIS = "Expandir esta", MENU_COLLAPSE_THIS = "Recolher esta",
  MENU_COLLAPSE_ALL = "Recolher todas", MENU_EXPAND_ALL = "Expandir todas",
  MENU_FAV_ALL = "Favoritar todos (protege de venda)", MENU_UNFAV_ALL = "Desfavoritar todos",
  MENU_DEPOSIT_ALL = "Guardar tudo no banco",
  TIP_CACHED_STORED = "📦 Guardado no banco (visualização)",
  TIP_CACHED_GOTOBANK = "Vá até o banco pra mover/sacar.",
  TIP_RIGHT_ACTIONS = "Direito: usar / equipar / abrir / vender",
  TIP_LEFT_PICKUP = "Esquerdo: pegar / arrastar",
  TIP_STAR = "Estrela: clique = favoritar  |  direito = menu",
  TIP_STACKED = "Pilha visual — usar/vender afeta 1 stack",
  TIP_STAR_AUTOFAV = "Favorito automático — está num Conjunto de Equipamento (protegido de venda)",
  TIP_STAR_ACTIONS = "Esquerdo: favoritar (protege de venda)\nDireito: menu (mover p/ categoria)",
  TIP_DROP_HERE = "Soltar aqui: jogar item nesta categoria",
  TIP_LEFT_EXPAND = "Esquerdo: expandir", TIP_LEFT_COLLAPSE = "Esquerdo: recolher",
  TIP_HEADER_ACTIONS = "Direito: ações  ·  arraste um item aqui pra categorizar",
  TIP_DISTRIBUTE_TITLE = "Distribuir recém-obtidos",
  TIP_DISTRIBUTE_BODY = "Esvazia esta seção: cada item vai pra sua categoria.",
  TIP_CONFIG = "Configurações", TIP_SEARCH_TITLE = "Busca avançada",
  TIP_SEARCH_L1 = "nome  ·  ilvl>200  ·  ilvl:200-300  ·  q:epico  ·  tipo:armadura",
  TIP_SEARCH_L2 = "palavras: boe, wb, vinculado, missao, lixo, equip, consumivel, novo, favorito",
  TIP_SEARCH_L3 = "operadores:  & (e)   | (ou)   ! (não)   ( )",
  TIP_AUTOSORT = "Organizar automático",
  TIP_SELLJUNK_TITLE = "Vende todos os itens cinza (lixo)",
  TIP_SELLJUNK_BODY = "Usa a venda nativa do jogo. Cuidado: cinza favoritado também é vendido.",
  TIP_VIEW_CATS = "Ver por categorias", TIP_VIEW_GRID = "Ver todos os slots (grade)",
  TIP_DEPOSIT = "Guarda automaticamente os itens marcados pra depósito neste banco",
  TIP_GRIP = "Arraste pra mudar colunas e altura",
  EMPTY = "Vazio", EMPTY_BANK_FREE = "%d slot(s) livre(s) no banco", JUNK_LABEL = "Lixo",
  CACHE_BANNER = "📦 Visualização — você não está no banco", CACHE_SAVED = " · salvo %s",
  POPUP_NEWCAT = "Nome da nova categoria:",
  POPUP_RULE = "Regra da categoria (busca que preenche sozinha).\nEx: ilvl>200 & boe   |   tipo:armadura   |   q:epico\nDeixe vazio pra virar categoria manual.",
  POPUP_EXPORT = "Copie o código (Ctrl+C) e compartilhe:",
  POPUP_IMPORT = "Cole o código de categorias (mescla com as suas):",
  MSG_BANK_FULL = "banco cheio.",
  MSG_EQUIPSET_AUTOFAV = "item de Conjunto de Equipamento — favorito/protegido automaticamente (tire-o do conjunto pra liberar).",
  MSG_NO_EQUIP_COMBAT = "não dá pra trocar equipamento em combate.",
  MSG_CATS_IMPORTED = "categorias importadas.",
  MSG_IMPORT_FAILED = "import falhou (%s).",
  MSG_SELLJUNK_UNAVAIL = "função de vender lixo indisponível nesta versão.",
  MSG_RELOAD_VISUAL = "dê |cffffff00/reload|r pra aplicar o novo visual.",
  MSG_RELOAD_BANK = "dê |cffffff00/reload|r pra aplicar a troca de banco.",
  MSG_RELOAD_BAG = "dê |cffffff00/reload|r pra aplicar a troca da bag.",
  MSG_REPAIR_GUILD = "reparado com fundos da guilda (%s).",
  MSG_REPAIR_SELF = "reparado por %s.",
  MSG_REPAIR_NOGOLD = "ouro insuficiente pra reparar (%s).",
  MSG_OPEN_BANK_ONCE = "abra o banco uma vez pra poder consultá-lo de longe.",
  IMP_ERR_EMPTY = "vazio", IMP_ERR_FORMAT = "formato inválido", IMP_ERR_NOCATS = "sem categorias",
  SEC_APPEARANCE = "Aparência", SEC_BEHAVIOR = "Comportamento", SEC_CATEGORIES = "Categorias",
  SEC_ICONS = "Ícones", SEC_VENDOR = "Vendedor", SEC_BANK = "Banco", SEC_ABOUT = "Sobre",
  OPT_BLIZZ_FRAME = "Moldura Blizzard", OPT_BLIZZ_COLORS = "Cores Blizzard (escuro)",
  THEME_LABEL = "Tema",
  GRP_WINDOW = "Janela", GRP_ORGANIZE = "Organização", GRP_SEARCH = "Busca", GRP_PROTECT = "Proteção & Alts",
  THEME_DARK = "Escuro", THEME_SLATE = "Ardósia", THEME_GOLD = "Dourado", THEME_KRONON = "Kronon", THEME_DRUID = "Druida", THEME_RUBY = "Rubi",
  THEME_NEEDS_DARK = "Desative a Moldura Blizzard para usar temas de cor.",
  OPT_SHOW_ILVL = "Mostrar item level", OPT_ILVL_RARITY = "Colorir item level pela raridade",
  OPT_GEAR_TRACK = "Mostrar trilha de upgrade",
  OPT_PROTECT = "Proteger itens (não vender)", OPT_AUTOOPEN = "Abrir no vendedor/banco",
  OPT_BANK_REPLACE = "Substituir banco / Brigada", OPT_ALT_COUNTS = "Contagem nos alts (tooltip)",
  OPT_REPLACE_BAGS = "Substituir a bag do jogo (tecla B)", OPT_STACK = "Empilhar itens iguais",
  OPT_QUAL_BORDER = "Borda colorida (raridade)", OPT_SEARCH_HL = "Realçar busca",
  OPT_AUTOSELL = "Auto-vender lixo", OPT_AUTOREPAIR = "Auto-reparar",
  OPT_OPACITY = "Opacidade do fundo: %d%%", OPT_COLS = "Colunas (itens por fileira): %d",
  TIP_OPT_BLIZZ_FRAME = "Usa a moldura nativa do WoW em vez do visual escuro do KrononBags.",
  TIP_OPT_BLIZZ_COLORS = "Usa o esquema de cores padrão da Blizzard.",
  TIP_OPT_SHOW_ILVL = "Mostra o item level no canto do ícone do equipamento.",
  TIP_OPT_GEAR_TRACK = "Mostra a trilha de upgrade do equipamento no ícone (ex: Herói 4/6).",
  TIP_OPT_ILVL_RARITY = "Ligado: item level na cor da raridade. Desligado: item level em branco.",
  TIP_OPT_QUAL_BORDER = "Borda colorida no ícone pela raridade (lixo = cinza; comum = sem borda).",
  TIP_OPT_AUTOOPEN = "Abre o KrononBags sozinho ao falar com vendedor ou abrir o banco.",
  TIP_OPT_REPLACE_BAGS = "A tecla B e os botões de bolsa passam a abrir o KrononBags. Precisa de /reload.",
  TIP_OPT_STACK = "Junta stacks do mesmo item num ícone só, somando a contagem.",
  TIP_OPT_SEARCH_HL = "Na busca, escurece o que não bate em vez de esconder.",
  TIP_OPT_PROTECT = "Protege de venda os itens que estão em alguma categoria.",
  TIP_OPT_ALT_COUNTS = "No tooltip do item, mostra quanto seus outros personagens têm dele.",
  TIP_OPT_AUTOSELL = "Vende todos os itens cinza automaticamente ao abrir o vendedor.",
  TIP_OPT_AUTOREPAIR = "Repara tudo ao abrir o vendedor (usa fundos da guilda quando dá).",
  TIP_OPT_BANK_REPLACE = "Substitui o banco e o banco da Brigada nativos pelo KrononBags. Precisa de /reload. (Pra comprar abas do banco, desligue + /reload.)",
  TIP_OPT_OPACITY = "Transparência da janela.",
  TIP_OPT_COLS = "Quantas colunas de itens a janela mostra.",
  TIP_OPT_SORT = "Como os itens são ordenados dentro de cada categoria.",
  OPT_NEST_EXPANSION = "Agrupar por expansão",
  TIP_OPT_NEST_EXPANSION = "Dentro de cada categoria, sub-agrupa os itens pela expansão de origem.",
  OPT_COMPACT_EXPAC = "Sub-grupos compactos",
  TIP_OPT_COMPACT_EXPAC = "Ao agrupar por expansão, flui os grupos lado a lado em vez de um por linha.",
  EXPAC_UNKNOWN = "Outros",
  SORT_ILVL = "Item level", SORT_QUALITY = "Qualidade", SORT_NAME = "Nome",
  SORT_TYPE = "Tipo", SORT_RECENT = "Recentes", SORT_BY = "Ordenar por: ", SORT_MENU_TITLE = "Ordenar itens por",
  CAT_HINT = "Ordem (cima → baixo) = ordem no inventário. ▲▼ move, Excluir remove.",
  TAG_PRESET = "(pré-pronta)", TAG_RULE = "(regra)", TAG_CUSTOM = "(sua)",
  PRESET_MENU_TITLE = "Adicionar categoria pré-pronta", PRESET_ALL_ADDED = "(todas já adicionadas)",
  CONFIG_TITLE = "KrononBags — Configurações",
  READY_TITLE = "Prontidão", READY_HINT = "Suprimentos contados na mochila",
  READY_DURABILITY = "Durabilidade", READY_FLASK = "Frasco", READY_POTION = "Poção",
  READY_FOOD = "Comida", READY_HEALTHSTONE = "Pedra de Vida", READY_RUNE = "Runa/encantamento",
  READY_KEYSTONE = "Pedra-chave M+", READY_MISSING = "falta", READY_NONE = "nenhuma",
  WARBAND_LABEL = "Brigada",
  MARKET_VALUE = "Mercado (AH)", SELL_VALUE = "Preço de venda",
  GOLD_PANEL_TITLE = "Ouro por personagem", GOLD_WARBAND = "Banco da Brigada", GOLD_TOTAL = "Total",
  TIP_HELP = "Dicas — clique para mostrar/esconder",
  TIP_SEARCH_CLEAR = "Limpar busca",
  HELP_TITLE = "KrononBags — Ajuda",
  HELP_CATEGORIES = "Categorias: os itens se organizam sozinhos. Arraste um item pro cabeçalho de uma categoria pra atribuí-lo; solte em Favoritos pra proteger, em Diversos pra resetar.",
  HELP_SEARCH = "Busca: nome, ilvl>200, q:epico, tipo:armadura, palavras (boe, wb, missao, lixo, equip, novo, favorito) com & | ! e ( ).",
  HELP_FAVORITES = "Favoritos: clique na estrela pra proteger um item de venda. Itens do Gerenciador de Equipamento são protegidos automaticamente (estrela azul).",
  HELP_BANK = "Banco/Brigada: as abas aparecem no banco, e o conteúdo fica consultável de qualquer lugar (último retrato). Comando: /kb banco.",
  HELP_SORT = "Organizar: o botão de vassoura organiza as bolsas. Auto-vender lixo e auto-reparar rodam no vendedor (ligar/desligar nas opções).",
  HELP_CONTROLLER = "Controle: suporte completo ao ConsolePort — ande pela grade de itens com o direcional.",
  HELP_COMMANDS = "Comandos: /kb, /kb config, /kb grade, /kb organizar, /kb pronto, /kb banco.",
  MODE_CATEGORIES = "Categorias", MODE_GRID = "Grade",
  TUT_NEXT = "Próximo", TUT_PREV = "Anterior", TUT_CLOSE = "Fechar",
  TUT_SEARCH_TITLE = "Busca",
  TUT_SEARCH_BODY = "Busque por nome, ilvl>200, q:epico, tipo:armadura — com & | ! e ( ).",
  TUT_MODES_TITLE = "Modos de visão",
  TUT_MODES_BODY = "Alterne entre ver por Categorias ou em Grade aqui.",
  TUT_SORT_TITLE = "Organizar",
  TUT_SORT_BODY = "Organiza suas bolsas automaticamente num clique.",
  TUT_TABS_TITLE = "Abas",
  TUT_TABS_BODY = "Mochila, Banco e Brigada — as abas do banco aparecem no banco.",
  TUT_HELP_TITLE = "Ajuda",
  TUT_HELP_BODY = "Reabra este tour quando quiser por este botão.",
  TUT_CATEGORIES_TITLE = "Categorias",
  TUT_CATEGORIES_BODY = "Os itens se organizam em categorias. Arraste um item pro cabeçalho de uma categoria pra atribuí-lo; clique-direito no cabeçalho pra ações.",
  TUT_FOOTER_TITLE = "Rodapé",
  TUT_FOOTER_BODY = "Ouro, currencies e slots livres aparecem aqui.",
  TUT_FILTER_TITLE = "Construtor de busca",
  TUT_FILTER_BODY = "Monte uma busca visualmente — escolha os campos e ele escreve a consulta pra você.",
  TUT_HISTORY_TITLE = "Histórico",
  TUT_HISTORY_BODY = "Veja o que entrou e saiu das suas bolsas recentemente.",
  -- v0.29.0: construtor de busca modular
  FILTER_BTN = "Filtrar", FILTER_TITLE = "Construtor de busca",
  FILTER_ADD = "Adicionar filtro", FILTER_APPLY = "Aplicar", FILTER_CLEAR = "Limpar",
  FILTER_ALL = "Todos (E)", FILTER_ANY = "Qualquer (OU)", FILTER_NOT = "NÃO",
  FIELD_ILVL = "Item level", FIELD_QUALITY = "Qualidade", FIELD_TYPE = "Tipo",
  FIELD_BIND = "Vínculo", FIELD_FLAG = "Marcador", FIELD_NAME = "Nome",
  COND_GT = "maior que", COND_LT = "menor que", COND_GE = "pelo menos", COND_LE = "no máximo",
  COND_EQ = "igual a", COND_BETWEEN = "entre", COND_IS = "é", COND_ATLEAST = "pelo menos",
  FTYPE_EQUIP = "Equipamento", FTYPE_CONSUM = "Consumível", FTYPE_QUEST = "Missão", FTYPE_JUNK = "Lixo",
  FBIND_BOE = "BoE", FBIND_BOU = "BoU", FBIND_WB = "Brigada", FBIND_BOUND = "Vinculado",
  FFLAG_NEW = "Novo", FFLAG_FAV = "Favorito",
  FILTER_HINT = "Escolha um campo, defina o valor e Aplique. Ele monta a busca pra você.",
  FTIP_ILVL = "Filtra pelo item level.", FTIP_QUALITY = "Filtra pela qualidade do item.",
  FTIP_TYPE = "Filtra pelo tipo do item.", FTIP_BIND = "Filtra pelo tipo de vínculo.",
  FTIP_FLAG = "Filtra pelo marcador (novo / favorito).", FTIP_NAME = "Filtra por parte do nome.",
  FTIP_COND = "Como comparar o valor.", FTIP_BETWEEN = "Entre dois valores.",
  FTIP_NOT = "Exclui o que bate.", FTIP_REMOVE = "Remove este filtro.",
  FTIP_VALUE = "Defina o valor a casar.",
  -- v0.30.0: histórico de entradas/saídas
  HIST_BTN = "Histórico", HIST_TITLE = "Mudanças recentes", HIST_EMPTY = "Nenhuma mudança recente",
  HIST_HINT = "Shift-clique para linkar no chat",
  -- v0.32.0: comparação com o equipado no tooltip
  CMP_HEADER = "vs. equipado", CMP_PAWN = "Upgrade (Pawn)",
}

local ES = {
  CAT_NEW = "Recién obtenidos", CAT_FAVORITES = "Favoritos", CAT_KEYSTONE = "Piedra angular",
  CAT_EQUIP = "Equipo", CAT_CONSUMABLE = "Consumibles", CAT_REAGENT = "Componentes",
  CAT_TRADE = "Materiales", CAT_QUEST = "Misión", CAT_JUNK = "Basura", CAT_MISC = "Varios",
  ITEM = "Objeto", CATEGORY = "Categoría",
  BTN_EQUIP = "Equipar", BTN_DISTRIBUTE = "Distribuir", BTN_CREATE = "Crear",
  BTN_CANCEL = "Cancelar", BTN_SAVE = "Guardar", BTN_CLOSE = "Cerrar", BTN_IMPORT = "Importar",
  BTN_EXPORT = "Exportar", BTN_DELETE = "Eliminar", BTN_RULE = "Regla", BTN_PRESET = "Predefinida…",
  BTN_SELL_JUNK = "Vender basura", BTN_DEPOSIT = "Depositar objetos",
  CAT_OPENABLE = "Para abrir", CAT_MOUNTS = "Monturas",
  BTN_OPEN_ALL = "Abrir todo",
  TIP_TRANSFER_SELL_TITLE = "Vender filtrados",
  TIP_TRANSFER_SELL_BODY = "Vende todos los objetos que coinciden con la búsqueda actual (pide confirmación).",
  TIP_TRANSFER_DEPOSIT_TITLE = "Depositar filtrados",
  TIP_TRANSFER_DEPOSIT_BODY = "Deposita en el banco todos los objetos que coinciden con la búsqueda actual.",
  TIP_OPEN_ALL = "Abre todos los contenedores de botín (omite los bloqueados).",
  MSG_TRANSFER_SOLD = "Vendido(s) %d objeto(s) que coinciden con la búsqueda.",
  MSG_TRANSFER_DEPOSITED = "Depositado(s) %d objeto(s) que coinciden con la búsqueda.",
  CONFIRM_TRANSFER_SELL = "¿Vender %d objeto(s) que coinciden con la búsqueda?",
  TAB_BAGS = "Mochila", TAB_BANK = "Banco", TAB_WARBAND = "Banda de guerra",
  MENU_PICKUP = "Mover (recoger objeto)", MENU_MOVE_TO_CAT = "Mover a categoría",
  MENU_CREATE_CAT_HINT = "(crea una categoría en los ajustes)", MENU_NEW_CAT = "Nueva categoría…",
  MENU_REMOVE_FROM_CAT = "Quitar de la categoría",
  MENU_FAVORITE = "Marcar favorito (protege de venta)", MENU_UNFAVORITE = "Quitar favorito (permite venta)",
  MENU_EXPAND_THIS = "Expandir esta", MENU_COLLAPSE_THIS = "Contraer esta",
  MENU_COLLAPSE_ALL = "Contraer todas", MENU_EXPAND_ALL = "Expandir todas",
  MENU_FAV_ALL = "Marcar todos favoritos (protege de venta)", MENU_UNFAV_ALL = "Quitar todos los favoritos",
  MENU_DEPOSIT_ALL = "Depositar todo en el banco",
  TIP_CACHED_STORED = "📦 Guardado en el banco (vista previa)",
  TIP_CACHED_GOTOBANK = "Ve al banco para mover/retirar.",
  TIP_RIGHT_ACTIONS = "Derecho: usar / equipar / abrir / vender",
  TIP_LEFT_PICKUP = "Izquierdo: recoger / arrastrar",
  TIP_STAR = "Estrella: clic = favorito  |  derecho = menú",
  TIP_STACKED = "Pila visual — usar/vender afecta 1 grupo",
  TIP_STAR_AUTOFAV = "Favorito automático — está en un Conjunto de equipo (protegido de venta)",
  TIP_STAR_ACTIONS = "Izquierdo: favorito (protege de venta)\nDerecho: menú (mover a categoría)",
  TIP_DROP_HERE = "Suelta aquí: poner objeto en esta categoría",
  TIP_LEFT_EXPAND = "Izquierdo: expandir", TIP_LEFT_COLLAPSE = "Izquierdo: contraer",
  TIP_HEADER_ACTIONS = "Derecho: acciones  ·  arrastra un objeto aquí para categorizar",
  TIP_DISTRIBUTE_TITLE = "Distribuir recién obtenidos",
  TIP_DISTRIBUTE_BODY = "Vacía esta sección: cada objeto va a su categoría.",
  TIP_CONFIG = "Ajustes", TIP_SEARCH_TITLE = "Búsqueda avanzada",
  TIP_SEARCH_L1 = "nombre  ·  ilvl>200  ·  ilvl:200-300  ·  q:epic  ·  tipo:armadura",
  TIP_SEARCH_L2 = "palabras: boe, wb, bound, quest, junk, equip, consumable, new, fav",
  TIP_SEARCH_L3 = "operadores:  & (y)   | (o)   ! (no)   ( )",
  TIP_AUTOSORT = "Organizar automático",
  TIP_SELLJUNK_TITLE = "Vende todos los objetos grises (basura)",
  TIP_SELLJUNK_BODY = "Usa la venta nativa del juego. Cuidado: los grises favoritos también se venden.",
  TIP_VIEW_CATS = "Ver por categorías", TIP_VIEW_GRID = "Ver todas las casillas (cuadrícula)",
  TIP_DEPOSIT = "Deposita automáticamente los objetos marcados para depósito en este banco",
  TIP_GRIP = "Arrastra para cambiar columnas y altura",
  EMPTY = "Vacío", EMPTY_BANK_FREE = "%d casilla(s) libre(s) en el banco", JUNK_LABEL = "Basura",
  CACHE_BANNER = "📦 Vista previa — no estás en el banco", CACHE_SAVED = " · guardado %s",
  POPUP_NEWCAT = "Nombre de la nueva categoría:",
  POPUP_RULE = "Regla de la categoría (búsqueda que la llena sola).\nEj: ilvl>200 & boe   |   tipo:armadura   |   q:epic\nDéjalo vacío para que sea una categoría manual.",
  POPUP_EXPORT = "Copia el código (Ctrl+C) y compártelo:",
  POPUP_IMPORT = "Pega el código de categorías (se fusiona con las tuyas):",
  MSG_BANK_FULL = "banco lleno.",
  MSG_EQUIPSET_AUTOFAV = "objeto de Conjunto de equipo — favorito/protegido automáticamente (quítalo del conjunto para liberarlo).",
  MSG_NO_EQUIP_COMBAT = "no se puede cambiar de equipo en combate.",
  MSG_CATS_IMPORTED = "categorías importadas.",
  MSG_IMPORT_FAILED = "la importación falló (%s).",
  MSG_SELLJUNK_UNAVAIL = "la función de vender basura no está disponible en esta versión.",
  MSG_RELOAD_VISUAL = "usa |cffffff00/reload|r para aplicar el nuevo aspecto.",
  MSG_RELOAD_BANK = "usa |cffffff00/reload|r para aplicar el cambio de banco.",
  MSG_RELOAD_BAG = "usa |cffffff00/reload|r para aplicar el cambio de bolsa.",
  MSG_REPAIR_GUILD = "reparado con fondos del clan (%s).",
  MSG_REPAIR_SELF = "reparado por %s.",
  MSG_REPAIR_NOGOLD = "oro insuficiente para reparar (%s).",
  MSG_OPEN_BANK_ONCE = "abre el banco una vez para poder consultarlo desde lejos.",
  IMP_ERR_EMPTY = "vacío", IMP_ERR_FORMAT = "formato inválido", IMP_ERR_NOCATS = "sin categorías",
  SEC_APPEARANCE = "Apariencia", SEC_BEHAVIOR = "Comportamiento", SEC_CATEGORIES = "Categorías",
  SEC_ICONS = "Iconos", SEC_VENDOR = "Vendedor", SEC_BANK = "Banco", SEC_ABOUT = "Acerca de",
  OPT_BLIZZ_FRAME = "Marco Blizzard", OPT_BLIZZ_COLORS = "Colores Blizzard (oscuro)",
  THEME_LABEL = "Tema",
  GRP_WINDOW = "Ventana", GRP_ORGANIZE = "Organización", GRP_SEARCH = "Búsqueda", GRP_PROTECT = "Protección y Alts",
  THEME_DARK = "Oscuro", THEME_SLATE = "Pizarra", THEME_GOLD = "Dorado", THEME_KRONON = "Kronon", THEME_DRUID = "Druida", THEME_RUBY = "Rubí",
  THEME_NEEDS_DARK = "Desactiva el Marco Blizzard para usar temas de color.",
  OPT_SHOW_ILVL = "Mostrar nivel de objeto", OPT_ILVL_RARITY = "Colorear nivel de objeto por rareza",
  OPT_GEAR_TRACK = "Mostrar nivel de mejora",
  OPT_PROTECT = "Proteger objetos (no vender)", OPT_AUTOOPEN = "Abrir en vendedor/banco",
  OPT_BANK_REPLACE = "Reemplazar banco / Banda de guerra", OPT_ALT_COUNTS = "Cantidad en alters (tooltip)",
  OPT_REPLACE_BAGS = "Reemplazar las bolsas del juego (tecla B)", OPT_STACK = "Apilar objetos iguales",
  OPT_QUAL_BORDER = "Borde de color (rareza)", OPT_SEARCH_HL = "Resaltar búsqueda",
  OPT_AUTOSELL = "Auto-vender basura", OPT_AUTOREPAIR = "Auto-reparar",
  OPT_OPACITY = "Opacidad del fondo: %d%%", OPT_COLS = "Columnas (objetos por fila): %d",
  TIP_OPT_BLIZZ_FRAME = "Usa el marco nativo de WoW en lugar del aspecto oscuro de KrononBags.",
  TIP_OPT_BLIZZ_COLORS = "Usa el esquema de colores predeterminado de Blizzard.",
  TIP_OPT_SHOW_ILVL = "Muestra el nivel de objeto en la esquina del icono del equipo.",
  TIP_OPT_GEAR_TRACK = "Muestra el nivel de mejora del equipo en el icono (p. ej. Héroe 4/6).",
  TIP_OPT_ILVL_RARITY = "Activado: nivel de objeto en el color de rareza. Desactivado: en blanco.",
  TIP_OPT_QUAL_BORDER = "Borde de color en el icono por rareza (basura = gris; común = sin borde).",
  TIP_OPT_AUTOOPEN = "Abre KrononBags automáticamente en un vendedor o banco.",
  TIP_OPT_REPLACE_BAGS = "La tecla B y los botones de bolsa abren KrononBags. Requiere /reload.",
  TIP_OPT_STACK = "Combina montones del mismo objeto en un icono, sumando la cantidad.",
  TIP_OPT_SEARCH_HL = "Al buscar, atenúa lo que no coincide en lugar de ocultarlo.",
  TIP_OPT_PROTECT = "Protege de la venta los objetos que están en una categoría.",
  TIP_OPT_ALT_COUNTS = "En la información del objeto, muestra cuántos tienen tus otros personajes.",
  TIP_OPT_AUTOSELL = "Vende todos los objetos grises automáticamente al abrir un vendedor.",
  TIP_OPT_AUTOREPAIR = "Repara todo en el vendedor (usa fondos del clan cuando es posible).",
  TIP_OPT_BANK_REPLACE = "Reemplaza el banco y el banco de la banda de guerra nativos por KrononBags. Requiere /reload. (Para comprar pestañas, desactiva + /reload.)",
  TIP_OPT_OPACITY = "Transparencia de la ventana.",
  TIP_OPT_COLS = "Cuántas columnas de objetos muestra la ventana.",
  TIP_OPT_SORT = "Cómo se ordenan los objetos dentro de cada categoría.",
  OPT_NEST_EXPANSION = "Agrupar por expansión",
  TIP_OPT_NEST_EXPANSION = "Dentro de cada categoría, subagrupa los objetos por su expansión.",
  OPT_COMPACT_EXPAC = "Subgrupos compactos",
  TIP_OPT_COMPACT_EXPAC = "Al agrupar por expansión, fluye los grupos lado a lado en vez de uno por fila.",
  EXPAC_UNKNOWN = "Otros",
  SORT_ILVL = "Nivel de objeto", SORT_QUALITY = "Calidad", SORT_NAME = "Nombre",
  SORT_TYPE = "Tipo", SORT_RECENT = "Recientes", SORT_BY = "Ordenar por: ", SORT_MENU_TITLE = "Ordenar objetos por",
  CAT_HINT = "Orden (arriba → abajo) = orden en el inventario. ▲▼ mueve, Eliminar quita.",
  TAG_PRESET = "(predefinida)", TAG_RULE = "(regla)", TAG_CUSTOM = "(tuya)",
  PRESET_MENU_TITLE = "Añadir categoría predefinida", PRESET_ALL_ADDED = "(todas ya añadidas)",
  CONFIG_TITLE = "KrononBags — Ajustes",
  READY_TITLE = "Preparación", READY_HINT = "Suministros contados en la mochila",
  READY_DURABILITY = "Durabilidad", READY_FLASK = "Frasco", READY_POTION = "Poción",
  READY_FOOD = "Comida", READY_HEALTHSTONE = "Piedra de salud", READY_RUNE = "Runa/encantamiento",
  READY_KEYSTONE = "Piedra angular M+", READY_MISSING = "falta", READY_NONE = "ninguna",
  WARBAND_LABEL = "Banda de guerra",
  MARKET_VALUE = "Mercado (CA)", SELL_VALUE = "Precio de venta",
  GOLD_PANEL_TITLE = "Oro por personaje", GOLD_WARBAND = "Banco de la banda de guerra", GOLD_TOTAL = "Total",
  TIP_HELP = "Consejos — clic para mostrar/ocultar",
  TIP_SEARCH_CLEAR = "Limpiar búsqueda",
  HELP_TITLE = "KrononBags — Ayuda",
  HELP_CATEGORIES = "Categorías: los objetos se ordenan solos. Arrastra un objeto al encabezado de una categoría para asignarlo; suéltalo en Favoritos para protegerlo, en Varios para restablecer.",
  HELP_SEARCH = "Búsqueda: nombre, ilvl>200, q:epic, type:armor, palabras (boe, wb, quest, junk, equip, new, fav) con & | ! y ( ).",
  HELP_FAVORITES = "Favoritos: haz clic en la estrella para proteger un objeto de la venta. El equipo del Administrador de equipo se protege automáticamente (estrella azul).",
  HELP_BANK = "Banco/Banda de guerra: las pestañas aparecen en el banco, y el contenido queda consultable desde cualquier lugar (última captura). Comando: /kb banco.",
  HELP_SORT = "Organizar: el botón de escoba organiza las bolsas. Vender basura y reparar automáticos funcionan en el vendedor (en opciones).",
  HELP_CONTROLLER = "Mando: soporte completo de ConsolePort — muévete por la cuadrícula de objetos con la cruceta.",
  HELP_COMMANDS = "Comandos: /kb, /kb config, /kb grade, /kb organizar, /kb pronto, /kb banco.",
  MODE_CATEGORIES = "Categorías", MODE_GRID = "Cuadrícula",
  TUT_NEXT = "Siguiente", TUT_PREV = "Atrás", TUT_CLOSE = "Cerrar",
  TUT_SEARCH_TITLE = "Búsqueda",
  TUT_SEARCH_BODY = "Busca por nombre, ilvl>200, q:epic, type:armor — con & | ! y ( ).",
  TUT_MODES_TITLE = "Modos de vista",
  TUT_MODES_BODY = "Cambia entre la vista por Categorías y Cuadrícula aquí.",
  TUT_SORT_TITLE = "Organizar",
  TUT_SORT_BODY = "Organiza tus bolsas automáticamente con un clic.",
  TUT_TABS_TITLE = "Pestañas",
  TUT_TABS_BODY = "Bolsas, Banco y Banda de guerra — las pestañas del banco aparecen en el banco.",
  TUT_HELP_TITLE = "Ayuda",
  TUT_HELP_BODY = "Reabre este tour cuando quieras con este botón.",
  TUT_CATEGORIES_TITLE = "Categorías",
  TUT_CATEGORIES_BODY = "Los objetos se ordenan en categorías. Arrastra un objeto al encabezado de una categoría para asignarlo; clic derecho en el encabezado para acciones.",
  TUT_FOOTER_TITLE = "Pie",
  TUT_FOOTER_BODY = "Oro, monedas y espacios libres se muestran aquí.",
  TUT_FILTER_TITLE = "Constructor de búsqueda",
  TUT_FILTER_BODY = "Crea una búsqueda visualmente — elige los campos y él escribe la consulta por ti.",
  TUT_HISTORY_TITLE = "Historial",
  TUT_HISTORY_BODY = "Mira lo que entró y salió de tus bolsas recientemente.",
  -- v0.29.0: constructor de búsqueda modular
  FILTER_BTN = "Filtrar", FILTER_TITLE = "Constructor de búsqueda",
  FILTER_ADD = "Añadir filtro", FILTER_APPLY = "Aplicar", FILTER_CLEAR = "Limpiar",
  FILTER_ALL = "Todos (Y)", FILTER_ANY = "Cualquiera (O)", FILTER_NOT = "NO",
  FIELD_ILVL = "Nivel de objeto", FIELD_QUALITY = "Calidad", FIELD_TYPE = "Tipo",
  FIELD_BIND = "Vínculo", FIELD_FLAG = "Marcador", FIELD_NAME = "Nombre",
  COND_GT = "mayor que", COND_LT = "menor que", COND_GE = "al menos", COND_LE = "como máximo",
  COND_EQ = "igual a", COND_BETWEEN = "entre", COND_IS = "es", COND_ATLEAST = "al menos",
  FTYPE_EQUIP = "Equipo", FTYPE_CONSUM = "Consumible", FTYPE_QUEST = "Misión", FTYPE_JUNK = "Basura",
  FBIND_BOE = "BoE", FBIND_BOU = "BoU", FBIND_WB = "Banda de guerra", FBIND_BOUND = "Vinculado",
  FFLAG_NEW = "Nuevo", FFLAG_FAV = "Favorito",
  FILTER_HINT = "Elige un campo, define el valor y Aplica. Construye la búsqueda por ti.",
  FTIP_ILVL = "Filtra por el nivel de objeto.", FTIP_QUALITY = "Filtra por la calidad del objeto.",
  FTIP_TYPE = "Filtra por el tipo de objeto.", FTIP_BIND = "Filtra por el tipo de vínculo.",
  FTIP_FLAG = "Filtra por el marcador (nuevo / favorito).", FTIP_NAME = "Filtra por parte del nombre.",
  FTIP_COND = "Cómo comparar el valor.", FTIP_BETWEEN = "Entre dos valores.",
  FTIP_NOT = "Excluye lo que coincide.", FTIP_REMOVE = "Quitar este filtro.",
  FTIP_VALUE = "Define el valor a coincidir.",
  -- v0.30.0: historial de entradas/salidas
  HIST_BTN = "Historial", HIST_TITLE = "Cambios recientes", HIST_EMPTY = "Sin cambios recientes",
  HIST_HINT = "Shift-clic para enlazar en el chat",
  -- v0.32.0: comparación con lo equipado en el tooltip
  CMP_HEADER = "vs. equipado", CMP_PAWN = "Mejora (Pawn)",
}

for k, v in pairs(EN) do L[k] = v end
if LOCALE == "ptBR" then for k, v in pairs(PT) do L[k] = v end
elseif LOCALE == "esES" or LOCALE == "esMX" then for k, v in pairs(ES) do L[k] = v end end

-- Mapa nome-interno-da-categoria → chave de tradução. Nomes internos (pt-BR) são
-- CHAVES de dados (DB.assignments/collapsed, comparações, ResolveCat) e NÃO mudam;
-- só o RÓTULO exibido é traduzido. Categoria custom (fora do mapa) mostra o próprio nome.
local CAT_DISPLAY_KEY = {
  ["Recém-obtidos"] = "CAT_NEW", ["Favoritos"] = "CAT_FAVORITES", ["Pedra-chave"] = "CAT_KEYSTONE",
  ["Equipamento"] = "CAT_EQUIP", ["Consumíveis"] = "CAT_CONSUMABLE", ["Reagentes"] = "CAT_REAGENT",
  ["Materiais"] = "CAT_TRADE", ["Missão"] = "CAT_QUEST", ["Lixo"] = "CAT_JUNK", ["Diversos"] = "CAT_MISC",
  ["Abríveis"] = "CAT_OPENABLE", ["Montarias"] = "CAT_MOUNTS",
}
local function CatDisplay(name)
  if name == nil then return nil end
  local key = CAT_DISPLAY_KEY[name]
  if key then return L[key] end
  return name
end

-- ---------------- Bancos (12.0): banco do personagem e da Brigada ----------------
-- BagIDs: mochila 0, bolsas 1-4, reagentes 5, banco do personagem 6-11,
-- banco da Brigada (warband) 12-16. As abas compradas vêm de C_Bank.
local BANK_CHAR = (Enum and Enum.BankType and Enum.BankType.Character) or 0
local BANK_ACCT = (Enum and Enum.BankType and Enum.BankType.Account)   or 2
local mode   = "bags"  -- aba ativa da janela: "bags" | "bank" | "warband"
local atBank = false   -- banco aberto agora?

-- abas (containers) compradas de um tipo de banco; {} se a API não existe (Classic)
local function PurchasedTabs(bankType)
  if C_Bank and C_Bank.FetchPurchasedBankTabIDs then
    local ok, ids = pcall(C_Bank.FetchPurchasedBankTabIDs, bankType)
    if ok and type(ids) == "table" then return ids end
  end
  return {}
end

-- bolsas que a janela mostra agora, conforme a aba ativa
local function ActiveBags()
  if mode == "bank"    then return PurchasedTabs(BANK_CHAR) end
  if mode == "warband" then return PurchasedTabs(BANK_ACCT) end
  return BAGS
end

local function WarbandAvailable()
  return #PurchasedTabs(BANK_ACCT) > 0
end

-- chave do personagem atual (pra salvar posição da janela por char)
local function CharKey()
  return (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
end

-- modo "visualização de cache": aba de banco/Brigada aberta SEM estar no banco de verdade
local function CachedMode()
  return (mode == "bank" or mode == "warband") and not atBank
end
-- snapshot salvo da aba ativa: itens (array), slots livres, hora da captura
local function CurrentSnap()
  if not DB then return nil end
  if mode == "warband" then return DB.warbandSnap, DB.warbandFree, DB.warbandTime end
  local ci = DB.charItems and DB.charItems[CharKey()]
  if ci then return ci.bankSnap, ci.bankFree, ci.bankTime end
  return nil
end
-- existe snapshot pra essa aba? (pra decidir se mostra a aba de longe)
local function HasCharBankSnap()
  local ci = DB and DB.charItems and DB.charItems[CharKey()]
  return ci and ci.bankSnap and #ci.bankSnap > 0
end
local function HasWarbandSnap() return DB and DB.warbandSnap and #DB.warbandSnap > 0 end

local pool = {}        -- pool de botões de item
local headerPool = {}  -- pool de cabeçalhos de seção
local subHeaderPool = {} -- pool de sub-cabeçalhos de expansão (sub-grupos por expansão)

-- catálogo de categorias pré-prontas (ordem de fresh install + menu "Pré-pronta…")
local KB_PRESETS = {
  { name = "Recém-obtidos", filter = "new" },
  { name = "Favoritos",   filter = "favorites" },
  { name = "Pedra-chave", filter = "keystone" },
  { name = "Equipamento", filter = "equip" },
  { name = "Montarias",   filter = "mounts" },
  { name = "Consumíveis", filter = "consumable" },
  { name = "Reagentes",   filter = "reagentbag" },
  { name = "Materiais",   filter = "trade" },
  { name = "Missão",      filter = "quest" },
  { name = "Abríveis",    filter = "openable" },
  { name = "Lixo",        filter = "junk" },
}

-- insere um preset novo na catList respeitando a ordem de KB_PRESETS
-- (antes do 1º preset "posterior" que já existe), pra não cair depois de Materiais
local function InjectPresetOrdered(p)
  local pIndex
  for i, kp in ipairs(KB_PRESETS) do if kp.filter == p.filter then pIndex = i; break end end
  local insertAt = #KrononBagsDB.catList + 1
  if pIndex then
    for i = pIndex + 1, #KB_PRESETS do
      local laterFilter = KB_PRESETS[i].filter
      for ci, c in ipairs(KrononBagsDB.catList) do
        if c.filter == laterFilter then if ci < insertAt then insertAt = ci end; break end
      end
    end
  end
  table.insert(KrononBagsDB.catList, insertAt, { name = p.name, filter = p.filter })
end

-- ---------------- SavedVariables ----------------
local function InitDB()
  KrononBagsDB = KrononBagsDB or {}
  KrononBagsDB.favorites   = KrononBagsDB.favorites or {}
  KrononBagsDB.protected   = KrononBagsDB.protected or {}
  KrononBagsDB.categories  = KrononBagsDB.categories or {}  -- legado (migrado p/ catList)
  KrononBagsDB.assignments = KrononBagsDB.assignments or {} -- [itemID] = nomeCategoria custom
  KrononBagsDB.collapsed   = KrononBagsDB.collapsed or {}   -- [nomeCategoria] = true (recolhida)
  KrononBagsDB.charPos     = KrononBagsDB.charPos or {}     -- [char-realm] = {point, relPoint, x, y}
  KrononBagsDB.charItems   = KrononBagsDB.charItems or {}   -- [char-realm] = {name, class, bags={}, bank={}} (contagem nos alts)
  KrononBagsDB.warband     = KrononBagsDB.warband or {}     -- [itemID] = qtd no banco da Brigada
  KrononBagsDB.recem       = KrononBagsDB.recem or {}       -- [itemID] = true (recém-obtido, fica até clicar em Distribuir)
  KrononBagsDB.introducedPresets = KrononBagsDB.introducedPresets or {} -- presets já injetados 1x
  KrononBagsDB.settings    = KrononBagsDB.settings or {}
  if KrononBagsDB.settings.opacity == nil then KrononBagsDB.settings.opacity = 0.92 end
  if KrononBagsDB.settings.autoProtectCategorized == nil then KrononBagsDB.settings.autoProtectCategorized = true end
  if KrononBagsDB.settings.blizzardStyle == nil then KrononBagsDB.settings.blizzardStyle = false end
  if KrononBagsDB.settings.theme == nil then -- migra do antigo blizzardStyle (cor): true => ardósia, senão escuro
    KrononBagsDB.settings.theme = KrononBagsDB.settings.blizzardStyle and "slate" or "dark"
  end
  if KrononBagsDB.settings.cols == nil then KrononBagsDB.settings.cols = 14 end
  if KrononBagsDB.settings.gridView == nil then KrononBagsDB.settings.gridView = false end
  if KrononBagsDB.settings.autoOpen == nil then KrononBagsDB.settings.autoOpen = true end
  if KrononBagsDB.settings.showIlvl == nil then KrononBagsDB.settings.showIlvl = true end
  if KrononBagsDB.settings.showGearTrack == nil then KrononBagsDB.settings.showGearTrack = true end -- trilha de upgrade (ex: H4/6) no ícone
  if KrononBagsDB.settings.ilvlUseRarity == nil then KrononBagsDB.settings.ilvlUseRarity = true end
  if KrononBagsDB.settings.frameStyle == nil then KrononBagsDB.settings.frameStyle = "dark" end -- "dark" (atual) | "blizzard" (moldura nativa)
  if KrononBagsDB.settings.bankReplace == nil then KrononBagsDB.settings.bankReplace = true end -- substituir o banco/Brigada nativo pelo KrononBags
  if KrononBagsDB.settings.altCounts == nil then KrononBagsDB.settings.altCounts = true end -- mostrar contagem nos alts no tooltip
  if KrononBagsDB.settings.maxHeight == nil then KrononBagsDB.settings.maxHeight = 520 end -- altura máxima visível (acima disso, rola)
  if KrononBagsDB.settings.replaceBags == nil then KrononBagsDB.settings.replaceBags = true end -- tecla B / botão da bolsa abrem o KrononBags
  if KrononBagsDB.settings.sortMode == nil then KrononBagsDB.settings.sortMode = "ilvl" end -- ordem dentro da categoria: ilvl/quality/name/type/recent
  if KrononBagsDB.settings.stackItems == nil then KrononBagsDB.settings.stackItems = false end -- empilhar itens iguais num ícone só
  if KrononBagsDB.settings.nestByExpansion == nil then KrononBagsDB.settings.nestByExpansion = false end -- sub-agrupar itens por expansão de origem dentro de cada categoria
  if KrononBagsDB.settings.compactExpac == nil then KrononBagsDB.settings.compactExpac = false end -- ao agrupar por expansão, fluir os sub-grupos lado a lado (compacto) em vez de um por linha
  if KrononBagsDB.settings.qualityBorder == nil then KrononBagsDB.settings.qualityBorder = true end -- borda colorida por raridade no ícone
  if KrononBagsDB.settings.searchHighlight == nil then KrononBagsDB.settings.searchHighlight = true end -- na busca, escurece o resto em vez de esconder
  if KrononBagsDB.settings.autoSellJunk == nil then KrononBagsDB.settings.autoSellJunk = true end -- vender lixo automaticamente ao abrir o vendedor
  if KrononBagsDB.settings.autoRepair == nil then KrononBagsDB.settings.autoRepair = true end -- reparar tudo ao abrir o vendedor (fundos da guilda quando possível)
  -- favoritar e proteger agora são UMA coisa só: migra protegidos antigos
  for id in pairs(KrononBagsDB.protected) do KrononBagsDB.favorites[id] = true end
  wipe(KrononBagsDB.protected)
  -- lista de categorias ordenáveis (presets com filtro + customizadas manuais)
  if KrononBagsDB.catList == nil then
    KrononBagsDB.catList = {}
    for _, nm in ipairs(KrononBagsDB.categories or {}) do
      table.insert(KrononBagsDB.catList, { name = nm }) -- filter nil = manual (custom)
    end
    for _, p in ipairs(KB_PRESETS) do
      table.insert(KrononBagsDB.catList, { name = p.name, filter = p.filter })
      KrononBagsDB.introducedPresets[p.filter] = true
    end
  else
    -- usuário já tem catList. Se introducedPresets nasceu vazio, é migração da v0.3:
    -- marca os presets ANTIGOS como já introduzidos pra NÃO ressuscitar os que o
    -- usuário apagou de propósito; assim só os presets NOVOS (keystone, reagentbag)
    -- são injetados, na posição certa da ordem.
    if not next(KrononBagsDB.introducedPresets) then
      for _, fil in ipairs({ "favorites", "equip", "consumable", "trade", "quest", "junk" }) do
        KrononBagsDB.introducedPresets[fil] = true
      end
    end
    for _, p in ipairs(KB_PRESETS) do
      if not KrononBagsDB.introducedPresets[p.filter] then
        KrononBagsDB.introducedPresets[p.filter] = true
        local has = false
        for _, c in ipairs(KrononBagsDB.catList) do
          if c.filter == p.filter or c.name == p.name then has = true; break end
        end
        if not has then InjectPresetOrdered(p) end
      end
    end
  end
  DB = KrononBagsDB
end

-- ---------------- Helpers de categoria (catList) ----------------
local function CatEntryByName(name)
  for _, c in ipairs(DB.catList) do if c.name == name then return c end end
end

-- existe categoria com esse nome? (custom OU preset — dá pra mover item p/ qualquer uma)
local function CategoryExists(name)
  return CatEntryByName(name) ~= nil
end

local function AddCategory(name)
  if name and name ~= "" and not CatEntryByName(name) then
    table.insert(DB.catList, 1, { name = name }) -- nova custom entra no topo
  end
end

local function DeleteCategory(entry)
  for i = #DB.catList, 1, -1 do
    if DB.catList[i] == entry then table.remove(DB.catList, i); break end
  end
  -- limpa atribuições manuais que apontavam pra essa categoria (custom ou preset)
  for id, c in pairs(DB.assignments) do
    if c == entry.name then DB.assignments[id] = nil end
  end
  DB.collapsed[entry.name] = nil -- limpa estado de recolhido órfão (não reaparece recolhida)
end

local function MoveCategory(i, dir)
  local j = i + dir
  if j < 1 or j > #DB.catList then return end
  DB.catList[i], DB.catList[j] = DB.catList[j], DB.catList[i]
end

local function AddPreset(p)
  for _, c in ipairs(DB.catList) do
    if c.filter == p.filter or c.name == p.name then return end -- já existe (filtro ou nome)
  end
  table.insert(DB.catList, { name = p.name, filter = p.filter })
end

-- ---------------- Export / Import de categorias (Layout Oficial da Guilda) ----------------
-- Serializa catList + assignments numa string compartilhável (sem depender de lib).
-- Escapa os separadores ; > = e \ pra nomes de categoria poderem conter qualquer coisa.
local KB_ESC = { ["\\"] = "\\\\", [";"] = "\\a", [">"] = "\\b", ["="] = "\\c" }
local KB_UNESC = { ["\\"] = "\\", a = ";", b = ">", c = "=" }
local function kbEsc(s) return (tostring(s):gsub("[\\;>=]", KB_ESC)) end
local function kbUnesc(s) return (s:gsub("\\(.)", KB_UNESC)) end

local function ExportCategories()
  local parts = { "KBCAT1" }
  for _, c in ipairs(DB.catList) do
    parts[#parts + 1] = "C>" .. kbEsc(c.name) .. ">" .. kbEsc(c.filter or "")
  end
  for id, name in pairs(DB.assignments) do
    parts[#parts + 1] = "A>" .. tostring(id) .. ">" .. kbEsc(name)
  end
  return table.concat(parts, ";")
end

-- replace=true substitui tudo; senão mescla (não destrói o que você já tem)
local function ImportCategories(str, replace)
  if type(str) ~= "string" or str == "" then return false, L.IMP_ERR_EMPTY end
  local recs = {}
  for r in (str .. ";"):gmatch("(.-);") do recs[#recs + 1] = r end
  if recs[1] ~= "KBCAT1" then return false, L.IMP_ERR_FORMAT end
  local newList, newAssign = {}, {}
  for i = 2, #recs do
    local kind, a, b = recs[i]:match("^(%a)>(.-)>(.*)$")
    if kind == "C" then
      newList[#newList + 1] = { name = kbUnesc(a), filter = (b ~= "" and kbUnesc(b)) or nil }
    elseif kind == "A" then
      local id = tonumber(a); if id then newAssign[id] = kbUnesc(b) end
    end
  end
  if #newList == 0 then return false, L.IMP_ERR_NOCATS end
  if replace then
    DB.catList, DB.assignments = newList, newAssign
  else
    for _, c in ipairs(newList) do
      local exists = false
      for _, e in ipairs(DB.catList) do if e.name == c.name then exists = true; break end end
      if not exists then table.insert(DB.catList, c) end
    end
    for id, name in pairs(newAssign) do DB.assignments[id] = name end
  end
  if Refresh then Refresh() end
  return true
end

-- ---------------- Filtros das categorias pré-prontas ----------------
local function classOf(itemID)
  return select(6, C_Item.GetItemInfoInstant(itemID)) or 15
end

-- detecção de Pedra-chave Mítica: itemID fixo + fallback por nome (memoizado)
local KEYSTONE_IDS = { [180653] = true }
local keystoneCache = {}
local function isKeystone(id)
  local c = keystoneCache[id]
  if c ~= nil then return c end
  if KEYSTONE_IDS[id] then keystoneCache[id] = true; return true end
  local name = C_Item.GetItemInfo(id)
  if not name then return false end -- nome ainda não carregou: não cacheia, tenta de novo depois
  local n = name:lower()
  local res = (n:find("pedra-chave", 1, true) or n:find("keystone", 1, true)) and true or false
  keystoneCache[id] = res
  return res
end

-- ---------------- Variação de item (chave estável) ----------------
-- Dois itens de MESMO nome mas ilvl/raridade/qualidade diferentes têm o mesmo itemID base
-- e bonusIDs diferentes. VariantKey monta uma chave canônica (itemID + bonusIDs ordenados +
-- qualidade de criação) pra distinguir variações. Descarta dono/enchant/gems/suffix/uniqueID/
-- linkLevel/spec/modifiersMask/itemContext (alinhado com Syndicator/Baganator). Robusto a link
-- nil/malformado: devolve nil sem erro.
local function VariantKey(link)
  if not link then return nil end
  local payload = link:match("item:([%-%d:]+)")   -- corpo numérico após item:
  if not payload then return nil end
  local f = { strsplit(":", payload) }             -- f[1]=itemID ... f[13]=numBonusIDs
  local itemID = tonumber(f[1]); if not itemID then return nil end
  local numBonus = tonumber(f[13]) or 0
  local bonuses = {}
  for i = 1, numBonus do bonuses[i] = tonumber(f[13 + i]) or 0 end
  table.sort(bonuses)                              -- canônico
  local craftQ, mStart = "", 14 + numBonus
  local numMods = tonumber(f[mStart]) or 0
  for i = 0, numMods - 1 do
    local t = tonumber(f[mStart + 1 + i*2]); local v = f[mStart + 2 + i*2]
    if t == 38 then craftQ = "q" .. tostring(v) end -- ITEM_MODIFIER_CRAFTING_QUALITY_ID
  end
  return itemID .. ":" .. table.concat(bonuses, ".") .. (craftQ ~= "" and ("#"..craftQ) or "")
end

-- favorito = protegido. Chaveado por VariantKey (variação exata), com COMPAT pra favoritos
-- legados (chaves numéricas itemID): a leitura checa AMBOS. (A escrita grava VariantKey;
-- desfavoritar limpa as duas — ver ToggleFavorite.)
local function IsFavorited(itemID, link)
  return (link and DB.favorites[VariantKey(link)]) or DB.favorites[itemID] or false
end

-- filtros recebem (itemID, quality, bag, slot, link). "reagentbag"/"keystone"/"new" são especiais.
local PRESET_FILTERS = {
  new        = function(id, q, bag, slot) return (DB and DB.recem and DB.recem[id]) and true or false end, -- recém-obtido (fica até clicar em Distribuir)
  favorites  = function(id, q, bag, slot, link) return IsFavorited(id, link) end,
  keystone   = function(id, q, bag) return isKeystone(id) end,                                -- Pedra-chave
  reagentbag = function(id, q, bag) return bag == 5 end,                                       -- bolsa de reagentes (loc)
  equip      = function(id, q, bag) local c = classOf(id); return c == 2 or c == 4 end,        -- arma / armadura
  mounts     = function(id) local _, _, _, _, _, c, sub = C_Item.GetItemInfoInstant(id); return c == 15 and sub == 5 end, -- montaria (Diversos / subclasse Montaria)
  consumable = function(id, q, bag) return classOf(id) == 0 end,                               -- consumível
  trade      = function(id, q, bag) local c = classOf(id); return c == 7 or c == 8 or c == 3 or c == 5 end, -- mats/gema/reagente
  quest      = function(id, q, bag) return classOf(id) == 12 end,                              -- missão
  openable   = function(id, q, bag, slot) if not (bag and slot) then return false end local info = C_Container.GetContainerItemInfo(bag, slot); return (info and info.hasLoot) and true or false end, -- recipiente de loot (hasLoot)
  junk       = function(id, q, bag) return q == 0 end,                                         -- lixo
}

-- catálogo de presets que dá pra adicionar na config (mesmo do fresh install)
local AVAILABLE_PRESETS = KB_PRESETS

-- ---------------- Conjuntos de Equipamento (auto PvP/PvE) ----------------
local equipSetByVariant = {} -- [VariantKey] = nome do conjunto
local equipSetNames = {}    -- lista ordenada de nomes de conjunto
local equipSetIDByName = {} -- [nome] = setID

-- Chaveia por VARIAÇÃO (não por itemID), pra casar a peça EXATA do conjunto (ilvl/bonusIDs).
-- Resolve cada location do conjunto pro link real: NÃO usa C_EquipmentSet.GetItemIDs (perde a
-- variação). Pula loc <= 0 e locations não-resolvíveis (peça que o jogador não tem não precisa
-- ser marcada).
local function RebuildEquipSets()
  wipe(equipSetByVariant); wipe(equipSetNames); wipe(equipSetIDByName)
  if not C_EquipmentSet then return end
  for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
    local name = C_EquipmentSet.GetEquipmentSetInfo(setID)
    if name then
      equipSetNames[#equipSetNames + 1] = name
      equipSetIDByName[name] = setID
      local locs = C_EquipmentSet.GetItemLocations and C_EquipmentSet.GetItemLocations(setID)
      if locs then
        for _, loc in pairs(locs) do
          if type(loc) == "number" and loc > 0 and EquipmentManager_GetLocationData then
            local d = EquipmentManager_GetLocationData(loc)
            local itemLoc
            if d then
              if d.isBags and d.bag and d.slot then
                itemLoc = ItemLocation:CreateFromBagAndSlot(d.bag, d.slot)
              elseif d.isPlayer and d.slot then
                itemLoc = ItemLocation:CreateFromEquipmentSlot(d.slot)
              end
            end
            if itemLoc and C_Item.DoesItemExist(itemLoc) then
              local key = VariantKey(C_Item.GetItemLink(itemLoc))
              if key then equipSetByVariant[key] = name end
            end
          end
        end
      end
    end
  end
end

-- ---------------- Categorização ----------------
-- item está numa categoria "de verdade" (manual ou conjunto de equipamento)?
-- exceção: jogar item manualmente em "Lixo" (filtro junk) NÃO protege de venda
local function IsCategorized(itemID, link)
  local a = DB.assignments[itemID]
  if a then
    local entry = CatEntryByName(a)
    if entry and entry.filter ~= "junk" then return true end
  end
  if link and equipSetByVariant[VariantKey(link)] then return true end
  return false
end

-- protegido = variação favoritada OU peça EXATA de Conjunto de Equipamento OU (opção ligada E categoria de verdade)
-- SEGURANÇA DE VENDA (CRÍTICO): sem link (cache frio) não dá pra determinar a variação →
-- tratar como protegido, nunca vender por engano.
local function IsProtected(itemID, link)
  if not link then return true end
  if IsFavorited(itemID, link) then return true end -- favorito = protegido
  if equipSetByVariant[VariantKey(link)] then return true end -- peça exata de Conjunto de Equipamento = SEMPRE protegida (favorito automático)
  if DB.settings and DB.settings.autoProtectCategorized and IsCategorized(itemID, link) then return true end
  return false
end

-- matchers de regra (categorias dinâmicas) compilados e memoizados por string de regra
local ruleCache = {}
local function GetRuleMatcher(rule)
  local m = ruleCache[rule]
  if m == nil then m = SearchMatcher(rule) or false; ruleCache[rule] = m end
  return m or nil
end

-- resolve a categoria final de um item (recebe o REGISTRO it: name/ilvl/quality/bound/bag/slot):
-- 1) manual  2) conjunto de equipamento  3) 1ª categoria que casa (regra OU preset, na ordem)  4) Diversos
ResolveCat = function(it)
  local itemID = it.itemID
  local a = DB.assignments[itemID]
  if a and CategoryExists(a) then return a end
  local s = it.link and equipSetByVariant[VariantKey(it.link)]
  if s then return s end
  for _, c in ipairs(DB.catList) do
    if c.rule and c.rule ~= "" then
      local m = GetRuleMatcher(c.rule)
      if m and m(it) then return c.name end
    elseif c.filter then
      local fn = PRESET_FILTERS[c.filter]
      if fn and fn(itemID, it.quality, it.bag, it.slot, it.link) then return c.name end
    end
  end
  return "Diversos"
end

GetIlvl = function(link)
  if not link then return 0 end
  if C_Item.GetDetailedItemLevelInfo then return C_Item.GetDetailedItemLevelInfo(link) or 0 end
  if GetDetailedItemLevelInfo then return GetDetailedItemLevelInfo(link) or 0 end
  return 0
end

-- ---------------- Valor pela Auction House ----------------
-- Lê o valor de mercado de um item via Auctionator (cache da última varredura = menor buyout)
-- ou TSM (dbmarket). Sem nenhum dos dois, cai pro sellPrice (preço de venda ao vendedor).
-- Tudo cacheado por itemID por sessão; pcall protege contra error() de tipo errado nas APIs.
local CALLER = "KrononBags"
local kbMarketCache = {} -- [itemID] = {v=copper, src="ah"|"sell"} | false (sem valor)
local kbHasMarketSrc = nil -- detecta Auctionator/TSM 1x (lazy)
local function GetMarketValue(itemID, link)
  if not itemID then return nil end
  local c = kbMarketCache[itemID]
  if c ~= nil then if c then return c.v, c.src else return nil end end
  local v, src
  if Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemID then
    local ok, p = pcall(Auctionator.API.v1.GetAuctionPriceByItemID, CALLER, itemID)
    if ok and type(p) == "number" and p > 0 then v, src = p, "ah" end
  end
  if not v and TSM_API and TSM_API.GetCustomPriceValue then
    local ok, p = pcall(TSM_API.GetCustomPriceValue, "dbmarket", "i:" .. itemID)
    if ok and type(p) == "number" and p > 0 then v, src = p, "ah" end
  end
  if not v then
    local sp = select(11, C_Item.GetItemInfo(link or itemID))
    if sp and sp > 0 then v, src = sp, "sell" end
  end
  kbMarketCache[itemID] = v and { v = v, src = src } or false
  return v, src
end
local function HasMarketSource()
  if kbHasMarketSrc == nil then
    kbHasMarketSrc = (Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemID and true)
      or (TSM_API and TSM_API.GetCustomPriceValue and true) or false
  end
  return kbHasMarketSrc
end

-- ---------------- Expansão de origem do item (sub-grupos por expansão) ----------------
-- O expacID (expansão de origem) vem do 15º retorno de C_Item.GetItemInfo. Em cache frio
-- (logo após login/troca de zona) o GetItemInfo devolve nil: nesse caso NÃO bloqueamos
-- nem cacheamos — retorna nil e o item cai no grupo "desconhecido" até GET_ITEM_INFO_RECEIVED
-- esquentar o cache e o Refresh re-renderizar. Cacheado por itemID (expacID não muda).
local kbExpacCache = {}
local function GetItemExpac(itemID, link)
  if not itemID then return nil end
  local cached = kbExpacCache[itemID]
  if cached ~= nil then return cached end
  local e = select(15, C_Item.GetItemInfo(link or itemID))
  if e == nil then return nil end -- cache frio: tenta de novo depois (não cacheia o nil)
  kbExpacCache[itemID] = e
  return e
end
-- nome legível da expansão (global EXPANSION_NAME<n>); nil → "Outros"
local function ExpacName(e)
  if e == nil then return L.EXPAC_UNKNOWN end
  return _G["EXPANSION_NAME" .. e] or L.EXPAC_UNKNOWN
end

-- ---------------- Trilha de upgrade (Gear Track) ----------------
-- Sem API limpa: a linha vem da global string ITEM_UPGRADE_TOOLTIP_FORMAT_STRING
-- (enUS = "Upgrade Level: %s %d/%d"). Pré-compila UMA vez o pattern Lua.
local KB_TRACK_PAT
do
  local s = ITEM_UPGRADE_TOOLTIP_FORMAT_STRING
  if s then
    s = s:gsub("([%.%-%(%)%[%]%+%*%?%^%$%%])", "%%%1") -- escapa magic chars (inclui % virando %%)
    s = s:gsub("%%%%s", "(.+)"):gsub("%%%%d", "(%%d+)")
    KB_TRACK_PAT = s -- ex: "Upgrade Level: (.+) (%d+)/(%d+)"
  end
end

-- devolve nome-da-trilha, atual, máx; ou nil se o item não tiver a linha
local function GetGearTrack(bag, slot)
  if bag and slot and KB_TRACK_PAT and C_TooltipInfo and C_TooltipInfo.GetBagItem then
    local data = C_TooltipInfo.GetBagItem(bag, slot)
    if data and data.lines then
      for _, line in ipairs(data.lines) do
        if TooltipUtil and TooltipUtil.SurfaceArgs then TooltipUtil.SurfaceArgs(line) end
        if line.leftText then
          local track, cur, max = line.leftText:match(KB_TRACK_PAT)
          if track then return track, tonumber(cur), tonumber(max) end
        end
      end
    end
  end
  return nil
end

-- ---------------- Masque (skin opcional dos ícones) ----------------
local KB_Masque = LibStub and LibStub("Masque", true)
local KB_MasqueGroup = KB_Masque and KB_Masque:Group("KrononBags", "Bags") or nil

-- ---------------- Menu de clique esquerdo ----------------
OpenItemMenu = function(self)
  local itemID = self.itemID
  if not itemID or not MenuUtil then return end
  MenuUtil.CreateContextMenu(self, function(owner, root)
    root:CreateTitle(self.itemName ~= "" and self.itemName or L.ITEM)
    -- usar/equipar é via CLIQUE DIREITO (ação segura); não dá pra fazer pelo menu (UseContainerItem é protegida)
    if self.bag and self.slot then -- item em cache não tem slot vivo: não dá pra pegar
      root:CreateButton(L.MENU_PICKUP, function()
        C_Container.PickupContainerItem(self.bag, self.slot)
      end)
    end

    local move = root:CreateButton(L.MENU_MOVE_TO_CAT)
    local anyCustom, anyPreset = false, false
    -- 1) categorias suas (custom)
    for _, c in ipairs(DB.catList) do
      if c.filter == nil then
        anyCustom = true
        move:CreateButton(CatDisplay(c.name), function() DB.assignments[itemID] = c.name; Refresh() end)
      end
    end
    -- 2) categorias pré-prontas (jogar o item nelas força — override do filtro)
    for _, c in ipairs(DB.catList) do
      if c.filter ~= nil then
        if not anyPreset and anyCustom then move:CreateDivider() end
        anyPreset = true
        move:CreateButton(CatDisplay(c.name), function() DB.assignments[itemID] = c.name; Refresh() end)
      end
    end
    if not anyCustom and not anyPreset then
      move:CreateButton("|cff999999" .. L.MENU_CREATE_CAT_HINT .. "|r", function() end)
    end
    move:CreateDivider()
    move:CreateButton(L.MENU_NEW_CAT, function()
      StaticPopup_Show("KRONONBAGS_NEWCAT", nil, nil, itemID)
    end)

    if DB.assignments[itemID] then
      root:CreateButton(L.MENU_REMOVE_FROM_CAT, function() DB.assignments[itemID] = nil; Refresh() end)
    end

    root:CreateDivider()
    root:CreateButton(IsFavorited(itemID, self.link) and L.MENU_UNFAVORITE or L.MENU_FAVORITE, function()
      ToggleFavorite(itemID, self.link)
    end)
  end)
end

-- ---------------- Ações em massa por categoria (clique-direito no cabeçalho) ----------------
-- Guardar todos os itens da categoria no banco do personagem via pegar/soltar
-- (PickupContainerItem NÃO é protegida, ao contrário de UseContainerItem). Throttle por
-- item (~0.08s) pra não perder movimentos por latência.
local function DepositCategoryToBank(items)
  if InCombatLockdown() or not atBank then return end
  local free = {}
  for _, bb in ipairs(PurchasedTabs(BANK_CHAR)) do
    local fs = C_Container.GetContainerFreeSlots and C_Container.GetContainerFreeSlots(bb)
    if fs then for _, s in ipairs(fs) do free[#free + 1] = { bag = bb, slot = s } end end
  end
  local queue = {}
  for _, it in ipairs(items) do
    if it.bag and it.slot and it.bag <= 5 then queue[#queue + 1] = it end -- só itens da mochila
  end
  local i = 1
  local function step()
    if InCombatLockdown() then return end
    local it = queue[i]; i = i + 1
    if not it then C_Timer.After(0.2, function() if UI and UI:IsShown() then Refresh() end end); return end
    local dst = table.remove(free, 1)
    if not dst then print(KB_PREFIX .. L.MSG_BANK_FULL); return end
    if CursorHasItem() then ClearCursor() end
    C_Container.PickupContainerItem(it.bag, it.slot)
    if CursorHasItem() then
      C_Container.PickupContainerItem(dst.bag, dst.slot)
    else
      table.insert(free, 1, dst) -- não pegou (item travado/bloqueado): devolve o slot livre
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.08, step) else step() end
  end
  step()
end

-- menu do cabeçalho de categoria
local function OpenCategoryMenu(h)
  if not (h and MenuUtil) then return end
  local cat, items = h.cat, h.catItems
  MenuUtil.CreateContextMenu(h, function(owner, root)
    root:CreateTitle(CatDisplay(cat) or L.CATEGORY)
    root:CreateButton(DB.collapsed[cat] and L.MENU_EXPAND_THIS or L.MENU_COLLAPSE_THIS, function()
      DB.collapsed[cat] = (not DB.collapsed[cat]) or nil; Refresh()
    end)
    local function setAll(v)
      for _, c in ipairs(DB.catList) do DB.collapsed[c.name] = v end
      for _, n in ipairs(equipSetNames) do DB.collapsed[n] = v end
      DB.collapsed["Diversos"] = v; DB.collapsed["Recém-obtidos"] = v
      Refresh()
    end
    root:CreateButton(L.MENU_COLLAPSE_ALL, function() setAll(true) end)
    root:CreateButton(L.MENU_EXPAND_ALL, function() setAll(nil) end)
    if items and #items > 0 then
      root:CreateDivider()
      root:CreateButton(L.MENU_FAV_ALL, function()
        for _, it in ipairs(items) do
          if it.itemID then
            local key = it.link and VariantKey(it.link)
            if key then DB.favorites[key] = true else DB.favorites[it.itemID] = true end
          end
        end
        Refresh()
      end)
      root:CreateButton(L.MENU_UNFAV_ALL, function()
        for _, it in ipairs(items) do
          if it.itemID then
            local key = it.link and VariantKey(it.link)
            if key then DB.favorites[key] = nil end
            DB.favorites[it.itemID] = nil -- compat: limpa também o favorito legado
          end
        end
        Refresh()
      end)
      if atBank and mode == "bags" then
        root:CreateDivider()
        root:CreateButton(L.MENU_DEPOSIT_ALL, function() DepositCategoryToBank(items) end)
      end
    end
  end)
end

-- arrastar item e soltar no cabeçalho de uma categoria = atribui ali (virtual, sem mover o item).
-- Favoritos → favorita; Diversos → tira da categoria (volta pro automático); Recém-obtidos → marca como recém.
local function AssignCursorToCategory(cat)
  if not cat or not CursorHasItem() then return end
  local kind, id, link = GetCursorInfo()
  ClearCursor() -- devolve o item pro slot de origem (atribuição é só uma marca)
  if kind ~= "item" then return end
  local itemID = id or (link and tonumber(link:match("item:(%d+)")))
  if not itemID then return end
  local entry = CatEntryByName(cat)
  if entry and entry.filter == "favorites" then
    local key = link and VariantKey(link)
    if key then DB.favorites[key] = true else DB.favorites[itemID] = true end
  elseif entry and entry.filter == "new" then
    DB.recem[itemID] = true; DB.assignments[itemID] = nil -- joga de volta pra Recém-obtidos
  elseif cat == "Diversos" then
    DB.assignments[itemID] = nil -- volta pro automático
  elseif entry then
    DB.assignments[itemID] = cat -- custom OU pré-pronta (força a categoria)
  else
    return -- categoria não-atribuível (ex: conjunto de equipamento)
  end
  Refresh()
end

-- ---------------- Handlers de botão ----------------
OnEnter = function(self)
  -- item em CACHE (visualização do banco de longe): tooltip pelo link salvo, sem ação
  if self.cached then
    if not self.cachedLink then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(self.cachedLink)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L.TIP_CACHED_STORED, 0.6, 0.8, 1)
    GameTooltip:AddLine(L.TIP_CACHED_GOTOBANK, 0.7, 0.7, 0.7)
    if self.kbUpdateStar then self.kbUpdateStar() end
    GameTooltip:Show()
    return
  end
  if not self.bag or not self.slot then return end
  -- ao olhar o item, ele deixa de ser "novo" (igual à bag da Blizzard)
  if C_NewItems and C_NewItems.RemoveNewItem then C_NewItems.RemoveNewItem(self.bag, self.slot) end
  if self.kbNewGlow then self.kbNewGlow:Hide() end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetBagItem(self.bag, self.slot)
  if self.itemID then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L.TIP_RIGHT_ACTIONS, 0.5, 1, 0.5)
    GameTooltip:AddLine(L.TIP_LEFT_PICKUP, 0.5, 1, 0.5)
    GameTooltip:AddLine(L.TIP_STAR, 0.5, 1, 0.5)
    if self.kbStacked then GameTooltip:AddLine(L.TIP_STACKED, 1, 0.6, 0.3) end
  end
  GameTooltip:Show()
end

-- Favoritar/desfavoritar uma VARIAÇÃO. Grava por VariantKey; ao desfavoritar limpa a chave
-- de variação E a chave numérica legada (itemID) pra um favorito antigo sair de vez. Sem link
-- (variação indeterminável): cai no toggle legado por itemID.
ToggleFavorite = function(itemID, link)
  if not itemID then return end
  local key = link and VariantKey(link)
  if not key then
    DB.favorites[itemID] = (not DB.favorites[itemID]) or nil -- favorito = protegido (legado)
    Refresh(); return
  end
  if IsFavorited(itemID, link) then
    DB.favorites[key] = nil
    DB.favorites[itemID] = nil -- compat: tira o favorito legado junto
  else
    DB.favorites[key] = true
  end
  Refresh()
end

-- frames "porta-bolsa": o ID do PAI = bagID. O ItemButton nativo lê GetParent():GetID()
-- pra saber a bolsa no clique seguro (usar/equipar/abrir/vender).
local bagHolders = {}
local function GetBagHolder(bag)
  local h = bagHolders[bag]
  if not h then
    h = CreateFrame("Frame", nil, UI.content) -- dentro do conteúdo rolável
    h:SetID(bag)
    h:SetAllPoints(UI.content)
    bagHolders[bag] = h
  end
  return h
end

-- Botão de item = template NATIVO da Blizzard (ContainerFrameItemButtonTemplate).
-- O clique-DIREITO usa/equipa/abre/vende de forma SEGURA (nativo), o esquerdo pega/arrasta.
-- NÃO usamos OnClick/PreClick/atributos no botão (isso causava taint → bloqueio silencioso).
-- Favoritar/menu ficam numa ESTRELA separada (não-segura) pra não contaminar o clique.
AcquireButton = function(i)
  local b = pool[i]
  if not b then
    b = CreateFrame("ItemButton", "KrononBagsItem" .. i, UI, "ContainerFrameItemButtonTemplate")
    b:SetSize(BTN, BTN)
    -- ConsolePort calcula o vizinho pelo CENTRO do hit rect; insets ≠ 0 (que alguns
    -- templates trazem) deslocam esse centro e desalinham a grade. Zerar = centro exato.
    b:SetHitRectInsets(0, 0, 0, 0)
    -- o UpdateTooltip nativo do ItemButton chama C_NewItems.RemoveNewItem(bag,slot); em itens
    -- cacheados (banco de longe) bag/slot = -1 e o 12.0.x recusa -1 (erro a cada frame de hover).
    -- Guardamos o nativo (pros vivos) e trocamos por um no-op nos cacheados (o OnEnter já mostra o tooltip via SetHyperlink).
    b.kbNativeUpdateTooltip = b.UpdateTooltip
    b.kbNoTooltip = function() end
    -- selos próprios (nomes únicos kb* pra não colidir com campos do template nativo)
    b.kbIlvl = b:CreateFontString(nil, "OVERLAY")
    b.kbIlvl:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
    b.kbIlvl:SetPoint("TOPRIGHT", -2, -2); b.kbIlvl:Hide()
    -- trilha de upgrade (ex: H4/6) no rodapé do ícone
    b.kbTrack = b:CreateFontString(nil, "OVERLAY")
    b.kbTrack:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
    b.kbTrack:SetPoint("BOTTOM", 0, 1); b.kbTrack:Hide()
    b.kbBind = b:CreateFontString(nil, "OVERLAY")
    b.kbBind:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
    b.kbBind:SetPoint("BOTTOMLEFT", 2, 2); b.kbBind:SetTextColor(0.4, 1, 0.4); b.kbBind:Hide()
    -- borda colorida por raridade (sublevel -1: fica abaixo da borda de missão/novo)
    b.kbBorder = b:CreateTexture(nil, "OVERLAY", nil, -1)
    b.kbBorder:SetPoint("TOPLEFT", -1, 1); b.kbBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    b.kbBorder:SetTexture("Interface\\Common\\WhiteIconFrame"); b.kbBorder:Hide()
    b.kbNewGlow = b:CreateTexture(nil, "OVERLAY")
    b.kbNewGlow:SetPoint("TOPLEFT", -2, 2); b.kbNewGlow:SetPoint("BOTTOMRIGHT", 2, -2)
    b.kbNewGlow:SetTexture("Interface\\Common\\WhiteIconFrame")
    b.kbNewGlow:SetBlendMode("ADD"); b.kbNewGlow:SetVertexColor(1, 0.9, 0.2); b.kbNewGlow:Hide()
    b.kbQuest = b:CreateTexture(nil, "OVERLAY")
    b.kbQuest:SetAllPoints(); b.kbQuest:SetTexture("Interface\\Common\\WhiteIconFrame")
    b.kbQuest:SetVertexColor(1, 0.82, 0); b.kbQuest:Hide()
    -- seta verde de upgrade (Pawn) na borda esquerda; estrela de qualidade de reagente (T1-3) embaixo
    b.kbUpgrade = b:CreateTexture(nil, "OVERLAY")
    b.kbUpgrade:SetSize(15, 15); b.kbUpgrade:SetPoint("LEFT", 0, 3)
    b.kbUpgrade:SetTexture("Interface\\PetBattles\\BattleBar-AbilityBadge-Strong"); b.kbUpgrade:Hide()
    b.kbQual = b:CreateTexture(nil, "OVERLAY")
    b.kbQual:SetSize(14, 14); b.kbQual:SetPoint("BOTTOM", 0, 0); b.kbQual:Hide()
    -- estrela: favoritar (esquerdo) + menu (direito) — botão separado, acima do item.
    -- DOURADA só quando favoritado; num não-favoritado, aparece APAGADA ao passar o mouse (pra clicar).
    local star = CreateFrame("Button", nil, b)
    star:SetSize(14, 14); star:SetPoint("TOPLEFT", -1, 1)
    star:SetFrameLevel(b:GetFrameLevel() + 5)
    star:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    -- a estrela fica grudada no canto do item: pro ConsolePort ela é um nó
    -- navegável concorrente sobreposto a cada item, o que bagunça a navegação
    -- por controle (pula/zigue-zague). nodeignore tira ela do scan do cursor
    -- (não afeta mouse). O item continua sendo o único nó daquele slot.
    star:SetAttribute("nodeignore", true)
    star.tex = star:CreateTexture(nil, "OVERLAY"); star.tex:SetAllPoints()
    star.tex:SetAtlas("PetJournal-FavoritesIcon")
    b.kbStar = star
    local function updateStar()
      local setFav = b.itemID and b.link and equipSetByVariant[VariantKey(b.link)] -- peça exata de Conjunto de Equipamento: favorito automático
      local fav = b.itemID and IsFavorited(b.itemID, b.link)
      if b.itemID and (fav or setFav) then
        star:Show(); star.tex:SetDesaturated(false); star.tex:SetAlpha(1)
        if setFav and not fav then star.tex:SetVertexColor(0.5, 0.8, 1) -- azulado = auto (Gerenciador de Equipamento)
        else star.tex:SetVertexColor(1, 1, 1) end
      elseif b.itemID and b:IsMouseOver() then
        star:Show(); star.tex:SetDesaturated(true); star.tex:SetAlpha(0.4); star.tex:SetVertexColor(1, 1, 1)
      else
        star:Hide()
      end
    end
    b.kbUpdateStar = updateStar
    star:SetScript("OnClick", function(_, mb)
      local id = b.itemID
      if not id then return end
      if mb == "RightButton" then OpenItemMenu(b)
      elseif b.link and equipSetByVariant[VariantKey(b.link)] then
        print(KB_PREFIX .. L.MSG_EQUIPSET_AUTOFAV)
      else ToggleFavorite(id, b.link) end
    end)
    star:SetScript("OnEnter", function(s)
      updateStar()
      GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
      if b.itemID and b.link and equipSetByVariant[VariantKey(b.link)] then
        GameTooltip:SetText(L.TIP_STAR_AUTOFAV)
      else
        GameTooltip:SetText(L.TIP_STAR_ACTIONS)
      end
      GameTooltip:Show()
    end)
    star:SetScript("OnLeave", function() GameTooltip:Hide(); updateStar() end)
    b:SetScript("OnEnter", function(self) OnEnter(self); if self.kbUpdateStar then self.kbUpdateStar() end end)
    b:SetScript("OnLeave", function(self) GameTooltip:Hide(); if self.kbUpdateStar then self.kbUpdateStar() end end)
    -- Masque (opcional): pinta as regiões do ItemButton. Regions=nil + Type "Item"
    -- → o Masque auto-detecta as regiões do ContainerFrameItemButtonTemplate.
    if KB_MasqueGroup then KB_MasqueGroup:AddButton(b, nil, "Item") end
    pool[i] = b
  end
  return b
end

-- botão "Equipar" para seções de Conjunto de Equipamento
local equipBtnPool = {}
local function AcquireEquipButton(i)
  local eb = equipBtnPool[i]
  if not eb then
    eb = CreateFrame("Button", nil, UI.content, "UIPanelButtonTemplate") -- dentro do conteúdo rolável
    eb:SetAttribute("nodeignore", true) -- botão "Equipar" fora da navegação por controle (fica na linha do cabeçalho; só mouse)
    eb:SetSize(62, 16)
    local fs = eb:GetFontString(); if fs then fs:SetTextScale(0.85) end
    eb:SetScript("OnClick", function(self)
      if InCombatLockdown() then
        print(KB_PREFIX .. L.MSG_NO_EQUIP_COMBAT)
        return
      end
      if self.setID and C_EquipmentSet then C_EquipmentSet.UseEquipmentSet(self.setID) end
    end)
    equipBtnPool[i] = eb
  end
  return eb
end

-- sub-cabeçalho de expansão (sub-grupos dentro de uma categoria). Só texto: Frame leve
-- + FontString, indentado ~8px, cor cinza-dourado suave. nodeignore tira da navegação por
-- controle (é rótulo, não item). Pooled como o headerPool: escondidos no reset do Refresh,
-- só os usados aparecem (sem texto-fantasma).
local function AcquireSubHeader(i)
  local sh = subHeaderPool[i]
  if not sh then
    sh = CreateFrame("Frame", nil, UI.content)
    sh:SetAttribute("nodeignore", true)
    sh.label = sh:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sh.label:SetPoint("LEFT", 0, 0)
    subHeaderPool[i] = sh
  end
  -- versão suave do accent do tema atual; re-setado a cada uso (pool é reaproveitado entre temas)
  local r, g, b = KB_Accent()
  sh.label:SetTextColor(r * 0.85, g * 0.85, b * 0.85)
  return sh
end

-- seção "Vazio": header + slot geral + slot reagentes (dentro do conteúdo rolável, x a partir de 0)
local function DrawEmpty(yOff)
  -- no modo cache não há slots vivos: mostra só a contagem salva de slots livres como texto
  if CachedMode() then
    local _, free = CurrentSnap()
    emptyHeader:ClearAllPoints(); emptyHeader:SetPoint("TOPLEFT", 0, yOff)
    emptyHeader:SetText("|cff808080" .. string.format(L.EMPTY_BANK_FREE, free or 0) .. "|r"); emptyHeader:Show()
    freeBox:Hide(); reagentBox:Hide()
    return yOff - 22
  end
  emptyHeader:ClearAllPoints(); emptyHeader:SetPoint("TOPLEFT", 0, yOff)
  emptyHeader:SetText("|cff" .. KB_AccentHex() .. L.EMPTY .. "|r"); emptyHeader:Show()
  yOff = yOff - 18
  freeBox:SetSize(BTN, BTN); freeBox:ClearAllPoints(); freeBox:SetPoint("TOPLEFT", 0, yOff); freeBox:Show()
  if mode == "bags" and (C_Container.GetContainerNumSlots(5) or 0) > 0 then
    reagentBox:SetSize(BTN, BTN); reagentBox:ClearAllPoints()
    reagentBox:SetPoint("TOPLEFT", (BTN + PAD), yOff); reagentBox:Show()
  else
    reagentBox:Hide()
  end
  return yOff - (BTN + PAD) - 6
end

-- arredonda um tamanho final pra grade de pixel real (bordas/ícones nítidos em qualquer UI scale)
local function PX(v) local s = UIParent:GetEffectiveScale(); if not s or s == 0 then return v end return math.floor(v * s + 0.5) / s end

-- aplica tamanho da janela/scroll/conteúdo e atualiza a barra de rolagem.
-- contentH = altura total do conteúdo; viewport limita à altura máxima e o resto rola.
local function FinishLayout(contentH)
  local M = UI.kbMargin or MARGIN
  local BOT = UI.kbBottom or (MARGIN + 22)
  local tabsVisible = atBank or HasCharBankSnap() or HasWarbandSnap() -- barra de abas ocupa o topo
  local TOP = (UI.kbTop or 34) + (tabsVisible and 22 or 0)
  local cols = (DB.settings and DB.settings.cols) or COLS
  local contentW = cols * (BTN + PAD) - PAD
  local maxH = (DB.settings and DB.settings.maxHeight) or 520
  local viewportH = math.max(80, math.min(contentH, maxH))
  UI:SetWidth(PX(contentW + M * 2 + SBW))
  UI:SetHeight(PX(TOP + viewportH + BOT))
  if UI.scroll then
    UI.scroll:ClearAllPoints()
    UI.scroll:SetPoint("TOPLEFT", PX(M), PX(-TOP))
    UI.scroll:SetSize(PX(contentW), PX(viewportH))
    UI.content:SetSize(PX(contentW), PX(math.max(contentH, viewportH)))
    local range = math.max(0, contentH - viewportH)
    if UI.sb then
      UI.sb:SetMinMaxValues(0, range)
      local cur = math.min(UI.sb:GetValue() or 0, range)
      UI.sb:SetValue(cur)
      UI.scroll:SetVerticalScroll(cur)
      UI.sb:SetShown(range > 0)
    end
  end
end

-- desenha os "selos" próprios de um botão de item: ilvl, vínculo (BoE/Warband), missão, novo
local function DecorateBadges(b, bag, slot, itemID, quality, ilvl, isBound)
  -- ilvl (só equipável, se ligado na config)
  local equipLoc = select(4, C_Item.GetItemInfoInstant(itemID))
  if DB.settings.showIlvl and equipLoc and equipLoc ~= "" then
    local lvl = ilvl
    if (not lvl or lvl <= 1) and ItemLocation and bag and slot then
      local loc = ItemLocation:CreateFromBagAndSlot(bag, slot)
      if loc and C_Item.DoesItemExist and C_Item.DoesItemExist(loc) and C_Item.GetCurrentItemLevel then
        lvl = C_Item.GetCurrentItemLevel(loc)
      end
    end
    if lvl and lvl > 1 then
      b.kbIlvl:SetText(lvl)
      if DB.settings.ilvlUseRarity then
        local r, g, bl = GetItemQualityColor(quality or 1)
        b.kbIlvl:SetTextColor(r, g, bl)
      else
        b.kbIlvl:SetTextColor(1, 1, 1) -- branco
      end
      b.kbIlvl:Show()
    else
      b.kbIlvl:Hide()
    end
  else
    b.kbIlvl:Hide()
  end
  -- trilha de upgrade (ex: H4/6) no rodapé — só equipável, com slot vivo, se ligado
  if b.kbTrack then
    if DB.settings.showGearTrack and equipLoc and equipLoc ~= "" then
      local track, cur, max = GetGearTrack(bag, slot)
      if track and cur and max then
        b.kbTrack:SetText(track:sub(1, 1):upper() .. cur .. "/" .. max)
        if cur == max then b.kbTrack:SetTextColor(1, 0.82, 0) -- dourado: trilha completa
        else b.kbTrack:SetTextColor(1, 1, 1) end              -- branco
        b.kbTrack:Show()
      else
        b.kbTrack:Hide()
      end
    else
      b.kbTrack:Hide()
    end
  end
  -- selo de vínculo (só se ainda NÃO estiver vinculado ao personagem)
  local tag
  if not isBound then
    local bindType = select(14, C_Item.GetItemInfo(itemID))
    if bindType == 2 then tag = "BoE"          -- vincula ao equipar
    elseif bindType == 3 then tag = "BoU"      -- vincula ao usar
    elseif bindType == 8 then tag = "WB"       -- Vínculo de Brigada
    elseif bindType == 9 then tag = "WuE" end  -- Brigada até equipar
  end
  if tag then b.kbBind:SetText(tag); b.kbBind:Show() else b.kbBind:Hide() end
  -- item de missão: borda dourada própria (só com slot vivo)
  local qinfo = (bag and slot) and C_Container.GetContainerItemQuestInfo(bag, slot)
  if qinfo and (qinfo.isQuestItem or qinfo.questID) then b.kbQuest:Show() else b.kbQuest:Hide() end
  -- borda colorida por raridade: incomum+ (cores) e lixo cinza; comum/branco fica sem borda (evita poluição)
  if b.kbBorder then
    if DB.settings.qualityBorder and quality and (quality >= 2 or quality == 0) then
      local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
      if c then b.kbBorder:SetVertexColor(c.r, c.g, c.b, 1); b.kbBorder:Show() else b.kbBorder:Hide() end
    else
      b.kbBorder:Hide()
    end
  end
  -- item novo (só com slot vivo)
  if bag and slot and C_NewItems and C_NewItems.IsNewItem and C_NewItems.IsNewItem(bag, slot) then b.kbNewGlow:Show() else b.kbNewGlow:Hide() end
  -- seta verde de upgrade (integração opcional com o Pawn) — precisa de slot vivo
  -- usamos SEMPRE nossa própria textura: a região nativa b.UpgradeIcon existe no 12.0
  -- mas ficou SEM textura (API removida em 10.0.2), então mostrá-la não desenha nada.
  do
    local up = false
    -- PawnIsContainerItemAnUpgrade (que usávamos) foi descontinuada no Pawn atual → era nil
    -- e a seta nunca aparecia. O entrypoint atual é PawnShouldItemLinkHaveUpgradeArrow(link)
    -- (booleano, já throttled). Precisa do link do item.
    if _G.PawnShouldItemLinkHaveUpgradeArrow then
      local link = b.cachedLink
      if (not link) and bag and slot then
        local ci = C_Container.GetContainerItemInfo(bag, slot)
        link = ci and ci.hyperlink
      end
      if link then
        local ok, res = pcall(_G.PawnShouldItemLinkHaveUpgradeArrow, link)
        up = (ok and res) and true or false
      end
    end
    if b.UpgradeIcon then b.UpgradeIcon:Hide() end -- não confiar na nativa (sem textura)
    if b.kbUpgrade then b.kbUpgrade:SetShown(up) end
  end
  -- estrela de qualidade de reagente de profissão (T1/T2/T3)
  if b.kbQual then
    local q
    if C_TradeSkillUI and C_TradeSkillUI.GetItemReagentQualityByItemInfo then
      local ok, res = pcall(C_TradeSkillUI.GetItemReagentQualityByItemInfo, itemID)
      if ok then q = res end
    end
    if q and q >= 1 and q <= 3 then
      b.kbQual:SetAtlas("Professions-Icon-Quality-Tier" .. q .. "-Small")
      b.kbQual:Show()
    else
      b.kbQual:Hide()
    end
  end
end

local function ClearBadges(b)
  b.kbIlvl:Hide(); b.kbBind:Hide(); b.kbNewGlow:Hide(); b.kbQuest:Hide()
  if b.kbTrack then b.kbTrack:Hide() end
  if b.kbBorder then b.kbBorder:Hide() end
  if b.kbUpgrade then b.kbUpgrade:Hide() end
  if b.UpgradeIcon then b.UpgradeIcon:Hide() end
  if b.kbQual then b.kbQual:Hide() end
end

-- atualização leve só dos cooldowns dos botões visíveis (evento BAG_UPDATE_COOLDOWN)
local function UpdateCooldowns()
  for _, b in ipairs(pool) do
    if b:IsShown() and b.bag and b.slot and b.itemID and b.Cooldown then
      local cs, cd, cen = C_Container.GetContainerItemCooldown(b.bag, b.slot)
      CooldownFrame_Set(b.Cooldown, cs or 0, cd or 0, cen or 0)
    end
  end
end

-- preenche o botão NATIVO: amarra bag/slot (clique seguro), display nativo + selos próprios.
-- Proteção: favorito no vendedor não vende (tiramos o registro do clique-direito daquele botão).
local function FillButton(b, bag, slot)
  -- PAI ÚNICO pra todos os botões vivos. O cursor do ConsolePort varre só os "irmãos"
  -- do mesmo pai (ScanLocal(GetParent())); com um holder por bolsa ele não atravessava
  -- pras outras bolsas e pulava seções. Com um pai só, a grade fica contígua.
  -- A bolsa vai por botão via SetBagID (guardada em self.bagID; GetBagID só usa o pai como
  -- fallback). É exatamente o que as Bolsas Combinadas nativas fazem — clique seguro de
  -- usar/equipar/vender (C_Container.UseContainerItem(GetBagID(), GetID())) continua certo, sem taint.
  b:SetParent(UI.content)
  b:SetID(slot)
  if b.SetBagID then b:SetBagID(bag) else b.bagID = bag end
  b.bag, b.slot = bag, slot
  b.cached, b.cachedLink = nil, nil -- modo vivo (não é visualização de cache)
  if b.kbNativeUpdateTooltip then b.UpdateTooltip = b.kbNativeUpdateTooltip end -- restaura o tooltip nativo (slot real)
  b:SetAlpha(1) -- reset (a busca-realce pode ter deixado escurecido num render anterior)
  b.kbStacked = nil -- limpa flag de pilha visual (re-setado no render se for empilhado)
  -- desliga o brilho de "item novo" NATIVO (tocava sozinho em slot vazio e em tudo após /reload);
  -- usamos o nosso próprio b.kbNewGlow, controlado por IsNewItem só em itens de verdade.
  if b.NewItemTexture then b.NewItemTexture:Hide() end
  if b.BattlepayItemTexture then b.BattlepayItemTexture:Hide() end
  if b.flashAnim and b.flashAnim:IsPlaying() then b.flashAnim:Stop() end
  if b.newitemglowAnim and b.newitemglowAnim:IsPlaying() then b.newitemglowAnim:Stop() end
  local info = C_Container.GetContainerItemInfo(bag, slot)
  if info and info.itemID then
    b.itemID = info.itemID
    b.link = info.hyperlink -- variação exata (bonusIDs): favoritar/proteger casa só esta peça
    b.itemName = C_Item.GetItemInfo(info.hyperlink) or ""
    b:SetItemButtonTexture(info.iconFileID)
    SetItemButtonCount(b, info.stackCount or 1)
    b:SetItemButtonQuality(info.quality, nil, true, info.isBound)
    if b.Cooldown then
      local cs, cd, cen = C_Container.GetContainerItemCooldown(bag, slot)
      CooldownFrame_Set(b.Cooldown, cs or 0, cd or 0, cen or 0)
    end
    if b.kbUpdateStar then b.kbUpdateStar() end
    DecorateBadges(b, bag, slot, info.itemID, info.quality, GetIlvl(info.hyperlink), info.isBound)
    if MerchantFrame and MerchantFrame:IsShown() and IsProtected(info.itemID, info.hyperlink) then
      b:RegisterForClicks("LeftButtonUp")               -- favorito não vende (sem clique direito)
    else
      b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    end
  else
    b.itemID, b.itemName, b.link = nil, nil, nil
    b:SetItemButtonTexture(nil)
    SetItemButtonCount(b, 0)
    if b.IconBorder then b.IconBorder:Hide() end
    if b.Cooldown then CooldownFrame_Set(b.Cooldown, 0, 0, 0) end
    if b.kbUpdateStar then b.kbUpdateStar() end
    ClearBadges(b)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  end
end

-- preenche o botão a partir do CACHE (visualização do banco de longe): só display + tooltip,
-- SEM amarrar a slot vivo e SEM cliques de ação (o item não está acessível fora do banco).
local function FillButtonCached(b, it)
  -- holder com ID -1 (bag inválida): mesmo se um clique escapar, a ação nativa não acha container nenhum
  if not UI.cacheHolder then
    UI.cacheHolder = CreateFrame("Frame", nil, UI.content)
    UI.cacheHolder:SetID(-1); UI.cacheHolder:SetAllPoints(UI.content)
  end
  b:SetParent(UI.cacheHolder)
  b:SetID(-1)
  if b.SetBagID then b:SetBagID(-1) else b.bagID = -1 end -- limpa a bolsa viva anterior: cacheado nunca aponta pra um container real
  b.bag, b.slot = nil, nil
  if b.kbNoTooltip then b.UpdateTooltip = b.kbNoTooltip end -- evita RemoveNewItem(-1) do UpdateTooltip nativo em item cacheado
  b.cached, b.cachedLink = true, it.link
  b:SetAlpha(1)
  b.kbStacked = nil
  if b.NewItemTexture then b.NewItemTexture:Hide() end
  if b.BattlepayItemTexture then b.BattlepayItemTexture:Hide() end
  b.itemID = it.itemID
  b.link = it.link
  b.itemName = it.name or ""
  b:SetItemButtonTexture(it.icon)
  SetItemButtonCount(b, it.count or 1)
  b:SetItemButtonQuality(it.quality, nil, true, it.bound)
  if b.Cooldown then CooldownFrame_Set(b.Cooldown, 0, 0, 0) end
  if b.kbUpdateStar then b.kbUpdateStar() end
  DecorateBadges(b, nil, nil, it.itemID, it.quality, it.ilvl, it.bound)
  b:RegisterForClicks() -- sem ação segura (slot não está acessível de longe)
end

-- ---------------- Render: modo grade (todos os slots, estilo Blizzard) ----------------
RenderGrid = function()
  local cols = (DB.settings and DB.settings.cols) or COLS
  for _, b in ipairs(pool) do b:Hide() end
  for _, h in ipairs(headerPool) do h:Hide() end
  for _, eb in ipairs(equipBtnPool) do eb:Hide() end
  for _, sh in ipairs(subHeaderPool) do sh:Hide() end -- sem sub-cabeçalhos fantasma na visão grade
  if UI.cacheBanner then UI.cacheBanner:Hide() end

  local idx, col = 0, 0
  local yOff = 0 -- topo do conteúdo rolável
  for _, bag in ipairs(ActiveBags()) do
    local slots = C_Container.GetContainerNumSlots(bag) or 0
    for slot = 1, slots do
      idx = idx + 1
      local b = AcquireButton(idx)
      FillButton(b, bag, slot)
      b:SetSize(BTN, BTN); b:ClearAllPoints()
      b:SetPoint("TOPLEFT", col * (BTN + PAD), yOff)
      b:Show()
      col = col + 1
      if col >= cols then col = 0; yOff = yOff - (BTN + PAD) end
    end
  end
  if col > 0 then yOff = yOff - (BTN + PAD) end
  yOff = DrawEmpty(yOff)
  UpdateMoney()
  FinishLayout(-yOff)
end

-- ---------------- Busca avançada (operadores + palavras-chave) ----------------
-- Compila a busca num matcher(item). Suporta:  & | !  e parênteses (AND implícito
-- entre termos adjacentes); ilvl>200 / ilvl:200-300 ; q:epico ou q>=4 ; tipo:armadura ;
-- id:12345 ; palavras boe/bou/wb/wue/vinculado/missao/lixo/equip/consumivel/novo/favorito.
-- Qualquer outra palavra = pedaço do NOME. Falha de parse → nil (cai no nome puro).
local QMAP = {
  pobre = 0, comum = 1, incomum = 2, raro = 3, epico = 4, ["épico"] = 4, lendario = 5, ["lendário"] = 5, artefato = 6,
  poor = 0, common = 1, uncommon = 2, rare = 3, epic = 4, legendary = 5, artifact = 6,
}
local function kbCmp(op, a, b)
  if op == ">" then return a > b elseif op == "<" then return a < b
  elseif op == ">=" then return a >= b elseif op == "<=" then return a <= b
  else return a == b end
end
local function bindTypeOf(id) return select(14, C_Item.GetItemInfo(id)) end
local function SearchTermPred(tok)
  local low = tok:lower()
  -- ilvl / nível
  local rest = low:match("^ilvl(.+)$") or low:match("^nivel(.+)$") or low:match("^nível(.+)$")
  if rest then
    local a, b = rest:match("^[:=]?(%d+)%-(%d+)$")
    if a then a, b = tonumber(a), tonumber(b); return function(it) return it.ilvl and it.ilvl >= a and it.ilvl <= b end end
    local op, n = rest:match("^([<>]=?)(%d+)$")
    if not op then n = rest:match("^[:=](%d+)$"); if n then op = "=" end end
    if op and n then n = tonumber(n); return function(it) return it.ilvl and kbCmp(op, it.ilvl, n) end end
  end
  -- qualidade / raridade
  local qrest = low:match("^qualidade(.+)$") or low:match("^raridade(.+)$") or low:match("^quality(.+)$") or low:match("^q(.+)$")
  if qrest then
    local nm = qrest:match("^[:=](.+)$")
    if nm and QMAP[nm] ~= nil then local v = QMAP[nm]; return function(it) return it.quality == v end end
    local op, n = qrest:match("^([<>]=?)(%d+)$")
    if not op then n = qrest:match("^[:=](%d+)$"); if n then op = "=" end end
    if op and n then n = tonumber(n); return function(it) return it.quality and kbCmp(op, it.quality, n) end end
  end
  local idn = low:match("^id[:=](%d+)$")
  if idn then idn = tonumber(idn); return function(it) return it.itemID == idn end end
  local tp = low:match("^tipo[:=](.+)$") or low:match("^type[:=](.+)$")
  if tp then return function(it)
    local _, itype, isub = C_Item.GetItemInfoInstant(it.itemID)
    return ((itype or ""):lower():find(tp, 1, true) or (isub or ""):lower():find(tp, 1, true)) ~= nil
  end end
  -- nome:texto / name:texto — força busca por NOME (o construtor de busca usa isto pra
  -- texto livre não colidir com palavra-chave/operador, ex: nome:novo, nome:não)
  local nmq = low:match("^nome[:=](.+)$") or low:match("^name[:=](.+)$")
  if nmq then return function(it) return it.name ~= "" and it.name:lower():find(nmq, 1, true) ~= nil end end
  local KW = {
    boe = function(it) return bindTypeOf(it.itemID) == 2 end,
    bou = function(it) return bindTypeOf(it.itemID) == 3 end,
    wb = function(it) return bindTypeOf(it.itemID) == 8 end,
    warband = function(it) return bindTypeOf(it.itemID) == 8 end,
    wue = function(it) return bindTypeOf(it.itemID) == 9 end,
    vinculado = function(it) return it.bound == true end,
    bound = function(it) return it.bound == true end,
    soulbound = function(it) return it.bound == true end,
    quest = function(it) return classOf(it.itemID) == 12 end,
    missao = function(it) return classOf(it.itemID) == 12 end,
    ["missão"] = function(it) return classOf(it.itemID) == 12 end,
    lixo = function(it) return it.quality == 0 end,
    junk = function(it) return it.quality == 0 end,
    equip = function(it) local c = classOf(it.itemID); return c == 2 or c == 4 end,
    equipamento = function(it) local c = classOf(it.itemID); return c == 2 or c == 4 end,
    gear = function(it) local c = classOf(it.itemID); return c == 2 or c == 4 end,
    consumivel = function(it) return classOf(it.itemID) == 0 end,
    ["consumível"] = function(it) return classOf(it.itemID) == 0 end,
    consumable = function(it) return classOf(it.itemID) == 0 end,
    montaria = function(it) local _, _, _, _, _, c, sub = C_Item.GetItemInfoInstant(it.itemID); return c == 15 and sub == 5 end,
    mount = function(it) local _, _, _, _, _, c, sub = C_Item.GetItemInfoInstant(it.itemID); return c == 15 and sub == 5 end,
    montura = function(it) local _, _, _, _, _, c, sub = C_Item.GetItemInfoInstant(it.itemID); return c == 15 and sub == 5 end,
    novo = function(it) return (DB.recem and DB.recem[it.itemID]) and true or false end,
    new = function(it) return (DB.recem and DB.recem[it.itemID]) and true or false end,
    favorito = function(it) return IsFavorited(it.itemID, it.link) and true or false end,
    fav = function(it) return IsFavorited(it.itemID, it.link) and true or false end,
  }
  if KW[low] then return KW[low] end
  return function(it) return it.name ~= "" and it.name:lower():find(low, 1, true) ~= nil end
end

SearchMatcher = function(query)
  query = (query or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if query == "" then return nil end
  local toks = {}
  for t in query:gsub("([()&|!])", " %1 "):gmatch("%S+") do toks[#toks + 1] = t end
  local pos, parseExpr = 1
  local function peek() return toks[pos] end
  local function adv() pos = pos + 1 end
  local function isOr(t) if not t then return false end local l = t:lower(); return t == "|" or l == "or" or l == "ou" end
  local function isNot(t) if not t then return false end local l = t:lower(); return t == "!" or l == "not" or l == "nao" or t == "não" end
  local function isAnd(t) if not t then return false end local l = t:lower(); return t == "&" or l == "and" or l == "e" end
  local function parseAtom()
    local t = peek()
    if t == nil then return function() return false end end
    if t == "(" then adv(); local e = parseExpr(); if peek() == ")" then adv() end; return e end
    adv(); return SearchTermPred(t)
  end
  local function parseNot()
    if isNot(peek()) then adv(); local p = parseNot(); return function(it) return not p(it) end end
    return parseAtom()
  end
  local function parseAnd()
    local p = parseNot()
    while true do
      local t = peek()
      if t == nil or t == ")" or isOr(t) then break end
      if isAnd(t) then adv() end
      local t2 = peek()
      if t2 == nil or t2 == ")" or isOr(t2) then break end
      local q = parseNot(); local prev = p
      p = function(it) return prev(it) and q(it) end
    end
    return p
  end
  parseExpr = function()
    local p = parseAnd()
    while isOr(peek()) do adv(); local q = parseAnd(); local prev = p; p = function(it) return prev(it) or q(it) end end
    return p
  end
  local ok, m = pcall(parseExpr)
  if not ok or type(m) ~= "function" then return nil end
  return function(it) local ok2, res = pcall(m, it); return ok2 and res end
end

-- ---------------- Carga assíncrona de itens (cache frio) ----------------
-- Logo após login/troca de zona, C_Item.GetItemInfo devolve nil (item ainda não
-- cacheado) e aí ilvl/vínculo/qualidade saem errados. Pré-carrega os itens das
-- bolsas ativas e re-renderiza UMA vez quando o servidor responde. É o mesmo bug
-- que a Blizzard tem no BankPanel — padrão ContinuableContainer + ContinueOnLoad.
-- Crítico pro banco, que tem centenas de itens não-cacheados ao abrir.
local loadPending = false
local function EnsureItemsCached(bagList)
  if loadPending then return end
  if not (ContinuableContainer and Item and Item.CreateFromBagAndSlot) then return end
  local cc = ContinuableContainer:Create()
  local any = false
  for _, bag in ipairs(bagList) do
    local slots = C_Container.GetContainerNumSlots(bag) or 0
    for slot = 1, slots do
      local it = Item:CreateFromBagAndSlot(bag, slot)
      if it and not it:IsItemEmpty() and not it:IsItemDataCached() then
        cc:AddContinuable(it); any = true
      end
    end
  end
  if any then
    loadPending = true
    cc:ContinueOnLoad(function()
      loadPending = false
      if UI and UI:IsShown() and not InCombatLockdown() then Refresh() end
    end)
  end
end

-- ---------------- Ordenação + empilhamento ----------------
local function ItemTypeKey(it)
  local _, _, _, _, _, classID, subID = C_Item.GetItemInfoInstant(it.itemID)
  return (classID or 99) * 100 + (subID or 0)
end
local function SortComparator(mode)
  if mode == "quality" then
    return function(a, b)
      if (a.quality or 0) ~= (b.quality or 0) then return (a.quality or 0) > (b.quality or 0) end
      if a.ilvl ~= b.ilvl then return a.ilvl > b.ilvl end
      return a.name < b.name
    end
  elseif mode == "name" then
    return function(a, b) if a.name ~= b.name then return a.name < b.name end return (a.ilvl or 0) > (b.ilvl or 0) end
  elseif mode == "type" then
    return function(a, b)
      local ka, kb = ItemTypeKey(a), ItemTypeKey(b)
      if ka ~= kb then return ka < kb end
      if a.name ~= b.name then return a.name < b.name end
      return (a.ilvl or 0) > (b.ilvl or 0)
    end
  elseif mode == "recent" then
    return function(a, b)
      local na = (C_NewItems and C_NewItems.IsNewItem and C_NewItems.IsNewItem(a.bag, a.slot)) and true or false
      local nb = (C_NewItems and C_NewItems.IsNewItem and C_NewItems.IsNewItem(b.bag, b.slot)) and true or false
      if na ~= nb then return na end
      if a.ilvl ~= b.ilvl then return a.ilvl > b.ilvl end
      return a.name < b.name
    end
  else -- ilvl (padrão)
    return function(a, b) if a.ilvl ~= b.ilvl then return a.ilvl > b.ilvl end return a.name < b.name end
  end
end
-- junta itens iguais (empilháveis) num registro só, somando a contagem (representante = 1º slot)
local function MergeStacks(g)
  local out, byId = {}, {}
  for _, it in ipairs(g) do
    local maxStack = select(8, C_Item.GetItemInfo(it.itemID)) or 1
    if maxStack and maxStack > 1 then
      local m = byId[it.itemID]
      if m then m.count = (m.count or 1) + (it.count or 1); m.stacked = true
      else byId[it.itemID] = it; out[#out + 1] = it end
    else
      out[#out + 1] = it
    end
  end
  return out
end

-- "Distribuir": esvazia Recém-obtidos — os itens caem nas categorias certas (e limpa qualquer glow remanescente)
local function DistributeNew()
  if DB and DB.recem then wipe(DB.recem) end
  if C_NewItems and C_NewItems.RemoveNewItem and C_Container then
    local done = {}
    local function clear(bag)
      if done[bag] then return end
      done[bag] = true
      local slots = C_Container.GetContainerNumSlots(bag) or 0
      for slot = 1, slots do C_NewItems.RemoveNewItem(bag, slot) end
    end
    for bag = 0, 5 do clear(bag) end                    -- mochila + bolsas + bolsa de reagentes (onde o "novo" vive)
    for _, bag in ipairs(ActiveBags()) do clear(bag) end -- + a aba ativa (banco/Brigada), por garantia
  end
  Refresh()
end

-- ---------------- Transferir pela busca + Abrir tudo ----------------
-- item TRANCADO (precisa de chave): scan do tooltip procurando a linha == global LOCKED
-- (PT "Trancado" / EN "Locked"). Item trancado NÃO conta como abrível em "abrir tudo".
local function IsBagSlotLocked(bag, slot)
  if not (C_TooltipInfo and C_TooltipInfo.GetBagItem) then return false end
  local data = C_TooltipInfo.GetBagItem(bag, slot)
  if not (data and data.lines) then return false end
  for _, line in ipairs(data.lines) do
    if TooltipUtil and TooltipUtil.SurfaceArgs then TooltipUtil.SurfaceArgs(line) end
    if line.leftText and line.leftText == LOCKED then return true end
  end
  return false
end

-- coleta os itens (vivos) das bolsas ativas que batem com a busca atual.
-- Reconstrói o MESMO registro it que o Refresh monta e usa o MESMO matcher,
-- então a regra de "bate na busca" é idêntica à do filtro da grade.
local function CollectSearchMatches()
  local out = {}
  if search == "" then return out end
  local matcher = SearchMatcher(search)
  for _, bag in ipairs(ActiveBags()) do
    local slots = C_Container.GetContainerNumSlots(bag) or 0
    for slot = 1, slots do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.itemID then
        local it = {
          bag = bag, slot = slot, itemID = info.itemID, link = info.hyperlink,
          icon = info.iconFileID, count = info.stackCount, quality = info.quality,
          name = C_Item.GetItemInfo(info.hyperlink) or "", ilvl = GetIlvl(info.hyperlink), bound = info.isBound,
        }
        local hit
        if matcher then hit = matcher(it) else hit = it.name ~= "" and it.name:lower():find(search, 1, true) end
        if hit then out[#out + 1] = it end
      end
    end
  end
  return out
end

-- vende (loop UseContainerItem) a lista já filtrada — chamado só no OnAccept do popup
local KB_transferSellList
local function SellMatches(list)
  if InCombatLockdown() then print(KB_PREFIX .. L.MSG_NO_EQUIP_COMBAT); return end
  if not (MerchantFrame and MerchantFrame:IsShown()) then return end
  local n = 0
  for _, it in ipairs(list or {}) do
    if it.bag and it.slot then
      -- revalida o slot na hora de vender: as bolsas podem ter sido reorganizadas (auto-sort
      -- dispara em BAG_UPDATE) entre abrir o popup e confirmar. Só vende se o slot ainda contém
      -- o MESMO item e ele NÃO está protegido (rede de segurança contra vender item trocado/favorito).
      local info = C_Container.GetContainerItemInfo(it.bag, it.slot)
      -- revalida pela variação ATUAL do slot (info.hyperlink); link nil → IsProtected devolve true (não vende)
      if info and info.itemID == it.itemID and not IsProtected(it.itemID, info.hyperlink) then
        C_Container.UseContainerItem(it.bag, it.slot); n = n + 1
      end
    end
  end
  print(KB_PREFIX .. string.format(L.MSG_TRANSFER_SOLD, n))
  if UI and UI:IsShown() then Refresh() end
end

-- vende lixo (cinza) RESPEITANDO a proteção do addon. Substitui C_MerchantFrame.SellAllJunkItems,
-- que vende todo item cinza ignorando favoritos / Conjunto de Equipamento / categoria protegida.
-- CRÍTICO (caminho de venda):
--  - só roda com o vendedor aberto: sem ele, UseContainerItem NÃO vende (pode até USAR o item) → guarda obrigatória.
--  - só vende quality 0 (cinza) COM valor de venda (info.hasNoValue false e sellPrice > 0).
--  - NUNCA vende item protegido (IsProtected) nem não-verificável (info/link nil → pula).
--  - revalida o MESMO slot imediatamente antes de cada venda (bolsas mudam ao vender).
--  - varre de trás pra frente (slot maior primeiro): vender não desloca os índices ainda não visitados.
local function SellJunkItems()
  if InCombatLockdown() then return end
  if not (MerchantFrame and MerchantFrame:IsShown()) then return end -- guarda obrigatória: sem vendedor, não vende
  if not (C_Container and C_Container.GetContainerItemInfo and C_Container.UseContainerItem) then return end
  for _, bag in ipairs(BAGS) do
    local slots = C_Container.GetContainerNumSlots(bag) or 0
    for slot = slots, 1, -1 do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      -- quality 0 = Enum.ItemQuality.Poor (cinza); hasNoValue false = tem valor de venda (sellPrice > 0)
      if info and info.itemID and info.quality == 0 and not info.hasNoValue then
        local link = info.hyperlink
        local sellPrice = link and select(11, C_Item.GetItemInfo(link)) or nil
        -- só vende com link válido, valor de venda confirmado (>0 quando conhecido) e NÃO protegido
        if link and (sellPrice == nil or sellPrice > 0) and not IsProtected(info.itemID, link) then
          -- REVALIDAÇÃO: relê o slot na hora exata da venda. Tem de ser o MESMO item, ainda cinza,
          -- ainda com valor, com link e ainda NÃO protegido. Qualquer divergência/nil → não vende.
          local now = C_Container.GetContainerItemInfo(bag, slot)
          if now and now.itemID == info.itemID and now.quality == 0 and not now.hasNoValue
             and now.hyperlink and not IsProtected(now.itemID, now.hyperlink) then
            C_Container.UseContainerItem(bag, slot)
          end
        end
      end
    end
  end
end

-- botão "Transferir": vende no vendedor (com confirmação) ou deposita no banco (direto)
local function TransferBySearch()
  if InCombatLockdown() then print(KB_PREFIX .. L.MSG_NO_EQUIP_COMBAT); return end
  if search == "" then return end
  local atMerchant = MerchantFrame and MerchantFrame:IsShown()
  local matches = CollectSearchMatches()
  if atMerchant then
    local sellable = {}
    for _, it in ipairs(matches) do
      if it.bag and it.slot and not IsProtected(it.itemID, it.link) then sellable[#sellable + 1] = it end
    end
    if #sellable == 0 then return end
    KB_transferSellList = sellable
    StaticPopup_Show("KRONONBAGS_TRANSFER_SELL", #sellable)
  elseif atBank then
    local n = 0
    for _, it in ipairs(matches) do
      if it.bag and it.slot then
        local info = C_Container.GetContainerItemInfo(it.bag, it.slot)
        if info and info.itemID == it.itemID then C_Container.UseContainerItem(it.bag, it.slot); n = n + 1 end
      end
    end
    print(KB_PREFIX .. string.format(L.MSG_TRANSFER_DEPOSITED, n))
    if UI and UI:IsShown() then Refresh() end
  end
end

-- abrir tudo: abre 1 recipiente de loot por vez (assíncrono). Acha o 1º hasLoot
-- não-trancado, abre, e marca UI.openingAll; o handler de BAG_UPDATE_DELAYED chama
-- de novo até não sobrar nenhum.
local function OpenAllOpenables()
  if not UI then return end
  if InCombatLockdown() then UI.openingAll = false; return end
  -- CRÍTICO: com o vendedor aberto, UseContainerItem VENDE em vez de abrir. Nunca "abrir tudo"
  -- no vendedor, senão venderia todos os recipientes em cadeia (via BAG_UPDATE_DELAYED).
  if MerchantFrame and MerchantFrame:IsShown() then UI.openingAll = false; return end
  for _, bag in ipairs(ActiveBags()) do
    local slots = C_Container.GetContainerNumSlots(bag) or 0
    for slot = 1, slots do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.hasLoot and not IsBagSlotLocked(bag, slot) then
        UI.openingAll = true
        C_Container.UseContainerItem(bag, slot)
        return
      end
    end
  end
  UI.openingAll = false -- não há mais nada pra abrir
end

-- ---------------- Render ----------------
Refresh = function()
  if not UI or not UI:IsShown() or not DB then return end
  -- em combate não dá pra reposicionar/alterar botões seguros: adia pro fim do combate
  if InCombatLockdown() then UI.refreshPending = true; return end
  RebuildEquipSets()
  if UI.tabs then UpdateTabs() end -- garante abas Banco/Brigada visíveis de longe quando há snapshot
  if UI.modeBar then UpdateModeBar() end -- selo de modo ativo na barra lateral de visualização
  local bags = ActiveBags()
  EnsureItemsCached(bags)
  if UI.distribBtn then UI.distribBtn:Hide() end -- esconde já (a grade não tem cabeçalho de seção)
  if UI.openAllBtn then UI.openAllBtn:Hide() end
  local cached = CachedMode()
  if DB.settings.gridView and not cached then return RenderGrid() end -- cache sempre usa a visão por categorias

  -- 1) coleta os itens (do banco AO VIVO ou do SNAPSHOT salvo, se consultando de longe)
  local items = {}
  if cached then
    local snap = CurrentSnap()
    if snap then
      for _, s in ipairs(snap) do
        local it = {
          cached = true, itemID = s.id, link = s.link, icon = s.icon,
          count = s.count, quality = s.q, bound = s.bound,
          name = (s.link and C_Item.GetItemInfo(s.link)) or "", ilvl = GetIlvl(s.link),
        }
        it.cat = ResolveCat(it)
        items[#items + 1] = it
      end
    end
  else
    for _, bag in ipairs(bags) do
      local slots = C_Container.GetContainerNumSlots(bag) or 0
      for slot = 1, slots do
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info and info.itemID then
          local it = {
            bag = bag, slot = slot, itemID = info.itemID, link = info.hyperlink,
            icon = info.iconFileID, count = info.stackCount, quality = info.quality,
            name = C_Item.GetItemInfo(info.hyperlink) or "", ilvl = GetIlvl(info.hyperlink), bound = info.isBound,
          }
          -- quando o jogo marca o item como novo, ele entra em "Recém-obtidos" e fica lá até clicar em Distribuir
          if C_NewItems and C_NewItems.IsNewItem and C_NewItems.IsNewItem(bag, slot) then DB.recem[info.itemID] = true end
          it.cat = ResolveCat(it) -- precisa do registro completo (regras usam name/ilvl/etc)
          items[#items + 1] = it
        end
      end
    end
  end

  -- 2) busca avançada (operadores & | ! + palavras-chave; fallback p/ nome)
  if search ~= "" then
    local matcher = SearchMatcher(search)
    local highlight = DB.settings.searchHighlight -- realça (escurece o resto) em vez de esconder
    local filtered = {}
    for _, it in ipairs(items) do
      local hit
      if matcher then hit = matcher(it) else hit = it.name ~= "" and it.name:lower():find(search, 1, true) end
      if highlight then
        it.dim = not hit          -- mantém todos os itens; só marca os que não batem
        filtered[#filtered + 1] = it
      elseif hit then
        filtered[#filtered + 1] = it
      end
    end
    items = filtered
  end

  -- 3) agrupa, empilha (opcional) e ordena pelo modo escolhido
  local groups = {}
  for _, it in ipairs(items) do
    groups[it.cat] = groups[it.cat] or {}
    table.insert(groups[it.cat], it)
  end
  local comparator = SortComparator(DB.settings.sortMode or "ilvl")
  for cat in pairs(groups) do
    local g = groups[cat]
    if DB.settings.stackItems then g = MergeStacks(g); groups[cat] = g end
    table.sort(g, comparator)
  end

  -- 4) ordem: conjuntos de equipamento > catList (na ordem escolhida) > Diversos > resto
  local order, seen = {}, {}
  local function addOrder(c) if c and not seen[c] then order[#order + 1] = c; seen[c] = true end end
  for _, c in ipairs(equipSetNames) do addOrder(c) end
  for _, c in ipairs(DB.catList) do addOrder(c.name) end
  addOrder("Diversos")
  for c in pairs(groups) do addOrder(c) end

  for _, b in ipairs(pool) do b:Hide() end
  for _, h in ipairs(headerPool) do h:Hide() end
  for _, eb in ipairs(equipBtnPool) do eb:Hide() end
  for _, sh in ipairs(subHeaderPool) do sh:Hide() end -- reset igual ao headerPool (sem fantasma)
  if UI.distribBtn then UI.distribBtn:Hide() end
  if UI.openAllBtn then UI.openAllBtn:Hide() end

  -- 5) desenha (dentro do conteúdo rolável: x a partir de 0, yOff a partir de 0)
  local cols = (DB.settings and DB.settings.cols) or COLS
  local contentW = cols * (BTN + PAD) - PAD
  local btnIdx, hdrIdx, ebIdx, shIdx = 0, 0, 0, 0
  local nestExpac = DB.settings.nestByExpansion and not DB.settings.gridView -- sub-grupos por expansão (só na visão por categorias)
  local yOff = 0
  -- desenha uma lista de itens num grid contíguo a partir de y; devolve o novo y.
  -- avança btnIdx (upvalue) e usa cols/BTN/PAD do escopo; reaproveitado pelo caminho
  -- normal e por cada sub-grupo de expansão.
  local function DrawItemGrid(lst, y)
    local col = 0
    for _, it in ipairs(lst) do
      btnIdx = btnIdx + 1
      local b = AcquireButton(btnIdx)
      if it.cached then FillButtonCached(b, it) else FillButton(b, it.bag, it.slot) end
      if it.stacked then SetItemButtonCount(b, it.count); b.kbStacked = true end -- contagem somada do empilhamento
      if it.dim then b:SetAlpha(0.25) end -- busca-realce: itens que não batem ficam apagados
      b:SetSize(BTN, BTN)
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", col * (BTN + PAD), y)
      b:Show()
      col = col + 1
      if col >= cols then col = 0; y = y - (BTN + PAD) end
    end
    if col > 0 then y = y - (BTN + PAD) end
    return y
  end
  -- banner de visualização (consulta do banco de longe, read-only)
  if cached then
    local _, _, snapTime = CurrentSnap()
    local when = ""
    if snapTime and date then local ok, s = pcall(date, "%d/%m %H:%M", snapTime); if ok and s then when = string.format(L.CACHE_SAVED, s) end end
    UI.cacheBanner:ClearAllPoints(); UI.cacheBanner:SetPoint("TOPLEFT", 0, yOff)
    UI.cacheBanner:SetWidth(contentW)
    UI.cacheBanner:SetText("|cff66b3ff" .. L.CACHE_BANNER .. when .. "|r")
    UI.cacheBanner:Show()
    yOff = yOff - 22
  else
    UI.cacheBanner:Hide()
  end
  for _, cat in ipairs(order) do
    local g = groups[cat]
    if g and #g > 0 then
      hdrIdx = hdrIdx + 1
      local h = headerPool[hdrIdx]
      if not h then
        h = CreateFrame("Button", nil, UI.content)
        h:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        -- cabeçalho é de largura total: pro ConsolePort o retângulo dele atravessa a tela
        -- e vira "candidato" em quase toda direção, quebrando a navegação por controle.
        -- nodeignore tira ele do scan do cursor (mouse intacto: clicar/recolher/arrastar segue).
        h:SetAttribute("nodeignore", true)
        local hl = h:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.08) -- alvo de drop / hover
        h.label = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.label:SetPoint("LEFT", 0, 0)
        h:SetScript("OnClick", function(self, mb)
          if CursorHasItem() then AssignCursorToCategory(self.cat); return end -- soltar item = atribuir
          if mb == "RightButton" then OpenCategoryMenu(self)
          elseif self.cat then DB.collapsed[self.cat] = (not DB.collapsed[self.cat]) or nil; Refresh() end
        end)
        h:SetScript("OnReceiveDrag", function(self) AssignCursorToCategory(self.cat) end)
        h:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          if CursorHasItem() then
            GameTooltip:SetText(L.TIP_DROP_HERE)
          else
            GameTooltip:SetText(DB.collapsed[self.cat] and L.TIP_LEFT_EXPAND or L.TIP_LEFT_COLLAPSE)
            GameTooltip:AddLine(L.TIP_HEADER_ACTIONS, 0.5, 1, 0.5)
          end
          GameTooltip:Show()
        end)
        h:SetScript("OnLeave", function() GameTooltip:Hide() end)
        headerPool[hdrIdx] = h
      end
      h.cat = cat
      h.catItems = g
      local collapsed = DB.collapsed[cat]
      h:SetSize(contentW, 16)
      h:ClearAllPoints(); h:SetPoint("TOPLEFT", 0, yOff)
      local sign = collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up"
      local lbl = "|T" .. sign .. ":14:14:0:0|t |cff" .. KB_AccentHex() .. CatDisplay(cat) .. "|r  |cff999999(" .. #g .. ")|r"
      -- valor total da categoria pela Auction House (só com fonte real de AH, fora da visão grade)
      if HasMarketSource() and not DB.settings.gridView then
        local total = 0
        for _, it in ipairs(g) do
          local v = GetMarketValue(it.itemID, it.link)
          if v then total = total + v * (it.count or 1) end
        end
        if total > 0 then lbl = lbl .. "  |cffffd700" .. GetCoinTextureString(total) .. "|r" end
      end
      h.label:SetText(lbl)
      h:Show()
      local setID = equipSetIDByName[cat]
      if setID then
        ebIdx = ebIdx + 1
        local eb = AcquireEquipButton(ebIdx)
        eb.setID = setID
        eb:SetText(L.BTN_EQUIP)
        eb:SetFrameLevel(h:GetFrameLevel() + 5)
        eb:ClearAllPoints()
        eb:SetPoint("LEFT", h.label, "RIGHT", 10, 0)
        eb:Show()
      end
      -- botão "Distribuir" no cabeçalho de Recém-obtidos: manda tudo pras categorias certas
      if cat == "Recém-obtidos" then
        if not UI.distribBtn then
          local d = CreateFrame("Button", nil, UI.content, "UIPanelButtonTemplate")
          d:SetAttribute("nodeignore", true) -- "Distribuir" fora da navegação por controle (linha do cabeçalho; só mouse)
          d:SetSize(72, 18); d:SetText(L.BTN_DISTRIBUTE)
          d:SetScript("OnClick", DistributeNew)
          d:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L.TIP_DISTRIBUTE_TITLE)
            GameTooltip:AddLine(L.TIP_DISTRIBUTE_BODY, 0.7, 0.7, 0.7, true)
            GameTooltip:Show()
          end)
          d:SetScript("OnLeave", function() GameTooltip:Hide() end)
          UI.distribBtn = d
        end
        UI.distribBtn:SetParent(UI.content)
        UI.distribBtn:SetFrameLevel(h:GetFrameLevel() + 5)
        UI.distribBtn:ClearAllPoints()
        UI.distribBtn:SetPoint("LEFT", h.label, "RIGHT", 10, 0)
        UI.distribBtn:Show()
      end
      -- botão "Abrir tudo" no cabeçalho de Abríveis: abre todos os recipientes de loot (pula trancados).
      -- escondido no vendedor (lá UseContainerItem venderia em vez de abrir); fica só no mouse fora do vendedor.
      if cat == "Abríveis" and not (MerchantFrame and MerchantFrame:IsShown()) then
        if not UI.openAllBtn then
          local o = CreateFrame("Button", nil, UI.content, "UIPanelButtonTemplate")
          o:SetAttribute("nodeignore", true) -- "Abrir tudo" fora da navegação por controle (linha do cabeçalho; só mouse)
          o:SetSize(72, 18); o:SetText(L.BTN_OPEN_ALL)
          o:SetScript("OnClick", function() OpenAllOpenables() end)
          o:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L.BTN_OPEN_ALL)
            GameTooltip:AddLine(L.TIP_OPEN_ALL, 0.7, 0.7, 0.7, true)
            GameTooltip:Show()
          end)
          o:SetScript("OnLeave", function() GameTooltip:Hide() end)
          UI.openAllBtn = o
        end
        UI.openAllBtn:SetParent(UI.content)
        UI.openAllBtn:SetFrameLevel(h:GetFrameLevel() + 5)
        UI.openAllBtn:ClearAllPoints()
        UI.openAllBtn:SetPoint("LEFT", h.label, "RIGHT", 10, 0)
        UI.openAllBtn:Show()
      end
      yOff = yOff - 18

      if not collapsed then
        if nestExpac then
          -- sub-agrupa os itens DESTA categoria pela expansão de origem.
          -- chave = expacID; nil (cache frio / sem expansão) vira o grupo UNK ("desconhecido").
          local UNK = -1 -- expacID válido é >= 0, então -1 é sentinela segura pro grupo nil
          local byExpac, expacKeys = {}, {}
          for _, it in ipairs(g) do
            local e = GetItemExpac(it.itemID, it.link)
            local key = (e == nil) and UNK or e
            if not byExpac[key] then byExpac[key] = {}; expacKeys[#expacKeys + 1] = key end
            local grp = byExpac[key]; grp[#grp + 1] = it
          end
          -- ordem: expacID DECRESCENTE (expansão mais nova primeiro); grupo desconhecido por último
          table.sort(expacKeys, function(a, b)
            if a == UNK then return false end
            if b == UNK then return true end
            return a > b
          end)
          if DB.settings.compactExpac then
            -- COMPACTO: os itens da categoria fluem num grid contínuo; o rótulo de cada
            -- expansão fica numa faixa ACIMA do 1º item daquele grupo. Vários grupos
            -- pequenos cabem na mesma linha; grupos grandes quebram pra próxima linha.
            local LBLBAND = 13               -- faixa de rótulo no topo de cada linha
            local ROWH = LBLBAND + BTN + PAD -- altura total de cada linha (rótulo + ícone + gap)
            -- lista plana dos itens na ordem dos grupos; o 1º item de cada grupo carrega o rótulo
            local flat = {}
            for _, key in ipairs(expacKeys) do
              local realE; if key ~= UNK then realE = key end -- evita o pitfall do "and/or" com 0
              local grp = byExpac[key]
              for idx = 1, #grp do
                flat[#flat + 1] = { it = grp[idx], lbl = (idx == 1) and ExpacName(realE) or nil, grpSize = (idx == 1) and #grp or nil }
              end
            end
            local col, rowTop = 0, yOff
            for _, node in ipairs(flat) do
              local x = col * (BTN + PAD)
              local it = node.it
              btnIdx = btnIdx + 1
              local b = AcquireButton(btnIdx)
              if it.cached then FillButtonCached(b, it) else FillButton(b, it.bag, it.slot) end
              if it.stacked then SetItemButtonCount(b, it.count); b.kbStacked = true end -- contagem somada do empilhamento
              if it.dim then b:SetAlpha(0.25) end -- busca-realce: itens que não batem ficam apagados
              b:SetSize(BTN, BTN)
              b:ClearAllPoints()
              b:SetPoint("TOPLEFT", x, rowTop - LBLBAND) -- ícone abaixo da faixa de rótulo
              b:Show()
              if node.lbl then -- 1º item do grupo: rótulo da expansão acima dele
                shIdx = shIdx + 1
                local sh = AcquireSubHeader(shIdx)
                local span = math.min(node.grpSize or 1, cols - col) * (BTN + PAD) -- largura do grupo nesta linha
                sh.label:SetText(node.lbl)
                sh.label:SetWidth(math.max(1, span - 4)); sh.label:SetWordWrap(false) -- trunca nome longo sem invadir o grupo vizinho
                sh:SetSize(math.max(1, span), LBLBAND)
                sh:ClearAllPoints(); sh:SetPoint("TOPLEFT", x, rowTop)
                sh:Show()
              end
              col = col + 1
              if col >= cols then col = 0; rowTop = rowTop - ROWH end
            end
            if col > 0 then rowTop = rowTop - ROWH end -- fecha a última linha parcial
            yOff = rowTop
          else
            -- SEPARADO (padrão): cada expansão é um bloco que começa em nova linha cheia
            for _, key in ipairs(expacKeys) do
              local realE; if key ~= UNK then realE = key end -- evita o pitfall do "and/or" com 0
              shIdx = shIdx + 1
              local sh = AcquireSubHeader(shIdx)
              sh.label:SetText(ExpacName(realE))
              sh.label:SetWidth(0); sh.label:SetWordWrap(true) -- largura automática (mostra o nome inteiro; reseta truncamento do modo compacto)
              sh:SetSize(math.max(1, contentW - 8), 14)
              sh:ClearAllPoints(); sh:SetPoint("TOPLEFT", 8, yOff)
              sh:Show()
              yOff = yOff - 16
              yOff = DrawItemGrid(byExpac[key], yOff)
              yOff = yOff - 4 -- pequeno gap ao fim do sub-grupo
            end
          end
        else
          yOff = DrawItemGrid(g, yOff)
        end
      end
      yOff = yOff - 6
    end
  end

  yOff = DrawEmpty(yOff)
  UpdateMoney()
  FinishLayout(-yOff)
end

-- ---------------- Popup: nova categoria ----------------
local function KB_CreateCategory(editBox, itemID)
  local name = editBox and editBox:GetText()
  AddCategory(name)
  if itemID and name and name ~= "" then DB.assignments[itemID] = name end
  Refresh()
end

StaticPopupDialogs["KRONONBAGS_NEWCAT"] = {
  text = L.POPUP_NEWCAT,
  button1 = L.BTN_CREATE,
  button2 = L.BTN_CANCEL,
  hasEditBox = true,
  OnAccept = function(self, itemID)
    KB_CreateCategory(self.editBox or self.EditBox, itemID)
  end,
  EditBoxOnEnterPressed = function(self, itemID)
    local dialog = self:GetParent()
    KB_CreateCategory(self, itemID or (dialog and dialog.data))
    if dialog then dialog:Hide() end
  end,
  EditBoxOnEscapePressed = function(self)
    local dialog = self:GetParent()
    if dialog then dialog:Hide() end
  end,
  timeout = 0, whileDead = true, hideOnEscape = true,
}

-- ---------------- Popups: exportar / importar / regra de categoria ----------------
local KB_exportStr = ""
local KB_ruleTargetEntry
StaticPopupDialogs["KRONONBAGS_RULE"] = {
  text = L.POPUP_RULE,
  button1 = L.BTN_SAVE,
  button2 = L.BTN_CANCEL,
  hasEditBox = true,
  editBoxWidth = 260,
  OnShow = function(self)
    local eb = self.editBox or self.EditBox
    if eb then eb:SetText((KB_ruleTargetEntry and KB_ruleTargetEntry.rule) or ""); eb:HighlightText() end
  end,
  OnAccept = function(self)
    if not KB_ruleTargetEntry then return end
    local eb = self.editBox or self.EditBox
    local txt = (eb and eb:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
    KB_ruleTargetEntry.rule = (txt ~= "" and txt) or nil
    if RefreshConfigCats then RefreshConfigCats() end
    if Refresh then Refresh() end
  end,
  EditBoxOnEscapePressed = function(self) local d = self:GetParent(); if d then d:Hide() end end,
  timeout = 0, whileDead = true, hideOnEscape = true,
}
StaticPopupDialogs["KRONONBAGS_EXPORT"] = {
  text = L.POPUP_EXPORT,
  button1 = L.BTN_CLOSE,
  hasEditBox = true,
  editBoxWidth = 260,
  OnShow = function(self)
    local eb = self.editBox or self.EditBox
    if eb then eb:SetText(KB_exportStr); eb:HighlightText(); eb:SetFocus() end
  end,
  EditBoxOnEnterPressed = function(self) local d = self:GetParent(); if d then d:Hide() end end,
  EditBoxOnEscapePressed = function(self) local d = self:GetParent(); if d then d:Hide() end end,
  timeout = 0, whileDead = true, hideOnEscape = true,
}
StaticPopupDialogs["KRONONBAGS_IMPORT"] = {
  text = L.POPUP_IMPORT,
  button1 = L.BTN_IMPORT,
  button2 = L.BTN_CANCEL,
  hasEditBox = true,
  editBoxWidth = 260,
  OnAccept = function(self)
    local eb = self.editBox or self.EditBox
    local ok, err = ImportCategories(eb and eb:GetText(), false)
    if ok then print(KB_PREFIX .. L.MSG_CATS_IMPORTED)
    else print(KB_PREFIX .. string.format(L.MSG_IMPORT_FAILED, tostring(err))) end
  end,
  EditBoxOnEscapePressed = function(self) local d = self:GetParent(); if d then d:Hide() end end,
  timeout = 0, whileDead = true, hideOnEscape = true,
}
StaticPopupDialogs["KRONONBAGS_TRANSFER_SELL"] = {
  text = L.CONFIRM_TRANSFER_SELL,
  button1 = YES,
  button2 = NO,
  OnAccept = function() SellMatches(KB_transferSellList); KB_transferSellList = nil end,
  OnCancel = function() KB_transferSellList = nil end,
  timeout = 0, whileDead = true, hideOnEscape = true,
}

-- ---------------- Temas de cor ----------------
-- Lista ordenada (dropdown da config) E indexável por chave (KB_THEMES[key]).
KB_THEMES = {
  { key = "dark",   name = L.THEME_DARK,   bg = { 0, 0, 0 },          border = { 0.4, 0.4, 0.4 },   accent = { 0.94, 0.85, 0.55 } },
  { key = "slate",  name = L.THEME_SLATE,  bg = { 0.10, 0.11, 0.14 }, border = { 0.3, 0.35, 0.45 },  accent = { 0.55, 0.70, 0.95 } },
  { key = "gold",   name = L.THEME_GOLD,   bg = { 0.05, 0.04, 0.01 }, border = { 1, 0.82, 0 },       accent = { 1, 0.82, 0 } },
  { key = "kronon", name = L.THEME_KRONON, bg = { 0.07, 0.04, 0.12 }, border = { 0.6, 0.3, 0.9 },    accent = { 0.78, 0.60, 0.95 } },
  { key = "druid",  name = L.THEME_DRUID,  bg = { 0.03, 0.07, 0.04 }, border = { 0.35, 0.8, 0.45 },  accent = { 0.55, 0.90, 0.60 } },
  { key = "ruby",   name = L.THEME_RUBY,   bg = { 0.09, 0.02, 0.03 }, border = { 0.85, 0.25, 0.3 },  accent = { 1, 0.50, 0.55 } },
}
for _, t in ipairs(KB_THEMES) do KB_THEMES[t.key] = t end -- acesso por chave sem perder a ordem (ipairs)

-- accent (cor de destaque) do tema atual: cabeçalhos, título, "Vazio", sub-grupos.
KB_Accent = function()
  local t = KB_THEMES[(DB and DB.settings and DB.settings.theme) or "dark"] or KB_THEMES.dark
  local a = t.accent or { 0.94, 0.85, 0.55 }
  return a[1], a[2], a[3]
end
-- mesma cor em hex "rrggbb" pra usar inline em |cff..|r
KB_AccentHex = function()
  local r, g, b = KB_Accent()
  return string.format("%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

-- Re-skin ao vivo: aplica a cor do tema (bg + alpha do slider), a borda e o accent na janela escura.
local KB_lastAccentTheme -- evita Refresh redundante quando só a opacidade muda (mesmo tema)
local function ApplyTheme(key)
  local t = KB_THEMES[key] or KB_THEMES.dark
  if DB and DB.settings and DB.settings.frameStyle == "blizzard" then return end -- moldura nativa controla o fundo/título
  if not (UI and UI.SetBackdropColor) then return end
  local op = (DB and DB.settings and DB.settings.opacity) or 0.92
  UI:SetBackdropColor(t.bg[1], t.bg[2], t.bg[3], op)
  if UI.SetBackdropBorderColor then
    UI:SetBackdropBorderColor(t.border[1], t.border[2], t.border[3], 1)
  end
  local a = t.accent or { 0.94, 0.85, 0.55 }
  if UI.titleFS then UI.titleFS:SetTextColor(a[1], a[2], a[3]) end -- título no estilo escuro
  -- remonta cabeçalhos de categoria/sub-headers (eles leem KB_AccentHex/KB_Accent no Refresh).
  -- só quando o tema realmente muda — não a cada tick do slider de opacidade. Refresh NÃO chama ApplyTheme (sem recursão).
  if t.key ~= KB_lastAccentTheme then
    KB_lastAccentTheme = t.key
    if Refresh then Refresh() end
  end
end

-- ---------------- Janela ----------------
ApplyOpacity = function()
  -- o alpha do fundo agora usa a COR do tema atual; ApplyTheme respeita frameStyle/UI prontos
  ApplyTheme(DB and DB.settings and DB.settings.theme or "dark")
end

UpdateMoney = function()
  if not goldText then return end
  goldText:SetText(GetMoneyString(GetMoney(), true))
  if freeNum then
    local free = 0
    if CachedMode() then
      local _, f = CurrentSnap(); free = f or 0 -- slots livres do snapshot salvo
    elseif mode == "bags" then
      for bag = 0, 4 do free = free + (C_Container.GetContainerNumFreeSlots(bag) or 0) end -- reagentes contam à parte
    else
      for _, bag in ipairs(ActiveBags()) do free = free + (C_Container.GetContainerNumFreeSlots(bag) or 0) end
    end
    freeNum:SetText(free)
    if free <= 5 then freeNum:SetTextColor(1, 0.3, 0.3) else freeNum:SetTextColor(1, 1, 1) end
  end
  if reagentNum then
    local rFree = C_Container.GetContainerNumFreeSlots(5) or 0
    reagentNum:SetText(rFree)
    if rFree <= 2 then reagentNum:SetTextColor(1, 0.3, 0.3) else reagentNum:SetTextColor(1, 1, 1) end
  end
  if currencyText then
    local parts = {}
    -- valor do lixo (qualidade Pobre que vende) primeiro
    local junk = 0
    for _, bag in ipairs(BAGS) do
      local slots = C_Container.GetContainerNumSlots(bag) or 0
      for slot = 1, slots do
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info and info.itemID and info.quality == 0 then
          local sell = select(11, C_Item.GetItemInfo(info.hyperlink))
          if sell and sell > 0 then junk = junk + sell * (info.stackCount or 1) end
        end
      end
    end
    if junk > 0 then parts[#parts + 1] = "|cff808080" .. L.JUNK_LABEL .. "|r " .. GetCoinTextureString(junk) end
    -- currencies acompanhadas
    if C_CurrencyInfo and C_CurrencyInfo.GetBackpackCurrencyInfo then
      for i = 1, 10 do
        local info = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
        if info and info.iconFileID then
          parts[#parts + 1] = string.format("|T%d:13:13:0:0|t %s", info.iconFileID, BreakUpLargeNumbers(info.quantity or 0))
        end
      end
    end
    currencyText:SetText(table.concat(parts, "   "))
  end
end

-- destaca o modo de visualização ativo (Categorias/Grade) na barra lateral
UpdateModeBar = function()
  if not (UI and UI.modeBar) then return end
  local grid = (DB and DB.settings and DB.settings.gridView) and true or false
  if UI.modeBar.catsBtn and UI.modeBar.catsBtn.sel then UI.modeBar.catsBtn.sel:SetShown(not grid) end
  if UI.modeBar.gridBtn and UI.modeBar.gridBtn.sel then UI.modeBar.gridBtn.sel:SetShown(grid) end
end

UpdateTabs = function()
  if not (UI and UI.tabs) then return end
  -- abas Banco/Brigada também aparecem de LONGE quando há snapshot salvo (consulta read-only)
  local showBank = atBank or HasCharBankSnap()
  local showWb   = (atBank and WarbandAvailable()) or HasWarbandSnap()
  local showBar  = atBank or showBank or showWb
  if UI.tabBar then UI.tabBar:SetShown(showBar) end
  for id, t in pairs(UI.tabs) do
    if id == "bags" then t:SetShown(true)
    elseif id == "bank" then t:SetShown(showBank)
    elseif id == "warband" then t:SetShown(showWb) end
    if t.sel then t.sel:SetShown(id == mode) end
  end
  -- depositar só vale no banco de verdade
  if UI.depositBtn then UI.depositBtn:SetShown(atBank and (mode == "bank" or mode == "warband")) end
  if UI.sellJunkBtn then UI.sellJunkBtn:SetShown((MerchantFrame and MerchantFrame:IsShown()) and mode == "bags") end
  -- "Transferir": só com busca ativa E (vendedor aberto OU no banco)
  if UI.transferBtn then
    local merchant = MerchantFrame and MerchantFrame:IsShown()
    UI.transferBtn:SetShown(search ~= "" and (merchant or atBank))
    -- ícone contextual: moeda no vendedor (vende), bolsa no banco (deposita)
    UI.transferBtn:SetNormalTexture(merchant and "Interface\\ICONS\\INV_Misc_Coin_01" or "Interface\\ICONS\\INV_Misc_Bag_08")
  end
end

-- ---------------- Construtor de busca modular ----------------
-- Painel visual pra quem não conhece a sintaxe da busca. Cada linha é um filtro
-- (campo + condição + valor) e, ao Aplicar, geramos a STRING que o parser já
-- entende (SearchMatcher) e fazemos sb:SetText(query). Reaproveita 100% o parser:
-- só produzimos tokens canônicos (ilvl>200, q:epico, equip, !boe…).
CreateFilterBuilder = function(sb, sortBtn)
  -- tokens canônicos por índice de qualidade (0-6), reconhecidos pelo QMAP em qualquer idioma
  local QUAL_TOKEN = { [0] = "pobre", [1] = "comum", [2] = "incomum", [3] = "raro", [4] = "epico", [5] = "lendario", [6] = "artefato" }
  local function qualName(i) return _G["ITEM_QUALITY" .. i .. "_DESC"] or QUAL_TOKEN[i] end

  -- rótulos (lidos de L, já resolvido no load)
  local FIELD_ORDER = { "ilvl", "quality", "type", "bind", "flag", "name" }
  local FIELD_LABEL = { ilvl = L.FIELD_ILVL, quality = L.FIELD_QUALITY, type = L.FIELD_TYPE, bind = L.FIELD_BIND, flag = L.FIELD_FLAG, name = L.FIELD_NAME }
  local FIELD_TIP   = { ilvl = L.FTIP_ILVL, quality = L.FTIP_QUALITY, type = L.FTIP_TYPE, bind = L.FTIP_BIND, flag = L.FTIP_FLAG, name = L.FTIP_NAME }
  local COND_LABEL  = { GT = L.COND_GT, LT = L.COND_LT, GE = L.COND_GE, LE = L.COND_LE, EQ = L.COND_EQ, BETWEEN = L.COND_BETWEEN, IS = L.COND_IS, ATLEAST = L.COND_ATLEAST }
  local ILVL_OP     = { GT = ">", LT = "<", GE = ">=", LE = "<=" }
  local ILVL_CONDS  = { "GT", "LT", "GE", "LE", "EQ", "BETWEEN" }
  local QUAL_CONDS  = { "IS", "ATLEAST" }
  -- opções que viram palavra-chave (token solto) — mais confiável que tipo:
  local TYPE_OPTS = { { "equip", L.FTYPE_EQUIP }, { "consumivel", L.FTYPE_CONSUM }, { "missao", L.FTYPE_QUEST }, { "lixo", L.FTYPE_JUNK } }
  local BIND_OPTS = { { "boe", L.FBIND_BOE }, { "bou", L.FBIND_BOU }, { "wb", L.FBIND_WB }, { "vinculado", L.FBIND_BOUND } }
  local FLAG_OPTS = { { "novo", L.FFLAG_NEW }, { "favorito", L.FFLAG_FAV } }

  local ROWS_TOP, ROWH = 64, 28
  local panelRows, freePool = {}, {}
  local FB, footer
  local addRow, removeRow, relayout, setField, setCond, layoutRow, acquireRow, releaseRow

  -- monta o TERMO de uma linha (ou nil se incompleta)
  local function rowToTerm(r)
    local f, term = r.field, nil
    if f == "ilvl" then
      if r.cond == "BETWEEN" then
        local a, b = tonumber(r.valEdit:GetText()), tonumber(r.valEdit2:GetText())
        if not a or not b then return nil end
        if a > b then a, b = b, a end
        term = "ilvl:" .. a .. "-" .. b
      else
        local n = tonumber(r.valEdit:GetText())
        if not n then return nil end
        if r.cond == "EQ" then term = "ilvl:" .. n
        else term = "ilvl" .. (ILVL_OP[r.cond] or ">") .. n end
      end
    elseif f == "quality" then
      if r.qIndex == nil then return nil end
      if r.cond == "ATLEAST" then term = "q>=" .. r.qIndex
      else term = "q:" .. (QUAL_TOKEN[r.qIndex] or "epico") end
    elseif f == "type" or f == "bind" or f == "flag" then
      if not r.token or r.token == "" then return nil end
      term = r.token
    elseif f == "name" then
      -- 1ª palavra (o parser casa substring sem espaço), sem metacaracteres que quebrariam
      -- o tokenizer, e com prefixo nome: pra NÃO colidir com palavra-chave/operador
      -- (ex: nome "novo"/"não" vira nome:novo / nome:não, não a flag/operador).
      local t = (r.valEdit:GetText() or ""):lower():match("^%s*(%S+)")
      if t then t = t:gsub("[&|!()]", "") end
      if not t or t == "" then return nil end
      term = "nome:" .. t
    end
    if not term then return nil end
    if r.negate then term = "!" .. term end
    return term
  end

  local function buildQuery()
    local terms = {}
    for _, r in ipairs(panelRows) do
      local t = rowToTerm(r)
      if t then terms[#terms + 1] = t end
    end
    if #terms == 0 then return "" end
    return table.concat(terms, FB.junctionAll and " & " or " | ")
  end

  -- helpers de widget (todos nodeignore: chrome do painel, fora da navegação por controle)
  local function fbDropdown(parent, w)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, 20); b:SetAttribute("nodeignore", true)
    return b
  end
  local function fbEdit(parent, w)
    local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    e:SetSize(w, 20); e:SetAutoFocus(false); e:SetAttribute("nodeignore", true)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return e
  end

  -- menus de contexto (mesmo padrão MenuUtil do resto do addon)
  local function openFieldMenu(r)
    if not MenuUtil then return end
    MenuUtil.CreateContextMenu(r.fieldBtn, function(owner, root)
      root:CreateTitle(L.FIELD_NAME)
      for _, f in ipairs(FIELD_ORDER) do
        root:CreateButton(FIELD_LABEL[f], function() setField(r, f); relayout() end)
      end
    end)
  end
  local function openCondMenu(r)
    if not MenuUtil then return end
    local conds = (r.field == "ilvl") and ILVL_CONDS or (r.field == "quality") and QUAL_CONDS
    if not conds then return end
    MenuUtil.CreateContextMenu(r.condBtn, function(owner, root)
      for _, c in ipairs(conds) do
        root:CreateButton(COND_LABEL[c], function() setCond(r, c); relayout() end)
      end
    end)
  end
  local function openValueMenu(r)
    if not MenuUtil then return end
    local f = r.field
    MenuUtil.CreateContextMenu(r.valBtn, function(owner, root)
      if f == "quality" then
        root:CreateTitle(L.FIELD_QUALITY)
        for i = 0, 6 do
          root:CreateButton(qualName(i), function() r.qIndex = i; r.valBtn:SetText(qualName(i)) end)
        end
      else
        local opts = (f == "type" and TYPE_OPTS) or (f == "bind" and BIND_OPTS) or (f == "flag" and FLAG_OPTS)
        if not opts then return end
        root:CreateTitle(FIELD_LABEL[f])
        for _, o in ipairs(opts) do
          root:CreateButton(o[2], function() r.token = o[1]; r.valBtn:SetText(o[2]) end)
        end
      end
    end)
  end

  local function NewRowFrame()
    local r = CreateFrame("Frame", nil, FB)
    r:SetSize(416, 24); r:SetAttribute("nodeignore", true)
    -- NÃO (prefixa ! no termo)
    r.notCheck = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
    r.notCheck:SetSize(22, 22); r.notCheck:SetPoint("LEFT", 0, 0); r.notCheck:SetAttribute("nodeignore", true)
    r.notCheck:SetScript("OnClick", function(self) r.negate = self:GetChecked() and true or false end)
    r.notCheck:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(L.FILTER_NOT)
      GameTooltip:AddLine(L.FTIP_NOT, 0.8, 0.8, 0.8, true); GameTooltip:Show()
    end)
    r.notCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- Campo
    r.fieldBtn = fbDropdown(r, 86); r.fieldBtn:SetPoint("LEFT", r.notCheck, "RIGHT", 2, 0)
    r.fieldBtn:SetScript("OnClick", function() openFieldMenu(r) end)
    r.fieldBtn:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(FIELD_LABEL[r.field] or L.FIELD_NAME)
      GameTooltip:AddLine(FIELD_TIP[r.field] or "", 0.8, 0.8, 0.8, true); GameTooltip:Show()
    end)
    r.fieldBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- Condição (só ilvl/qualidade)
    r.condBtn = fbDropdown(r, 88); r.condBtn:SetPoint("LEFT", r.fieldBtn, "RIGHT", 4, 0)
    r.condBtn:SetScript("OnClick", function() openCondMenu(r) end)
    r.condBtn:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(COND_LABEL[r.cond] or L.COND_EQ)
      GameTooltip:AddLine(r.cond == "BETWEEN" and L.FTIP_BETWEEN or L.FTIP_COND, 0.8, 0.8, 0.8, true); GameTooltip:Show()
    end)
    r.condBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- Valor: edit (número/nome), edit2 (máx do "entre") e dropdown (qualidade/tipo/vínculo/marcador)
    r.valEdit = fbEdit(r, 44)
    r.dash = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); r.dash:SetText("–")
    r.valEdit2 = fbEdit(r, 44)
    r.valBtn = fbDropdown(r, 150)
    r.valBtn:SetScript("OnClick", function() openValueMenu(r) end)
    local function valTip(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(L.FTIP_VALUE); GameTooltip:Show()
    end
    r.valBtn:SetScript("OnEnter", valTip);  r.valBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    r.valEdit:SetScript("OnEnter", valTip); r.valEdit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- × remover
    r.removeBtn = CreateFrame("Button", nil, r, "UIPanelCloseButton")
    r.removeBtn:SetSize(24, 24); r.removeBtn:SetPoint("RIGHT", 0, 0); r.removeBtn:SetAttribute("nodeignore", true)
    r.removeBtn:SetScript("OnClick", function() removeRow(r) end)
    r.removeBtn:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(L.FTIP_REMOVE); GameTooltip:Show()
    end)
    r.removeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return r
  end

  -- define o campo e os defaults (já deixa a linha válida quando possível)
  setField = function(r, f)
    r.field = f
    r.fieldBtn:SetText(FIELD_LABEL[f])
    r.token, r.qIndex = nil, nil
    r.valEdit:SetText(""); r.valEdit2:SetText("")
    if f == "ilvl" then
      r.cond = "GT"; r.valEdit:SetNumeric(true); r.valEdit2:SetNumeric(true)
    elseif f == "quality" then
      r.cond = "IS"; r.qIndex = 4; r.valBtn:SetText(qualName(4))
    elseif f == "name" then
      r.cond = nil; r.valEdit:SetNumeric(false)
    elseif f == "type" then
      r.cond = nil; r.token = TYPE_OPTS[1][1]; r.valBtn:SetText(TYPE_OPTS[1][2])
    elseif f == "bind" then
      r.cond = nil; r.token = BIND_OPTS[1][1]; r.valBtn:SetText(BIND_OPTS[1][2])
    elseif f == "flag" then
      r.cond = nil; r.token = FLAG_OPTS[1][1]; r.valBtn:SetText(FLAG_OPTS[1][2])
    end
    if r.cond then r.condBtn:SetText(COND_LABEL[r.cond]) end
  end

  setCond = function(r, c) r.cond = c; r.condBtn:SetText(COND_LABEL[c]) end

  -- posiciona os widgets da linha conforme campo/condição
  layoutRow = function(r)
    local f = r.field
    local hasCond = (f == "ilvl" or f == "quality")
    r.condBtn:SetShown(hasCond)
    local anchor = hasCond and r.condBtn or r.fieldBtn
    r.valEdit:Hide(); r.valEdit2:Hide(); r.dash:Hide(); r.valBtn:Hide()
    if f == "ilvl" then
      r.valEdit:SetWidth(44); r.valEdit:SetNumeric(true)
      r.valEdit:ClearAllPoints(); r.valEdit:SetPoint("LEFT", anchor, "RIGHT", 12, 0); r.valEdit:Show()
      if r.cond == "BETWEEN" then
        r.dash:ClearAllPoints(); r.dash:SetPoint("LEFT", r.valEdit, "RIGHT", 5, 0); r.dash:Show()
        r.valEdit2:SetWidth(44)
        r.valEdit2:ClearAllPoints(); r.valEdit2:SetPoint("LEFT", r.dash, "RIGHT", 8, 0); r.valEdit2:Show()
      end
    elseif f == "name" then
      r.valEdit:SetWidth(150); r.valEdit:SetNumeric(false)
      r.valEdit:ClearAllPoints(); r.valEdit:SetPoint("LEFT", anchor, "RIGHT", 12, 0); r.valEdit:Show()
    else
      r.valBtn:ClearAllPoints(); r.valBtn:SetPoint("LEFT", anchor, "RIGHT", 12, 0); r.valBtn:Show()
    end
  end

  acquireRow = function()
    local r = table.remove(freePool) or NewRowFrame()
    r.notCheck:SetChecked(false); r.negate = false
    r:Show()
    return r
  end
  releaseRow = function(r) r:Hide(); freePool[#freePool + 1] = r end

  relayout = function()
    local y = -ROWS_TOP
    for _, r in ipairs(panelRows) do
      r:ClearAllPoints()
      r:SetPoint("TOPLEFT", FB, "TOPLEFT", 12, y)
      r:SetPoint("RIGHT", FB, "RIGHT", -12, 0)
      layoutRow(r); r:Show()
      y = y - ROWH
    end
    footer:ClearAllPoints(); footer:SetPoint("TOPLEFT", FB, "TOPLEFT", 12, y - 6)
    FB:SetHeight(ROWS_TOP + #panelRows * ROWH + 6 + 54 + 12)
  end

  addRow = function()
    local r = acquireRow()
    panelRows[#panelRows + 1] = r
    setField(r, "ilvl")
    relayout()
  end
  removeRow = function(r)
    for i, rr in ipairs(panelRows) do if rr == r then table.remove(panelRows, i); break end end
    releaseRow(r)
    if #panelRows == 0 then addRow() else relayout() end
  end

  -- ===== painel =====
  FB = CreateFrame("Frame", "KrononBagsFilter", UIParent, "BackdropTemplate")
  FB:SetSize(440, 220)
  FB:SetFrameStrata("DIALOG")
  FB:SetPoint("TOPLEFT", UI, "TOPRIGHT", 6, 0)
  FB:SetMovable(true); FB:EnableMouse(true); FB:RegisterForDrag("LeftButton")
  FB:SetScript("OnDragStart", FB.StartMoving)
  FB:SetScript("OnDragStop", FB.StopMovingOrSizing)
  FB:SetAttribute("nodeignore", true) -- painel inteiro fora da navegação por controle
  if FB.SetBackdrop then
    FB:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    FB:SetBackdropColor(0, 0, 0, 0.95)
  end
  FB.junctionAll = true
  FB:Hide()
  UI.filterBuilder = FB
  tinsert(UISpecialFrames, "KrononBagsFilter") -- ESC fecha o construtor

  local ftitle = FB:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  ftitle:SetPoint("TOP", 0, -12); ftitle:SetText("|cfff0d98c" .. L.FILTER_TITLE .. "|r")
  local fclose = CreateFrame("Button", nil, FB, "UIPanelCloseButton")
  fclose:SetPoint("TOPRIGHT", 2, 2); fclose:SetAttribute("nodeignore", true)
  local fhint = FB:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  fhint:SetPoint("TOPLEFT", 14, -36); fhint:SetPoint("TOPRIGHT", -14, -36)
  fhint:SetJustifyH("LEFT"); fhint:SetText(L.FILTER_HINT)

  -- rodapé: junção (E/OU), + adicionar, aplicar, limpar
  footer = CreateFrame("Frame", nil, FB)
  footer:SetSize(416, 54); footer:SetAttribute("nodeignore", true)
  local junctionBtn = fbDropdown(footer, 150); junctionBtn:SetPoint("TOPLEFT", 0, 0); junctionBtn:SetHeight(22)
  local function updJunction() junctionBtn:SetText(FB.junctionAll and L.FILTER_ALL or L.FILTER_ANY) end
  junctionBtn:SetScript("OnClick", function() FB.junctionAll = not FB.junctionAll; updJunction() end)
  updJunction()
  local addBtn = fbDropdown(footer, 140); addBtn:SetPoint("LEFT", junctionBtn, "RIGHT", 8, 0); addBtn:SetHeight(22)
  addBtn:SetText("+ " .. L.FILTER_ADD)
  addBtn:SetScript("OnClick", function() addRow() end)
  local applyBtn = fbDropdown(footer, 120); applyBtn:SetPoint("TOPLEFT", 0, -26); applyBtn:SetHeight(22)
  applyBtn:SetText(L.FILTER_APPLY)
  applyBtn:SetScript("OnClick", function() sb:SetText(buildQuery()); sb:ClearFocus() end)
  local clearBtn = fbDropdown(footer, 120); clearBtn:SetPoint("LEFT", applyBtn, "RIGHT", 8, 0); clearBtn:SetHeight(22)
  clearBtn:SetText(L.FILTER_CLEAR)
  clearBtn:SetScript("OnClick", function()
    for i = #panelRows, 1, -1 do releaseRow(panelRows[i]); panelRows[i] = nil end
    addRow(); sb:SetText("")
  end)

  -- ===== botão "Filtrar" no cabeçalho, à esquerda da caixa de busca =====
  local filterBtn = CreateFrame("Button", nil, UI, "UIPanelButtonTemplate")
  filterBtn:SetSize(54, 20)
  filterBtn:SetText(L.FILTER_BTN)
  filterBtn:SetAttribute("nodeignore", true) -- só mouse
  filterBtn:SetPoint("RIGHT", sb, "LEFT", -6, 0)
  sortBtn:ClearAllPoints(); sortBtn:SetPoint("RIGHT", filterBtn, "LEFT", -6, 0) -- a vassoura desce pra esquerda do "Filtrar"
  filterBtn:SetScript("OnClick", function()
    if FB:IsShown() then
      FB:Hide()
    else
      if #panelRows == 0 then addRow() end
      FB:Show()
    end
  end)
  filterBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM"); GameTooltip:SetText(L.FILTER_TITLE)
    GameTooltip:AddLine(L.FILTER_HINT, 0.8, 0.8, 0.8, true); GameTooltip:Show()
  end)
  filterBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
  UI.filterBtn = filterBtn
end

CreateUI = function()
  local blizzard = (DB.settings.frameStyle == "blizzard")
  UI = CreateFrame("Frame", "KrononBagsFrame", UIParent, blizzard and "ButtonFrameTemplate" or "BackdropTemplate")
  UI:SetPoint("CENTER")
  UI:SetFrameStrata("HIGH")
  UI:SetClampedToScreen(true)
  UI:SetMovable(true); UI:EnableMouse(true); UI:RegisterForDrag("LeftButton")
  UI:SetScript("OnDragStart", UI.StartMoving)
  UI:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    if p and DB and DB.charPos then DB.charPos[CharKey()] = { p, rp, x, y } end
  end)

  local logoPath = "Interface\\AddOns\\KrononBags\\Media\\KrononLogo.tga"
  local ctrlY, gearAnchorX, clockX, clockY

  if blizzard then
    -- moldura NATIVA (igual à bag combinada): portrait + barra de título + X + inset
    UI.kbMargin, UI.kbTop, UI.kbBottom, ctrlY, gearAnchorX = 13, 60, 40, -32, -10
    clockX, clockY = 70, -32 -- à direita do portrait, fora do título centralizado
    if UI.SetTitle then UI:SetTitle("KrononBags") end
    local portrait = (UI.PortraitContainer and UI.PortraitContainer.portrait) or UI.portrait
    if portrait then
      portrait:SetTexture(logoPath)
      portrait:SetTexCoord(-0.08, 1.08, -0.08, 1.08) -- preenche o círculo, centralizada, pontas sem cortar
    end
    if ButtonFrameTemplate_HideButtonBar then ButtonFrameTemplate_HideButtonBar(UI) end
  else
    -- estilo ESCURO (atual): backdrop preto + header próprio (logo + título + X)
    UI.kbMargin, UI.kbTop, UI.kbBottom, ctrlY, gearAnchorX = MARGIN, 34, MARGIN + 22, -6, -28
    clockX, clockY = 152, -4 -- logo após o título "KrononBags", à esquerda (longe da fileira de controles)
    if UI.SetBackdrop then
      UI:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
      })
    end
    local logo = UI:CreateTexture(nil, "ARTWORK")
    logo:SetSize(24, 24); logo:SetPoint("TOPLEFT", MARGIN - 2, -5)
    logo:SetTexture(logoPath)
    local title = UI:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", logo, "RIGHT", 5, -1); title:SetText("KrononBags")
    title:SetTextColor(KB_Accent()) -- accent do tema (recolorido pelo ApplyTheme)
    UI.titleFS = title
    local divider = UI:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.45, 0.45, 0.5, 0.5); divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", UI, "TOPLEFT", MARGIN, -31)
    divider:SetPoint("TOPRIGHT", UI, "TOPRIGHT", -MARGIN, -31)
    local close = CreateFrame("Button", nil, UI, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)
  end
  UI:SetSize(COLS * (BTN + PAD) - PAD + UI.kbMargin * 2, 400)

  -- controles: organizar / busca / engrenagem (ambos os estilos), ancorados ao topo-direita
  local gear = CreateFrame("Button", nil, UI)
  gear:SetSize(22, 22)
  gear:SetPoint("TOPRIGHT", UI, "TOPRIGHT", gearAnchorX, ctrlY)
  gear:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
  gear:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton", "ADD")
  gear:SetScript("OnClick", function() ToggleConfig() end)
  gear:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText(L.TIP_CONFIG); GameTooltip:Show() end)
  gear:SetScript("OnLeave", function() GameTooltip:Hide() end)

  -- botão "i" (info/dicas) à esquerda da engrenagem
  local help = CreateFrame("Button", nil, UI)
  help:SetSize(22, 22)
  help:SetPoint("RIGHT", gear, "LEFT", -6, 0)
  help:SetNormalTexture("Interface\\Common\\help-i") -- "i" dourado (SWAPPÁVEL: troque a textura aqui)
  help:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  help:SetScript("OnClick", function()
    if UI.ToggleHelp then UI.ToggleHelp() end -- alterna os marcadores de dica (coach-marks, não-modal)
  end)
  help:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText(L.TIP_HELP); GameTooltip:Show() end)
  help:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local sb = CreateFrame("EditBox", nil, UI, "InputBoxTemplate")
  sb:SetSize(150, 20); sb:SetPoint("RIGHT", help, "LEFT", -6, 0); sb:SetAutoFocus(false) -- à esquerda do "?" (sem sobrepor)
  -- botãozinho "✕" pra limpar a busca (só aparece quando há texto)
  local clr = CreateFrame("Button", nil, sb)
  clr:SetSize(14, 14); clr:SetPoint("RIGHT", sb, "RIGHT", -4, 0)
  clr:SetNormalAtlas("common-search-clearbutton")   -- "✕" oficial das caixas de busca
  clr:SetHighlightAtlas("common-search-clearbutton")
  clr:Hide()
  clr:SetScript("OnClick", function() sb:SetText(""); sb:ClearFocus() end) -- OnTextChanged zera a busca e dá Refresh (evita Refresh duplo)
  clr:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(L.TIP_SEARCH_CLEAR); GameTooltip:Show() end)
  clr:SetScript("OnLeave", function() GameTooltip:Hide() end)
  sb:SetScript("OnTextChanged", function(self) search = (self:GetText() or ""):lower(); clr:SetShown((self:GetText() or "") ~= ""); Refresh() end)
  sb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  sb:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText(L.TIP_SEARCH_TITLE)
    GameTooltip:AddLine(L.TIP_SEARCH_L1, 0.8, 0.8, 0.8)
    GameTooltip:AddLine(L.TIP_SEARCH_L2, 0.8, 0.8, 0.8)
    GameTooltip:AddLine(L.TIP_SEARCH_L3, 0.5, 1, 0.5)
    GameTooltip:Show()
  end)
  sb:SetScript("OnLeave", function() GameTooltip:Hide() end)

  -- botão "organizar automático" (vassoura da Blizzard), à esquerda da busca
  local sortBtn = CreateFrame("Button", nil, UI)
  sortBtn:SetSize(24, 24)
  sortBtn:SetPoint("RIGHT", sb, "LEFT", -6, 0)
  sortBtn:SetNormalAtlas("bags-button-autosort-up")
  sortBtn:SetPushedAtlas("bags-button-autosort-down")
  sortBtn:SetHighlightAtlas("bags-button-autosort-highlight")
  sortBtn:SetScript("OnClick", function()
    if InCombatLockdown() then return end
    if C_Container and C_Container.SortBags then C_Container.SortBags() end
  end)
  sortBtn:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText(L.TIP_AUTOSORT); GameTooltip:Show() end)
  sortBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

  -- botão "Filtrar" + construtor visual de busca (gera a string que o parser já entende)
  CreateFilterBuilder(sb, sortBtn)

  -- barra de modos de visualização (à ESQUERDA, FORA da janela: não mexe na largura/scroll)
  local modeBar = CreateFrame("Frame", nil, UI)
  modeBar:SetSize(30, 64)
  modeBar:SetPoint("TOPRIGHT", UI, "TOPLEFT", -2, -(UI.kbTop or 34))
  modeBar:SetAttribute("nodeignore", true) -- chrome lateral: fora da navegação por controle
  UI.modeBar = modeBar
  local function makeModeBtn(yOff, isGrid, icon, tipText)
    local b = CreateFrame("Button", nil, modeBar)
    b:SetSize(28, 28); b:SetPoint("TOP", modeBar, "TOP", 0, yOff)
    b:SetNormalTexture(icon)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b.sel = b:CreateTexture(nil, "OVERLAY"); b.sel:SetAllPoints(); b.sel:SetColorTexture(1, 0.82, 0, 0.30); b.sel:Hide()
    b:SetAttribute("nodeignore", true) -- só mouse; não interfere na navegação por controle da grade
    b:SetScript("OnClick", function()
      DB.settings.gridView = isGrid
      UpdateModeBar(); Refresh()
    end)
    b:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText(tipText); GameTooltip:Show() end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
  end
  modeBar.catsBtn = makeModeBtn(-4, false, "Interface\\ICONS\\INV_Misc_Note_02", L.MODE_CATEGORIES)
  modeBar.gridBtn = makeModeBtn(-36, true, "Interface\\ICONS\\INV_Misc_Gem_Variety_01", L.MODE_GRID)
  UpdateModeBar()

  -- botão "Vender lixo" (só aparece no vendedor, modo Mochila); API nativa, sem taint
  local sellJunk = CreateFrame("Button", nil, UI, "UIPanelButtonTemplate")
  sellJunk:SetSize(86, 20)
  sellJunk:SetPoint("RIGHT", sortBtn, "LEFT", -6, 0)
  sellJunk:SetText(L.BTN_SELL_JUNK)
  sellJunk:SetScript("OnClick", function()
    if InCombatLockdown() then return end
    -- varredura própria que respeita a proteção (favoritos/Conjunto/categoria) em vez de
    -- C_MerchantFrame.SellAllJunkItems, que venderia até cinza favoritado/protegido.
    SellJunkItems()
  end)
  sellJunk:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(L.TIP_SELLJUNK_TITLE)
    GameTooltip:AddLine(L.TIP_SELLJUNK_BODY, 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
  end)
  sellJunk:SetScript("OnLeave", function() GameTooltip:Hide() end)
  UI.sellJunkBtn = sellJunk; sellJunk:Hide()

  -- botão "Transferir" (só com busca ativa, no vendedor ou no banco): vende/deposita o que bate.
  -- Botão de ÍCONE contextual: moeda no vendedor (vende), bolsa no banco (deposita). O ícone e o
  -- tooltip mudam conforme o contexto — atualizados em UpdateTabs (ícone) e no OnEnter (tooltip).
  local transferBtn = CreateFrame("Button", nil, UI)
  transferBtn:SetSize(24, 24)
  transferBtn:SetPoint("RIGHT", sellJunk, "LEFT", -6, 0)
  transferBtn:SetNormalTexture("Interface\\ICONS\\INV_Misc_Coin_01") -- ícone inicial; UpdateTabs troca conforme o contexto
  transferBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  transferBtn:SetAttribute("nodeignore", true) -- linha do cabeçalho; só mouse, fora da navegação por controle
  transferBtn:SetScript("OnClick", TransferBySearch)
  transferBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    if MerchantFrame and MerchantFrame:IsShown() then
      GameTooltip:SetText(L.TIP_TRANSFER_SELL_TITLE)
      GameTooltip:AddLine(L.TIP_TRANSFER_SELL_BODY, 0.8, 0.8, 0.8, true)
    else
      GameTooltip:SetText(L.TIP_TRANSFER_DEPOSIT_TITLE)
      GameTooltip:AddLine(L.TIP_TRANSFER_DEPOSIT_BODY, 0.8, 0.8, 0.8, true)
    end
    GameTooltip:Show()
  end)
  transferBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
  UI.transferBtn = transferBtn; transferBtn:Hide()

  goldText = UI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  goldText:SetPoint("BOTTOMRIGHT", UI, "BOTTOMRIGHT", blizzard and -24 or -20, blizzard and 12 or 7) -- folga p/ a alça

  currencyText = UI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  currencyText:SetJustifyH("LEFT")
  currencyText:SetPoint("BOTTOMLEFT", UI, "BOTTOMLEFT", blizzard and 12 or 8, blizzard and 12 or 7)
  currencyText:SetPoint("RIGHT", goldText, "LEFT", -10, 0)

  -- frame invisível por cima do ouro: hover abre o painel de ouro por personagem (+ Brigada).
  -- nodeignore tira da navegação por controle; só mouse.
  UI.goldHover = CreateFrame("Frame", nil, UI)
  UI.goldHover:SetAttribute("nodeignore", true)
  UI.goldHover:EnableMouse(true)
  UI.goldHover:SetAllPoints(goldText)
  UI.goldHover:SetScript("OnEnter", function(self)
    if not (DB and DB.settings and DB.settings.altCounts) then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(L.GOLD_PANEL_TITLE)
    local meKey = CharKey()
    local total = 0
    local function addGold(nm, classToken, amount)
      if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
        local col = RAID_CLASS_COLORS[classToken]
        nm = string.format("|cff%02x%02x%02x%s|r", col.r * 255, col.g * 255, col.b * 255, nm)
      end
      GameTooltip:AddDoubleLine(nm, GetCoinTextureString(amount), 1, 1, 1, 1, 1, 1)
      total = total + amount
    end
    -- char atual SEMPRE aparece, com ouro ao vivo (mesmo antes da 1ª captura)
    local me = DB.charItems[meKey]
    addGold((me and me.name) or meKey, me and me.class, GetMoney())
    -- demais personagens (ouro salvo no logout)
    for k, data in pairs(DB.charItems) do
      if k ~= meKey and type(data) == "table" and data.gold then
        addGold(data.name or k, data.class, data.gold)
      end
    end
    -- Brigada (warband): defensivo — só mostra se a API existir e devolver um número > 0
    local wb
    if C_Bank and C_Bank.FetchDepositedMoney and Enum and Enum.BankType then
      local ok, amount = pcall(C_Bank.FetchDepositedMoney, Enum.BankType.Account)
      if ok and type(amount) == "number" then wb = amount end
    end
    if wb and wb > 0 then
      GameTooltip:AddDoubleLine("|cff00ccff" .. L.GOLD_WARBAND .. "|r", GetCoinTextureString(wb), 1, 1, 1, 1, 1, 1)
      total = total + wb
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(L.GOLD_TOTAL, GetCoinTextureString(total), 1, 0.85, 0, 1, 1, 1)
    GameTooltip:Show()
  end)
  UI.goldHover:SetScript("OnLeave", function() GameTooltip:Hide() end)

  -- seção "Vazio": 2 slots grandes (geral + reagentes). A troca de modo é pela
  -- barra lateral de visualização (modeBar); /kb grade alterna direto.

  -- área rolável: o conteúdo (categorias + itens + "Vazio") vai num ScrollFrame com
  -- altura limitada; cabeçalho e rodapé ficam fixos. O ScrollFrame recorta o clique
  -- dos itens fora da área visível (essencial pro banco gigante).
  UI.scroll = CreateFrame("ScrollFrame", nil, UI)
  UI.content = CreateFrame("Frame", nil, UI.scroll)
  UI.content:SetSize(10, 10)
  UI.scroll:SetScrollChild(UI.content)
  UI.scroll:EnableMouseWheel(true)
  local sbar = CreateFrame("Slider", nil, UI)
  sbar:SetOrientation("VERTICAL"); sbar:SetWidth(12)
  sbar:SetPoint("TOPLEFT", UI.scroll, "TOPRIGHT", 3, 0)
  sbar:SetPoint("BOTTOMLEFT", UI.scroll, "BOTTOMRIGHT", 3, 0)
  sbar.track = sbar:CreateTexture(nil, "BACKGROUND"); sbar.track:SetAllPoints(); sbar.track:SetColorTexture(0, 0, 0, 0.35)
  sbar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
  local thumb = sbar:GetThumbTexture(); if thumb then thumb:SetSize(12, 28) end
  sbar:SetMinMaxValues(0, 0); sbar:SetValue(0); sbar:SetValueStep(1); sbar:SetObeyStepOnDrag(true)
  sbar:SetScript("OnValueChanged", function(_, v) UI.scroll:SetVerticalScroll(v) end)
  sbar:SetAttribute("nodeignore", true) -- o controle rola sozinho (auto-scroll do ConsolePort); a barra não é alvo de navegação
  sbar:Hide()
  UI.sb = sbar
  UI.scroll:SetScript("OnMouseWheel", function(_, delta)
    local _, maxv = UI.sb:GetMinMaxValues()
    if (maxv or 0) <= 0 then return end
    local nv = math.max(0, math.min(maxv, (UI.sb:GetValue() or 0) - delta * (BTN + PAD)))
    UI.sb:SetValue(nv)
  end)

  emptyHeader = UI.content:CreateFontString(nil, "OVERLAY", "GameFontNormal"); emptyHeader:Hide()
  -- banner de visualização do banco em cache (mostrado no topo do conteúdo quando consultando de longe)
  UI.cacheBanner = UI.content:CreateFontString(nil, "OVERLAY", "GameFontNormal"); UI.cacheBanner:SetJustifyH("LEFT"); UI.cacheBanner:Hide()

  freeBox = CreateFrame("Button", nil, UI.content)
  freeBox.bg = freeBox:CreateTexture(nil, "BACKGROUND"); freeBox.bg:SetAllPoints(); freeBox.bg:SetAtlas("bags-item-slot64")
  freeBox.border = freeBox:CreateTexture(nil, "ARTWORK"); freeBox.border:SetAllPoints(); freeBox.border:SetTexture("Interface\\Common\\WhiteIconFrame"); freeBox.border:SetVertexColor(0.4, 0.4, 0.45, 0.7)
  freeNum = freeBox:CreateFontString(nil, "OVERLAY", "NumberFontNormal"); freeNum:SetPoint("BOTTOMRIGHT", -2, 2)
  freeBox:Hide()

  reagentBox = CreateFrame("Button", nil, UI.content)
  reagentBox.bg = reagentBox:CreateTexture(nil, "BACKGROUND"); reagentBox.bg:SetAllPoints(); reagentBox.bg:SetAtlas("bags-item-slot64")
  reagentBox.border = reagentBox:CreateTexture(nil, "ARTWORK"); reagentBox.border:SetAllPoints(); reagentBox.border:SetTexture("Interface\\Common\\WhiteIconFrame"); reagentBox.border:SetVertexColor(0.4, 0.4, 0.45, 0.7)
  reagentNum = reagentBox:CreateFontString(nil, "OVERLAY", "NumberFontNormal"); reagentNum:SetPoint("BOTTOMRIGHT", -2, 2)
  reagentBox:Hide()

  -- abas Mochila/Banco/Brigada (aparecem só com o banco aberto) + depositar automático
  local tabBar = CreateFrame("Frame", nil, UI)
  tabBar:SetSize(10, 20)
  tabBar:SetPoint("TOPLEFT", UI, "TOPLEFT", UI.kbMargin, -(UI.kbTop - 2))
  UI.tabBar = tabBar; UI.tabs = {}
  local tdefs = {
    { id = "bags",    t = L.TAB_BAGS,    icon = "Interface\\Icons\\INV_Misc_Bag_08" },
    { id = "bank",    t = L.TAB_BANK,    icon = "Interface\\Icons\\Achievement_GuildPerk_MobileBanking" },
    { id = "warband", t = L.TAB_WARBAND, icon = "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend" },
  }
  local tx = 0
  for _, d in ipairs(tdefs) do
    local tb = CreateFrame("Button", nil, tabBar)
    tb:SetSize(24, 24); tb:SetPoint("LEFT", tx, 0); tx = tx + 28
    tb:SetNormalTexture(d.icon)
    tb:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    tb.sel = tb:CreateTexture(nil, "OVERLAY")
    tb.sel:SetAllPoints()
    tb.sel:SetColorTexture(1, 0.82, 0, 0.30)
    tb.sel:Hide()
    tb.mode = d.id
    tb:SetScript("OnClick", function() mode = tb.mode; UpdateTabs(); Refresh() end)
    tb:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(d.t); GameTooltip:Show() end)
    tb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    UI.tabs[d.id] = tb
  end
  local dep = CreateFrame("Button", nil, tabBar, "UIPanelButtonTemplate")
  dep:SetSize(120, 18); dep:SetText(L.BTN_DEPOSIT); dep:SetPoint("LEFT", tx + 8, 0)
  dep:SetScript("OnClick", function()
    if InCombatLockdown() then return end
    local bt = (mode == "warband") and BANK_ACCT or BANK_CHAR
    if C_Bank and C_Bank.AutoDepositItemsIntoBank then pcall(C_Bank.AutoDepositItemsIntoBank, bt) end
  end)
  dep:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(L.TIP_DEPOSIT)
    GameTooltip:Show()
  end)
  dep:SetScript("OnLeave", function() GameTooltip:Hide() end)
  UI.depositBtn = dep
  tabBar:Hide()

  -- tutorial em COACH-MARKS NÃO-MODAIS no botão "i": espalha marcadores "i" pelos controles.
  -- Com o tutorial aberto, todo alvo válido ganha uma borda dourada suave (mostra a que cada "i" se refere).
  -- Passar o mouse num marcador reforça a borda daquele controle e abre um balão com a dica.
  -- Sem escurecer a tela e sem capturar o mouse: a bag segue 100% usável com os marcadores ligados.
  local tour = CreateFrame("Frame", "KrononBagsTour", UIParent)
  tour:SetFrameStrata("FULLSCREEN_DIALOG")
  tour:SetAllPoints(UIParent)
  tour:SetAttribute("nodeignore", true) -- overlay: fora da navegação por controle
  tour:Hide()
  UI.tour = tour
  tour.markers = {}
  tour.glows = {}        -- pool de bordas douradas (uma por alvo válido); por baixo dos marcadores
  tour.activeGlow = nil  -- glow reforçado sob o mouse (volta ao tom suave no OnLeave)

  -- balão da dica (estilo Blizzard): fundo escuro, borda dourada e uma setinha apontando pro controle
  local box = CreateFrame("Frame", nil, tour, "BackdropTemplate")
  box:SetSize(300, 110); box:SetFrameStrata("TOOLTIP"); box:SetClampedToScreen(true)
  if box.SetBackdrop then
    box:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    box:SetBackdropColor(0, 0, 0, 0.95)
    box:SetBackdropBorderColor(1, 0.82, 0) -- borda dourada (destaque do tutorial)
  end
  tour.box = box
  box.title = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  box.title:SetPoint("TOPLEFT", 14, -12); box.title:SetWidth(272); box.title:SetJustifyH("LEFT")
  box.title:SetTextColor(1, 0.82, 0)
  box.body = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  box.body:SetPoint("TOPLEFT", box.title, "BOTTOMLEFT", 0, -6); box.body:SetWidth(272)
  box.body:SetJustifyH("LEFT"); box.body:SetJustifyV("TOP"); box.body:SetSpacing(2)
  -- setinha apontando do balão pro controle (SWAPPÁVEL: troque textura/rotação aqui; ex.: um triângulo próprio)
  box.arrow = box:CreateTexture(nil, "OVERLAY")
  box.arrow:SetTexture("Interface\\Tooltips\\ChatBubble-Tail")
  box.arrow:SetSize(20, 20); box.arrow:SetVertexColor(1, 0.82, 0); box.arrow:Hide()
  box:Hide()

  -- passos = fonte dos marcadores (alvos lidos lazy: os UI.* já existem quando a bag abre)
  local steps = {
    { getTarget = function() return sb end,           title = L.TUT_SEARCH_TITLE,     body = L.TUT_SEARCH_BODY },
    { getTarget = function() return UI.filterBtn end, title = L.TUT_FILTER_TITLE,     body = L.TUT_FILTER_BODY },
    { getTarget = function() return sortBtn end,      title = L.TUT_SORT_TITLE,       body = L.TUT_SORT_BODY },
    { getTarget = function() return UI.modeBar end,   title = L.TUT_MODES_TITLE,      body = L.TUT_MODES_BODY },
    { getTarget = function() return UI.tabBar end,    title = L.TUT_TABS_TITLE,       body = L.TUT_TABS_BODY },
    { getTarget = function() return UI.histBtn end,   title = L.TUT_HISTORY_TITLE,    body = L.TUT_HISTORY_BODY },
    { getTarget = function() return help end,         title = L.TUT_HELP_TITLE,       body = L.TUT_HELP_BODY },
    { getTarget = function() return UI.content end,   title = L.TUT_CATEGORIES_TITLE, body = L.TUT_CATEGORIES_BODY },
    { getTarget = function() return goldText end,     title = L.TUT_FOOTER_TITLE,     body = L.TUT_FOOTER_BODY },
  }
  tour.steps = steps

  local function stepValid(s)
    if not s or not s.getTarget then return false end
    local t = s.getTarget()
    return (t and t.IsShown and t:IsShown() and t.GetWidth and (t:GetWidth() or 0) > 0) and true or false
  end
  -- o conteúdo é gigante e rola: usa a área VISÍVEL (scroll) como alvo de glow/âncora
  local function glowTargetOf(target)
    return (target == UI.content and UI.scroll) or target
  end
  local function positionBox(target)
    box:ClearAllPoints(); box.arrow:ClearAllPoints(); box.arrow:Hide()
    if not target then box:SetPoint("CENTER", UIParent, "CENTER", 0, 0); return end
    local cx = target:GetCenter()
    local sw = UIParent:GetWidth() or 1024
    box.arrow:Show()
    if cx and cx < sw * 0.6 then
      box:SetPoint("LEFT", target, "RIGHT", 18, 0)         -- balão à direita do alvo
      box.arrow:SetPoint("CENTER", box, "LEFT", 1, 0)
      box.arrow:SetRotation(math.rad(-90))                  -- seta aponta pra ESQUERDA (troque o sinal se mudar a textura)
    else
      box:SetPoint("RIGHT", target, "LEFT", -18, 0)        -- balão à esquerda do alvo
      box.arrow:SetPoint("CENTER", box, "RIGHT", -1, 0)
      box.arrow:SetRotation(math.rad(90))                   -- seta aponta pra DIREITA
    end
  end
  local function hideTip()
    -- volta o glow reforçado ao tom suave (os demais continuam visíveis) e fecha o balão
    if tour.activeGlow then
      tour.activeGlow:SetVertexColor(1, 0.82, 0); tour.activeGlow:SetAlpha(0.30)
      tour.activeGlow = nil
    end
    box:Hide()
  end
  local function showTip(stepIndex, marker)
    local step = steps[stepIndex]
    if not step then return end
    local target = step.getTarget()
    if not target then return end
    local gt = glowTargetOf(target)
    -- reforça a borda DESTE alvo (mais viva); as outras seguem no tom suave
    if marker and marker.glow then
      tour.activeGlow = marker.glow
      marker.glow:SetVertexColor(1, 0.92, 0.4); marker.glow:SetAlpha(1)
    end
    box.title:SetText(step.title or "")
    box.body:SetText(step.body or "")
    local bodyH = math.max(28, box.body:GetStringHeight() or 28)
    box:SetHeight(44 + bodyH)
    positionBox(gt)
    box:Show()
  end
  -- pool de marcadores "i" (botões só-mouse), um por passo válido; reusados a cada toggle (sem ghost)
  local function getMarker(i)
    local m = tour.markers[i]
    if not m then
      m = CreateFrame("Button", nil, tour)
      m:SetSize(18, 18); m:SetFrameStrata("FULLSCREEN_DIALOG")
      m:SetAttribute("nodeignore", true) -- marcador: só mouse, fora da navegação por controle
      m:SetNormalTexture("Interface\\Common\\help-i")   -- "i" dourado (SWAPPÁVEL: troque a textura aqui)
      m:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
      m:SetScript("OnEnter", function(self) showTip(self.stepIndex, self) end)
      m:SetScript("OnLeave", function() hideTip() end)
      tour.markers[i] = m
    end
    return m
  end
  -- pool de glows: borda dourada por alvo, criada lazy (igual ao getMarker), por baixo dos marcadores
  local function getGlow(i)
    local g = tour.glows[i]
    if not g then
      g = tour:CreateTexture(nil, "ARTWORK")
      g:SetTexture("Interface\\Buttons\\ButtonHilight-Square"); g:SetBlendMode("ADD")
      g:SetVertexColor(1, 0.82, 0); g:Hide()
      tour.glows[i] = g
    end
    return g
  end
  local function layoutMarkers()
    local n = 0
    for idx, s in ipairs(steps) do
      if stepValid(s) then
        n = n + 1
        local gt = glowTargetOf(s.getTarget())
        local m = getMarker(n)
        m.stepIndex = idx
        m:ClearAllPoints()
        m:SetPoint("CENTER", gt, "TOPRIGHT", 0, 0) -- "i" no canto sup. direito do controle
        m:Show()
        -- borda suave SEMPRE visível com o tutorial aberto (mostra a que cada "i" se refere)
        local g = getGlow(n)
        g:ClearAllPoints()
        g:SetPoint("TOPLEFT", gt, "TOPLEFT", -4, 4)
        g:SetPoint("BOTTOMRIGHT", gt, "BOTTOMRIGHT", 4, -4)
        g:SetVertexColor(1, 0.82, 0); g:SetAlpha(0.30); g:Show()
        m.glow = g -- o hover usa esta referência pra reforçar só este alvo
      end
    end
    for k = n + 1, #tour.markers do tour.markers[k]:Hide() end -- esconde sobras (pool sem ghost)
    for k = n + 1, #tour.glows do tour.glows[k]:Hide() end     -- glows sobrando: escondidos (sem ghost)
  end
  local function setHelpShown(on)
    hideTip()
    if on then
      layoutMarkers(); tour:Show()   -- mostra marcadores + bordas suaves; reforço/balão só no hover
    else
      tour:Hide()                    -- esconde marcadores + todos os glows + balão (filhos do overlay)
    end
  end
  UI.ToggleHelp = function() setHelpShown(not tour:IsShown()) end
  UI.ShowTour = UI.ToggleHelp -- compat: chamadas antigas agora só alternam os coach-marks
  tinsert(UISpecialFrames, "KrononBagsTour") -- ESC esconde os marcadores

  -- alça de redimensionar (canto inferior direito): arraste pra mudar quantas colunas cabem.
  -- Ao soltar, calcula as colunas pela largura e re-renderiza (que reajusta a janela).
  UI:SetResizable(true)
  local function kbColsForWidth(w)
    local M = UI.kbMargin or MARGIN
    local n = math.floor((w - M * 2 - SBW + PAD) / (BTN + PAD) + 0.5)
    return math.max(COLS_MIN, math.min(COLS_MAX, n))
  end
  do
    local M = UI.kbMargin or MARGIN
    local minW = COLS_MIN * (BTN + PAD) - PAD + M * 2 + SBW
    local maxW = COLS_MAX * (BTN + PAD) - PAD + M * 2 + SBW
    if UI.SetResizeBounds then UI:SetResizeBounds(minW, 160, maxW, 1400)
    else
      if UI.SetMinResize then UI:SetMinResize(minW, 160) end
      if UI.SetMaxResize then UI:SetMaxResize(maxW, 1400) end
    end
  end
  local grip = CreateFrame("Button", nil, UI)
  grip:SetSize(16, 16); grip:SetPoint("BOTTOMRIGHT", -3, 3)
  grip:SetFrameLevel(UI:GetFrameLevel() + 10)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  grip:SetScript("OnMouseDown", function() UI:StartSizing("BOTTOMRIGHT") end)
  grip:SetScript("OnMouseUp", function()
    UI:StopMovingOrSizing()
    DB.settings.cols = kbColsForWidth(UI:GetWidth())
    local TOP = (UI.kbTop or 34) + ((atBank or HasCharBankSnap() or HasWarbandSnap()) and 22 or 0)
    local BOT = UI.kbBottom or (MARGIN + 22)
    DB.settings.maxHeight = math.max(120, math.floor(UI:GetHeight() - TOP - BOT)) -- altura visível arrastada
    Refresh() -- recalcula largura/altura/scroll pro novo tamanho
  end)
  grip:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText(L.TIP_GRIP); GameTooltip:Show()
  end)
  grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
  UI.grip = grip

  -- ESC fecha a janela (igual à bag do jogo)
  tinsert(UISpecialFrames, "KrononBagsFrame")

  -- Navegação por controle (ConsolePort): registra a janela no cursor de interface
  -- pra ele varrer/navegar nossos itens e fazer auto-scroll do conteúdo. O cursor
  -- dele é geométrico (vizinho mais próximo na direção), então o que faz a navegação
  -- seguir a ordem é a grade limpa de itens — por isso tiramos a estrela e a barra
  -- de rolagem do scan (nodeignore). Sem ConsolePort, isto é só um no-op.
  if ConsolePort and ConsolePort.AddInterfaceCursorFrame then
    pcall(function() ConsolePort:AddInterfaceCursorFrame(UI) end)
  end

  -- ao esconder (X, /kb ou auto), zera a flag de auto-aberta pra não fechar janela manual
  UI:HookScript("OnHide", function(self) self.autoOpened = false; if UI.tour then UI.tour:Hide() end end)

  -- restaura a posição salva deste personagem (se houver)
  local sp = DB.charPos and DB.charPos[CharKey()]
  if sp and sp[1] then
    UI:ClearAllPoints()
    UI:SetPoint(sp[1], UIParent, sp[2] or sp[1], sp[3] or 0, sp[4] or 0)
  end

  -- ====== Histórico de entradas/saídas: painel flutuante + botão de relógio ======
  -- O rastreio roda sempre (BAG_UPDATE_DELAYED → HistorySnapshotDiff); o painel é só
  -- exibição. Lista os primeiros eventos de kbHistory (mais novos primeiro): +N entrou,
  -- −N saiu, com o horário.
  local histPanel = CreateFrame("Frame", "KrononBagsHistory", UIParent, "BackdropTemplate")
  histPanel:SetSize(300, 432)
  histPanel:SetPoint("CENTER")
  histPanel:SetFrameStrata("DIALOG")
  histPanel:SetMovable(true); histPanel:EnableMouse(true); histPanel:RegisterForDrag("LeftButton")
  histPanel:SetScript("OnDragStart", histPanel.StartMoving)
  histPanel:SetScript("OnDragStop", histPanel.StopMovingOrSizing)
  histPanel:SetAttribute("nodeignore", true) -- fora da navegação por controle; só mouse
  if histPanel.SetBackdrop then
    histPanel:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    histPanel:SetBackdropColor(0, 0, 0, 0.95)
  end
  local histTitle = histPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  histTitle:SetPoint("TOP", 0, -12); histTitle:SetText("|cfff0d98c" .. L.HIST_TITLE .. "|r")
  local histClose = CreateFrame("Button", nil, histPanel, "UIPanelCloseButton")
  histClose:SetPoint("TOPRIGHT", 2, 2)
  local histEmpty = histPanel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  histEmpty:SetPoint("CENTER", 0, 0); histEmpty:SetText(L.HIST_EMPTY); histEmpty:Hide()
  histPanel:Hide()
  UI.histPanel = histPanel
  tinsert(UISpecialFrames, "KrononBagsHistory") -- ESC fecha

  -- rodapé com a dica de shift-clique (deixa o painel menos "pobre" e ensina o atalho)
  local histHint = histPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  histHint:SetPoint("BOTTOM", 0, 10); histHint:SetText(L.HIST_HINT)

  -- pool de linhas: ícone (18, com borda de qualidade) + nome colorido + delta/hora.
  -- Cada linha tem mouse: hover mostra tooltip e realce; shift-clique linka no chat. Sem ghost.
  local histRowPool = {}
  local HIST_ROWS = 18
  local function AcquireHistRow(i)
    local row = histRowPool[i]
    if not row then
      row = CreateFrame("Button", nil, histPanel) -- Button: precisa de OnClick/RegisterForClicks
      row:SetSize(272, 19)
      if i == 1 then
        row:SetPoint("TOPLEFT", histPanel, "TOPLEFT", 14, -44)
      else
        row:SetPoint("TOPLEFT", histRowPool[i - 1], "BOTTOMLEFT", 0, -1)
      end
      row:SetAttribute("nodeignore", true) -- fora da navegação por controle; só mouse
      row:EnableMouse(true)
      row:RegisterForClicks("AnyUp")
      -- realce sutil de hover
      row.hl = row:CreateTexture(nil, "BACKGROUND")
      row.hl:SetAllPoints(row)
      row.hl:SetColorTexture(1, 1, 1, 0.08)
      row.hl:Hide()
      row.icon = row:CreateTexture(nil, "ARTWORK")
      row.icon:SetSize(18, 18); row.icon:SetPoint("LEFT", 0, 0)
      -- borda de qualidade ao redor do ícone (cor definida no render conforme o link)
      row.border = row:CreateTexture(nil, "OVERLAY")
      row.border:SetTexture("Interface\\Common\\WhiteIconFrame")
      row.border:SetPoint("CENTER", row.icon, "CENTER", 0, 0)
      row.border:SetSize(20, 20)
      row.border:Hide()
      row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0); row.name:SetJustifyH("LEFT")
      row.info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      row.info:SetPoint("RIGHT", row, "RIGHT", 0, 0); row.info:SetJustifyH("RIGHT")
      row.name:SetPoint("RIGHT", row.info, "LEFT", -4, 0) -- nome não invade o delta/hora
      row:SetScript("OnEnter", function(self)
        local ev = self.ev
        if not ev then return end
        self.hl:Show()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if ev.link then GameTooltip:SetHyperlink(ev.link)
        else GameTooltip:SetItemByID(ev.id) end
        GameTooltip:Show()
      end)
      row:SetScript("OnLeave", function(self)
        self.hl:Hide()
        GameTooltip:Hide()
      end)
      row:SetScript("OnClick", function(self)
        local ev = self.ev
        if ev and ev.link and IsShiftKeyDown() then
          HandleModifiedItemClick(ev.link)
        end
      end)
      histRowPool[i] = row
    end
    return row
  end

  RenderHistory = function()
    if not UI or not UI.histPanel then return end
    local n = #kbHistory
    if n == 0 then
      for _, row in ipairs(histRowPool) do row.ev = nil; row:Hide() end
      histEmpty:Show()
      return
    end
    histEmpty:Hide()
    local shown = math.min(n, HIST_ROWS)
    for i = 1, shown do
      local ev = kbHistory[i]
      local row = AcquireHistRow(i)
      row.ev = ev
      local iconID = select(5, C_Item.GetItemInfoInstant(ev.id))
      row.icon:SetTexture(iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
      -- nome: o link já vem colorido por qualidade; sem link, cai no nome simples
      if ev.link then row.name:SetText(ev.link)
      else row.name:SetText(C_Item.GetItemInfo(ev.id) or "...") end
      -- borda de qualidade no ícone (só quando há link com qualidade conhecida)
      local q = ev.link and select(3, C_Item.GetItemInfo(ev.link))
      local c = q and q >= 0 and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
      if c then row.border:SetVertexColor(c.r, c.g, c.b); row.border:Show()
      else row.border:Hide() end
      local deltaStr
      if ev.delta > 0 then deltaStr = "|cff33ff33+" .. ev.delta .. "|r"
      else deltaStr = "|cffff5555" .. ev.delta .. "|r" end
      local hora = ""
      if date and ev.t and ev.t > 0 then
        local ok, s = pcall(date, "%H:%M", ev.t)
        if ok and s then hora = s end
      end
      row.info:SetText(deltaStr .. "  " .. hora)
      row.hl:Hide()
      row:Show()
    end
    for i = shown + 1, #histRowPool do histRowPool[i].ev = nil; histRowPool[i]:Hide() end -- esconde sobras (sem ghost)
  end

  -- botão de relógio: alterna o painel. À esquerda, perto do título (longe da fileira cheia).
  local histBtn = CreateFrame("Button", nil, UI)
  histBtn:SetSize(20, 20)
  histBtn:SetPoint("TOPLEFT", UI, "TOPLEFT", clockX, clockY)
  histBtn:SetAttribute("nodeignore", true) -- só mouse
  histBtn:SetNormalTexture("Interface\\ICONS\\INV_Misc_PocketWatch_01")
  histBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  histBtn:SetScript("OnClick", function()
    if histPanel:IsShown() then histPanel:Hide()
    else RenderHistory(); histPanel:Show() end
  end)
  histBtn:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_BOTTOM"); GameTooltip:SetText(L.HIST_BTN); GameTooltip:Show() end)
  histBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
  UI.histBtn = histBtn

  ApplyOpacity()
  UI:Hide()
end

Toggle = function()
  if not UI then CreateUI() end
  if UI:IsShown() then UI:Hide() else UI:Show(); Refresh() end
end

-- ---------------- Configurações (extensível) ----------------
local catRows = {}
-- A lista de categorias agora vive num ScrollFrame dentro da aba "Categorias" (CFG.catChild).
-- As linhas ancoram no topo do scroll child; a altura do child cresce com a lista (rola sozinha),
-- nunca mais a altura da janela de configuração.
RefreshConfigCats = function()
  if not CFG or not CFG.catChild then return end
  for _, r in ipairs(catRows) do r:Hide() end
  local parent = CFG.catChild
  local y = -2
  local n = #DB.catList
  for i, c in ipairs(DB.catList) do
    local r = catRows[i]
    if not r then
      r = CreateFrame("Frame", nil, parent)
      r:SetSize(268, 20)
      r.up = CreateFrame("Button", nil, r)
      r.up:SetSize(18, 18); r.up:SetPoint("LEFT", 2, 0)
      r.up:SetNormalTexture("Interface\\Buttons\\Arrow-Up-Up")
      r.up:SetPushedTexture("Interface\\Buttons\\Arrow-Up-Down")
      r.up:SetHighlightTexture("Interface\\Buttons\\Arrow-Up-Up", "ADD")
      r.down = CreateFrame("Button", nil, r)
      r.down:SetSize(18, 18); r.down:SetPoint("LEFT", r.up, "RIGHT", 2, 0)
      r.down:SetNormalTexture("Interface\\Buttons\\Arrow-Down-Up")
      r.down:SetPushedTexture("Interface\\Buttons\\Arrow-Down-Down")
      r.down:SetHighlightTexture("Interface\\Buttons\\Arrow-Down-Up", "ADD")
      r.label = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      r.label:SetPoint("LEFT", r.down, "RIGHT", 6, 0)
      r.del = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
      r.del:SetSize(48, 18); r.del:SetText(L.BTN_DELETE); r.del:SetPoint("RIGHT", -2, 0)
      r.rule = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
      r.rule:SetSize(46, 18); r.rule:SetText(L.BTN_RULE); r.rule:SetPoint("RIGHT", r.del, "LEFT", -3, 0)
      r.label:SetPoint("RIGHT", r.rule, "LEFT", -4, 0); r.label:SetJustifyH("LEFT")
      catRows[i] = r
    end
    local tag
    if c.filter then tag = "|cff80c0ff" .. L.TAG_PRESET .. "|r"
    elseif c.rule and c.rule ~= "" then tag = "|cffffd000" .. L.TAG_RULE .. "|r"
    else tag = "|cff80ff80" .. L.TAG_CUSTOM .. "|r" end
    r.label:SetText(CatDisplay(c.name) .. "  " .. tag)
    r.up:SetEnabled(i > 1);  r.up:SetAlpha(i > 1 and 1 or 0.3)
    r.down:SetEnabled(i < n); r.down:SetAlpha(i < n and 1 or 0.3)
    r.up:SetScript("OnClick", function() MoveCategory(i, -1); RefreshConfigCats(); Refresh() end)
    r.down:SetScript("OnClick", function() MoveCategory(i, 1); RefreshConfigCats(); Refresh() end)
    r.del:SetScript("OnClick", function() DeleteCategory(c); RefreshConfigCats(); Refresh() end)
    -- "Regra" só pras categorias suas (custom): define uma busca que preenche a categoria sozinha
    if c.filter == nil then
      r.rule:Show()
      r.rule:SetScript("OnClick", function() KB_ruleTargetEntry = c; StaticPopup_Show("KRONONBAGS_RULE") end)
    else
      r.rule:Hide()
    end
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, y); r:Show()
    y = y - 22
  end
  -- altura do scroll child = tamanho da lista (a barra de rolagem cuida do overflow)
  parent:SetHeight(math.max(1, -y + 2))
end

CreateConfig = function()
  CFG = CreateFrame("Frame", "KrononBagsConfig", UIParent, "BackdropTemplate")
  -- altura FIXA: cabe folgado em telas de 768px; a aba mais cheia das curtas (Comportamento)
  -- entra sem rolar e a aba Categorias rola por dentro. Sem mais altura dinâmica.
  CFG:SetSize(440, 430)
  CFG:SetPoint("CENTER")
  CFG:SetFrameStrata("DIALOG")
  CFG:SetMovable(true); CFG:EnableMouse(true); CFG:RegisterForDrag("LeftButton")
  CFG:SetScript("OnDragStart", CFG.StartMoving)
  CFG:SetScript("OnDragStop", CFG.StopMovingOrSizing)
  if CFG.SetBackdrop then
    CFG:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    CFG:SetBackdropColor(0, 0, 0, 0.95)
  end

  local clogo = CFG:CreateTexture(nil, "ARTWORK")
  clogo:SetSize(30, 30); clogo:SetPoint("TOPLEFT", 10, -8)
  clogo:SetTexture("Interface\\AddOns\\KrononBags\\Media\\KrononLogo.tga")

  local title = CFG:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -12); title:SetText("|cfff0d98c" .. L.CONFIG_TITLE .. "|r")

  local close = CreateFrame("Button", nil, CFG, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 2)

  -- versão lida do .toc automaticamente (usada nos créditos da aba "Sobre")
  local ver = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")) or ""

  -- linha divisória vertical entre a sidebar de abas e a área de conteúdo
  local vdiv = CFG:CreateTexture(nil, "ARTWORK")
  vdiv:SetColorTexture(0.4, 0.4, 0.45, 0.4); vdiv:SetWidth(1)
  vdiv:SetPoint("TOPLEFT", 116, -44); vdiv:SetPoint("BOTTOMLEFT", 116, 14)

  -- ===== Abas: sidebar (esquerda) + painéis de conteúdo (direita) =====
  CFG.panels = {}      -- [chave] = frame-painel
  CFG.tabButtons = {}  -- [chave] = botão da sidebar

  -- mostra o painel da aba pedida, esconde os outros e destaca o botão ativo
  local function ShowConfigTab(key)
    for k, p in pairs(CFG.panels) do p:SetShown(k == key) end
    for k, b in pairs(CFG.tabButtons) do
      local fs = b:GetFontString()
      if k == key then
        b:LockHighlight()
        if fs then fs:SetTextColor(1, 0.82, 0) end
      else
        b:UnlockHighlight()
        if fs then fs:SetTextColor(1, 1, 1) end
      end
    end
    CFG.activeTab = key
  end
  CFG.ShowTab = ShowConfigTab

  -- cria um painel de conteúdo (altura fixa, à direita da sidebar)
  local function makePanel(key)
    local p = CreateFrame("Frame", nil, CFG)
    p:SetPoint("TOPLEFT", 120, -44)
    p:SetPoint("BOTTOMRIGHT", -10, 14)
    p:Hide()
    CFG.panels[key] = p
    return p
  end
  -- título + linha no topo de cada painel (reaproveita o rótulo da aba)
  local function panelTitle(p, text)
    local h = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetPoint("TOPLEFT", 4, -4); h:SetText("|cfff0d98c" .. text .. "|r")
    local d = p:CreateTexture(nil, "ARTWORK")
    d:SetColorTexture(0.4, 0.4, 0.45, 0.5); d:SetHeight(1)
    d:SetPoint("TOPLEFT", 0, -22); d:SetPoint("TOPRIGHT", 0, -22)
  end
  -- checkbox: agora recebe o PARENT (o painel da aba); offsets relativos ao topo do painel
  local function check(parent, name, x, y, label, getf, setf, tipKey)
    local c = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    c:SetPoint("TOPLEFT", x, y)
    local lbl = c.Text or _G[name .. "Text"]
    if lbl then lbl:SetText(label) end
    c:SetChecked(getf())
    c:SetScript("OnClick", function(self) setf(self:GetChecked() and true or false) end)
    if tipKey then
      c:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(label)
        GameTooltip:AddLine(L[tipKey], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
      end)
      c:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return c
  end
  -- sub-título de grupo dentro de um painel: rótulo dourado pequeno + linha fininha à direita
  local function groupLabel(parent, y, text)
    local h = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h:SetPoint("TOPLEFT", 8, y)
    h:SetText("|cfff0d98c" .. text .. "|r")
    local d = parent:CreateTexture(nil, "ARTWORK")
    d:SetColorTexture(0.4, 0.4, 0.45, 0.35); d:SetHeight(1)
    d:SetPoint("LEFT", h, "RIGHT", 8, 0)
    d:SetPoint("RIGHT", parent, "RIGHT", -6, 0)
    return h
  end

  -- ordem das abas (reaproveita os rótulos de seção L.SEC_*)
  local TABS = {
    { key = "appearance", label = L.SEC_APPEARANCE },
    { key = "icons",      label = L.SEC_ICONS },
    { key = "behavior",   label = L.SEC_BEHAVIOR },
    { key = "vendor",     label = L.SEC_VENDOR },
    { key = "bank",       label = L.SEC_BANK },
    { key = "categories", label = L.SEC_CATEGORIES },
    { key = "about",      label = L.SEC_ABOUT },
  }
  for i, t in ipairs(TABS) do
    local p = makePanel(t.key)
    panelTitle(p, t.label)
    local b = CreateFrame("Button", nil, CFG, "UIPanelButtonTemplate")
    b:SetSize(104, 24); b:SetText(t.label)
    b:SetPoint("TOPLEFT", 8, -44 - (i - 1) * 27)
    b:SetAttribute("nodeignore", true) -- só mouse; fora da navegação por controle
    b:SetScript("OnClick", function() ShowConfigTab(t.key) end)
    CFG.tabButtons[t.key] = b
  end

  -- ========== Aparência ==========
  local apP = CFG.panels.appearance
  -- grupo: Janela (moldura + opacidade + colunas)
  groupLabel(apP, -32, L.GRP_WINDOW)
  check(apP, "KrononBagsFrameStyleCheck", 4, -50, L.OPT_BLIZZ_FRAME, function() return DB.settings.frameStyle == "blizzard" end, function(v)
    DB.settings.frameStyle = v and "blizzard" or "dark"
    if CFG.updateThemeBtnState then CFG.updateThemeBtnState() end -- liga/desliga o seletor de tema na hora
    print(KB_PREFIX .. L.MSG_RELOAD_VISUAL)
  end, "TIP_OPT_BLIZZ_FRAME")
  -- grupo: Tema (dropdown de cor, mais abaixo) — dropdown de TEMA com pré-visualização ao vivo (hover = preview, clique = aplica)
  groupLabel(apP, -202, L.THEME_LABEL)
  local themeBtn = CreateFrame("Button", "KrononBagsThemeDropdown", apP, "UIPanelButtonTemplate")
  themeBtn:SetSize(180, 24); themeBtn:SetPoint("TOPLEFT", 8, -220)
  themeBtn:SetAttribute("nodeignore", true) -- só mouse; fora da navegação por controle
  local function themeOf(key) return KB_THEMES[key] or KB_THEMES.dark end
  local function setThemeBtnLabel() themeBtn:SetText(L.THEME_LABEL .. ": " .. themeOf(DB.settings.theme).name) end
  setThemeBtnLabel()
  themeBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.THEME_LABEL)
    if DB.settings.frameStyle == "blizzard" then GameTooltip:AddLine(L.THEME_NEEDS_DARK, 1, 0.5, 0.5, true) end
    GameTooltip:Show()
  end)
  themeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local themeList = CreateFrame("Frame", "KrononBagsThemeList", themeBtn, "BackdropTemplate")
  themeList:SetPoint("TOPLEFT", themeBtn, "BOTTOMLEFT", 0, -2)
  themeList:SetSize(180, #KB_THEMES * 22 + 8)
  themeList:SetFrameStrata("DIALOG")
  themeList:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  themeList:SetBackdropColor(0, 0, 0, 0.95)
  themeList:EnableMouse(true)
  themeList:Hide()
  -- fechar sem escolher (toggle pelo botão / config fecha) restaura o tema salvo
  themeList:SetScript("OnHide", function() ApplyTheme(DB.settings.theme) end)

  -- gate: o tema de cor não afeta a moldura nativa, então o seletor fica desabilitado nela
  CFG.themeBtn = themeBtn
  local function updateThemeBtnState()
    if DB.settings.frameStyle == "blizzard" then
      themeList:Hide()
      themeBtn:Disable()
    else
      themeBtn:Enable()
    end
  end
  CFG.updateThemeBtnState = updateThemeBtnState
  updateThemeBtnState()

  for i, th in ipairs(KB_THEMES) do
    local row = CreateFrame("Button", nil, themeList)
    row:SetSize(168, 20)
    row:SetPoint("TOPLEFT", 6, -4 - (i - 1) * 22)
    row:SetAttribute("nodeignore", true)
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.18)
    local swatch = row:CreateTexture(nil, "ARTWORK")
    swatch:SetSize(12, 12); swatch:SetPoint("LEFT", 2, 0)
    swatch:SetColorTexture(th.border[1], th.border[2], th.border[3], 1)
    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", swatch, "RIGHT", 8, 0); fs:SetText(th.name)
    row:SetScript("OnEnter", function() ApplyTheme(th.key) end) -- PREVIEW ao vivo (não grava em DB)
    row:SetScript("OnClick", function()
      DB.settings.theme = th.key      -- commit ANTES de esconder (OnHide reaplica o salvo)
      ApplyTheme(th.key)
      setThemeBtnLabel()
      themeList:Hide()
    end)
  end

  themeBtn:SetScript("OnShow", function() setThemeBtnLabel(); updateThemeBtnState() end) -- reflete tema + estado do gate ao reabrir
  themeBtn:SetScript("OnClick", function()
    if themeList:IsShown() then themeList:Hide()
    else setThemeBtnLabel(); themeList:Show() end
  end)

  local opLabel = apP:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  opLabel:SetPoint("TOPLEFT", 8, -84)
  local function setOpLabel(v) opLabel:SetText(string.format(L.OPT_OPACITY, math.floor(v * 100 + 0.5))) end
  local slider = CreateFrame("Slider", "KrononBagsOpacitySlider", apP, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", 8, -104); slider:SetWidth(280)
  slider:SetMinMaxValues(0.1, 1.0); slider:SetValueStep(0.05); slider:SetObeyStepOnDrag(true)
  local low  = slider.Low  or _G["KrononBagsOpacitySliderLow"];  if low  then low:SetText("10%")   end
  local high = slider.High or _G["KrononBagsOpacitySliderHigh"]; if high then high:SetText("100%") end
  local txt  = slider.Text or _G["KrononBagsOpacitySliderText"]; if txt  then txt:SetText("")       end
  slider:SetValue((DB.settings and DB.settings.opacity) or 0.92)
  setOpLabel((DB.settings and DB.settings.opacity) or 0.92)
  slider:SetScript("OnValueChanged", function(_, v) DB.settings.opacity = v; setOpLabel(v); ApplyOpacity() end)
  slider:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(opLabel:GetText())
    GameTooltip:AddLine(L.TIP_OPT_OPACITY, 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
  end)
  slider:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local colLabel = apP:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  colLabel:SetPoint("TOPLEFT", 8, -144)
  local function setColLabel(v) colLabel:SetText(string.format(L.OPT_COLS, v)) end
  local colSlider = CreateFrame("Slider", "KrononBagsColsSlider", apP, "OptionsSliderTemplate")
  colSlider:SetPoint("TOPLEFT", 8, -164); colSlider:SetWidth(280)
  colSlider:SetMinMaxValues(COLS_MIN, COLS_MAX); colSlider:SetValueStep(1); colSlider:SetObeyStepOnDrag(true)
  local cLow  = colSlider.Low  or _G["KrononBagsColsSliderLow"];  if cLow  then cLow:SetText(COLS_MIN) end
  local cHigh = colSlider.High or _G["KrononBagsColsSliderHigh"]; if cHigh then cHigh:SetText(COLS_MAX) end
  local cTxt  = colSlider.Text or _G["KrononBagsColsSliderText"]; if cTxt  then cTxt:SetText("")     end
  colSlider:SetValue((DB.settings and DB.settings.cols) or 14)
  setColLabel((DB.settings and DB.settings.cols) or 14)
  colSlider:SetScript("OnValueChanged", function(_, v) v = math.floor(v + 0.5); DB.settings.cols = v; setColLabel(v); Refresh() end)
  colSlider:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(colLabel:GetText())
    GameTooltip:AddLine(L.TIP_OPT_COLS, 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
  end)
  colSlider:SetScript("OnLeave", function() GameTooltip:Hide() end)

  -- ========== Ícones ==========
  local icP = CFG.panels.icons
  check(icP, "KrononBagsShowIlvlCheck", 4, -32, L.OPT_SHOW_ILVL, function() return DB.settings.showIlvl end, function(v)
    DB.settings.showIlvl = v; Refresh()
  end, "TIP_OPT_SHOW_ILVL")
  check(icP, "KrononBagsIlvlRarityCheck", 4, -58, L.OPT_ILVL_RARITY, function() return DB.settings.ilvlUseRarity end, function(v)
    DB.settings.ilvlUseRarity = v; Refresh()
  end, "TIP_OPT_ILVL_RARITY")
  check(icP, "KrononBagsQualBorderCheck", 4, -84, L.OPT_QUAL_BORDER, function() return DB.settings.qualityBorder end, function(v)
    DB.settings.qualityBorder = v; Refresh()
  end, "TIP_OPT_QUAL_BORDER")
  check(icP, "KrononBagsGearTrackCheck", 4, -110, L.OPT_GEAR_TRACK, function() return DB.settings.showGearTrack end, function(v)
    DB.settings.showGearTrack = v; Refresh()
  end, "TIP_OPT_GEAR_TRACK")

  -- ========== Comportamento ==========
  local bhP = CFG.panels.behavior
  -- grupo: Janela (abrir automaticamente / substituir mochilas)
  groupLabel(bhP, -32, L.GRP_WINDOW)
  check(bhP, "KrononBagsAutoOpenCheck", 4, -50, L.OPT_AUTOOPEN, function() return DB.settings.autoOpen end, function(v)
    DB.settings.autoOpen = v
  end, "TIP_OPT_AUTOOPEN")
  check(bhP, "KrononBagsReplaceBagsCheck", 4, -76, L.OPT_REPLACE_BAGS, function() return DB.settings.replaceBags end, function(v)
    DB.settings.replaceBags = v
    print(KB_PREFIX .. L.MSG_RELOAD_BAG)
  end, "TIP_OPT_REPLACE_BAGS")
  -- grupo: Organização (empilhar / ordenar / aninhar por expansão / compactar)
  groupLabel(bhP, -106, L.GRP_ORGANIZE)
  check(bhP, "KrononBagsStackCheck", 4, -124, L.OPT_STACK, function() return DB.settings.stackItems end, function(v)
    DB.settings.stackItems = v; Refresh()
  end, "TIP_OPT_STACK")
  check(bhP, "KrononBagsNestExpacCheck", 4, -176, L.OPT_NEST_EXPANSION, function() return DB.settings.nestByExpansion end, function(v)
    DB.settings.nestByExpansion = v; Refresh()
  end, "TIP_OPT_NEST_EXPANSION")
  check(bhP, "KrononBagsCompactExpacCheck", 4, -202, L.OPT_COMPACT_EXPAC, function() return DB.settings.compactExpac end, function(v)
    DB.settings.compactExpac = v; Refresh()
  end, "TIP_OPT_COMPACT_EXPAC")
  -- grupo: Busca
  groupLabel(bhP, -232, L.GRP_SEARCH)
  check(bhP, "KrononBagsSearchHLCheck", 4, -250, L.OPT_SEARCH_HL, function() return DB.settings.searchHighlight end, function(v)
    DB.settings.searchHighlight = v; Refresh()
  end, "TIP_OPT_SEARCH_HL")
  -- grupo: Proteção & Alts
  groupLabel(bhP, -280, L.GRP_PROTECT)
  check(bhP, "KrononBagsAutoProtectCheck", 4, -298, L.OPT_PROTECT, function() return DB.settings.autoProtectCategorized end, function(v)
    DB.settings.autoProtectCategorized = v; Refresh()
  end, "TIP_OPT_PROTECT")
  check(bhP, "KrononBagsAltCountsCheck", 4, -324, L.OPT_ALT_COUNTS, function() return DB.settings.altCounts end, function(v)
    DB.settings.altCounts = v
  end, "TIP_OPT_ALT_COUNTS")
  -- seletor de ordenação dentro da categoria (faz parte do grupo Organização)
  local SORT_NAMES = { ilvl = L.SORT_ILVL, quality = L.SORT_QUALITY, name = L.SORT_NAME, type = L.SORT_TYPE, recent = L.SORT_RECENT }
  local sortBtn = CreateFrame("Button", nil, bhP, "UIPanelButtonTemplate")
  sortBtn:SetSize(200, 20); sortBtn:SetPoint("TOPLEFT", 8, -150); sortBtn:SetAttribute("nodeignore", true)
  local function updSortBtn() sortBtn:SetText(L.SORT_BY .. (SORT_NAMES[DB.settings.sortMode] or L.SORT_ILVL)) end
  updSortBtn()
  sortBtn:SetScript("OnClick", function(self)
    if not MenuUtil then return end
    MenuUtil.CreateContextMenu(self, function(owner, root)
      root:CreateTitle(L.SORT_MENU_TITLE)
      for _, k in ipairs({ "ilvl", "quality", "name", "type", "recent" }) do
        root:CreateButton(SORT_NAMES[k], function() DB.settings.sortMode = k; updSortBtn(); Refresh() end)
      end
    end)
  end)
  sortBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.SORT_MENU_TITLE)
    GameTooltip:AddLine(L.TIP_OPT_SORT, 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
  end)
  sortBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

  -- ========== Vendedor ==========
  local vnP = CFG.panels.vendor
  check(vnP, "KrononBagsAutoSellCheck", 4, -32, L.OPT_AUTOSELL, function() return DB.settings.autoSellJunk end, function(v)
    DB.settings.autoSellJunk = v
  end, "TIP_OPT_AUTOSELL")
  check(vnP, "KrononBagsAutoRepairCheck", 4, -58, L.OPT_AUTOREPAIR, function() return DB.settings.autoRepair end, function(v)
    DB.settings.autoRepair = v
  end, "TIP_OPT_AUTOREPAIR")

  -- ========== Banco ==========
  local bkP = CFG.panels.bank
  check(bkP, "KrononBagsBankReplaceCheck", 4, -32, L.OPT_BANK_REPLACE, function() return DB.settings.bankReplace end, function(v)
    DB.settings.bankReplace = v
    print(KB_PREFIX .. L.MSG_RELOAD_BANK)
  end, "TIP_OPT_BANK_REPLACE")

  -- ========== Categorias ==========
  local catP = CFG.panels.categories
  local catHint = catP:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  catHint:SetPoint("TOPLEFT", 6, -30); catHint:SetWidth(296); catHint:SetJustifyH("LEFT")
  catHint:SetText(L.CAT_HINT)

  local newCat = CreateFrame("EditBox", "KrononBagsNewCatEdit", catP, "InputBoxTemplate")
  newCat:SetSize(110, 20); newCat:SetPoint("TOPLEFT", 10, -64); newCat:SetAutoFocus(false)
  newCat:SetAttribute("nodeignore", true)
  local addBtn = CreateFrame("Button", nil, catP, "UIPanelButtonTemplate")
  addBtn:SetSize(56, 20); addBtn:SetText(L.BTN_CREATE); addBtn:SetPoint("LEFT", newCat, "RIGHT", 8, 0)
  addBtn:SetAttribute("nodeignore", true)
  local presetBtn = CreateFrame("Button", nil, catP, "UIPanelButtonTemplate")
  presetBtn:SetSize(96, 20); presetBtn:SetText(L.BTN_PRESET); presetBtn:SetPoint("LEFT", addBtn, "RIGHT", 6, 0)
  presetBtn:SetAttribute("nodeignore", true)
  local function doAdd()
    AddCategory(newCat:GetText()); newCat:SetText(""); newCat:ClearFocus()
    RefreshConfigCats(); Refresh()
  end
  addBtn:SetScript("OnClick", doAdd)
  newCat:SetScript("OnEnterPressed", doAdd)
  newCat:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  presetBtn:SetScript("OnClick", function(self)
    if not MenuUtil then return end
    MenuUtil.CreateContextMenu(self, function(owner, root)
      root:CreateTitle(L.PRESET_MENU_TITLE)
      local any = false
      for _, p in ipairs(AVAILABLE_PRESETS) do
        local exists = false
        for _, c in ipairs(DB.catList) do if c.filter == p.filter then exists = true break end end
        if not exists then
          any = true
          root:CreateButton(CatDisplay(p.name), function() AddPreset(p); RefreshConfigCats(); Refresh() end)
        end
      end
      if not any then root:CreateButton("|cff999999" .. L.PRESET_ALL_ADDED .. "|r", function() end) end
    end)
  end)

  -- Exportar / Importar (Layout Oficial da Guilda)
  local exportBtn = CreateFrame("Button", nil, catP, "UIPanelButtonTemplate")
  exportBtn:SetSize(100, 20); exportBtn:SetText(L.BTN_EXPORT); exportBtn:SetPoint("TOPLEFT", 10, -92)
  exportBtn:SetAttribute("nodeignore", true)
  exportBtn:SetScript("OnClick", function()
    KB_exportStr = ExportCategories(); StaticPopup_Show("KRONONBAGS_EXPORT")
  end)
  local importBtn = CreateFrame("Button", nil, catP, "UIPanelButtonTemplate")
  importBtn:SetSize(100, 20); importBtn:SetText(L.BTN_IMPORT); importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
  importBtn:SetAttribute("nodeignore", true)
  importBtn:SetScript("OnClick", function() StaticPopup_Show("KRONONBAGS_IMPORT") end)

  -- lista de categorias com ROLAGEM (controles acima ficam fixos; só a lista rola)
  local catScroll = CreateFrame("ScrollFrame", "KrononBagsCatScroll", catP, "UIPanelScrollFrameTemplate")
  catScroll:SetPoint("TOPLEFT", 4, -118)
  catScroll:SetPoint("BOTTOMRIGHT", -26, 6)
  catScroll:SetAttribute("nodeignore", true)
  local catChild = CreateFrame("Frame", nil, catScroll)
  catChild:SetSize(270, 1)
  catScroll:SetScrollChild(catChild)
  CFG.catScroll = catScroll
  CFG.catChild = catChild

  -- ========== Sobre ========== (créditos / Discord / versão)
  local abP = CFG.panels.about
  CFG.kbCredits = abP:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  CFG.kbCredits:SetPoint("TOPLEFT", 6, -40); CFG.kbCredits:SetWidth(296); CFG.kbCredits:SetJustifyH("LEFT")
  CFG.kbCredits:SetText("|cff9d9d9dKrononBags v" .. ver .. "  ·  Kronon  ·  discord.gg/yFdQsFewN3|r")

  ShowConfigTab("appearance") -- aba padrão ao abrir
  CFG:Hide()
end

ToggleConfig = function()
  if not CFG then CreateConfig() end
  if CFG:IsShown() then
    CFG:Hide()
  else
    RefreshConfigCats()
    if CFG.ShowTab then CFG.ShowTab("appearance") end -- sempre abre na aba Aparência
    CFG:Show()
  end
end

-- ---------------- Prontidão de Raide / M+ ----------------
-- Painel "estou pronto?": conta suprimentos na mochila (por subclasse + nome PT/EN),
-- durabilidade mínima do equipado e pedra-chave M+. Tudo leitura — sem ação protegida.
local READY
local function ScanSupplies()
  local n = { flask = 0, potion = 0, food = 0, hs = 0, rune = 0 }
  for _, bag in ipairs(BAGS) do
    local slots = C_Container.GetContainerNumSlots(bag) or 0
    for slot = 1, slots do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.itemID then
        local _, _, _, _, _, classID, subID = C_Item.GetItemInfoInstant(info.itemID)
        local nm = (C_Item.GetItemInfo(info.hyperlink) or ""):lower()
        local cnt = info.stackCount or 1
        if classID == 0 then
          if subID == 3 or nm:find("frasco") or nm:find("flask") or nm:find("phial") then n.flask = n.flask + cnt
          elseif subID == 1 or nm:find("poção") or nm:find("potion") then n.potion = n.potion + cnt
          elseif subID == 5 or nm:find("comida") or nm:find("food") then n.food = n.food + cnt end
        end
        if nm:find("pedra de vida") or nm:find("healthstone") then n.hs = n.hs + cnt end
        if nm:find("runa") or nm:find("rune") or nm:find("vantagem") then n.rune = n.rune + cnt end
      end
    end
  end
  return n
end
local function MinDurability()
  local minPct
  for slot = 1, 18 do
    local cur, mx = GetInventoryItemDurability(slot)
    if cur and mx and mx > 0 then
      local p = cur / mx * 100
      if not minPct or p < minPct then minPct = p end
    end
  end
  return minPct
end
local function RefreshReady()
  if not (READY and READY:IsShown()) then return end
  local s = ScanSupplies()
  local dur = MinDurability()
  local kLvl = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel and C_MythicPlus.GetOwnedKeystoneLevel()
  local function color(ok) return ok and "|cff40ff40" or "|cffff5050" end
  local function line(label, value, ok)
    return string.format("%s%s|r  %s%s|r", "|cfff0d98c", label, color(ok), value)
  end
  local rows = {}
  if dur then rows[#rows + 1] = line(L.READY_DURABILITY, math.floor(dur) .. "%", dur >= 30)
  else rows[#rows + 1] = line(L.READY_DURABILITY, "—", true) end
  rows[#rows + 1] = line(L.READY_FLASK, s.flask > 0 and tostring(s.flask) or L.READY_MISSING, s.flask > 0)
  rows[#rows + 1] = line(L.READY_POTION, s.potion > 0 and tostring(s.potion) or L.READY_MISSING, s.potion > 0)
  rows[#rows + 1] = line(L.READY_FOOD, s.food > 0 and tostring(s.food) or L.READY_MISSING, s.food > 0)
  rows[#rows + 1] = line(L.READY_HEALTHSTONE, s.hs > 0 and tostring(s.hs) or L.READY_MISSING, s.hs > 0)
  rows[#rows + 1] = line(L.READY_RUNE, s.rune > 0 and tostring(s.rune) or L.READY_MISSING, s.rune > 0)
  rows[#rows + 1] = line(L.READY_KEYSTONE, (kLvl and kLvl > 0) and ("+" .. kLvl) or L.READY_NONE, kLvl and kLvl > 0)
  READY.body:SetText(table.concat(rows, "\n"))
end
local function ToggleReady()
  if not READY then
    READY = CreateFrame("Frame", "KrononBagsReady", UIParent, "BackdropTemplate")
    READY:SetSize(240, 220); READY:SetPoint("CENTER", 260, 0); READY:SetFrameStrata("DIALOG")
    READY:SetMovable(true); READY:EnableMouse(true); READY:RegisterForDrag("LeftButton")
    READY:SetScript("OnDragStart", READY.StartMoving); READY:SetScript("OnDragStop", READY.StopMovingOrSizing)
    if READY.SetBackdrop then
      READY:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
      READY:SetBackdropColor(0, 0, 0, 0.92)
    end
    local title = READY:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10); title:SetText("|cfff0d98c" .. L.READY_TITLE .. "|r")
    local close = CreateFrame("Button", nil, READY, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", 2, 2)
    READY.body = READY:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    READY.body:SetPoint("TOPLEFT", 16, -40); READY.body:SetJustifyH("LEFT"); READY.body:SetSpacing(6)
    local hint = READY:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOM", 0, 10); hint:SetText(L.READY_HINT)
    READY:HookScript("OnShow", RefreshReady)
  end
  if READY:IsShown() then READY:Hide() else READY:Show(); RefreshReady() end
end

-- ---------------- Substituir o banco nativo ----------------
-- Esconde o banco nativo SEM reparentar e SEM :Hide(). Reparentar o BankFrame pra um frame
-- de addon TAINTA o PurchaseBankTab (comprar aba dava ADDON_ACTION_FORBIDDEN); :Hide() fecharia
-- a sessão. Alpha 0 + sem mouse/teclado deixa invisível e não-clicável, a sessão segue aberta
-- (C_Bank/C_Container respondem) e desenhamos o banco na nossa janela. Padrão BetterBags/ElvUI.
local kbBankHooked = {}
local function kbBankSet(frame, shown)
  if not frame then return end
  frame:SetAlpha(shown and 1 or 0)
  if frame.EnableMouse then frame:EnableMouse(shown) end
  if frame.EnableKeyboard then frame:EnableKeyboard(shown) end
end
local function kbHookBank(frame)
  if not frame or kbBankHooked[frame] then return end
  kbBankHooked[frame] = true -- reaplica o esconde se a Blizzard reexibir o painel (troca de aba)
  frame:HookScript("OnShow", function(self)
    if DB and DB.settings and DB.settings.bankReplace then kbBankSet(self, false) end
  end)
end
local function SuppressDefaultBank()
  if not (DB and DB.settings and DB.settings.bankReplace) then return end
  kbBankSet(BankFrame, false); kbBankSet(BankPanel, false); kbBankSet(AccountBankPanel, false)
  kbHookBank(BankFrame); kbHookBank(BankPanel); kbHookBank(AccountBankPanel)
end
local function RestoreDefaultBank() -- bankReplace desligado: volta o banco nativo visível
  kbBankSet(BankFrame, true); kbBankSet(BankPanel, true); kbBankSet(AccountBankPanel, true)
end

-- ---------------- Substituir a bag do jogo (tecla B / botão da bolsa) ----------------
-- Troca as funções globais de abrir/fechar bag pra controlarem o KrononBags. Assim a
-- tecla B, o botão da mochila e os auto-abrir do jogo passam a usar a nossa janela, e
-- as bolsas padrão nunca aparecem. Feito 1x no login (precisa /reload pra desligar).
local bagsReplaced
local function ReplaceGameBags()
  if not (DB and DB.settings and DB.settings.replaceBags) then return end
  if bagsReplaced then return end
  bagsReplaced = true
  local function kbOpen() if not UI then CreateUI() end; if not UI:IsShown() then UI:Show(); Refresh() end end
  local function kbClose() if UI and UI:IsShown() then UI:Hide() end end
  ToggleAllBags  = function() Toggle() end
  ToggleBackpack = function() Toggle() end
  ToggleBag      = function() Toggle() end
  OpenAllBags    = function() kbOpen() end
  OpenBackpack   = function() kbOpen() end
  OpenBag        = function() kbOpen() end
  CloseAllBags   = function() kbClose() end
  CloseBackpack  = function() kbClose() end
  CloseBag       = function() kbClose() end
end

-- ---------------- Auto-abrir no vendedor / banco / correio ----------------
local function AutoShow()
  if not (DB and DB.settings and DB.settings.autoOpen) then return end
  if not UI then CreateUI() end
  if not UI:IsShown() then UI:Show(); UI.autoOpened = true; Refresh() end
end
local function AutoHide()
  if UI and UI.autoOpened then UI:Hide(); UI.autoOpened = false end
end

-- ---------------- Contagem de itens nos alts (snapshot + tooltip) ----------------
-- Captura a contagem de itens deste personagem (mochila no logout; banco/Brigada ao
-- usar o banco) e mostra no tooltip "fulano: N" dos outros chars + "Brigada: N".
-- Usa CHAVES NOVAS no SavedVariables (não mexe nas suas categorias/favoritos).
-- Cada captura é um SNAPSHOT completo (substitui o anterior daquele char), não acumula.
local function ScanCounts(bagList)
  local c = {}
  for _, bag in ipairs(bagList) do
    local slots = C_Container.GetContainerNumSlots(bag) or 0
    for slot = 1, slots do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.itemID then c[info.itemID] = (c[info.itemID] or 0) + (info.stackCount or 1) end
    end
  end
  return c
end
local function CaptureBags()
  if not DB then return end
  local k = CharKey()
  DB.charItems[k] = DB.charItems[k] or {}
  DB.charItems[k].name = UnitName("player")
  DB.charItems[k].class = select(2, UnitClass("player"))
  DB.charItems[k].bags = ScanCounts(BAGS)
  if DB.settings and DB.settings.altCounts then DB.charItems[k].gold = GetMoney() end -- painel de ouro por personagem
end
-- snapshot rico (display por slot ocupado) pra consultar o banco de longe + slots livres
local function SnapList(bagList)
  local out, free = {}, 0
  for _, bag in ipairs(bagList) do
    local slots = C_Container.GetContainerNumSlots(bag) or 0
    for slot = 1, slots do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.itemID then
        out[#out + 1] = { id = info.itemID, link = info.hyperlink, icon = info.iconFileID,
                          count = info.stackCount or 1, q = info.quality, bound = info.isBound }
      else
        free = free + 1
      end
    end
  end
  return out, free
end
local function CaptureBank()
  if not DB then return end
  local k = CharKey()
  DB.charItems[k] = DB.charItems[k] or {}
  DB.charItems[k].bank = ScanCounts(PurchasedTabs(BANK_CHAR)) -- contagem (tooltip dos alts)
  local items, free = SnapList(PurchasedTabs(BANK_CHAR))      -- snapshot rico (visualização)
  DB.charItems[k].bankSnap, DB.charItems[k].bankFree = items, free
  DB.charItems[k].bankTime = (time and time()) or nil
  local wb = PurchasedTabs(BANK_ACCT)
  if #wb > 0 then
    DB.warband = ScanCounts(wb)
    local wi, wf = SnapList(wb)
    DB.warbandSnap, DB.warbandFree, DB.warbandTime = wi, wf, (time and time()) or nil
  end
end
local function AddCountsToTooltip(tooltip, itemID)
  if not (DB and DB.settings and DB.settings.altCounts and itemID) then return end
  local meKey, lines = CharKey(), {}
  for k, data in pairs(DB.charItems) do
    if k ~= meKey and type(data) == "table" then
      local total = ((data.bags and data.bags[itemID]) or 0) + ((data.bank and data.bank[itemID]) or 0)
      if total > 0 then
        local nm = data.name or k
        local col = data.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[data.class]
        if col then nm = string.format("|cff%02x%02x%02x%s|r", col.r * 255, col.g * 255, col.b * 255, nm) end
        lines[#lines + 1] = nm .. ": " .. total
      end
    end
  end
  local wb = DB.warband and DB.warband[itemID]
  if wb and wb > 0 then lines[#lines + 1] = "|cff00ccff" .. L.WARBAND_LABEL .. "|r: " .. wb end
  if #lines > 0 then tooltip:AddLine("|cfff0d98cKronon|r  " .. table.concat(lines, "   "), 1, 1, 1) end
end
-- valor pela Auction House no tooltip (sempre que houver fonte/sellPrice; nil = não mostra nada)
local function AddMarketValueToTooltip(tooltip, itemID)
  if not itemID then return end
  local v, src = GetMarketValue(itemID)
  if v then
    tooltip:AddDoubleLine(src == "ah" and L.MARKET_VALUE or L.SELL_VALUE, GetCoinTextureString(v), 1, 0.82, 0, 1, 1, 1)
  end
end
-- ---------------- v0.32.0: comparação com o equipado no tooltip ----------------
-- Só-leitura: mostra ilvl vs. equipado, delta de secundários e % do Pawn (se houver).
-- mapa invType (4º retorno de GetItemInfoInstant) → slot(s) de inventário.
local INVTYPE_SLOT = {
  INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_CHEST = { 5 },
  INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 },
  INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 },
  INVTYPE_CLOAK = { 15 }, INVTYPE_WEAPON = { 16, 17 }, INVTYPE_WEAPONMAINHAND = { 16 },
  INVTYPE_2HWEAPON = { 16 }, INVTYPE_RANGED = { 16 }, INVTYPE_RANGEDRIGHT = { 16 },
  INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 },
}
-- retorna o itemLink equipado a comparar (o de MENOR ilvl quando há 2 slots), ou nil
local function GetEquippedForCompare(itemID)
  if not (itemID and C_Item and C_Item.GetItemInfoInstant) then return nil end
  local _, _, _, invType = C_Item.GetItemInfoInstant(itemID)
  local slots = invType and INVTYPE_SLOT[invType]
  if not slots then return nil end
  local bestLink, bestIlvl
  for i = 1, #slots do
    local eq = GetInventoryItemLink and GetInventoryItemLink("player", slots[i])
    if eq then
      local ilvl = (C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(eq)) or 0
      if (not bestLink) or ilvl < bestIlvl then bestLink, bestIlvl = eq, ilvl end
    end
  end
  return bestLink
end
-- adiciona ao tooltip a comparação com a peça equipada (ilvl, secundários, Pawn)
local function AddUpgradeCompareToTooltip(tooltip, itemID, link)
  if not (link and itemID and C_Item) then return end
  local eqLink = GetEquippedForCompare(itemID)
  if not eqLink then return end       -- não é equipável OU o slot está vazio
  if link == eqLink then return end   -- não compara o item consigo mesmo
  -- diferença de item level
  local a = C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(link)
  local b = C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(eqLink)
  if a and b then
    local diff = a - b
    local r, g, bl
    if diff > 0 then r, g, bl = 0.2, 1, 0.2
    elseif diff < 0 then r, g, bl = 1, 0.3, 0.3
    else r, g, bl = 0.6, 0.6, 0.6 end
    tooltip:AddDoubleLine(L.CMP_HEADER, "ilvl " .. a .. " (" .. (diff >= 0 and "+" or "") .. diff .. ")",
      1, 0.82, 0, r, g, bl)
  end
  -- delta de atributos secundários (GetItemStatDelta; senão calcula via GetItemStats)
  local d
  if C_Item.GetItemStatDelta then
    d = C_Item.GetItemStatDelta(link, eqLink)
  else
    local gs = C_Item.GetItemStats or GetItemStats
    if gs then
      local s1, s2 = gs(link), gs(eqLink)
      if type(s1) == "table" or type(s2) == "table" then
        d, s1, s2 = {}, s1 or {}, s2 or {}
        for k, v in pairs(s1) do d[k] = v - (s2[k] or 0) end
        for k, v in pairs(s2) do if d[k] == nil then d[k] = -v end end
      end
    end
  end
  if type(d) == "table" then
    local keys = { "ITEM_MOD_CRIT_RATING", "ITEM_MOD_HASTE_RATING", "ITEM_MOD_MASTERY_RATING", "ITEM_MOD_VERSATILITY" }
    local parts = {}
    for i = 1, #keys do
      local v = d[keys[i]]
      if v and v ~= 0 then
        local nm = _G[keys[i]] or keys[i]
        parts[#parts + 1] = (v > 0 and ("|cff33ff33+" .. v) or ("|cffff5555" .. v)) .. " " .. nm .. "|r"
      end
    end
    if #parts > 0 then tooltip:AddLine(table.concat(parts, "  "), 1, 1, 1, true) end
  end
  -- % de upgrade pelo Pawn (100% opcional; protegido por existência + pcall)
  if PawnGetItemData and PawnIsItemAnUpgrade then
    local ok, up = pcall(function()
      local pitem = PawnGetItemData(link)
      if pitem then return PawnIsItemAnUpgrade(pitem) end
    end)
    if ok and type(up) == "table" and up[1] and up[1].PercentUpgrade then
      local pct = math.floor(up[1].PercentUpgrade * 100 + 0.5)
      local scale = up[1].LocalizedScaleName and (" " .. up[1].LocalizedScaleName) or ""
      tooltip:AddDoubleLine(L.CMP_PAWN, "+" .. pct .. "%" .. scale, 1, 0.82, 0, 0.2, 1, 0.2)
    end
  end
end
-- registra o hook de tooltip (API moderna do 12.0); silencioso se ausente
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
    if tooltip == GameTooltip and data and data.id then
      AddCountsToTooltip(tooltip, data.id)
      AddMarketValueToTooltip(tooltip, data.id)
      AddUpgradeCompareToTooltip(tooltip, data.id, select(2, C_Item.GetItemInfo(data.id)))
    end
  end)
end

-- ---------------- Auto-vendedor: vender lixo + reparar ----------------
-- Roda no MERCHANT_SHOW. Vender lixo usa varredura própria (SellJunkItems) que respeita a
-- proteção do addon — NÃO C_MerchantFrame.SellAllJunkItems, que ignora favoritos/categorias.
-- Reparo: tenta fundos da guilda primeiro (se houver permissão e saldo), senão ouro próprio.
local function AutoVendor()
  if not (DB and DB.settings) then return end
  if DB.settings.autoSellJunk then
    pcall(SellJunkItems)
  end
  if DB.settings.autoRepair and CanMerchantRepair and CanMerchantRepair() then
    local cost = GetRepairAllCost and select(1, GetRepairAllCost()) or 0
    if cost and cost > 0 then
      local guildOk = IsInGuild and IsInGuild() and CanGuildBankRepair and CanGuildBankRepair()
      local withdraw = GetGuildBankWithdrawMoney and GetGuildBankWithdrawMoney() or 0 -- -1 = ilimitado
      if guildOk and (withdraw == -1 or withdraw >= cost) then
        RepairAllItems(true)
        print(KB_PREFIX .. string.format(L.MSG_REPAIR_GUILD, GetCoinTextureString(cost)))
      elseif (GetMoney() or 0) >= cost then
        RepairAllItems(false)
        print(KB_PREFIX .. string.format(L.MSG_REPAIR_SELF, GetCoinTextureString(cost)))
      else
        print(KB_PREFIX .. string.format(L.MSG_REPAIR_NOGOLD, GetCoinTextureString(cost)))
      end
    end
  end
end

-- ---------------- Eventos / comandos ----------------
-- GET_ITEM_INFO_RECEIVED dispara em RAJADA quando muitos itens carregam. Debounce:
-- agenda 1 Refresh só (pra os sub-grupos por expansão se acertarem quando o cache esquenta).
local kbExpacRefreshPending = false
local function KB_ExpacRefreshSoon()
  if kbExpacRefreshPending then return end
  kbExpacRefreshPending = true
  C_Timer.After(0.3, function()
    kbExpacRefreshPending = false
    if UI and UI:IsShown() and not InCombatLockdown() then Refresh() end
  end)
end

-- Histórico: compara um snapshot da mochila (itemID -> contagem total nas bolsas 0..5)
-- com o anterior e registra os deltas. O 1º snapshot só calibra (kbHistInit), pra não
-- despejar o inventário inteiro como "+N" no login/primeira abertura.
local function HistorySnapshotDiff()
  local cur = {}
  local curLink = {}
  for _, bag in ipairs(BAGS) do
    local slots = C_Container.GetContainerNumSlots(bag)
    if slots and slots > 0 then
      for slot = 1, slots do
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info and info.itemID then
          local id = info.itemID
          cur[id] = (cur[id] or 0) + (info.stackCount or 1)
          if not curLink[id] then
            local link = C_Container.GetContainerItemLink(bag, slot)
            if link then curLink[id] = link; kbLastLink[id] = link end
          end
        end
      end
    end
  end
  if not kbHistInit then
    kbLastCounts = cur
    kbHistInit = true
    return
  end
  local seen = {}
  for id in pairs(cur) do seen[id] = true end
  for id in pairs(kbLastCounts) do seen[id] = true end
  for id in pairs(seen) do
    local delta = (cur[id] or 0) - (kbLastCounts[id] or 0)
    if delta ~= 0 then
      -- link representativo: o capturado neste scan ou o último conhecido (item que saiu)
      tinsert(kbHistory, 1, { id = id, delta = delta, t = (time and time()) or 0, link = curLink[id] or kbLastLink[id] })
    end
  end
  kbLastCounts = cur
  while #kbHistory > 50 do tremove(kbHistory) end -- cap de 50 eventos
  if UI and UI.histPanel and UI.histPanel:IsShown() and RenderHistory then RenderHistory() end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:RegisterEvent("EQUIPMENT_SETS_CHANGED")
f:RegisterEvent("PLAYER_MONEY")
f:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
f:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
f:RegisterEvent("BAG_UPDATE_COOLDOWN")
f:RegisterEvent("GET_ITEM_INFO_RECEIVED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("PLAYER_LOGOUT")
f:RegisterEvent("MERCHANT_SHOW");      f:RegisterEvent("MERCHANT_CLOSED")
f:RegisterEvent("BANKFRAME_OPENED");   f:RegisterEvent("BANKFRAME_CLOSED")
f:RegisterEvent("MAIL_SHOW");          f:RegisterEvent("MAIL_CLOSED")
f:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 == ADDON_NAME then InitDB() end
  elseif event == "PLAYER_LOGIN" then
    SuppressDefaultBank() -- esconde o banco nativo (se a opção estiver ligada)
    ReplaceGameBags()     -- B / clique na bolsa / atalho passam a abrir o KrononBags
    -- invalida o cache de valor de mercado quando o Auctionator termina uma varredura
    if Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.RegisterForDBUpdate then
      pcall(Auctionator.API.v1.RegisterForDBUpdate, CALLER, function() wipe(kbMarketCache) end)
    end
  elseif event == "PLAYER_LOGOUT" then
    CaptureBags() -- snapshot da mochila pra contagem nos alts
  elseif event == "PLAYER_MONEY" or event == "CURRENCY_DISPLAY_UPDATE" then
    if UI and UI:IsShown() then UpdateMoney() end
  elseif event == "BAG_UPDATE_COOLDOWN" then
    if UI and UI:IsShown() then UpdateCooldowns() end
  elseif event == "GET_ITEM_INFO_RECEIVED" then
    -- cache de item esquentou: re-renderiza pra acertar os sub-grupos por expansão.
    -- só quando a opção está ligada e a janela aberta (pra não refreshar à toa); debounced.
    if DB and DB.settings and DB.settings.nestByExpansion and UI and UI:IsShown() then
      KB_ExpacRefreshSoon()
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if UI and UI.refreshPending and UI:IsShown() then UI.refreshPending = nil; Refresh() end
  elseif event == "MERCHANT_SHOW" then
    AutoVendor() -- auto-vender lixo + auto-reparar (se ligados na config)
    AutoShow(); if UI then UpdateTabs() end; Refresh() -- bloquear venda de protegidos + botão vender lixo
  elseif event == "MERCHANT_CLOSED" then
    AutoHide(); if UI then UpdateTabs() end; Refresh() -- restaura usar/equipar; esconde vender lixo
  elseif event == "BANKFRAME_OPENED" then
    if DB and DB.settings and DB.settings.bankReplace then
      atBank = true; SuppressDefaultBank(); mode = "bank"
      AutoShow(); if UI then UpdateTabs() end; Refresh()
    else
      RestoreDefaultBank() -- garante o banco nativo visível (caso tenha sido escondido antes)
      AutoShow() -- banco nativo cuida do banco; só abrimos a mochila
    end
  elseif event == "BANKFRAME_CLOSED" then
    if DB then CaptureBank() end -- captura o estado final do banco ANTES de sair (pra consulta de longe)
    atBank = false; mode = "bags"
    if UI then UpdateTabs() end
    AutoHide(); if UI and UI:IsShown() then Refresh() end
  elseif event == "MAIL_SHOW" then
    AutoShow()
  elseif event == "MAIL_CLOSED" then
    AutoHide()
  else -- BAG_UPDATE_DELAYED, EQUIPMENT_SETS_CHANGED, BAG_NEW_ITEMS_UPDATED
    -- "Abrir tudo" é assíncrono: depois que um recipiente abre, BAG_UPDATE_DELAYED dispara
    -- e a gente abre o próximo, até não sobrar nenhum (OpenAllOpenables zera openingAll).
    if event == "BAG_UPDATE_DELAYED" and UI and UI.openingAll then OpenAllOpenables() end
    if event == "BAG_UPDATE_DELAYED" then HistorySnapshotDiff() end -- rastreia entradas/saídas (BAG_UPDATE_DELAYED já é throttled)
    Refresh(); RefreshReady()
    if DB and atBank then CaptureBank() end -- snapshot do banco fresco (base da consulta de longe), sempre que no banco
    if DB and DB.settings and DB.settings.altCounts then CaptureBags() end -- contagem da mochila nos alts (se ligado)
  end
end)

SLASH_KRONONBAGS1 = "/kb"
SLASH_KRONONBAGS2 = "/krononbags"
SlashCmdList["KRONONBAGS"] = function(msg)
  msg = (msg or ""):lower():gsub("%s+", "")
  if msg == "config" or msg == "cfg" or msg == "opcoes" or msg == "opções" then
    ToggleConfig()
  elseif msg == "grade" or msg == "grid" then
    if not UI then CreateUI() end
    DB.settings.gridView = not DB.settings.gridView
    if not UI:IsShown() then UI:Show() end
    Refresh()
  elseif msg == "organizar" or msg == "sort" then
    if not InCombatLockdown() and C_Container and C_Container.SortBags then C_Container.SortBags() end
  elseif msg == "banco" or msg == "bank" then
    if not UI then CreateUI() end
    if not UI:IsShown() then UI:Show() end
    if atBank or HasCharBankSnap() then mode = "bank"
    elseif HasWarbandSnap() then mode = "warband"
    else print(KB_PREFIX .. L.MSG_OPEN_BANK_ONCE) end
    UpdateTabs(); Refresh()
  elseif msg == "pronto" or msg == "prontidao" or msg == "prontidão" or msg == "readiness" then
    ToggleReady()
  else
    Toggle()
  end
end
