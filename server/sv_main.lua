-- [[ QBCore ]] --
local QBCore = exports['qb-core']:GetCoreObject()

-- [[ Variables ]] --
local Jobs = {}
local NewPayment

-- [[ Resource ]] --


-- [[ Functions ]] --
local function GetLocationInfo(id)
    if id ~= nil then
        Data = Config.Resource['JobLocations'][id]
    else
        Data = Config.Resource['JobLocations'][math.random(#Config.Resource['JobLocations'])]
    end

    local Coords = Data.Coords[math.random(#Data.Coords)]
    local Payment = Data.Payment
    local Identifier = Data.Identifier

    return Coords, Payment, Identifier
end

local function GetPlayerPostalJob(job)
    for k, v in pairs(Config.Resource['Job']['JobName']) do
        if v == job then
            return true
        end
    end

    return false
end

-- [[ Events ]] --
RegisterServerEvent("LENT-PackageService:Server:CreateJob", function()
    local src = source
    if Config.Resource['Job']['JobRequired'] then
        if GetPlayerPostalJob(QBCore.Functions.GetPlayer(src).PlayerData.job.name) then
            TriggerEvent("LENT-PackageService:Server:StartJob", src)
        else
            exports['LENT-Library']:ServerNotification("You are not employed as: LENT-PackageService", 'error')
        end
    else
        TriggerEvent("LENT-PackageService:Server:StartJob", src)
    end
end)

RegisterNetEvent("LENT-PackageService:Server:StartJob", function(source)
    local src = source
    local Coords, Payment, Identifier = GetLocationInfo()

    Jobs[QBCore.Functions.GetPlayer(src).PlayerData.citizenid] = {
        ['JobIdentifier'] = Identifier,
        ['DeliveryLocation'] = vector4(0, 0, 0, 0),
        ['DeliveryVehicleIdentifier'] = 0,
        ['Payment'] = 0,
    }

    Jobs[QBCore.Functions.GetPlayer(src).PlayerData.citizenid]['DeliveryLocation'] = Coords
    Jobs[QBCore.Functions.GetPlayer(src).PlayerData.citizenid]['Payment'] = Payment

    TriggerClientEvent("LENT-PackageService:Client:CreateJob", src)
end)

RegisterNetEvent("LENT-PackageService:Server:NewJob", function(source)
    local src = source

    local Coords, Payment, Identifier = GetLocationInfo(Jobs[QBCore.Functions.GetPlayer(src).PlayerData.citizenid]['JobIdentifier'])

    Jobs[QBCore.Functions.GetPlayer(src).PlayerData.citizenid]['DeliveryLocation'] = Coords
    NewPayment = Jobs[QBCore.Functions.GetPlayer(src).PlayerData.citizenid]['Payment'] + Payment

    local BlipCoords = Jobs[QBCore.Functions.GetPlayer(src).PlayerData.citizenid]['DeliveryLocation']
    local PlayerCitizenId = QBCore.Functions.GetPlayer(src).PlayerData.citizenid

    TriggerClientEvent("LENT-PackageService:Client:AddBoxTarget", src, PlayerCitizenId, BlipCoords)
    TriggerClientEvent("LENT-PackageService:Client:DrawWaypoint", src, BlipCoords)
end)

RegisterNetEvent("LENT-PackageService:Server:CancelJob", function(JobsDone)
    local src = source
    if JobsDone ~= nil then
        TriggerClientEvent("LENT-PackageService:Client:ClearAll", src)
        TriggerClientEvent("LENT-PackageService:Client:ZoneSync", -1)
        TriggerClientEvent("LENT-PackageService:Client:RemoveVehicle", src)
        TriggerEvent("LENT-PackageService:Server:GetPayment", src, JobsDone)
    else
        local Player = QBCore.Functions.GetPlayer(src)
        Player.Functions.SetJob("unemployed", 0)
        if GetResourceState("ps-multijob") == "started" and Config.Resource['Job']['JobRequired'] then
            if QBCore.Functions.GetPlayer(src).PlayerData.job.name == "gopostal" then
                exports["ps-multijob"]:RemoveJob(QBCore.Functions.GetPlayer(src).PlayerData.citizenid, "gopostal")
            elseif QBCore.Functions.GetPlayer(src).PlayerData.job.name == "postop" then
                exports["ps-multijob"]:RemoveJob(QBCore.Functions.GetPlayer(src).PlayerData.citizenid, "postop")
            end
        end
        TriggerClientEvent("LENT-PackageService:Client:ClearAll", src)
        TriggerClientEvent("LENT-PackageService:Client:ZoneSync", -1)
        TriggerClientEvent("LENT-PackageService:Client:RemoveVehicle", src)
    end

    Jobs[QBCore.Functions.GetPlayer(src).PlayerData.citizenid] = nil
end)

RegisterNetEvent("LENT-PackageService:Server:GiveVehicleKeys", function(Plate, Network)
    local src = source

    Jobs[QBCore.Functions.GetPlayer(src).PlayerData.citizenid]['DeliveryVehicleIdentifier'] = Network
    local BlipCoords = Jobs[QBCore.Functions.GetPlayer(src).PlayerData.citizenid]['DeliveryLocation']
    local PlayerCitizenId = QBCore.Functions.GetPlayer(src).PlayerData.citizenid

    TriggerClientEvent("vehiclekeys:client:SetOwner", src, Plate)
    TriggerClientEvent("LENT-PackageService:Client:AddBoxTarget", src, PlayerCitizenId, BlipCoords)
    TriggerClientEvent("LENT-PackageService:Client:DrawWaypoint", src, BlipCoords)
end)

RegisterNetEvent("LENT-PackageService:Server:GetPayment", function(source, JobsDone)
    local src = source
    JobsDone = tonumber(JobsDone)
    if JobsDone > 0 then
        local bonus = 0
        NewPayment = Jobs[QBCore.Functions.GetPlayer(src).PlayerData.citizenid]['Payment']

        if JobsDone > 5 then
            bonus = math.ceil((pay / 10) * 5)
        elseif JobsDone > 10 then
            bonus = math.ceil((pay / 10) * 7)
        elseif  JobsDone > 15 then
            bonus = math.ceil((pay / 10) * 10)
        elseif JobsDone > 20 then
            bonus = math.ceil((pay / 10) * 12)
        end

        local check = bonus + NewPayment

        local Player = QBCore.Functions.GetPlayer(src)
        if Config.Resource['Payment']['Type'] == "bank" then
            local cid = Player.PlayerData.citizenid
            local title
            local issuer
            if Player.PlayerData.job.name == "gopostal" then
                title = 'GoPostal - Salary'
                issuer = 'Fredarick Smith @ GoPostal'
                -- [[ ^ Reference to: Frederick W. Smith CEO FedEx Express ]]
            elseif Player.PlayerData.job.name == "postop" then
                title = 'Post OP - Salary'
                issuer = 'Carrol C. Tome @ Post OP'
                -- [[ ^ Reference to: Carol B. Tomé CEO UPS ]]
            end
            local name = ('%s %s'):format(Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname)
            local txt = 'Salary deposit of: ' .. check
            local reciver = name
            local type = 'deposit'
            exports['Renewed-Banking']:handleTransaction(cid, title, check, txt, issuer, reciver, type)
            Player.Functions.AddMoney('bank', check, 'Delivery Job')
        else
            Player.Functions.AddMoney('cash', check, 'Delivery Job')
        end
    end

    Jobs[QBCore.Functions.GetPlayer(src).PlayerData.citizenid] = nil
end)

RegisterNetEvent("LENT-PackageService:Server:DeliveredPackage", function()
    local src = source
    if Jobs[QBCore.Functions.GetPlayer(src).PlayerData.citizenid] == nil then return end
    TriggerEvent('LENT-PackageService:Server:NewJob', src)
end)
-- [[ Threads ]] --

-- [[ Others ]] --
