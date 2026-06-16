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
local ApplyOpacity, CreateConfig, ToggleConfig, UpdateMoney

local BAGS = { 0, 1, 2, 3, 4, 5 } -- mochila + 4 bolsas + bolsa de reagentes
local COLS = 14
local BTN  = 37
local PAD  = 4
local search = ""

local pool = {}        -- pool de botões de item
local headerPool = {}  -- pool de cabeçalhos de seção

-- catálogo de categorias pré-prontas (ordem de fresh install + menu "Pré-pronta…")
local KB_PRESETS = {
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

-- filtros recebem (itemID, quality, bag). "reagentbag" e "keystone" são especiais.
local PRESET_FILTERS = {
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

-- resolve a categoria final de um item:
-- 1) manual (custom)  2) conjunto de equipamento  3) 1º preset que casa (na ordem da lista)  4) Diversos
ResolveCat = function(itemID, quality, bag)
  local a = DB.assignments[itemID]
  if a and CategoryExists(a) then return a end
  local s = equipSetByItem[itemID]
  if s then return s end
  for _, c in ipairs(DB.catList) do
    if c.filter then
      local fn = PRESET_FILTERS[c.filter]
      if fn and fn(itemID, quality, bag) then return c.name end
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
    h = CreateFrame("Frame", nil, UI)
    h:SetID(bag)
    h:SetAllPoints(UI)
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
    -- estrela: favoritar (esquerdo) + menu (direito) — botão separado, acima do item
    local star = CreateFrame("Button", nil, b)
    star:SetSize(14, 14); star:SetPoint("TOPLEFT", -1, 1)
    star:SetFrameLevel(b:GetFrameLevel() + 5)
    star:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    star.tex = star:CreateTexture(nil, "OVERLAY"); star.tex:SetAllPoints()
    star.tex:SetAtlas("PetJournal-FavoritesIcon")
    star:SetScript("OnClick", function(_, mb)
      local id = b.itemID
      if not id then return end
      if mb == "RightButton" then OpenItemMenu(b) else ToggleFavorite(id) end
    end)
    star:SetScript("OnEnter", function(s)
      GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
      GameTooltip:SetText("Esquerdo: favoritar (protege de venda)\nDireito: menu (mover p/ categoria)")
      GameTooltip:Show()
    end)
    star:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b.kbStar = star
    b:SetScript("OnEnter", OnEnter)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    pool[i] = b
  end
  return b
end

-- botão "Equipar" para seções de Conjunto de Equipamento
local equipBtnPool = {}
local function AcquireEquipButton(i)
  local eb = equipBtnPool[i]
  if not eb then
    eb = CreateFrame("Button", nil, UI, "UIPanelButtonTemplate")
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

-- seção "Vazio": header + slot geral + slot reagentes (tamanho de item, clicáveis)
local function DrawEmpty(yOff)
  emptyHeader:ClearAllPoints(); emptyHeader:SetPoint("TOPLEFT", PAD + 2, yOff)
  emptyHeader:SetText("|cfff0d98cVazio|r"); emptyHeader:Show()
  yOff = yOff - 18
  freeBox:SetSize(BTN, BTN); freeBox:ClearAllPoints(); freeBox:SetPoint("TOPLEFT", PAD, yOff); freeBox:Show()
  if (C_Container.GetContainerNumSlots(5) or 0) > 0 then
    reagentBox:SetSize(BTN, BTN); reagentBox:ClearAllPoints()
    reagentBox:SetPoint("TOPLEFT", PAD + (BTN + PAD), yOff); reagentBox:Show()
  else
    reagentBox:Hide()
  end
  return yOff - (BTN + PAD) - 6
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
end

local function ClearBadges(b)
  b.kbIlvl:Hide(); b.kbBind:Hide(); b.kbNewGlow:Hide(); b.kbQuest:Hide()
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
    b.kbStar:Show()
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
    b.kbStar:Hide()
    ClearBadges(b)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  end
end

-- ---------------- Render: modo grade (todos os slots, estilo Blizzard) ----------------
RenderGrid = function()
  local cols = (DB.settings and DB.settings.cols) or COLS
  UI:SetWidth(cols * (BTN + PAD) + PAD * 2)
  for _, b in ipairs(pool) do b:Hide() end
  for _, h in ipairs(headerPool) do h:Hide() end
  for _, eb in ipairs(equipBtnPool) do eb:Hide() end

  local idx, col = 0, 0
  local yOff = -34
  for _, bag in ipairs(BAGS) do
    local slots = C_Container.GetContainerNumSlots(bag) or 0
    for slot = 1, slots do
      idx = idx + 1
      local b = AcquireButton(idx)
      FillButton(b, bag, slot)
      b:SetSize(BTN, BTN); b:ClearAllPoints()
      b:SetPoint("TOPLEFT", PAD + col * (BTN + PAD), yOff)
      b:Show()
      col = col + 1
      if col >= cols then col = 0; yOff = yOff - (BTN + PAD) end
    end
  end
  if col > 0 then yOff = yOff - (BTN + PAD) end
  yOff = DrawEmpty(yOff)
  UpdateMoney()
  UI:SetHeight(math.max(-yOff + PAD + 22, 140))
end

-- ---------------- Render ----------------
Refresh = function()
  if not UI or not UI:IsShown() or not DB then return end
  -- em combate não dá pra reposicionar/alterar botões seguros: adia pro fim do combate
  if InCombatLockdown() then UI.refreshPending = true; return end
  RebuildEquipSets()
  if DB.settings.gridView then return RenderGrid() end

  -- 1) coleta os itens
  local items = {}
  for _, bag in ipairs(BAGS) do
    local slots = C_Container.GetContainerNumSlots(bag) or 0
    for slot = 1, slots do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.itemID then
        local name = C_Item.GetItemInfo(info.hyperlink) or ""
        items[#items + 1] = {
          bag = bag, slot = slot, itemID = info.itemID, link = info.hyperlink,
          icon = info.iconFileID, count = info.stackCount, quality = info.quality,
          name = name, ilvl = GetIlvl(info.hyperlink), bound = info.isBound,
          cat = ResolveCat(info.itemID, info.quality, bag),
        }
      end
    end
  end

  -- 2) busca
  if search ~= "" then
    local q, filtered = search, {}
    for _, it in ipairs(items) do
      if it.name ~= "" and it.name:lower():find(q, 1, true) then filtered[#filtered + 1] = it end
    end
    items = filtered
  end

  -- 3) agrupa + ordena por ilvl/nome
  local groups = {}
  for _, it in ipairs(items) do
    groups[it.cat] = groups[it.cat] or {}
    table.insert(groups[it.cat], it)
  end
  for _, g in pairs(groups) do
    table.sort(g, function(a, b)
      if a.ilvl ~= b.ilvl then return a.ilvl > b.ilvl end
      return a.name < b.name
    end)
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

  -- 5) desenha
  local cols = (DB.settings and DB.settings.cols) or COLS
  UI:SetWidth(cols * (BTN + PAD) + PAD * 2)
  local btnIdx, hdrIdx, ebIdx = 0, 0, 0
  local yOff = -34
  for _, cat in ipairs(order) do
    local g = groups[cat]
    if g and #g > 0 then
      hdrIdx = hdrIdx + 1
      local h = headerPool[hdrIdx]
      if not h then
        h = CreateFrame("Button", nil, UI)
        h:RegisterForClicks("LeftButtonUp")
        h.label = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.label:SetPoint("LEFT", 0, 0)
        h:SetScript("OnClick", function(self)
          if self.cat then DB.collapsed[self.cat] = (not DB.collapsed[self.cat]) or nil; Refresh() end
        end)
        h:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
          GameTooltip:SetText(DB.collapsed[self.cat] and "Clique pra expandir" or "Clique pra recolher")
          GameTooltip:Show()
        end)
        h:SetScript("OnLeave", function() GameTooltip:Hide() end)
        headerPool[hdrIdx] = h
      end
      h.cat = cat
      local collapsed = DB.collapsed[cat]
      h:SetSize(cols * (BTN + PAD), 16)
      h:ClearAllPoints(); h:SetPoint("TOPLEFT", PAD + 2, yOff)
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
      yOff = yOff - 18

      if not collapsed then
        local col = 0
        for _, it in ipairs(g) do
          btnIdx = btnIdx + 1
          local b = AcquireButton(btnIdx)
          FillButton(b, it.bag, it.slot)
          b:SetSize(BTN, BTN)
          b:ClearAllPoints()
          b:SetPoint("TOPLEFT", PAD + col * (BTN + PAD), yOff)
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
  UI:SetHeight(math.max(-yOff + PAD + 22, 140))
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

-- ---------------- Janela ----------------
ApplyOpacity = function()
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
    for bag = 0, 4 do free = free + (C_Container.GetContainerNumFreeSlots(bag) or 0) end
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

CreateUI = function()
  UI = CreateFrame("Frame", "KrononBagsFrame", UIParent, "BackdropTemplate")
  UI:SetSize(COLS * (BTN + PAD) + PAD * 2, 400)
  UI:SetPoint("CENTER")
  UI:SetFrameStrata("HIGH")
  UI:SetClampedToScreen(true)
  UI:SetMovable(true); UI:EnableMouse(true); UI:RegisterForDrag("LeftButton")
  UI:SetScript("OnDragStart", UI.StartMoving)
  UI:SetScript("OnDragStop", UI.StopMovingOrSizing)
  if UI.SetBackdrop then
    UI:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    UI:SetBackdropColor(0, 0, 0, (DB.settings and DB.settings.opacity) or 0.92)
  end

  -- ---- header compacto estilo Blizzard: título ... [organizar] [busca] [engrenagem] [X] ----
  local title = UI:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 10, -9); title:SetText("|cfff0d98cKrononBags|r")

  local close = CreateFrame("Button", nil, UI, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 2)

  -- engrenagem (mantida exatamente como estava — "perfeita")
  local gear = CreateFrame("Button", nil, UI)
  gear:SetSize(22, 22)
  gear:SetPoint("RIGHT", close, "LEFT", 0, 0)
  gear:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
  gear:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton", "ADD")
  gear:SetScript("OnClick", function() ToggleConfig() end)
  gear:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText("Configurações"); GameTooltip:Show() end)
  gear:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local sb = CreateFrame("EditBox", nil, UI, "InputBoxTemplate")
  sb:SetSize(150, 20); sb:SetPoint("RIGHT", gear, "LEFT", -10, 0); sb:SetAutoFocus(false)
  sb:SetScript("OnTextChanged", function(self) search = (self:GetText() or ""):lower(); Refresh() end)
  sb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

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

  goldText = UI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  goldText:SetPoint("BOTTOMRIGHT", -8, 7)

  currencyText = UI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  currencyText:SetJustifyH("LEFT")
  currencyText:SetPoint("BOTTOMLEFT", 8, 7)
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

  emptyHeader = UI:CreateFontString(nil, "OVERLAY", "GameFontNormal"); emptyHeader:Hide()

  freeBox = CreateFrame("Button", nil, UI)
  freeBox.bg = freeBox:CreateTexture(nil, "BACKGROUND"); freeBox.bg:SetAllPoints(); freeBox.bg:SetAtlas("bags-item-slot64")
  freeBox.border = freeBox:CreateTexture(nil, "ARTWORK"); freeBox.border:SetAllPoints(); freeBox.border:SetTexture("Interface\\Common\\WhiteIconFrame"); freeBox.border:SetVertexColor(0.4, 0.4, 0.45, 0.7)
  freeNum = freeBox:CreateFontString(nil, "OVERLAY", "NumberFontNormal"); freeNum:SetPoint("BOTTOMRIGHT", -2, 2)
  freeBox:SetScript("OnClick", toggleGrid)
  freeBox:SetScript("OnEnter", gridTip)
  freeBox:SetScript("OnLeave", function() GameTooltip:Hide() end)
  freeBox:Hide()

  reagentBox = CreateFrame("Button", nil, UI)
  reagentBox.bg = reagentBox:CreateTexture(nil, "BACKGROUND"); reagentBox.bg:SetAllPoints(); reagentBox.bg:SetAtlas("bags-item-slot64")
  reagentBox.border = reagentBox:CreateTexture(nil, "ARTWORK"); reagentBox.border:SetAllPoints(); reagentBox.border:SetTexture("Interface\\Common\\WhiteIconFrame"); reagentBox.border:SetVertexColor(0.4, 0.4, 0.45, 0.7)
  reagentNum = reagentBox:CreateFontString(nil, "OVERLAY", "NumberFontNormal"); reagentNum:SetPoint("BOTTOMRIGHT", -2, 2)
  reagentBox:SetScript("OnClick", toggleGrid)
  reagentBox:SetScript("OnEnter", gridTip)
  reagentBox:SetScript("OnLeave", function() GameTooltip:Hide() end)
  reagentBox:Hide()

  -- ao esconder (X, /kb ou auto), zera a flag de auto-aberta pra não fechar janela manual
  UI:HookScript("OnHide", function(self) self.autoOpened = false end)

  ApplyOpacity()
  UI:Hide()
end

Toggle = function()
  if not UI then CreateUI() end
  if UI:IsShown() then UI:Hide() else UI:Show(); Refresh() end
end

-- ---------------- Configurações (extensível) ----------------
local catRows = {}
local CAT_LIST_TOP = -422
local RefreshConfigCats
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
      catRows[i] = r
    end
    local tag = c.filter and "|cff80c0ff(pré-pronta)|r" or "|cff80ff80(sua)|r"
    r.label:SetText(c.name .. "  " .. tag)
    r.up:SetEnabled(i > 1);  r.up:SetAlpha(i > 1 and 1 or 0.3)
    r.down:SetEnabled(i < n); r.down:SetAlpha(i < n and 1 or 0.3)
    r.up:SetScript("OnClick", function() MoveCategory(i, -1); RefreshConfigCats(); Refresh() end)
    r.down:SetScript("OnClick", function() MoveCategory(i, 1); RefreshConfigCats(); Refresh() end)
    r.del:SetScript("OnClick", function() DeleteCategory(c); RefreshConfigCats(); Refresh() end)
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", 16, y); r:Show()
    y = y - 22
  end
  CFG:SetHeight(math.max(380, -y + 16))
end

CreateConfig = function()
  CFG = CreateFrame("Frame", "KrononBagsConfig", UIParent, "BackdropTemplate")
  CFG:SetSize(400, 380)
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

  local title = CFG:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -12); title:SetText("|cfff0d98cKrononBags — Configurações|r")

  local close = CreateFrame("Button", nil, CFG, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 2)

  -- Opção: opacidade do fundo
  local opLabel = CFG:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  opLabel:SetPoint("TOPLEFT", 18, -50)
  local function setOpLabel(v) opLabel:SetText(string.format("Opacidade do fundo: %d%%", math.floor(v * 100 + 0.5))) end

  local slider = CreateFrame("Slider", "KrononBagsOpacitySlider", CFG, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", 18, -80)
  slider:SetWidth(300)
  slider:SetMinMaxValues(0.1, 1.0)
  slider:SetValueStep(0.05)
  slider:SetObeyStepOnDrag(true)
  local low  = slider.Low  or _G["KrononBagsOpacitySliderLow"];  if low  then low:SetText("10%")   end
  local high = slider.High or _G["KrononBagsOpacitySliderHigh"]; if high then high:SetText("100%") end
  local txt  = slider.Text or _G["KrononBagsOpacitySliderText"]; if txt  then txt:SetText("")       end
  slider:SetValue((DB.settings and DB.settings.opacity) or 0.92)
  setOpLabel((DB.settings and DB.settings.opacity) or 0.92)
  slider:SetScript("OnValueChanged", function(_, v)
    DB.settings.opacity = v
    setOpLabel(v)
    ApplyOpacity()
  end)

  -- Opção: proteger/favoritar itens em categorias
  local cb = CreateFrame("CheckButton", "KrononBagsAutoProtectCheck", CFG, "UICheckButtonTemplate")
  cb:SetPoint("TOPLEFT", 16, -120)
  local cbLabel = cb.Text or _G["KrononBagsAutoProtectCheckText"]
  if cbLabel then cbLabel:SetText("Proteger/favoritar itens em categorias") end
  cb:SetChecked(DB.settings.autoProtectCategorized)
  cb:SetScript("OnClick", function(self)
    DB.settings.autoProtectCategorized = self:GetChecked() and true or false
    Refresh()
  end)
  local cbHint = CFG:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  cbHint:SetPoint("TOPLEFT", 18, -150)
  cbHint:SetText("Itens em PvP/PvE ou categorias suas não vendem sem querer.")

  -- Opção: tema de cor (Dark x Blizzard)
  local cb2 = CreateFrame("CheckButton", "KrononBagsBlizzColorsCheck", CFG, "UICheckButtonTemplate")
  cb2:SetPoint("TOPLEFT", 16, -176)
  local cb2Label = cb2.Text or _G["KrononBagsBlizzColorsCheckText"]
  if cb2Label then cb2Label:SetText("Cores estilo Blizzard (desmarcado = preto/dark)") end
  cb2:SetChecked(DB.settings.blizzardStyle)
  cb2:SetScript("OnClick", function(self)
    DB.settings.blizzardStyle = self:GetChecked() and true or false
    ApplyOpacity()
  end)

  -- Opção: número de colunas (itens por fileira)
  local colLabel = CFG:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  colLabel:SetPoint("TOPLEFT", 18, -212)
  local function setColLabel(v) colLabel:SetText(string.format("Colunas (itens por fileira): %d", v)) end
  local colSlider = CreateFrame("Slider", "KrononBagsColsSlider", CFG, "OptionsSliderTemplate")
  colSlider:SetPoint("TOPLEFT", 18, -240)
  colSlider:SetWidth(300)
  colSlider:SetMinMaxValues(8, 20)
  colSlider:SetValueStep(1)
  colSlider:SetObeyStepOnDrag(true)
  local cLow  = colSlider.Low  or _G["KrononBagsColsSliderLow"];  if cLow  then cLow:SetText("8")   end
  local cHigh = colSlider.High or _G["KrononBagsColsSliderHigh"]; if cHigh then cHigh:SetText("20") end
  local cTxt  = colSlider.Text or _G["KrononBagsColsSliderText"]; if cTxt  then cTxt:SetText("")     end
  colSlider:SetValue((DB.settings and DB.settings.cols) or 14)
  setColLabel((DB.settings and DB.settings.cols) or 14)
  colSlider:SetScript("OnValueChanged", function(_, v)
    v = math.floor(v + 0.5)
    DB.settings.cols = v
    setColLabel(v)
    Refresh()
  end)

  -- Opção: abrir automaticamente no vendedor/banco/correio
  local cb3 = CreateFrame("CheckButton", "KrononBagsAutoOpenCheck", CFG, "UICheckButtonTemplate")
  cb3:SetPoint("TOPLEFT", 16, -266)
  local cb3Label = cb3.Text or _G["KrononBagsAutoOpenCheckText"]
  if cb3Label then cb3Label:SetText("Abrir automático no vendedor / banco / correio") end
  cb3:SetChecked(DB.settings.autoOpen)
  cb3:SetScript("OnClick", function(self)
    DB.settings.autoOpen = self:GetChecked() and true or false
  end)

  -- Opção: mostrar item level no canto do ícone
  local cb4 = CreateFrame("CheckButton", "KrononBagsShowIlvlCheck", CFG, "UICheckButtonTemplate")
  cb4:SetPoint("TOPLEFT", 16, -292)
  local cb4Label = cb4.Text or _G["KrononBagsShowIlvlCheckText"]
  if cb4Label then cb4Label:SetText("Mostrar item level (ilvl) no canto do ícone") end
  cb4:SetChecked(DB.settings.showIlvl)
  cb4:SetScript("OnClick", function(self)
    DB.settings.showIlvl = self:GetChecked() and true or false
    Refresh()
  end)

  -- Opção: cor do ilvl (raridade x branco)
  local cb5 = CreateFrame("CheckButton", "KrononBagsIlvlRarityCheck", CFG, "UICheckButtonTemplate")
  cb5:SetPoint("TOPLEFT", 16, -318)
  local cb5Label = cb5.Text or _G["KrononBagsIlvlRarityCheckText"]
  if cb5Label then cb5Label:SetText("ilvl colorido pela raridade (desmarcado = branco)") end
  cb5:SetChecked(DB.settings.ilvlUseRarity)
  cb5:SetScript("OnClick", function(self)
    DB.settings.ilvlUseRarity = self:GetChecked() and true or false
    Refresh()
  end)

  -- Gerenciar categorias (criar custom + adicionar pré-pronta + reordenar + excluir)
  local catHeader = CFG:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  catHeader:SetPoint("TOPLEFT", 16, -356); catHeader:SetText("|cfff0d98cCategorias|r")
  local catHint = CFG:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  catHint:SetPoint("TOPLEFT", 18, -374)
  catHint:SetText("A ordem aqui (de cima → baixo) é a ordem no inventário. Use ▲▼ pra mover.")

  local newCat = CreateFrame("EditBox", "KrononBagsNewCatEdit", CFG, "InputBoxTemplate")
  newCat:SetSize(150, 20); newCat:SetPoint("TOPLEFT", 22, -396); newCat:SetAutoFocus(false)
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

  CFG:Hide()
end

ToggleConfig = function()
  if not CFG then CreateConfig() end
  if CFG:IsShown() then CFG:Hide() else RefreshConfigCats(); CFG:Show() end
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

-- ---------------- Eventos / comandos ----------------
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:RegisterEvent("EQUIPMENT_SETS_CHANGED")
f:RegisterEvent("PLAYER_MONEY")
f:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
f:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
f:RegisterEvent("BAG_UPDATE_COOLDOWN")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("MERCHANT_SHOW");      f:RegisterEvent("MERCHANT_CLOSED")
f:RegisterEvent("BANKFRAME_OPENED");   f:RegisterEvent("BANKFRAME_CLOSED")
f:RegisterEvent("MAIL_SHOW");          f:RegisterEvent("MAIL_CLOSED")
f:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 == ADDON_NAME then InitDB() end
  elseif event == "PLAYER_MONEY" or event == "CURRENCY_DISPLAY_UPDATE" then
    if UI and UI:IsShown() then UpdateMoney() end
  elseif event == "BAG_UPDATE_COOLDOWN" then
    if UI and UI:IsShown() then UpdateCooldowns() end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if UI and UI.refreshPending and UI:IsShown() then UI.refreshPending = nil; Refresh() end
  elseif event == "MERCHANT_SHOW" then
    AutoShow(); Refresh() -- re-render p/ bloquear venda de itens protegidos (atributo seguro)
  elseif event == "MERCHANT_CLOSED" then
    AutoHide(); Refresh() -- restaura o usar/equipar nos itens antes protegidos
  elseif event == "BANKFRAME_OPENED" or event == "MAIL_SHOW" then
    AutoShow()
  elseif event == "BANKFRAME_CLOSED" or event == "MAIL_CLOSED" then
    AutoHide()
  else -- BAG_UPDATE_DELAYED, EQUIPMENT_SETS_CHANGED, BAG_NEW_ITEMS_UPDATED
    Refresh()
  end
end)

SLASH_KRONONBAGS1 = "/kb"
SLASH_KRONONBAGS2 = "/krononbags"
SlashCmdList["KRONONBAGS"] = function(msg)
  msg = (msg or ""):lower():gsub("%s+", "")
  if msg == "config" or msg == "cfg" or msg == "opcoes" or msg == "opções" then
    ToggleConfig()
  else
    Toggle()
  end
end
