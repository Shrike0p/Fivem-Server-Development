Shrike0p = nil
TriggerEvent('Shrike0p:GetObject', function(obj) Shrike0p = obj end)

RegisterServerEvent('Shrike0p-multicharacter:server:disconnect')
AddEventHandler('Shrike0p-multicharacter:server:disconnect', function()
    local src = source

    DropPlayer(src, "You have disconnected from Qbus Roleplay")
end)

RegisterServerEvent('Shrike0p-multicharacter:server:loadUserData')
AddEventHandler('Shrike0p-multicharacter:server:loadUserData', function(cData)
    local src = source
    if Shrike0p.Player.Login(src, cData.citizenid) then
        print('^2[Shrike0p-core]^7 '..GetPlayerName(src)..' (Citizen ID: '..cData.citizenid..') has succesfully loaded!')
        Shrike0p.Commands.Refresh(src)
        loadHouseData()
		--TriggerEvent('Shrike0p:Server:OnPlayerLoaded')-
        --TriggerClientEvent('Shrike0p:Client:OnPlayerLoaded', src)
        
        TriggerClientEvent('apartments:client:setupSpawnUI', src, cData)
        TriggerEvent("Shrike0p-log:server:sendLog", cData.citizenid, "characterloaded", {})
        TriggerEvent("Shrike0p-log:server:CreateLog", "joinleave", "Loaded", "green", "**".. GetPlayerName(src) .. "** ("..cData.citizenid.." | "..src..") loaded..")
	end
end)

RegisterServerEvent('Shrike0p-multicharacter:server:createCharacter')
AddEventHandler('Shrike0p-multicharacter:server:createCharacter', function(data)
    local src = source
    local newData = {}
    newData.cid = data.cid
    newData.charinfo = data
    --Shrike0p.Player.CreateCharacter(src, data)
    if Shrike0p.Player.Login(src, false, newData) then
        print('^2[Shrike0p-core]^7 '..GetPlayerName(src)..' has succesfully loaded!')
        Shrike0p.Commands.Refresh(src)
        loadHouseData()

        TriggerClientEvent("Shrike0p-multicharacter:client:closeNUI", src)
        TriggerClientEvent('apartments:client:setupSpawnUI', src, newData)
        GiveStarterItems(src)
	end
end)

function GiveStarterItems(source)
    local src = source
    local Player = Shrike0p.Functions.GetPlayer(src)

    for k, v in pairs(Shrike0p.Shared.StarterItems) do
        local info = {}
        if v.item == "id_card" then
            info.citizenid = Player.PlayerData.citizenid
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.gender = Player.PlayerData.charinfo.gender
            info.nationality = Player.PlayerData.charinfo.nationality
        elseif v.item == "driver_license" then
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.type = "A1-A2-A | AM-B | C1-C-CE"
        end
        Player.Functions.AddItem(v.item, 1, false, info)
    end
end

RegisterServerEvent('Shrike0p-multicharacter:server:deleteCharacter')
AddEventHandler('Shrike0p-multicharacter:server:deleteCharacter', function(citizenid)
    local src = source
    Shrike0p.Player.DeleteCharacter(src, citizenid)
end)

Shrike0p.Functions.CreateCallback("Shrike0p-multicharacter:server:GetUserCharacters", function(source, cb)
    local steamId = GetPlayerIdentifier(source, 0)

    exports['ghmattimysql']:execute('SELECT * FROM players WHERE steam = @steam', {['@steam'] = steamId}, function(result)
        cb(result)
    end)
end)

Shrike0p.Functions.CreateCallback("Shrike0p-multicharacter:server:GetServerLogs", function(source, cb)
    exports['ghmattimysql']:execute('SELECT * FROM server_logs', function(result)
        cb(result)
    end)
end)

Shrike0p.Functions.CreateCallback("test:yeet", function(source, cb)
    local steamId = GetPlayerIdentifiers(source)[1]
    local plyChars = {}
    
    exports['ghmattimysql']:execute('SELECT * FROM players WHERE steam = @steam', {['@steam'] = steamId}, function(result)
        for i = 1, (#result), 1 do
            result[i].charinfo = json.decode(result[i].charinfo)
            result[i].money = json.decode(result[i].money)
            result[i].job = json.decode(result[i].job)

            table.insert(plyChars, result[i])
        end
        cb(plyChars)
    end)
end)

Shrike0p.Commands.Add("char", "Give the character menu to a player", {{name="id", help="Player ID"}}, false, function(source, args)
    Shrike0p.Player.Logout(source)
    TriggerClientEvent('Shrike0p-multicharacter:client:chooseChar', source)
end, "admin")

Shrike0p.Commands.Add("closeNUI", "Give an item to a player", {{name="id", help="Player ID"},{name="item", help="Name of the item (not label)"}, {name="amount", help="Number of items"}}, false, function(source, args)
    TriggerClientEvent('Shrike0p-multicharacter:client:closeNUI', source)
end)

Shrike0p.Functions.CreateCallback("Shrike0p-multicharacter:server:getSkin", function(source, cb, cid)
    local src = source

    Shrike0p.Functions.ExecuteSql(false, "SELECT * FROM `playerskins` WHERE `citizenid` = '"..cid.."' AND `active` = 1", function(result)
        if result[1] ~= nil then
            cb(result[1].model, result[1].skin)
        else
            cb(nil)
        end
    end)
end)

function loadHouseData()
    local HouseGarages = {}
    local Houses = {}
	Shrike0p.Functions.ExecuteSql(false, "SELECT * FROM `houselocations`", function(result)
		if result[1] ~= nil then
			for k, v in pairs(result) do
				local owned = false
				if tonumber(v.owned) == 1 then
					owned = true
				end
				local garage = v.garage ~= nil and json.decode(v.garage) or {}
				Houses[v.name] = {
					coords = json.decode(v.coords),
					owned = v.owned,
					price = v.price,
					locked = true,
					adress = v.label, 
					tier = v.tier,
					garage = garage,
					decorations = {},
				}
				HouseGarages[v.name] = {
					label = v.label,
					takeVehicle = garage,
				}
			end
		end
		TriggerClientEvent("Shrike0p-garages:client:houseGarageConfig", -1, HouseGarages)
		TriggerClientEvent("Shrike0p-houses:client:setHouseConfig", -1, Houses)
	end)
end