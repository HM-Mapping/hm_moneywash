ESX = nil
local player,coords,ped,Menu = nil,{},nil,false
local Washing,Washed = false,false
Citizen.CreateThread(function()
    while ESX == nil do
        Citizen.Wait(0)
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    end
end)
--Cache thread
Citizen.CreateThread(function()
    while true do
        player = PlayerPedId()
        coords = GetEntityCoords(player)
        Citizen.Wait(500)
    end
end)
AddEventHandler('esx:playerLoaded', function()
    ESX.TriggerServerCallback('hm_moneywash:isWashing', function(cb)
        Washing = cb.Washing
        Washed = cb.Washed
    end)
end)
--Update washing event
RegisterNetEvent('hm_moneywash:updateWash')
AddEventHandler('hm_moneywash:updateWash', function(washing, washed)
    Washing = washing
    Washed = washed
end)
--Wash Money Function
function OpenMoneyDialog()
	local amount = nil
    Menu = true
	ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'name_input_dialog', {
		title = 'Amount to wash'
	},
	function(data, menu)
		local amountInput = tonumber(data.value)
		menu.close()
        Menu = false
		amount = amountInput
	end, function(data, menu)
		menu.close()
        Menu = false
	end)
	while Menu and amount == nil do
		Wait(100)
	end
	return amount
end
local function washMoney()
    if Washing then
        ESX.ShowNotification('Already washing some money, come back later.')
    else
        local money = OpenMoneyDialog()
        TriggerServerEvent('hm_moneywash:takeCash', money)
    end
end
RegisterNetEvent('hm_moneywash:continueWash')
AddEventHandler('hm_moneywash:continueWash', function()
    if not HasModelLoaded('prop_poly_bag_money') then
        LoadPropDict('prop_poly_bag_money')
    end
    TaskTurnPedToFaceCoord(player, Config.NPC.loc.x, Config.NPC.loc.y, Config.NPC.loc.z, -1)
    Wait(500)
    prop = CreateObject(GetHashKey('prop_poly_bag_money'), coords.x, coords.y, coords.z, true, true, true)
    AttachEntityToEntity(prop, player, GetPedBoneIndex(player, 28422), 0.13, 0.0, -0.28, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded('prop_poly_bag_money')
	LoadAnim('amb@world_human_tourist_map@male@base')
    TaskPlayAnim(player, 'amb@world_human_tourist_map@male@base', 'base', 2.0, 2.0, -1, 51, 0, false, false, false)
    Wait(1000)
    TaskPlayAnim(ped, 'amb@world_human_tourist_map@male@base', 'base', 2.0, 2.0, -1, 51, 0, false, false, false)
    Wait(500)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 28422), 0.13, 0.0, -0.28, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    Wait(250)
    ClearPedTasks(player)
    Wait(500)
    ClearPedTasks(ped)
    Wait(500)
    DeleteEntity(prop)
end)
--Collect Money Function
local function collectMoney()
    TriggerServerEvent('hm_moneywash:collect')
    if not HasModelLoaded('prop_poly_bag_money') then
        LoadPropDict('prop_poly_bag_money')
    end
    TaskTurnPedToFaceCoord(player, Config.NPC.loc.x, Config.NPC.loc.y, Config.NPC.loc.z, -1)
    Wait(500)
    prop = CreateObject(GetHashKey('prop_poly_bag_money'), Config.NPC.loc.x, Config.NPC.loc.y, Config.NPC.loc.z, true, true, true)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 28422), 0.13, 0.0, -0.28, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded('prop_poly_bag_money')
	LoadAnim('amb@world_human_tourist_map@male@base')
    TaskPlayAnim(ped, 'amb@world_human_tourist_map@male@base', 'base', 2.0, 2.0, -1, 51, 0, false, false, false)
    Wait(1000)
    TaskPlayAnim(player, 'amb@world_human_tourist_map@male@base', 'base', 2.0, 2.0, -1, 51, 0, false, false, false)
    Wait(500)
    AttachEntityToEntity(prop, player, GetPedBoneIndex(player, 28422), 0.13, 0.0, -0.28, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    Wait(250)
    ClearPedTasks(ped)
    Wait(500)
    ClearPedTasks(player)
    Wait(500)
    DeleteEntity(prop)
    TriggerServerEvent('hm_moneywash:collectCash')
end
--NPC
function LoadAnim(dict)
    while not HasAnimDictLoaded(dict) do
      RequestAnimDict(dict)
      Wait(10)
    end
end
function LoadPropDict(model)
    while not HasModelLoaded(GetHashKey(model)) do
      RequestModel(GetHashKey(model))
      Wait(10)
    end
end
function loadModel(model)
    while not HasModelLoaded(GetHashKey(model)) do
        RequestModel(GetHashKey(model))
        Citizen.Wait(50)
    end
end
Citizen.CreateThread(function()
    loadModel(Config.NPC.ped)
    ped = CreatePed(4, GetHashKey(Config.NPC.ped), Config.NPC.loc.x, Config.NPC.loc.y, Config.NPC.loc.z, Config.NPC.heading, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
end)
--Marker thread
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local loc = Config.NPC.loc
        local dist = #(coords - loc)
        if dist <= 2.0 then
            sleep = 1
            local text = '[E] Wash Money'
            if Washing then
                text = 'Washing Money....'
            elseif Washed then
                text = '[E] Collect Clean Money'
            end
            draw3DText(loc.x,loc.y,loc.z+1.0,text)
            if not Washing and not Washed and IsControlJustReleased(0, 38) then
                washMoney()
            elseif Washed and IsControlJustReleased(0, 38) then
                collectMoney()
            end
        end
        Citizen.Wait(sleep)
    end
end)
--Draw 3D Text
function draw3DText(x,y,z,text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoord())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)
    local scale = ((1 / dist) * 2) * (1 / GetGameplayCamFov()) * 100
    if onScreen then
        SetTextColour(255, 255, 255, 255)
        SetTextScale(0.0 * scale, 0.35 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextCentre(true)
        SetTextDropshadow(1, 1, 1, 1, 255)
        BeginTextCommandWidth("STRING")
        AddTextComponentString(text)
        local height = GetTextScaleHeight(0.55 * scale, 4)
        local width = EndTextCommandGetWidth(4)
        SetTextEntry("STRING")
        AddTextComponentString(text)
        EndTextCommandDisplayText(_x, _y)
    end
end