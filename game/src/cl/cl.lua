lib.locale(fd.locale)

local tbhed = nil
local cokeplant = 0
local cokeplants = {}
local inside = false

local ESX = exports["es_extended"]:getSharedObject()

CreateThread(function()
    for _, ipl in ipairs(fd.ipls) do
        if not IsIplActive(ipl) then
            RequestIpl(ipl)
        end
    end

    local interior = GetInteriorAtCoords(1093.6, -3196.6, -38.99)
    if interior ~= 0 then
        for _, prop in ipairs(fd.props) do
            ActivateInteriorEntitySet(interior, prop)
        end
        RefreshInterior(interior)
    end
end)



local function destroyplant(id)
    if cokeplants[id] then
        if DoesEntityExist(cokeplants[id]) then
            SetEntityAsMissionEntity(cokeplants[id], false, true)
            DeleteObject(cokeplants[id])
        end
        cokeplants[id] = nil
    end
end

local cokezone = lib.zones.sphere({
    coords = fd.field.coords,
    radius = fd.field.radius,
    debug = fd.debug,
    onEnter = function()
        inside = true
        CreateThread(function()
            while inside and cokeplant < 15 do
                Wait(0)
                local cokecoords = randomplantcoords()
                RequestModel(`prop_plant_01a`)
                while not HasModelLoaded(`prop_plant_01a`) do
                    Wait(100)
                end
                local obj = CreateObject(`prop_plant_01a`, cokecoords.x, cokecoords.y, cokecoords.z, true, true, false)
                PlaceObjectOnGroundProperly(obj)
                FreezeEntityPosition(obj, true)

                table.insert(cokeplants, obj)
                cokeplant = cokeplant + 1
            end
        end)
    end,
    onExit = function()
        inside = false
        for k, v in pairs(cokeplants) do
           destroyplant(k)
        end
        cokeplants = {}
        cokeplant = 0
    end
})

function pickupcoke(target)
    local nearbyid
    for i = 1, #cokeplants, 1 do
        if cokeplants[i] == target then
            nearbyid = i
            break
        end
    end

    if IsPedOnFoot(cache.ped) then
        if not lib.progressActive() then
            lib.callback('fd_cocaine:getitem', false, function(value, token)
                if value then
                    if lib.progressBar({
                        duration = 10000,
                        label = locale("pickingup"),
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            move = true,
                            car = true,
                            combat = true,
                            mouse = false,
                        },
                        anim = {
                            scenario = "world_human_gardener_plant",
                        },
                    }) then
                        SetEntityAsMissionEntity(target, false, true)
                        DeleteObject(target)
                        if nearbyid then
                            table.remove(cokeplants, nearbyid)
                            cokeplant = cokeplant - 1
                        end
                        lib.callback('fd_cocaine:giveitems', false, function() end, "CokePick", token)
                    end
                else
                    notify("error", locale("error"), locale("RequiredTrowel"))
                end
            end, "CokePick")
        end
    else
        Wait(500)
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for k, v in pairs(cokeplants) do
            if DoesEntityExist(v) then
                SetEntityAsMissionEntity(v, false, true)
                DeleteObject(v)
            end
        end
    end
end)

exports.ox_target:addModel(`prop_plant_01a`, {
    {
        name = 'pick_coke',
        icon = "fas fa-leaf",
        label = locale("pickup"),
        onSelect = function(data)
            pickupcoke(data.entity)
        end,
        canInteract = function()
            return inside
        end
    }
})

exports.ox_target:addSphereZone({
    coords = fd.enter.coords,
    radius = fd.enter.radius,
    debug = false,
    options = {
        {
            name = 'enter_coke_lab',
            icon = "fas fa-door-open",
            label = locale("EnterLab"),
            onSelect = function()
                if fd.enter.requestitem then
                    local count = exports.ox_inventory:Search('count', fd.enter.key)
                    if count > 0 then
                        TriggerEvent("fd_cocaine:progress", { menu = "CokeDoor1" })
                    else
                        lib.notify({ type = 'error', description = locale("RequiredItems") })
                    end
                else
                    TriggerEvent("fd_cocaine:progress", { menu = "CokeDoor1" })
                end
            end
        }
    }
})

exports.ox_target:addSphereZone({
    coords = fd.leave.coords,
    radius = fd.leave.radius,
    debug = false,
    options = {
        {
            name = 'leave_coke_lab',
            icon = "fas fa-door-open",
            label = locale("LeaveLab"),
            onSelect = function()
                TriggerEvent("fd_cocaine:progress", { menu = "CokeDoor2" })
            end
        }
    }
})

exports.ox_target:addSphereZone({
    coords = fd.processing.leaf.coords,
    radius = fd.processing.leaf.radius,
    debug = false,
    options = {
        {
            name = 'process_coke_leaves',
            icon = "fas fa-hands",
            label = fd.processing.leaf.header,
            onSelect = function()
                TriggerEvent("fd_cocaine:progress", { menu = "CokeProcess" })
            end
        }
    }
})

exports.ox_target:addSphereZone({
    coords = fd.processing.box.coords,
    radius = fd.processing.box.radius,
    debug = false,
    options = {
        {
            name = 'process_coke_box',
            icon = "fas fa-box",
            label = fd.processing.box.header,
            onSelect = function()
                TriggerEvent("fd_cocaine:progress", { menu = "CokeBox" })
            end
        }
    }
})

exports.ox_target:addSphereZone({
    coords = fd.processing.bag.coords,
    radius = fd.processing.bag.radius,
    debug = false,
    options = {
        {
            name = 'pack_coke_bag',
            icon = "fas fa-bag-shopping",
            label = fd.processing.bag.header,
            onSelect = function()
                TriggerEvent("fd_cocaine:progress", { menu = "CokeBag" })
            end
        }
    }
})

CreateThread(function()
    local v = fd.dealer
    RequestModel(GetHashKey(v.model))
    while not HasModelLoaded(GetHashKey(v.model)) do
        Wait(1)
    end
    cokedealerped = CreatePed(4, v.model, v.coords, false, true)
    SetEntityHeading(cokedealerped, v.coords.w)
    FreezeEntityPosition(cokedealerped, true)
    SetEntityInvincible(cokedealerped, true)
    SetBlockingOfNonTemporaryEvents(cokedealerped, true)
    TaskStartScenarioInPlace(cokedealerped, v.scenario, 0, true)

    exports.ox_target:addLocalEntity(cokedealerped, {
        {
            name = 'coke_dealer',
            icon = "fas fa-comments",
            label = fd.dealer.header,
            onSelect = function()
                local options = {}
                for _, item in pairs(fd.dealer.items) do
                    table.insert(options, {
                        title = item.label,
                        description = item.description .. item.price,
                        icon = "fas fa-shopping-basket",
                        onSelect = function()
                            TriggerEvent("fd_cocaine:progress", { menu = "CokeDealer", id = item.item })
                        end
                    })
                end
                lib.registerContext({
                    id = 'CokeDealerMenu',
                    title = fd.dealer.header,
                    options = options
                })
                lib.showContext('CokeDealerMenu')
            end
        }
    })
end)

function randomplantcoords()
    while true do
        Wait(0)

        local cokecoordx, cokecoordy

        math.randomseed(GetGameTimer())
        local modx = math.random(math.floor(fd.field.radius * -1) + 2, math.floor(fd.field.radius) - 2)

        Wait(100)

        math.randomseed(GetGameTimer())
        local mody = math.random(math.floor(fd.field.radius * -1) + 2, math.floor(fd.field.radius) - 2)

        cokecoordx = fd.field.coords.x + modx
        cokecoordy = fd.field.coords.y + mody

        local coordz = getcoordzcoke(cokecoordx, cokecoordy)
        local coord = vector3(cokecoordx, cokecoordy, coordz)

        if validatecokeplantcoord(coord) then
            return coord
        end
    end
end

function getcoordzcoke(x, y)
    local z = fd.field.coords.z
    for i = 50, -50, -1 do
        local found, groundz = GetGroundZFor_3dCoord(x, y, z + i)
        if found then
            return groundz
        end
    end
    return z
end

function validatecokeplantcoord(plantcoord)
    if cokeplant > 0 then
        local validate = true

        for k, v in pairs(cokeplants) do
            local dist = #(plantcoord - GetEntityCoords(v))
            if dist < 5 then
                validate = false
            end
        end

        if validate then
            return true
        else
            return false
        end
    else
        return true
    end
end

function notify(type, title, text)
    lib.notify({
        title = title,
        description = text,
        type = type
    })
end

AddEventHandler('fd_cocaine:progress', function(data)
    if data.menu == "CokeDoor1" then
        DoScreenFadeOut(1000)
        if lib.progressBar({
            duration = 5000,
            label = locale("entering"),
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true, mouse = false },
        }) then
            SetEntityCoords(cache.ped, fd.enter.target, false, false, false, true)
            Wait(1100)
            DoScreenFadeIn(300)
        end
    elseif data.menu == "CokeDoor2" then
        DoScreenFadeOut(1000)
        if lib.progressBar({
            duration = 5000,
            label = locale("leaving"),
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true, mouse = false },
        }) then
            SetEntityCoords(cache.ped, fd.leave.target, false, false, false, true)
            Wait(1100)
            DoScreenFadeIn(300)
        end
    elseif data.menu == "CokeBox" then
        if not lib.progressActive() then
            lib.callback('fd_cocaine:getitem', false, function(value, token)
                if value then
                    local ped = cache.ped
                    local dict = "anim@amb@business@coc@coc_unpack_cut@"

                    RequestAnimDict(dict)
                    RequestModel("bkr_prop_coke_box_01a")
                    RequestModel("bkr_prop_coke_fullmetalbowl_02")
                    RequestModel("bkr_prop_coke_fullscoop_01a")
                    while not HasAnimDictLoaded(dict) and not HasModelLoaded("bkr_prop_coke_box_01a") and
                        not HasModelLoaded("bkr_prop_coke_fullmetalbowl_02") and
                        not HasModelLoaded("bkr_prop_coke_fullscoop_01a") do
                        Wait(100)
                    end

                    local x, y, z = table.unpack(fd.processing.box.target)
                    local cokebowl = CreateObject(GetHashKey('bkr_prop_coke_fullmetalbowl_02'), x, y, z, 1, 0, 1)
                    local cokescoop = CreateObject(GetHashKey('bkr_prop_coke_fullscoop_01a'), x, y, z, 1, 0, 1)
                    local cokebox = CreateObject(GetHashKey('bkr_prop_coke_box_01a'), x, y, z, 1, 0, 1)
                    local targetRotation = vec3(180.0, 180.0, fd.processing.box.coords.w)
                    local netScene = NetworkCreateSynchronisedScene(x - 0.2, y - 0.1, z - 0.65, targetRotation, 2, false,
                        false, 1148846080, 0, 1.3)

                    NetworkAddPedToSynchronisedScene(ped, netScene, dict, "fullcut_cycle_v1_cokepacker", 1.5, -4.0, 1, 16,
                        1148846080, 0)
                    NetworkAddEntityToSynchronisedScene(cokebowl, netScene, dict, "fullcut_cycle_v1_cokebowl", 4.0, -8.0, 1)
                    NetworkAddEntityToSynchronisedScene(cokebox, netScene, dict, 'fullcut_cycle_v1_cokebox', 4.0, -8.0, 1)
                    NetworkAddEntityToSynchronisedScene(cokescoop, netScene, dict, 'fullcut_cycle_v1_cokescoop', 4.0, -8.0, 1)
                    FreezeEntityPosition(ped, true)
                    Wait(150)
                    NetworkStartSynchronisedScene(netScene)
                    SetEntityVisible(cokescoop, false, 0)
                    if lib.progressBar({
                        duration = 43828,
                        label = locale("CokeBoxProg"),
                        useWhileDead = false,
                        canCancel = false,
                        disable = { move = true, car = true, combat = true, mouse = false },
                    }) then
                        DeleteObject(cokebowl)
                        DeleteObject(cokebox)
                        DeleteObject(cokescoop)
                        FreezeEntityPosition(ped, false)
                        ClearPedTasks(ped)
                        lib.callback('fd_cocaine:giveitems', false, function() end, "CokeBox", token)
                    else
                        DeleteObject(cokebowl)
                        DeleteObject(cokebox)
                        DeleteObject(cokescoop)
                        FreezeEntityPosition(ped, false)
                        ClearPedTasks(ped)
                    end
                else
                    notify("error", locale("error"), locale("RequiredItems"))
                end
            end, "CokeBox")
        end
    elseif data.menu == "CokeBag" then
        if not lib.progressActive() then
            lib.callback('fd_cocaine:getitem', false, function(value, token)
                if value then
                    TaskTurnPedToFaceCoord(cache.ped, fd.processing.bag.coords, 500)
                    if lib.progressBar({
                        duration = 5000,
                        label = locale("CokePacking"),
                        useWhileDead = false,
                        canCancel = false,
                        disable = { move = true, car = true, combat = true, mouse = false },
                        anim = {
                            dict = "mp_arresting",
                            clip = "a_uncuff",
                            flags = 49,
                        },
                        prop = {
                            model = `xm3_prop_xm3_bag_coke_01a`,
                            pos = vec3(0.13, 0.05, 0.0),
                            rot = vec3(0.0, 0.0, 0.0),
                            bone = 18905
                        },
                    }) then
                        ClearPedTasks(cache.ped)
                        lib.callback('fd_cocaine:giveitems', false, function() end, "CokeBag", token)
                    else
                        ClearPedTasks(cache.ped)
                    end
                else
                    notify("error", locale("error"), locale("RequiredItems"))
                end
            end, "CokeBag")
        end

    elseif data.menu == "CokeProcess" then
        if not lib.progressActive() then
            lib.callback('fd_cocaine:getitem', false, function(value, token)
                if value then
                    local object = CreateObject(GetHashKey("bkr_prop_coke_box_01a"), fd.processing.leaf.prop.coords.x,
                        fd.processing.leaf.prop.coords.y, fd.processing.leaf.prop.coords.z, true, true, false)
                    SetEntityHeading(object, fd.processing.leaf.prop.coords.w)
                    TaskTurnPedToFaceCoord(cache.ped, fd.processing.leaf.coords, 500)
                    if lib.progressBar({
                        duration = 10000,
                        label = locale('CokeProcessing'),
                        useWhileDead = false,
                        canCancel = false,
                        disable = { move = true, car = true, combat = true, mouse = false },
                        anim = {
                            dict = "mp_arresting",
                            clip = "a_uncuff",
                            flags = 49,
                        },
                        prop = {
                            model = `ng_proc_leaves01`,
                            pos = vec3(0.13, 0.05, 0.0),
                            rot = vec3(0.0, 0.0, 0.0),
                            bone = 18905
                        },
                    }) then
                        ClearPedTasks(cache.ped)
                        lib.callback('fd_cocaine:giveitems', false, function() end, "CokeProcess", token)
                        DeleteObject(object)
                    else
                        DeleteObject(object)
                    end
                else
                    notify("error", locale("error"), locale("RequiredItems"))
                end
            end, "CokeProcess")
        end
    elseif data.menu == "CokeDealer" then
        lib.callback('fd_cocaine:shop', false, function() end, data.id)
    end
end)
