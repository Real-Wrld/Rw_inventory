if not lib then return end

-- ═════════════════════════════════════════════════════════════
--  REALWRLD · ox_inventory · shop favourites (3.7 «Boutique premium»)
--
--  The stars a player puts on shop products, per CHARACTER and per shop
--  TYPE («General 3» and «General 7» share one list), kept in this
--  client's KVP: they survive reconnects, restarts and other shops.
--  The character key (`who`) is a short hash the server sends with the
--  shop session (ox_inventory:rwShopWallet → who), so two characters on
--  one PC keep separate lists.
--
--    NUI  oxlynShopFav { shop, name, on }  → { list }   (star / unstar)
--    Fav.setWho(who)          from the wallet session (client.lua)
--    Fav.list(shop)           the names, newest first (the session carries
--                             them to the NUI: `favourites`)
--  KVP key: oxinv_shopfav:<who>:<shop type> = JSON array of item names
--  (≤ 200 names of ≤ 64 bytes). Display only: nothing here is trusted by
--  the server.
-- ═════════════════════════════════════════════════════════════

local KVP = 'oxinv_shopfav:'
local MAX, MAX_NAME, MAX_SHOP = 200, 64, 64

local Fav = {}
local who = 'default'

---«General 3» → «General»; anything outside [A-Za-z0-9 _-.] becomes «_».
---@param shop any
---@return string?
local function shopKey(shop)
    if type(shop) ~= 'string' and type(shop) ~= 'number' then return end
    local s = tostring(shop):gsub('%s+%d+$', '')
    s = s:match('^%s*(.-)%s*$') or ''
    s = s:gsub('[^%w %-_%.]', '_'):sub(1, MAX_SHOP)
    if s == '' then return end
    return s
end

local function keyOf(shop) return KVP .. who .. ':' .. shop end

local function validName(n) return type(n) == 'string' and n ~= '' and #n <= MAX_NAME end

---@param shop string
---@return string[]
local function load(shop)
    local raw = GetResourceKvpString(keyOf(shop))
    if not raw or raw == '' then return {} end
    local ok, list = pcall(json.decode, raw)
    if not ok or type(list) ~= 'table' then return {} end
    local out, seen = {}, {}
    for i = 1, #list do
        local n = list[i]
        if validName(n) and not seen[n] then
            seen[n] = true
            out[#out + 1] = n
            if #out >= MAX then break end
        end
    end
    return out
end

local function save(shop, list)
    if #list == 0 then
        DeleteResourceKvp(keyOf(shop))
    else
        SetResourceKvp(keyOf(shop), json.encode(list))
    end
end

---The character key from the shop session (a hex hash; anything else is ignored).
---@param w any
function Fav.setWho(w)
    if type(w) == 'string' and #w >= 1 and #w <= 40 and w:match('^[%w]+$') then who = w end
end

---@param shop any the shop inventory id or type
---@return string[]
function Fav.list(shop)
    local key = shopKey(shop)
    if not key then return {} end
    return load(key)
end

RegisterNUICallback('rwShopFav', function(data, cb)
    local shop = type(data) == 'table' and shopKey(data.shop) or nil
    local name = type(data) == 'table' and data.name or nil
    if not shop or not validName(name) then return cb(false) end

    local list = load(shop)
    local at
    for i = 1, #list do
        if list[i] == name then at = i break end
    end

    if data.on == true then
        if not at then
            table.insert(list, 1, name)
            while #list > MAX do list[#list] = nil end
        end
    elseif at then
        table.remove(list, at)
    end

    save(shop, list)
    cb({ list = list, n = #list })
end)
-- Legacy alias (pre-rename name): the closed Creator app / external callers still use it.
RegisterNUICallback('oxlynShopFav', function(data, cb)
    local shop = type(data) == 'table' and shopKey(data.shop) or nil
    local name = type(data) == 'table' and data.name or nil
    if not shop or not validName(name) then return cb(false) end

    local list = load(shop)
    local at
    for i = 1, #list do
        if list[i] == name then at = i break end
    end

    if data.on == true then
        if not at then
            table.insert(list, 1, name)
            while #list > MAX do list[#list] = nil end
        end
    elseif at then
        table.remove(list, at)
    end

    save(shop, list)
    cb({ list = list, n = #list })
end)

return Fav
