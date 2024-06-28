local SMDXCore = exports['smdx-core']:GetSMDX()

-----------------------------------------------------------------------
-- version checker
-----------------------------------------------------------------------
local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'

    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/SMDX-RedM-Framework/smdx-multicharacter/main/version.txt', function(err, text, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')

        if not text then 
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return 
        end

        --versionCheckPrint('success', ('Current Version: %s'):format(currentVersion))
        --versionCheckPrint('success', ('Latest Version: %s'):format(text))
        
        if text == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(text))
        end
    end)
end

-----------------------------------------------------------------------

-- Functions
local identifierUsed = GetConvar('es_identifierUsed', 'steam')
local foundResources = {}
-- Functions

-- starter items
local StarterItems = {
    ['bread']      = { amount = 2, item = 'bread' },
    ['canteen50'] = { amount = 1, item = 'canteen50' }
}

-- give starter items
local function GiveStarterItems(source)
    local Player = SMDXCore.Functions.GetPlayer(source)
    for k, v in pairs(StarterItems) do
        Player.Functions.AddItem(v.item, v.amount)
    end
end

RegisterNetEvent('smdx-multicharacter:server:disconnect', function(source)
    DropPlayer(source, "You have disconnected from SMDX RedM")
end)

RegisterNetEvent('smdx-multicharacter:server:loadUserData', function(cData, skindata)
    local src = source
    if SMDXCore.Player.Login(src, cData.citizenid) then
        print('^2[smdx-core]^7 '..GetPlayerName(src)..' (Citizen ID: '..cData.citizenid..') has succesfully loaded!')
        SMDXCore.Commands.Refresh(src)
        TriggerClientEvent("smdx-multicharacter:client:closeNUI", src)
        if not skindata then
            TriggerClientEvent('smdx-spawn:client:setupSpawnUI', src, cData, false)
        else
            TriggerClientEvent('smdx-appearance:OpenCreator', src, false, true)
        end
        TriggerEvent('smdx-log:server:CreateLog', 'joinleave', 'Player Joined Server', 'green', '**' .. GetPlayerName(src) .. '** joined the server..')
    end
end)

RegisterNetEvent('smdx-multicharacter:server:createCharacter', function(data)
    local newData = {}
    local src = source
    newData.cid = data.cid
    newData.charinfo = data
    if SMDXCore.Player.Login(src, false, newData) then
        SMDXCore.ShowSuccess(GetCurrentResourceName(), GetPlayerName(src)..' has succesfully loaded!')
        SMDXCore.Commands.Refresh(src)
        GiveStarterItems(src)
    end
end)

RegisterNetEvent('smdx-multicharacter:server:deleteCharacter', function(citizenid)
    SMDXCore.Player.DeleteCharacter(source, citizenid)
end)

-- Callbacks

SMDXCore.Functions.CreateCallback("smdx-multicharacter:server:setupCharacters", function(source, cb)
    local license = SMDXCore.Functions.GetIdentifier(source, 'license')
    local plyChars = {}
    MySQL.Async.fetchAll('SELECT * FROM players WHERE license = @license', {['@license'] = license}, function(result)
        for i = 1, (#result), 1 do
            result[i].charinfo = json.decode(result[i].charinfo)
            result[i].money = json.decode(result[i].money)
            result[i].job = json.decode(result[i].job)
            plyChars[#plyChars+1] = result[i]
        end
        cb(plyChars)
    end)
end)

SMDXCore.Functions.CreateCallback("smdx-multicharacter:server:GetNumberOfCharacters", function(source, cb)
    local license = SMDXCore.Functions.GetIdentifier(source, 'license')
    local numOfChars = 0
    if next(Config.PlayersNumberOfCharacters) then
        for i, v in pairs(Config.PlayersNumberOfCharacters) do
            if v.license == license then
                numOfChars = v.numberOfChars
                break
            else
                numOfChars = Config.DefaultNumberOfCharacters
            end
        end
    else
        numOfChars = Config.DefaultNumberOfCharacters
    end
    cb(numOfChars)
end)

SMDXCore.Functions.CreateCallback("smdx-multicharacter:server:getAppearance", function(source, cb, citizenid)
    MySQL.Async.fetchAll('SELECT * FROM playerskins WHERE citizenid = ?', { citizenid}, function(result)
        if result ~= nil and #result > 0 then
            local skinData = json.decode(result[1].skin)
            local clothesData = json.decode(result[1].clothes)
            result[1].skin = skinData
            result[1].clothes = clothesData
            cb(result[1])
        else
            cb(nil)
        end
    end)
end)

SMDXCore.Commands.Add("logout", "Logout of Character (Admin Only)", {}, false, function(source)
    SMDXCore.Player.Logout(source)
    TriggerClientEvent('smdx-multicharacter:client:chooseChar', source)
end, 'admin')

SMDXCore.Commands.Add("closeNUI", "Close Multi NUI", {}, false, function(source)
    TriggerClientEvent('smdx-multicharacter:client:closeNUI', source)
end, 'user')

--------------------------------------------------------------------------------------------------
-- start version check
--------------------------------------------------------------------------------------------------
CheckVersion()
