-- [[ QBCore ]] --
local QBCore = exports['qb-core']:GetCoreObject()

-- [[ Variables ]] --
local CurrentlyOnJob = false
local ReturnVehicle = false
local JobsDone = 0
local DeliveryCoords = vector3(0, 0, 0)
local PostalVehicle
local PostalBlip

-- [[ Resource ]] --
AddEventHandler("onResourceStart", function(Resource)
    if GetCurrentResourceName() == Resource then
        PlayerJob = QBCore.Functions.GetPlayerData().job
    end
end)

AddEventHandler("onResourceStop", function(Resource)
    if GetCurrentResourceName() == Resource then
        RemoveBlip(PostalBlip)
    end
end)

-- [[ Functions ]] --

-- [[ Events ]] --
RegisterNetEvent("QBCore:Client:onPlayerLoaded", function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate", function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
end)

RegisterNetEvent("LENT-PackageService:Client:CreateJob", function()
    if QBCore.Functions.GetPlayerData().job.name == "gopostal" then
        VehicleHash = Config.Resource['Vehicle']['GPVehicleModel']
        QBCore.Functions.LoadModel(VehicleHash)
        VehicleSpawn = Config.Resource['Vehicle']['GPVehicleCoords']
        PostalVehicle = CreateVehicle(VehicleHash, VehicleSpawn.x, VehicleSpawn.y, VehicleSpawn.z, VehicleSpawn.w, true, true)
    elseif QBCore.Functions.GetPlayerData().job.name == "postop" then
        VehicleHash = Config.Resource['Vehicle']['POPVehicleModel']
        QBCore.Functions.LoadModel(VehicleHash)
        VehicleSpawn = Config.Resource['Vehicle']['POPVehicleCoords']
        PostalVehicle = CreateVehicle(VehicleHash, VehicleSpawn.x, VehicleSpawn.y, VehicleSpawn.z, VehicleSpawn.w, true, true)
    end


    local Plate = GetVehicleNumberPlateText(PostalVehicle)
    local Network = NetworkGetNetworkIdFromEntity(PostalVehicle)

    SetEntityAsMissionEntity(PostalVehicle)
    SetNetworkIdExistsOnAllMachines(PostalVehicle, true)
    NetworkRegisterEntityAsNetworked(PostalVehicle)
    SetNetworkIdCanMigrate(PostalVehicle, true)

    SetVehicleDirtLevel(PostalVehicle, math.random(1, 15))
    SetVehicleEngineOn(PostalVehicle, true, true)
    SetVehicleDoorsLocked(PostalVehicle, 1)

    exports[Config.Resource['Fuel']]:SetFuel(PostalVehicle, 100)

    CurrentlyOnJob = true
    TriggerServerEvent("LENT-PackageService:Server:GiveVehicleKeys", Plate, Network)
end)

RegisterNetEvent("LENT-PackageService:Client:AddBoxTarget", function(PlayerCitizenId, Coords)
    print(Coords)
    DeliveryCoords = Coords
    exports["qb-target"]:AddBoxZone(PlayerCitizenId, vector3(DeliveryCoords.x, DeliveryCoords.y, DeliveryCoords.z), 3.5, 2.0, {
        name = PlayerCitizenId,
        heading = DeliveryCoords.w,
        debugPoly = Config.Resource['Debug'],
        minZ = DeliveryCoords.z - 1,
        maxZ = DeliveryCoords.z + 1,
    }, {
        options = {
            {
                icon = 'fas fa-box',
                label = "Deliver Package",
                canInteract = function()
                    return not cl_delivered
                end,
                action = function()
                    TriggerEvent("LENT-PackageService:Client:DeliverPackage")
                end
            },
        },
        distance = 2.0
    })
end)

RegisterNetEvent("LENT-PackageService:Client:DeliverPackage", function()
    ExecuteCommand("e knock")
    QBCore.Functions.Progressbar("delivering_package", "Delivering Package", math.random(2500, 7500), false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        ExecuteCommand("e c")
        TriggerEvent("LENT-PackageService:Client:SendJob")
        TriggerServerEvent("LENT-Library:Server:SendPhoneEmail", "PackageService", "Delivery Status", "You made that delivery? Well good! We've marked the next location on your G.P.S.!")
    end, function()
        ExecuteCommand("e c")
        TriggerServerEvent("LENT-Library:Server:SendPhoneEmail", "PackageService", "Delivery Status", "Why did you not deliver that package? Deliver it and hurry up!")
    end)
end)

RegisterNetEvent("LENT-PackageService:Client:SendJob", function()
    if CurrentlyOnJob then
        JobsDone = JobsDone + 1
        RemoveBlip(PostalBlip)
        Wait(2500)
        TriggerServerEvent("LENT-PackageService:Server:DeliveredPackage")
    end
end)

RegisterNetEvent("LENT-PackageService:Client:GetPaySlip", function()
    if JobsDone > 0 then
        TriggerServerEvent('LENT-PackageService:Server:CancelJob', JobsDone)
        JobsDone = 0
    else
        TriggerServerEvent("LENT-Library:Server:SendPhoneEmail", "PackageService", "Employment Status", "If you did not want to work for us you should've told us! You're FIRED!")
        TriggerServerEvent("LENT-Electrician:Server:ReturnVehicle", JobsDone, true)
    end
end)

RegisterNetEvent("LENT-PackageService:Client:ClearAll", function()
    CurrentlyOnJob = false
    DeliveryCoords = vector3(0, 0, 0)
    RetrunVehicle = false
    RemoveBlip(PostalBlip)
end)

RegisterNetEvent("LENT-PackageService:Client:RemoveVehicle", function()
    if DoesEntityExist(PostalVehicle) then
        NetworkRequestControlOfEntity(Postalvehicle)
        Wait(500)
        DeleteEntity(PostalVehicle)
        PostalVehicle = nil
    end
end)

RegisterNetEvent("LENT-PackageService:Client:ZoneSync", function(PlayerCitizenId)
    exports['qb-target']:RemoveZone(PlayerCitizenId)
end)

RegisterNetEvent("LENT-PackageService:Client:DrawWaypoint", function(Coords)
    PostalBlip = AddBlipForCoord(Coords.x, Coords.y, Coords.z)
    SetBlipSprite(PostalBlip, 478)
    SetBlipScale(PostalBlip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName('Deliver Package')
    EndTextCommandSetBlipName(PostalBlip)
    SetBlipColour(PostalBlip, 26)
    SetBlipRoute(PostalBlip, true)
    SetBlipRouteColour(PostalBlip, 5)
end)

-- [[ Threads ]] --
CreateThread(function()
    local JobBlip = AddBlipForCoord(Config.Resource['Ped']['GPPedLocation'].x, Config.Resource['Ped']['GPPedLocation'].y, Config.Resource['Ped']['GPPedLocation'].z)
    SetBlipSprite(JobBlip, 738)
    SetBlipColour(JobBlip, 59)
    SetBlipScale(JobBlip, 0.8)
    SetBlipAsShortRange(JobBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName("GoPostal")
    EndTextCommandSetBlipName(JobBlip)

    local JobBlip2 = AddBlipForCoord(Config.Resource['Ped']['POPPedLocation'].x, Config.Resource['Ped']['POPPedLocation'].y, Config.Resource['Ped']['POPPedLocation'].z)
    SetBlipSprite(JobBlip2, 389)
    SetBlipColour(JobBlip2, 56)
    SetBlipScale(JobBlip2, 0.8)
    SetBlipAsShortRange(JobBlip2, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName("Post OP")
    EndTextCommandSetBlipName(JobBlip2)

    QBCore.Functions.LoadModel(Config.Resource['Ped']['GPPedModel'])
    local PostalPed = CreatePed(0, Config.Resource['Ped']['GPPedModel'], Config.Resource['Ped']['GPPedLocation'].x, Config.Resource['Ped']['GPPedLocation'].y, Config.Resource['Ped']['GPPedLocation'].z - 1, Config.Resource['Ped']['GPPedLocation'].w, false, false)
    TaskStartScenarioInPlace(PostalPed, 'WORLD_HUMAN_CLIPBOARD', true)
    FreezeEntityPosition(PostalPed, true)
    SetEntityInvincible(PostalPed, true)
    SetBlockingOfNonTemporaryEvents(PostalPed, true)

    QBCore.Functions.LoadModel(Config.Resource['Ped']['POPPedModel'])
    local PostalPed2 = CreatePed(0, Config.Resource['Ped']['POPPedModel'], Config.Resource['Ped']['POPPedLocation'].x, Config.Resource['Ped']['POPPedLocation'].y, Config.Resource['Ped']['POPPedLocation'].z - 1, Config.Resource['Ped']['POPPedLocation'].w, false, false)
    TaskStartScenarioInPlace(PostalPed2, 'WORLD_HUMAN_CLIPBOARD', true)
    FreezeEntityPosition(PostalPed2, true)
    SetEntityInvincible(PostalPed2, true)
    SetBlockingOfNonTemporaryEvents(PostalPed2, true)

    exports['qb-target']:AddTargetEntity(PostalPed, {
        options = {
            { -- Create Jpb
                icon = 'fas fa-circle',
                label = 'Request Job',
                canInteract = function()
                    return not CurrentlyOnJob
                end,
                action = function()
                    TriggerServerEvent('LENT-PackageService:Server:CreateJob')
                end,
            },
            { -- Cancel the current job
                icon = 'fas fa-circle',
                label = 'Cancel Job',
                canInteract = function()
                    return CurrentlyOnJob
                end,
                action = function()
                    TriggerEvent('LENT-PackageService:Client:GetPaySlip')
                end,
            },
        },

        distance = 2.0
    })

    exports['qb-target']:AddTargetEntity(PostalPed2, {
        options = {
            { -- Create Jpb
                icon = 'fas fa-circle',
                label = 'Request Job',
                canInteract = function()
                    return not CurrentlyOnJob
                end,
                action = function()
                    TriggerServerEvent('LENT-PackageService:Server:CreateJob')
                end,
            },
            { -- Cancel the current job
                icon = 'fas fa-circle',
                label = 'Cancel Job',
                canInteract = function()
                    return CurrentlyOnJob
                end,
                action = function()
                    TriggerEvent('LENT-PackageService:Client:GetPaySlip')
                end,
            },
        },

        distance = 2.0
    })
end)

-- [[ Others ]] --
if Config.Resource['Debug'] then
    for _, v in pairs(Config.Resource['JobLocations'][1]["Coords"]) do
        print(vector3(v.x, v.y, v.z))
        exports["qb-target"]:AddBoxZone("testing", vector3(v.x, v.y, v.z), 3.5, 2.0, {
            name = "testing",
            heading = v.w,
            debugPoly = Config.Resource['Debug'],
            minZ = v.z - 1000,
            maxZ = v.z + 1000,
        }, {
            options = {
                {
                    icon = 'fas fa-circle',
                    label = 'Cancel Job',
                    canInteract = function()
                        return CurrentlyOnJob
                    end,
                    action = function()
                        print("Testing!")
                    end,
                }
            }
        })
    end
end