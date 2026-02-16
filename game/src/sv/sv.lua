local ontimercoke = {}
local playeractstate = {}

local ESX = exports["es_extended"]:getSharedObject()

local valid = {
    CokePick = true,
    CokeProcess = true,
    CokeBox = true,
    CokeBag = true,
}

local cooldownelp = {
    CokePick = 9000,
    CokeProcess = 9000,
    CokeBox = 42000,
    CokeBag = 4000,
}

local cooldownms = {
    CokePick = 10000,
    CokeProcess = 10000,
    CokeBox = 44000,
    CokeBag = 5000,
}

local maxdist = {
    CokePick = 50,
    CokeProcess = 20,
    CokeBox = 20,
    CokeBag = 20,
}

local function generateToken()
    local chars = '0123456789abcdef'
    local token = ''
    for i = 1, 32 do
        local idx = math.random(1, #chars)
        token = token .. chars:sub(idx, idx)
    end
    return token
end

local function getitem(name, count, source)
    local item = exports.ox_inventory:GetItem(source, name)
    if item and item.count >= count then
        return true
    end
    return false
end

local function removeitem(name, count, source)
    return exports.ox_inventory:RemoveItem(source, name, count)
end

local function additem(name, count, source)
    if exports.ox_inventory:CanCarryItem(source, name, count) then
        return exports.ox_inventory:AddItem(source, name, count)
    end
    return false
end

local function getactcoords(actionType)
    if actionType == "CokeBox" then
        return fd.processing.box.coords.xyz
    elseif actionType == "CokeProcess" then
        return fd.processing.leaf.coords
    elseif actionType == "CokeBag" then
        return fd.processing.bag.coords.xyz
    elseif actionType == "CokePick" then
        return fd.field.coords
    end
end

local function getrqitems(actionType)
    if actionType == "CokeBox" then
        return fd.processing.box.required
    elseif actionType == "CokeProcess" then
        return fd.processing.leaf.required
    elseif actionType == "CokeBag" then
        return fd.processing.bag.required
    elseif actionType == "CokePick" then
        return fd.field.required
    end
end

local function hasrqitems(src, required)
    local count = 0
    for _, v in pairs(required) do
        if getitem(v.item, v.count, src) then
            count = count + 1
        end
    end
    return count == #required
end

lib.callback.register('fd_cocaine:getitem', function(source, type)
    if not valid[type] then return false end

    local required = getrqitems(type)
    if not required then return false end

    if hasrqitems(source, required) then
        local token = generateToken()
        playeractstate[source] = {
            type = type,
            startTime = GetGameTimer(),
            token = token,
        }
        return true, token
    end

    return false
end)

lib.callback.register('fd_cocaine:giveitems', function(source, actionType, token)
    local src = source

    if not valid[actionType] then return false end
    if not token or type(token) ~= 'string' then return false end

    local state = playeractstate[src]
    if not state or state.type ~= actionType then
        return false
    end

    if state.token ~= token then
        playeractstate[src] = nil
        return false
    end

    local elapsed = GetGameTimer() - state.startTime
    if elapsed < (cooldownelp[actionType] or 5000) then
        playeractstate[src] = nil
        return false
    end

    if ontimercoke[src] and ontimercoke[src] > GetGameTimer() then
        return false
    end

    local srccoords = GetEntityCoords(GetPlayerPed(src))
    local actioncoords = getactcoords(actionType)
    if not actioncoords then
        playeractstate[src] = nil
        return false
    end

    local dist = #(actioncoords - srccoords)
    if dist > (maxdist[actionType] or 20) then
        playeractstate[src] = nil
        return false
    end

    local required = getrqitems(actionType)
    if not required or not hasrqitems(src, required) then
        playeractstate[src] = nil
        return false
    end

    playeractstate[src] = nil

    if actionType == "CokePick" then
        for _, v in pairs(required) do
            if v.remove then
                removeitem(v.item, v.count, src)
            end
        end

        local reward = fd.field.reward
        local amount = 1
        if reward.min and reward.max then
            amount = math.random(reward.min, reward.max)
        end
        additem(reward.item, amount, src)
    elseif actionType == "CokeProcess" then
        for _, v in pairs(required) do
            if v.remove then
                removeitem(v.item, v.count, src)
            end
        end
        for _, v in pairs(fd.processing.leaf.reward) do
            additem(v.item, v.count, src)
        end
    elseif actionType == "CokeBox" then
        for _, v in pairs(required) do
            if v.remove then
                removeitem(v.item, v.count, src)
            end
        end
        for _, v in pairs(fd.processing.box.reward) do
            additem(v.item, v.count, src)
        end
    elseif actionType == "CokeBag" then
        for _, v in pairs(required) do
            if v.remove then
                removeitem(v.item, v.count, src)
            end
        end
        for _, v in pairs(fd.processing.bag.reward) do
            additem(v.item, v.count, src)
        end
    end

    ontimercoke[src] = GetGameTimer() + (cooldownms[actionType] or 5000)
    return true
end)

lib.callback.register('fd_cocaine:shop', function(source, item)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    local founditem = nil
    for _, v in pairs(fd.dealer.items) do
        if v.item == item then
            founditem = v
            break
        end
    end

    if not founditem or founditem.price <= 0 then return false end

    local price = founditem.price

    if xPlayer.getMoney() >= price then
        xPlayer.removeMoney(price)
        xPlayer.addInventoryItem(item, 1)
        return true
    elseif xPlayer.getAccount('bank').money >= price then
        xPlayer.removeAccountMoney('bank', price)
        xPlayer.addInventoryItem(item, 1)
        return true
    else
        TriggerClientEvent('ox_lib:notify', source, {type = 'error', description = 'Not enough money'})
        return false
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    playeractstate[src] = nil
    ontimercoke[src] = nil
end)
