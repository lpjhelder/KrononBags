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
local ApplyOpacity, CreateConfig, ToggleConfig, UpdateMoney, UpdateTabs, SearchMatcher, RefreshConfigCats

local BAGS = { 0, 1, 2, 3, 4, 5 } -- mochila + 4 bolsas + bolsa de reagentes
local COLS = 14
local COLS_MIN, COLS_MAX = 6, 28 -- faixa de colunas (slider + redimensionar pela alça)
local SBW    = 16  -- largura reservada pra barra de rolagem à direita
local BTN    = 37
local PAD    = 4   -- espaço ENTRE itens
local MARGIN = 10  -- distância da borda da janela
local search = ""

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

local pool = {}        -- pool de botões de item
local headerPool = {}  -- pool de cabeçalhos de seção

-- catálogo de categorias pré-prontas (ordem de fresh install + menu "Pré-pronta…")
local KB_PRESETS = {
  { name = "Recém-obtidos", filter = "new" },
  { name = "Favoritos",   filter = "favorites" },
  { name = "Pedra-chave", filter = "keystone" },
  { name = "Equipamento", filter = "equip" },
  { name = "Consumíveis", filter = "consumable" },
  { name = "Reagentes",   filter = "reagentbag" },
  { name = "Materiais",   filter = "trade" },
  { name = "Missão",      filter = "quest" },
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
  if KrononBagsDB.settings.cols == nil then KrononBagsDB.settings.cols = 14 end
  if KrononBagsDB.settings.gridView == nil then KrononBagsDB.settings.gridView = false end
  if KrononBagsDB.settings.autoOpen == nil then KrononBagsDB.settings.autoOpen = true end
  if KrononBagsDB.settings.showIlvl == nil then KrononBagsDB.settings.showIlvl = true end
  if KrononBagsDB.settings.ilvlUseRarity == nil then KrononBagsDB.settings.ilvlUseRarity = true end
  if KrononBagsDB.settings.frameStyle == nil then KrononBagsDB.settings.frameStyle = "dark" end -- "dark" (atual) | "blizzard" (moldura nativa)
  if KrononBagsDB.settings.bankReplace == nil then KrononBagsDB.settings.bankReplace = true end -- substituir o banco/Brigada nativo pelo KrononBags
  if KrononBagsDB.settings.altCounts == nil then KrononBagsDB.settings.altCounts = true end -- mostrar contagem nos alts no tooltip
  if KrononBagsDB.settings.maxHeight == nil then KrononBagsDB.settings.maxHeight = 520 end -- altura máxima visível (acima disso, rola)
  if KrononBagsDB.settings.replaceBags == nil then KrononBagsDB.settings.replaceBags = true end -- tecla B / botão da bolsa abrem o KrononBags
  if KrononBagsDB.settings.sortMode == nil then KrononBagsDB.settings.sortMode = "ilvl" end -- ordem dentro da categoria: ilvl/quality/name/type/recent
  if KrononBagsDB.settings.stackItems == nil then KrononBagsDB.settings.stackItems = false end -- empilhar itens iguais num ícone só
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
  if type(str) ~= "string" or str == "" then return false, "vazio" end
  local recs = {}
  for r in (str .. ";"):gmatch("(.-);") do recs[#recs + 1] = r end
  if recs[1] ~= "KBCAT1" then return false, "formato inválido" end
  local newList, newAssign = {}, {}
  for i = 2, #recs do
    local kind, a, b = recs[i]:match("^(%a)>(.-)>(.*)$")
    if kind == "C" then
      newList[#newList + 1] = { name = kbUnesc(a), filter = (b ~= "" and kbUnesc(b)) or nil }
    elseif kind == "A" then
      local id = tonumber(a); if id then newAssign[id] = kbUnesc(b) end
    end
  end
  if #newList == 0 then return false, "sem categorias" end
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

-- filtros recebem (itemID, quality, bag, slot). "reagentbag"/"keystone"/"new" são especiais.
local PRESET_FILTERS = {
  new        = function(id, q, bag, slot) return (DB and DB.recem and DB.recem[id]) and true or false end, -- recém-obtido (fica até clicar em Distribuir)
  favorites  = function(id, q, bag) return DB.favorites[id] and true or false end,
  keystone   = function(id, q, bag) return isKeystone(id) end,                                -- Pedra-chave
  reagentbag = function(id, q, bag) return bag == 5 end,                                       -- bolsa de reagentes (loc)
  equip      = function(id, q, bag) local c = classOf(id); return c == 2 or c == 4 end,        -- arma / armadura
  consumable = function(id, q, bag) return classOf(id) == 0 end,                               -- consumível
  trade      = function(id, q, bag) local c = classOf(id); return c == 7 or c == 8 or c == 3 or c == 5 end, -- mats/gema/reagente
  quest      = function(id, q, bag) return classOf(id) == 12 end,                              -- missão
  junk       = function(id, q, bag) return q == 0 end,                                         -- lixo
}

-- catálogo de presets que dá pra adicionar na config (mesmo do fresh install)
local AVAILABLE_PRESETS = KB_PRESETS

-- ---------------- Conjuntos de Equipamento (auto PvP/PvE) ----------------
local equipSetByItem = {}   -- [itemID] = nome do conjunto
local equipSetNames = {}    -- lista ordenada de nomes de conjunto
local equipSetIDByName = {} -- [nome] = setID

local function RebuildEquipSets()
  wipe(equipSetByItem); wipe(equipSetNames); wipe(equipSetIDByName)
  if not C_EquipmentSet then return end
  for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
    local name = C_EquipmentSet.GetEquipmentSetInfo(setID)
    if name then
      equipSetNames[#equipSetNames + 1] = name
      equipSetIDByName[name] = setID
      local items = C_EquipmentSet.GetItemIDs(setID)
      if items then
        for _, itemID in pairs(items) do
          if type(itemID) == "number" and itemID > 1 then
            equipSetByItem[itemID] = name
          end
        end
      end
    end
  end
end

-- ---------------- Categorização ----------------
-- item está numa categoria "de verdade" (manual ou conjunto de equipamento)?
-- exceção: jogar item manualmente em "Lixo" (filtro junk) NÃO protege de venda
local function IsCategorized(itemID)
  local a = DB.assignments[itemID]
  if a then
    local entry = CatEntryByName(a)
    if entry and entry.filter ~= "junk" then return true end
  end
  if equipSetByItem[itemID] then return true end
  return false
end

-- protegido = favorito OU (opção ligada E está numa categoria de verdade)
local function IsProtected(itemID)
  if DB.favorites[itemID] then return true end -- favorito = protegido
  if DB.settings and DB.settings.autoProtectCategorized and IsCategorized(itemID) then return true end
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
  local s = equipSetByItem[itemID]
  if s then return s end
  for _, c in ipairs(DB.catList) do
    if c.rule and c.rule ~= "" then
      local m = GetRuleMatcher(c.rule)
      if m and m(it) then return c.name end
    elseif c.filter then
      local fn = PRESET_FILTERS[c.filter]
      if fn and fn(itemID, it.quality, it.bag, it.slot) then return c.name end
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

-- ---------------- Menu de clique esquerdo ----------------
OpenItemMenu = function(self)
  local itemID = self.itemID
  if not itemID or not MenuUtil then return end
  MenuUtil.CreateContextMenu(self, function(owner, root)
    root:CreateTitle(self.itemName ~= "" and self.itemName or "Item")
    -- usar/equipar é via CLIQUE DIREITO (ação segura); não dá pra fazer pelo menu (UseContainerItem é protegida)
    root:CreateButton("Mover (pegar item)", function()
      C_Container.PickupContainerItem(self.bag, self.slot)
    end)

    local move = root:CreateButton("Mover para categoria")
    local anyCustom, anyPreset = false, false
    -- 1) categorias suas (custom)
    for _, c in ipairs(DB.catList) do
      if c.filter == nil then
        anyCustom = true
        move:CreateButton(c.name, function() DB.assignments[itemID] = c.name; Refresh() end)
      end
    end
    -- 2) categorias pré-prontas (jogar o item nelas força — override do filtro)
    for _, c in ipairs(DB.catList) do
      if c.filter ~= nil then
        if not anyPreset and anyCustom then move:CreateDivider() end
        anyPreset = true
        move:CreateButton(c.name, function() DB.assignments[itemID] = c.name; Refresh() end)
      end
    end
    if not anyCustom and not anyPreset then
      move:CreateButton("|cff999999(crie uma categoria na config)|r", function() end)
    end
    move:CreateDivider()
    move:CreateButton("Nova categoria…", function()
      StaticPopup_Show("KRONONBAGS_NEWCAT", nil, nil, itemID)
    end)

    if DB.assignments[itemID] then
      root:CreateButton("Tirar da categoria", function() DB.assignments[itemID] = nil; Refresh() end)
    end

    root:CreateDivider()
    root:CreateButton(DB.favorites[itemID] and "Desfavoritar (libera venda)" or "Favoritar (protege de venda)", function()
      DB.favorites[itemID] = (not DB.favorites[itemID]) or nil; Refresh()
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
    if not dst then print("|cfff0d98cKrononBags|r: banco cheio."); return end
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
    root:CreateTitle(cat or "Categoria")
    root:CreateButton(DB.collapsed[cat] and "Expandir esta" or "Recolher esta", function()
      DB.collapsed[cat] = (not DB.collapsed[cat]) or nil; Refresh()
    end)
    local function setAll(v)
      for _, c in ipairs(DB.catList) do DB.collapsed[c.name] = v end
      for _, n in ipairs(equipSetNames) do DB.collapsed[n] = v end
      DB.collapsed["Diversos"] = v; DB.collapsed["Recém-obtidos"] = v
      Refresh()
    end
    root:CreateButton("Recolher todas", function() setAll(true) end)
    root:CreateButton("Expandir todas", function() setAll(nil) end)
    if items and #items > 0 then
      root:CreateDivider()
      root:CreateButton("Favoritar todos (protege de venda)", function()
        for _, it in ipairs(items) do if it.itemID then DB.favorites[it.itemID] = true end end
        Refresh()
      end)
      root:CreateButton("Desfavoritar todos", function()
        for _, it in ipairs(items) do if it.itemID then DB.favorites[it.itemID] = nil end end
        Refresh()
      end)
      if atBank and mode == "bags" then
        root:CreateDivider()
        root:CreateButton("Guardar tudo no banco", function() DepositCategoryToBank(items) end)
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
    DB.favorites[itemID] = true
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
  if not self.bag or not self.slot then return end
  -- ao olhar o item, ele deixa de ser "novo" (igual à bag da Blizzard)
  if C_NewItems and C_NewItems.RemoveNewItem then C_NewItems.RemoveNewItem(self.bag, self.slot) end
  if self.kbNewGlow then self.kbNewGlow:Hide() end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetBagItem(self.bag, self.slot)
  if self.itemID then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Direito: usar / equipar / abrir / vender", 0.5, 1, 0.5)
    GameTooltip:AddLine("Esquerdo: pegar / arrastar", 0.5, 1, 0.5)
    GameTooltip:AddLine("Estrela: clique = favoritar  |  direito = menu", 0.5, 1, 0.5)
    if self.kbStacked then GameTooltip:AddLine("Pilha visual — usar/vender afeta 1 stack", 1, 0.6, 0.3) end
  end
  GameTooltip:Show()
end

local function ToggleFavorite(itemID)
  if not itemID then return end
  DB.favorites[itemID] = (not DB.favorites[itemID]) or nil -- favorito = protegido
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
    -- selos próprios (nomes únicos kb* pra não colidir com campos do template nativo)
    b.kbIlvl = b:CreateFontString(nil, "OVERLAY")
    b.kbIlvl:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
    b.kbIlvl:SetPoint("TOPRIGHT", -2, -2); b.kbIlvl:Hide()
    b.kbBind = b:CreateFontString(nil, "OVERLAY")
    b.kbBind:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
    b.kbBind:SetPoint("BOTTOMLEFT", 2, 2); b.kbBind:SetTextColor(0.4, 1, 0.4); b.kbBind:Hide()
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
    star.tex = star:CreateTexture(nil, "OVERLAY"); star.tex:SetAllPoints()
    star.tex:SetAtlas("PetJournal-FavoritesIcon")
    b.kbStar = star
    local function updateStar()
      if b.itemID and DB.favorites[b.itemID] then
        star:Show(); star.tex:SetDesaturated(false); star.tex:SetAlpha(1)
      elseif b.itemID and b:IsMouseOver() then
        star:Show(); star.tex:SetDesaturated(true); star.tex:SetAlpha(0.4)
      else
        star:Hide()
      end
    end
    b.kbUpdateStar = updateStar
    star:SetScript("OnClick", function(_, mb)
      local id = b.itemID
      if not id then return end
      if mb == "RightButton" then OpenItemMenu(b) else ToggleFavorite(id) end
    end)
    star:SetScript("OnEnter", function(s)
      updateStar()
      GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
      GameTooltip:SetText("Esquerdo: favoritar (protege de venda)\nDireito: menu (mover p/ categoria)")
      GameTooltip:Show()
    end)
    star:SetScript("OnLeave", function() GameTooltip:Hide(); updateStar() end)
    b:SetScript("OnEnter", function(self) OnEnter(self); if self.kbUpdateStar then self.kbUpdateStar() end end)
    b:SetScript("OnLeave", function(self) GameTooltip:Hide(); if self.kbUpdateStar then self.kbUpdateStar() end end)
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
    eb:SetSize(62, 16)
    local fs = eb:GetFontString(); if fs then fs:SetTextScale(0.85) end
    eb:SetScript("OnClick", function(self)
      if InCombatLockdown() then
        print("|cfff0d98cKrononBags|r: não dá pra trocar equipamento em combate.")
        return
      end
      if self.setID and C_EquipmentSet then C_EquipmentSet.UseEquipmentSet(self.setID) end
    end)
    equipBtnPool[i] = eb
  end
  return eb
end

-- seção "Vazio": header + slot geral + slot reagentes (dentro do conteúdo rolável, x a partir de 0)
local function DrawEmpty(yOff)
  emptyHeader:ClearAllPoints(); emptyHeader:SetPoint("TOPLEFT", 0, yOff)
  emptyHeader:SetText("|cfff0d98cVazio|r"); emptyHeader:Show()
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

-- aplica tamanho da janela/scroll/conteúdo e atualiza a barra de rolagem.
-- contentH = altura total do conteúdo; viewport limita à altura máxima e o resto rola.
local function FinishLayout(contentH)
  local M = UI.kbMargin or MARGIN
  local BOT = UI.kbBottom or (MARGIN + 22)
  local TOP = (UI.kbTop or 34) + (atBank and 22 or 0)
  local cols = (DB.settings and DB.settings.cols) or COLS
  local contentW = cols * (BTN + PAD) - PAD
  local maxH = (DB.settings and DB.settings.maxHeight) or 520
  local viewportH = math.max(80, math.min(contentH, maxH))
  UI:SetWidth(contentW + M * 2 + SBW)
  UI:SetHeight(TOP + viewportH + BOT)
  if UI.scroll then
    UI.scroll:ClearAllPoints()
    UI.scroll:SetPoint("TOPLEFT", M, -TOP)
    UI.scroll:SetSize(contentW, viewportH)
    UI.content:SetSize(contentW, math.max(contentH, viewportH))
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
    if (not lvl or lvl <= 1) and ItemLocation then
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
  -- item de missão: borda dourada própria
  local qinfo = C_Container.GetContainerItemQuestInfo(bag, slot)
  if qinfo and (qinfo.isQuestItem or qinfo.questID) then b.kbQuest:Show() else b.kbQuest:Hide() end
  -- item novo
  if C_NewItems and C_NewItems.IsNewItem and C_NewItems.IsNewItem(bag, slot) then b.kbNewGlow:Show() else b.kbNewGlow:Hide() end
  -- seta verde de upgrade (integração opcional com o Pawn)
  -- usamos SEMPRE nossa própria textura: a região nativa b.UpgradeIcon existe no 12.0
  -- mas ficou SEM textura (API removida em 10.0.2), então mostrá-la não desenha nada.
  do
    local up = false
    if _G.PawnIsContainerItemAnUpgrade then
      local ok, res = pcall(_G.PawnIsContainerItemAnUpgrade, bag, slot)
      up = (ok and res) and true or false
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
  b:SetParent(GetBagHolder(bag))
  b:SetID(slot)
  b.bag, b.slot = bag, slot
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
    if MerchantFrame and MerchantFrame:IsShown() and IsProtected(info.itemID) then
      b:RegisterForClicks("LeftButtonUp")               -- favorito não vende (sem clique direito)
    else
      b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    end
  else
    b.itemID, b.itemName = nil, nil
    b:SetItemButtonTexture(nil)
    SetItemButtonCount(b, 0)
    if b.IconBorder then b.IconBorder:Hide() end
    if b.Cooldown then CooldownFrame_Set(b.Cooldown, 0, 0, 0) end
    if b.kbUpdateStar then b.kbUpdateStar() end
    ClearBadges(b)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  end
end

-- ---------------- Render: modo grade (todos os slots, estilo Blizzard) ----------------
RenderGrid = function()
  local cols = (DB.settings and DB.settings.cols) or COLS
  for _, b in ipairs(pool) do b:Hide() end
  for _, h in ipairs(headerPool) do h:Hide() end
  for _, eb in ipairs(equipBtnPool) do eb:Hide() end

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
    novo = function(it) return (DB.recem and DB.recem[it.itemID]) and true or false end,
    new = function(it) return (DB.recem and DB.recem[it.itemID]) and true or false end,
    favorito = function(it) return DB.favorites[it.itemID] and true or false end,
    fav = function(it) return DB.favorites[it.itemID] and true or false end,
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
  if C_NewItems and C_NewItems.RemoveNewItem then
    for _, bag in ipairs(ActiveBags()) do
      local slots = C_Container.GetContainerNumSlots(bag) or 0
      for slot = 1, slots do C_NewItems.RemoveNewItem(bag, slot) end
    end
  end
  Refresh()
end

-- ---------------- Render ----------------
Refresh = function()
  if not UI or not UI:IsShown() or not DB then return end
  -- em combate não dá pra reposicionar/alterar botões seguros: adia pro fim do combate
  if InCombatLockdown() then UI.refreshPending = true; return end
  RebuildEquipSets()
  local bags = ActiveBags()
  EnsureItemsCached(bags)
  if UI.distribBtn then UI.distribBtn:Hide() end -- esconde já (a grade não tem cabeçalho de seção)
  if DB.settings.gridView then return RenderGrid() end

  -- 1) coleta os itens
  local items = {}
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

  -- 2) busca avançada (operadores & | ! + palavras-chave; fallback p/ nome)
  if search ~= "" then
    local matcher = SearchMatcher(search)
    local filtered = {}
    for _, it in ipairs(items) do
      local hit
      if matcher then hit = matcher(it) else hit = it.name ~= "" and it.name:lower():find(search, 1, true) end
      if hit then filtered[#filtered + 1] = it end
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
  if UI.distribBtn then UI.distribBtn:Hide() end

  -- 5) desenha (dentro do conteúdo rolável: x a partir de 0, yOff a partir de 0)
  local cols = (DB.settings and DB.settings.cols) or COLS
  local contentW = cols * (BTN + PAD) - PAD
  local btnIdx, hdrIdx, ebIdx = 0, 0, 0
  local yOff = 0
  for _, cat in ipairs(order) do
    local g = groups[cat]
    if g and #g > 0 then
      hdrIdx = hdrIdx + 1
      local h = headerPool[hdrIdx]
      if not h then
        h = CreateFrame("Button", nil, UI.content)
        h:RegisterForClicks("LeftButtonUp", "RightButtonUp")
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
            GameTooltip:SetText("Soltar aqui: jogar item nesta categoria")
          else
            GameTooltip:SetText(DB.collapsed[self.cat] and "Esquerdo: expandir" or "Esquerdo: recolher")
            GameTooltip:AddLine("Direito: ações  ·  arraste um item aqui pra categorizar", 0.5, 1, 0.5)
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
      h.label:SetText("|T" .. sign .. ":14:14:0:0|t |cfff0d98c" .. cat .. "|r  |cff999999(" .. #g .. ")|r")
      h:Show()
      local setID = equipSetIDByName[cat]
      if setID then
        ebIdx = ebIdx + 1
        local eb = AcquireEquipButton(ebIdx)
        eb.setID = setID
        eb:SetText("Equipar")
        eb:SetFrameLevel(h:GetFrameLevel() + 5)
        eb:ClearAllPoints()
        eb:SetPoint("LEFT", h.label, "RIGHT", 10, 0)
        eb:Show()
      end
      -- botão "Distribuir" no cabeçalho de Recém-obtidos: manda tudo pras categorias certas
      if cat == "Recém-obtidos" then
        if not UI.distribBtn then
          local d = CreateFrame("Button", nil, UI.content, "UIPanelButtonTemplate")
          d:SetSize(72, 18); d:SetText("Distribuir")
          d:SetScript("OnClick", DistributeNew)
          d:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Distribuir recém-obtidos")
            GameTooltip:AddLine("Esvazia esta seção: cada item vai pra sua categoria.", 0.7, 0.7, 0.7, true)
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
      yOff = yOff - 18

      if not collapsed then
        local col = 0
        for _, it in ipairs(g) do
          btnIdx = btnIdx + 1
          local b = AcquireButton(btnIdx)
          FillButton(b, it.bag, it.slot)
          if it.stacked then SetItemButtonCount(b, it.count); b.kbStacked = true end -- contagem somada do empilhamento
          b:SetSize(BTN, BTN)
          b:ClearAllPoints()
          b:SetPoint("TOPLEFT", col * (BTN + PAD), yOff)
          b:Show()
          col = col + 1
          if col >= cols then col = 0; yOff = yOff - (BTN + PAD) end
        end
        if col > 0 then yOff = yOff - (BTN + PAD) end
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
  text = "Nome da nova categoria:",
  button1 = "Criar",
  button2 = "Cancelar",
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
  text = "Regra da categoria (busca que preenche sozinha).\nEx: ilvl>200 & boe   |   tipo:armadura   |   q:epico\nDeixe vazio pra virar categoria manual.",
  button1 = "Salvar",
  button2 = "Cancelar",
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
  text = "Copie o código (Ctrl+C) e compartilhe:",
  button1 = "Fechar",
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
  text = "Cole o código de categorias (mescla com as suas):",
  button1 = "Importar",
  button2 = "Cancelar",
  hasEditBox = true,
  editBoxWidth = 260,
  OnAccept = function(self)
    local eb = self.editBox or self.EditBox
    local ok, err = ImportCategories(eb and eb:GetText(), false)
    if ok then print("|cfff0d98cKrononBags|r: categorias importadas.")
    else print("|cfff0d98cKrononBags|r: import falhou (" .. tostring(err) .. ").") end
  end,
  EditBoxOnEscapePressed = function(self) local d = self:GetParent(); if d then d:Hide() end end,
  timeout = 0, whileDead = true, hideOnEscape = true,
}

-- ---------------- Janela ----------------
ApplyOpacity = function()
  if DB and DB.settings and DB.settings.frameStyle == "blizzard" then return end -- moldura nativa controla o fundo
  if not (UI and UI.SetBackdropColor) then return end
  local s = DB and DB.settings
  local op = (s and s.opacity) or 0.92
  if s and s.blizzardStyle then
    UI:SetBackdropColor(0.10, 0.11, 0.14, op) -- cinza-azulado (slate) estilo Blizzard
  else
    UI:SetBackdropColor(0, 0, 0, op)          -- preto (dark)
  end
end

UpdateMoney = function()
  if not goldText then return end
  goldText:SetText(GetMoneyString(GetMoney(), true))
  if freeNum then
    local free = 0
    if mode == "bags" then
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
    if junk > 0 then parts[#parts + 1] = "|cff808080Lixo|r " .. GetCoinTextureString(junk) end
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

-- mostra/esconde e destaca as abas (Mochila/Banco/Brigada) + botão de depositar
UpdateTabs = function()
  if not (UI and UI.tabs) then return end
  if UI.tabBar then UI.tabBar:SetShown(atBank) end
  for id, t in pairs(UI.tabs) do
    if id == "warband" then t:SetShown(atBank and WarbandAvailable()) end
    if id == mode then t:SetButtonState("PUSHED", true) else t:SetButtonState("NORMAL") end
  end
  if UI.depositBtn then UI.depositBtn:SetShown(atBank and (mode == "bank" or mode == "warband")) end
  if UI.sellJunkBtn then UI.sellJunkBtn:SetShown((MerchantFrame and MerchantFrame:IsShown()) and mode == "bags") end
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
  local ctrlY, gearAnchorX

  if blizzard then
    -- moldura NATIVA (igual à bag combinada): portrait + barra de título + X + inset
    UI.kbMargin, UI.kbTop, UI.kbBottom, ctrlY, gearAnchorX = 13, 60, 40, -32, -10
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
    title:SetPoint("LEFT", logo, "RIGHT", 5, -1); title:SetText("|cfff0d98cKrononBags|r")
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
  gear:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText("Configurações"); GameTooltip:Show() end)
  gear:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local sb = CreateFrame("EditBox", nil, UI, "InputBoxTemplate")
  sb:SetSize(150, 20); sb:SetPoint("RIGHT", gear, "LEFT", -10, 0); sb:SetAutoFocus(false)
  sb:SetScript("OnTextChanged", function(self) search = (self:GetText() or ""):lower(); Refresh() end)
  sb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  sb:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Busca avançada")
    GameTooltip:AddLine("nome  ·  ilvl>200  ·  ilvl:200-300  ·  q:epico  ·  tipo:armadura", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("palavras: boe, wb, vinculado, missao, lixo, equip, consumivel, novo, favorito", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("operadores:  & (e)   | (ou)   ! (não)   ( )", 0.5, 1, 0.5)
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
  sortBtn:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText("Organizar automático"); GameTooltip:Show() end)
  sortBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

  -- botão "Vender lixo" (só aparece no vendedor, modo Mochila); API nativa, sem taint
  local sellJunk = CreateFrame("Button", nil, UI, "UIPanelButtonTemplate")
  sellJunk:SetSize(86, 20)
  sellJunk:SetPoint("RIGHT", sortBtn, "LEFT", -6, 0)
  sellJunk:SetText("Vender lixo")
  sellJunk:SetScript("OnClick", function()
    if InCombatLockdown() then return end
    if C_MerchantFrame and C_MerchantFrame.SellAllJunkItems then
      C_MerchantFrame.SellAllJunkItems()
    else
      print("|cfff0d98cKrononBags|r: função de vender lixo indisponível nesta versão.")
    end
  end)
  sellJunk:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Vende todos os itens cinza (lixo)")
    GameTooltip:AddLine("Usa a venda nativa do jogo. Cuidado: cinza favoritado também é vendido.", 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
  end)
  sellJunk:SetScript("OnLeave", function() GameTooltip:Hide() end)
  UI.sellJunkBtn = sellJunk; sellJunk:Hide()

  goldText = UI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  goldText:SetPoint("BOTTOMRIGHT", UI, "BOTTOMRIGHT", blizzard and -24 or -20, blizzard and 12 or 7) -- folga p/ a alça

  currencyText = UI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  currencyText:SetJustifyH("LEFT")
  currencyText:SetPoint("BOTTOMLEFT", UI, "BOTTOMLEFT", blizzard and 12 or 8, blizzard and 12 or 7)
  currencyText:SetPoint("RIGHT", goldText, "LEFT", -10, 0)

  -- seção "Vazio": 2 slots grandes (geral + reagentes), clicáveis = alternar grade
  local function toggleGrid()
    DB.settings.gridView = not DB.settings.gridView
    Refresh()
  end
  local function gridTip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(DB.settings.gridView and "Ver por categorias" or "Ver todos os slots (grade)")
    GameTooltip:Show()
  end

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
  sbar:Hide()
  UI.sb = sbar
  UI.scroll:SetScript("OnMouseWheel", function(_, delta)
    local _, maxv = UI.sb:GetMinMaxValues()
    if (maxv or 0) <= 0 then return end
    local nv = math.max(0, math.min(maxv, (UI.sb:GetValue() or 0) - delta * (BTN + PAD)))
    UI.sb:SetValue(nv)
  end)

  emptyHeader = UI.content:CreateFontString(nil, "OVERLAY", "GameFontNormal"); emptyHeader:Hide()

  freeBox = CreateFrame("Button", nil, UI.content)
  freeBox.bg = freeBox:CreateTexture(nil, "BACKGROUND"); freeBox.bg:SetAllPoints(); freeBox.bg:SetAtlas("bags-item-slot64")
  freeBox.border = freeBox:CreateTexture(nil, "ARTWORK"); freeBox.border:SetAllPoints(); freeBox.border:SetTexture("Interface\\Common\\WhiteIconFrame"); freeBox.border:SetVertexColor(0.4, 0.4, 0.45, 0.7)
  freeNum = freeBox:CreateFontString(nil, "OVERLAY", "NumberFontNormal"); freeNum:SetPoint("BOTTOMRIGHT", -2, 2)
  freeBox:SetScript("OnClick", toggleGrid)
  freeBox:SetScript("OnEnter", gridTip)
  freeBox:SetScript("OnLeave", function() GameTooltip:Hide() end)
  freeBox:Hide()

  reagentBox = CreateFrame("Button", nil, UI.content)
  reagentBox.bg = reagentBox:CreateTexture(nil, "BACKGROUND"); reagentBox.bg:SetAllPoints(); reagentBox.bg:SetAtlas("bags-item-slot64")
  reagentBox.border = reagentBox:CreateTexture(nil, "ARTWORK"); reagentBox.border:SetAllPoints(); reagentBox.border:SetTexture("Interface\\Common\\WhiteIconFrame"); reagentBox.border:SetVertexColor(0.4, 0.4, 0.45, 0.7)
  reagentNum = reagentBox:CreateFontString(nil, "OVERLAY", "NumberFontNormal"); reagentNum:SetPoint("BOTTOMRIGHT", -2, 2)
  reagentBox:SetScript("OnClick", toggleGrid)
  reagentBox:SetScript("OnEnter", gridTip)
  reagentBox:SetScript("OnLeave", function() GameTooltip:Hide() end)
  reagentBox:Hide()

  -- abas Mochila/Banco/Brigada (aparecem só com o banco aberto) + depositar automático
  local tabBar = CreateFrame("Frame", nil, UI)
  tabBar:SetSize(10, 20)
  tabBar:SetPoint("TOPLEFT", UI, "TOPLEFT", UI.kbMargin, -(UI.kbTop - 2))
  UI.tabBar = tabBar; UI.tabs = {}
  local tdefs = { { id = "bags", t = "Mochila" }, { id = "bank", t = "Banco" }, { id = "warband", t = "Brigada" } }
  local tx = 0
  for _, d in ipairs(tdefs) do
    local tb = CreateFrame("Button", nil, tabBar, "UIPanelButtonTemplate")
    tb:SetSize(70, 18); tb:SetText(d.t); tb:SetPoint("LEFT", tx, 0); tx = tx + 73
    tb.mode = d.id
    tb:SetScript("OnClick", function() mode = tb.mode; UpdateTabs(); Refresh() end)
    UI.tabs[d.id] = tb
  end
  local dep = CreateFrame("Button", nil, tabBar, "UIPanelButtonTemplate")
  dep:SetSize(120, 18); dep:SetText("Depositar itens"); dep:SetPoint("LEFT", tx + 8, 0)
  dep:SetScript("OnClick", function()
    if InCombatLockdown() then return end
    local bt = (mode == "warband") and BANK_ACCT or BANK_CHAR
    if C_Bank and C_Bank.AutoDepositItemsIntoBank then pcall(C_Bank.AutoDepositItemsIntoBank, bt) end
  end)
  dep:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Guarda automaticamente os itens marcados pra depósito neste banco")
    GameTooltip:Show()
  end)
  dep:SetScript("OnLeave", function() GameTooltip:Hide() end)
  UI.depositBtn = dep
  tabBar:Hide()

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
    local TOP = (UI.kbTop or 34) + (atBank and 22 or 0)
    local BOT = UI.kbBottom or (MARGIN + 22)
    DB.settings.maxHeight = math.max(120, math.floor(UI:GetHeight() - TOP - BOT)) -- altura visível arrastada
    Refresh() -- recalcula largura/altura/scroll pro novo tamanho
  end)
  grip:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText("Arraste pra mudar colunas e altura"); GameTooltip:Show()
  end)
  grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
  UI.grip = grip

  -- ESC fecha a janela (igual à bag do jogo)
  tinsert(UISpecialFrames, "KrononBagsFrame")

  -- ao esconder (X, /kb ou auto), zera a flag de auto-aberta pra não fechar janela manual
  UI:HookScript("OnHide", function(self) self.autoOpened = false end)

  -- restaura a posição salva deste personagem (se houver)
  local sp = DB.charPos and DB.charPos[CharKey()]
  if sp and sp[1] then
    UI:ClearAllPoints()
    UI:SetPoint(sp[1], UIParent, sp[2] or sp[1], sp[3] or 0, sp[4] or 0)
  end

  ApplyOpacity()
  UI:Hide()
end

Toggle = function()
  if not UI then CreateUI() end
  if UI:IsShown() then UI:Hide() else UI:Show(); Refresh() end
end

-- ---------------- Configurações (extensível) ----------------
local catRows = {}
local CAT_LIST_TOP = -458
RefreshConfigCats = function()
  if not CFG then return end
  for _, r in ipairs(catRows) do r:Hide() end
  local y = CAT_LIST_TOP
  local n = #DB.catList
  for i, c in ipairs(DB.catList) do
    local r = catRows[i]
    if not r then
      r = CreateFrame("Frame", nil, CFG)
      r:SetSize(360, 20)
      r.up = CreateFrame("Button", nil, r)
      r.up:SetSize(18, 18); r.up:SetPoint("LEFT", 4, 0)
      r.up:SetNormalTexture("Interface\\Buttons\\Arrow-Up-Up")
      r.up:SetPushedTexture("Interface\\Buttons\\Arrow-Up-Down")
      r.up:SetHighlightTexture("Interface\\Buttons\\Arrow-Up-Up", "ADD")
      r.down = CreateFrame("Button", nil, r)
      r.down:SetSize(18, 18); r.down:SetPoint("LEFT", r.up, "RIGHT", 2, 0)
      r.down:SetNormalTexture("Interface\\Buttons\\Arrow-Down-Up")
      r.down:SetPushedTexture("Interface\\Buttons\\Arrow-Down-Down")
      r.down:SetHighlightTexture("Interface\\Buttons\\Arrow-Down-Up", "ADD")
      r.label = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      r.label:SetPoint("LEFT", r.down, "RIGHT", 8, 0)
      r.del = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
      r.del:SetSize(56, 18); r.del:SetText("Excluir"); r.del:SetPoint("RIGHT", -6, 0)
      r.rule = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
      r.rule:SetSize(52, 18); r.rule:SetText("Regra"); r.rule:SetPoint("RIGHT", r.del, "LEFT", -4, 0)
      catRows[i] = r
    end
    local tag
    if c.filter then tag = "|cff80c0ff(pré-pronta)|r"
    elseif c.rule and c.rule ~= "" then tag = "|cffffd000(regra)|r"
    else tag = "|cff80ff80(sua)|r" end
    r.label:SetText(c.name .. "  " .. tag)
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
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", 16, y); r:Show()
    y = y - 22
  end
  CFG:SetHeight(math.max(494, -y + 30)) -- +espaço pro rodapé de créditos
end

CreateConfig = function()
  CFG = CreateFrame("Frame", "KrononBagsConfig", UIParent, "BackdropTemplate")
  CFG:SetSize(400, 494)
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
  title:SetPoint("TOP", 0, -12); title:SetText("|cfff0d98cKrononBags — Configurações|r")

  local close = CreateFrame("Button", nil, CFG, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 2)

  -- créditos (rodapé) — versão lida do .toc automaticamente
  local ver = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")) or ""
  CFG.kbCredits = CFG:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  CFG.kbCredits:SetPoint("BOTTOM", CFG, "BOTTOM", 0, 9)
  CFG.kbCredits:SetText("|cff9d9d9dKrononBags v" .. ver .. "  ·  Kronon  ·  discord.gg/yFdQsFewN3|r")

  -- helpers de layout: seção (título + linha) e checkbox
  local function section(text, y)
    local h = CFG:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetPoint("TOPLEFT", 16, y); h:SetText("|cfff0d98c" .. text .. "|r")
    local d = CFG:CreateTexture(nil, "ARTWORK")
    d:SetColorTexture(0.4, 0.4, 0.45, 0.5); d:SetHeight(1)
    d:SetPoint("TOPLEFT", 14, y - 15); d:SetPoint("TOPRIGHT", -14, y - 15)
  end
  local function check(name, x, y, label, getf, setf)
    local c = CreateFrame("CheckButton", name, CFG, "UICheckButtonTemplate")
    c:SetPoint("TOPLEFT", x, y)
    local lbl = c.Text or _G[name .. "Text"]
    if lbl then lbl:SetText(label) end
    c:SetChecked(getf())
    c:SetScript("OnClick", function(self) setf(self:GetChecked() and true or false) end)
    return c
  end
  local LCOL, RCOL = 16, 205

  -- ===== Aparência =====
  section("Aparência", -44)
  check("KrononBagsFrameStyleCheck", LCOL, -66, "Moldura Blizzard", function() return DB.settings.frameStyle == "blizzard" end, function(v)
    DB.settings.frameStyle = v and "blizzard" or "dark"
    print("|cfff0d98cKrononBags|r: dê |cffffff00/reload|r pra aplicar o novo visual.")
  end)
  check("KrononBagsBlizzColorsCheck", RCOL, -66, "Cores Blizzard (escuro)", function() return DB.settings.blizzardStyle end, function(v)
    DB.settings.blizzardStyle = v; ApplyOpacity()
  end)
  check("KrononBagsShowIlvlCheck", LCOL, -94, "Mostrar item level", function() return DB.settings.showIlvl end, function(v)
    DB.settings.showIlvl = v; Refresh()
  end)
  check("KrononBagsIlvlRarityCheck", RCOL, -94, "ilvl pela raridade", function() return DB.settings.ilvlUseRarity end, function(v)
    DB.settings.ilvlUseRarity = v; Refresh()
  end)

  local opLabel = CFG:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  opLabel:SetPoint("TOPLEFT", 18, -124)
  local function setOpLabel(v) opLabel:SetText(string.format("Opacidade do fundo: %d%%", math.floor(v * 100 + 0.5))) end
  local slider = CreateFrame("Slider", "KrononBagsOpacitySlider", CFG, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", 18, -144); slider:SetWidth(360)
  slider:SetMinMaxValues(0.1, 1.0); slider:SetValueStep(0.05); slider:SetObeyStepOnDrag(true)
  local low  = slider.Low  or _G["KrononBagsOpacitySliderLow"];  if low  then low:SetText("10%")   end
  local high = slider.High or _G["KrononBagsOpacitySliderHigh"]; if high then high:SetText("100%") end
  local txt  = slider.Text or _G["KrononBagsOpacitySliderText"]; if txt  then txt:SetText("")       end
  slider:SetValue((DB.settings and DB.settings.opacity) or 0.92)
  setOpLabel((DB.settings and DB.settings.opacity) or 0.92)
  slider:SetScript("OnValueChanged", function(_, v) DB.settings.opacity = v; setOpLabel(v); ApplyOpacity() end)

  local colLabel = CFG:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  colLabel:SetPoint("TOPLEFT", 18, -176)
  local function setColLabel(v) colLabel:SetText(string.format("Colunas (itens por fileira): %d", v)) end
  local colSlider = CreateFrame("Slider", "KrononBagsColsSlider", CFG, "OptionsSliderTemplate")
  colSlider:SetPoint("TOPLEFT", 18, -196); colSlider:SetWidth(360)
  colSlider:SetMinMaxValues(COLS_MIN, COLS_MAX); colSlider:SetValueStep(1); colSlider:SetObeyStepOnDrag(true)
  local cLow  = colSlider.Low  or _G["KrononBagsColsSliderLow"];  if cLow  then cLow:SetText(COLS_MIN) end
  local cHigh = colSlider.High or _G["KrononBagsColsSliderHigh"]; if cHigh then cHigh:SetText(COLS_MAX) end
  local cTxt  = colSlider.Text or _G["KrononBagsColsSliderText"]; if cTxt  then cTxt:SetText("")     end
  colSlider:SetValue((DB.settings and DB.settings.cols) or 14)
  setColLabel((DB.settings and DB.settings.cols) or 14)
  colSlider:SetScript("OnValueChanged", function(_, v) v = math.floor(v + 0.5); DB.settings.cols = v; setColLabel(v); Refresh() end)

  -- ===== Comportamento =====
  section("Comportamento", -230)
  check("KrononBagsAutoProtectCheck", LCOL, -252, "Proteger itens (não vender)", function() return DB.settings.autoProtectCategorized end, function(v)
    DB.settings.autoProtectCategorized = v; Refresh()
  end)
  check("KrononBagsAutoOpenCheck", RCOL, -252, "Abrir no vendedor/banco", function() return DB.settings.autoOpen end, function(v)
    DB.settings.autoOpen = v
  end)
  check("KrononBagsBankReplaceCheck", LCOL, -280, "Substituir banco / Brigada", function() return DB.settings.bankReplace end, function(v)
    DB.settings.bankReplace = v
    print("|cfff0d98cKrononBags|r: dê |cffffff00/reload|r pra aplicar a troca de banco.")
  end)
  check("KrononBagsAltCountsCheck", RCOL, -280, "Contagem nos alts (tooltip)", function() return DB.settings.altCounts end, function(v)
    DB.settings.altCounts = v
  end)
  check("KrononBagsReplaceBagsCheck", LCOL, -308, "Substituir a bag do jogo (tecla B)", function() return DB.settings.replaceBags end, function(v)
    DB.settings.replaceBags = v
    print("|cfff0d98cKrononBags|r: dê |cffffff00/reload|r pra aplicar a troca da bag.")
  end)
  check("KrononBagsStackCheck", RCOL, -308, "Empilhar itens iguais", function() return DB.settings.stackItems end, function(v)
    DB.settings.stackItems = v; Refresh()
  end)
  -- seletor de ordenação dentro da categoria
  local SORT_NAMES = { ilvl = "Item level", quality = "Qualidade", name = "Nome", type = "Tipo", recent = "Recentes" }
  local sortBtn = CreateFrame("Button", nil, CFG, "UIPanelButtonTemplate")
  sortBtn:SetSize(180, 20); sortBtn:SetPoint("TOPLEFT", 18, -334)
  local function updSortBtn() sortBtn:SetText("Ordenar por: " .. (SORT_NAMES[DB.settings.sortMode] or "Item level")) end
  updSortBtn()
  sortBtn:SetScript("OnClick", function(self)
    if not MenuUtil then return end
    MenuUtil.CreateContextMenu(self, function(owner, root)
      root:CreateTitle("Ordenar itens por")
      for _, k in ipairs({ "ilvl", "quality", "name", "type", "recent" }) do
        root:CreateButton(SORT_NAMES[k], function() DB.settings.sortMode = k; updSortBtn(); Refresh() end)
      end
    end)
  end)

  -- ===== Categorias =====
  section("Categorias", -366)
  local catHint = CFG:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  catHint:SetPoint("TOPLEFT", 18, -384)
  catHint:SetText("Ordem (cima → baixo) = ordem no inventário. ▲▼ move, Excluir remove.")

  local newCat = CreateFrame("EditBox", "KrononBagsNewCatEdit", CFG, "InputBoxTemplate")
  newCat:SetSize(150, 20); newCat:SetPoint("TOPLEFT", 22, -406); newCat:SetAutoFocus(false)
  local addBtn = CreateFrame("Button", nil, CFG, "UIPanelButtonTemplate")
  addBtn:SetSize(60, 20); addBtn:SetText("Criar"); addBtn:SetPoint("LEFT", newCat, "RIGHT", 8, 0)
  local presetBtn = CreateFrame("Button", nil, CFG, "UIPanelButtonTemplate")
  presetBtn:SetSize(96, 20); presetBtn:SetText("Pré-pronta…"); presetBtn:SetPoint("LEFT", addBtn, "RIGHT", 8, 0)
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
      root:CreateTitle("Adicionar categoria pré-pronta")
      local any = false
      for _, p in ipairs(AVAILABLE_PRESETS) do
        local exists = false
        for _, c in ipairs(DB.catList) do if c.filter == p.filter then exists = true break end end
        if not exists then
          any = true
          root:CreateButton(p.name, function() AddPreset(p); RefreshConfigCats(); Refresh() end)
        end
      end
      if not any then root:CreateButton("|cff999999(todas já adicionadas)|r", function() end) end
    end)
  end)

  -- Exportar / Importar (Layout Oficial da Guilda)
  local exportBtn = CreateFrame("Button", nil, CFG, "UIPanelButtonTemplate")
  exportBtn:SetSize(110, 20); exportBtn:SetText("Exportar"); exportBtn:SetPoint("TOPLEFT", 22, -432)
  exportBtn:SetScript("OnClick", function()
    KB_exportStr = ExportCategories(); StaticPopup_Show("KRONONBAGS_EXPORT")
  end)
  local importBtn = CreateFrame("Button", nil, CFG, "UIPanelButtonTemplate")
  importBtn:SetSize(110, 20); importBtn:SetText("Importar"); importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
  importBtn:SetScript("OnClick", function() StaticPopup_Show("KRONONBAGS_IMPORT") end)

  CFG:Hide()
end

ToggleConfig = function()
  if not CFG then CreateConfig() end
  if CFG:IsShown() then CFG:Hide() else RefreshConfigCats(); CFG:Show() end
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
  if dur then rows[#rows + 1] = line("Durabilidade", math.floor(dur) .. "%", dur >= 30)
  else rows[#rows + 1] = line("Durabilidade", "—", true) end
  rows[#rows + 1] = line("Frasco", s.flask > 0 and tostring(s.flask) or "falta", s.flask > 0)
  rows[#rows + 1] = line("Poção", s.potion > 0 and tostring(s.potion) or "falta", s.potion > 0)
  rows[#rows + 1] = line("Comida", s.food > 0 and tostring(s.food) or "falta", s.food > 0)
  rows[#rows + 1] = line("Pedra de Vida", s.hs > 0 and tostring(s.hs) or "falta", s.hs > 0)
  rows[#rows + 1] = line("Runa/encantamento", s.rune > 0 and tostring(s.rune) or "falta", s.rune > 0)
  rows[#rows + 1] = line("Pedra-chave M+", (kLvl and kLvl > 0) and ("+" .. kLvl) or "nenhuma", kLvl and kLvl > 0)
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
    title:SetPoint("TOP", 0, -10); title:SetText("|cfff0d98cProntidão|r")
    local close = CreateFrame("Button", nil, READY, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", 2, 2)
    READY.body = READY:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    READY.body:SetPoint("TOPLEFT", 16, -40); READY.body:SetJustifyH("LEFT"); READY.body:SetSpacing(6)
    local hint = READY:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOM", 0, 10); hint:SetText("Suprimentos contados na mochila")
    READY:HookScript("OnShow", RefreshReady)
  end
  if READY:IsShown() then READY:Hide() else READY:Show(); RefreshReady() end
end

-- ---------------- Substituir o banco nativo ----------------
-- Reparenta o BankFrame pra um frame escondido: some da tela SEM disparar OnHide
-- (que fecharia a sessão do banco). A sessão segue aberta no servidor, então
-- C_Bank/C_Container continuam respondendo e nós desenhamos o banco na nossa janela.
local bankHider
local function SuppressDefaultBank()
  if not (DB and DB.settings and DB.settings.bankReplace) then return end
  if not BankFrame then return end
  if not bankHider then bankHider = CreateFrame("Frame"); bankHider:Hide() end
  pcall(function() BankFrame:SetParent(bankHider) end)
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
end
local function CaptureBank()
  if not DB then return end
  local k = CharKey()
  DB.charItems[k] = DB.charItems[k] or {}
  DB.charItems[k].bank = ScanCounts(PurchasedTabs(BANK_CHAR))
  local wb = PurchasedTabs(BANK_ACCT)
  if #wb > 0 then DB.warband = ScanCounts(wb) end
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
  if wb and wb > 0 then lines[#lines + 1] = "|cff00ccffBrigada|r: " .. wb end
  if #lines > 0 then tooltip:AddLine("|cfff0d98cKronon|r  " .. table.concat(lines, "   "), 1, 1, 1) end
end
-- registra o hook de tooltip (API moderna do 12.0); silencioso se ausente
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
    if tooltip == GameTooltip and data and data.id then AddCountsToTooltip(tooltip, data.id) end
  end)
end

-- ---------------- Eventos / comandos ----------------
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:RegisterEvent("EQUIPMENT_SETS_CHANGED")
f:RegisterEvent("PLAYER_MONEY")
f:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
f:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
f:RegisterEvent("BAG_UPDATE_COOLDOWN")
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
  elseif event == "PLAYER_LOGOUT" then
    CaptureBags() -- snapshot da mochila pra contagem nos alts
  elseif event == "PLAYER_MONEY" or event == "CURRENCY_DISPLAY_UPDATE" then
    if UI and UI:IsShown() then UpdateMoney() end
  elseif event == "BAG_UPDATE_COOLDOWN" then
    if UI and UI:IsShown() then UpdateCooldowns() end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if UI and UI.refreshPending and UI:IsShown() then UI.refreshPending = nil; Refresh() end
  elseif event == "MERCHANT_SHOW" then
    AutoShow(); if UI then UpdateTabs() end; Refresh() -- bloquear venda de protegidos + botão vender lixo
  elseif event == "MERCHANT_CLOSED" then
    AutoHide(); if UI then UpdateTabs() end; Refresh() -- restaura usar/equipar; esconde vender lixo
  elseif event == "BANKFRAME_OPENED" then
    if DB and DB.settings and DB.settings.bankReplace then
      atBank = true; SuppressDefaultBank(); mode = "bank"
      AutoShow(); if UI then UpdateTabs() end; Refresh()
    else
      AutoShow() -- banco nativo cuida do banco; só abrimos a mochila
    end
  elseif event == "BANKFRAME_CLOSED" then
    atBank = false; mode = "bags"
    if UI then UpdateTabs() end
    AutoHide(); if UI and UI:IsShown() then Refresh() end
  elseif event == "MAIL_SHOW" then
    AutoShow()
  elseif event == "MAIL_CLOSED" then
    AutoHide()
  else -- BAG_UPDATE_DELAYED, EQUIPMENT_SETS_CHANGED, BAG_NEW_ITEMS_UPDATED
    Refresh(); RefreshReady()
    if DB and DB.settings and DB.settings.altCounts then -- mantém snapshot dos alts fresco (só se ligado)
      CaptureBags(); if atBank then CaptureBank() end
    end
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
  elseif msg == "pronto" or msg == "prontidao" or msg == "prontidão" or msg == "readiness" then
    ToggleReady()
  else
    Toggle()
  end
end
