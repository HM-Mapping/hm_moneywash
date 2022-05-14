ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

Cache = {}
Washing,Washed,Collected = false,false,false

local function wash()
    Citizen.CreateThread(function()
        Citizen.Wait(Config.Time*1000)
        TriggerClientEvent('esx:showNotification', Cache.Player, "I've finished washing your money, come get it.")
        Washing = false
        Washed = true
        TriggerClientEvent('hm_moneywash:updateWash', -1, Washing, Washed)
    end)
end

RegisterServerEvent('hm_moneywash:takeCash')
AddEventHandler('hm_moneywash:takeCash', function(amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if xPlayer.getAccount('black_money').money >= amount then
        if not Washing then
            Washing = true
            Collected = false
            TriggerClientEvent('hm_moneywash:updateWash', -1, Washing, Washed)
            xPlayer.removeAccountMoney('black_money', amount)
            Cache.Amount = amount*(Config.Percentage/100)
            TriggerClientEvent('hm_moneywash:continueWash', _source)
            TriggerClientEvent('esx:showNotification', _source, 'This will take some time, come back later to pick it up.')
            Cache.Player = _source
            wash()
        else
            TriggerClientEvent('esx:showNotification', _source, 'Already washing some money, come back later.')
        end
    else
        TriggerClientEvent('esx:showNotification', source, 'Not enough dirty cash!')
    end
end)

RegisterServerEvent('hm_moneywash:collect')
AddEventHandler('hm_moneywash:collect', function()
    Washed = false
    TriggerClientEvent('hm_moneywash:updateWash', -1, Washing, Washed)
end)

RegisterServerEvent('hm_moneywash:collectCash')
AddEventHandler('hm_moneywash:collectCash', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not Collected then
        Collected = true
        xPlayer.addAccountMoney('money', Cache.Amount)
        Cache.Amount = nil
    else
        TriggerClientEvent('esx:showNotification', _source, 'Cash has already been collected buddy!')
    end
end)

ESX.RegisterServerCallback('hm_moneywash:isWashing', function(source, cb)
    cb({Washing = Washing, Washed = Washed})
 end)