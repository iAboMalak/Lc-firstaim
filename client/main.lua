local shot = false
local check = false
local check2 = false
local count = 0
local currentVeh = nil
local lastSeat = nil
local AboMalak = false

local function debugPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local out = ""
    for i = 1, #args do
        out = out .. tostring(args[i])
        if i < #args then out = out .. " | " end
    end
    print("^5[Lc-firstaim]^7 " .. out)
end


CreateThread(function()
    Wait(1000)
    lib.callback('Lc-firstaim:requestResourceInfo', false, function(result)
        if result == true then
            AboMalak = true
            debugPrint("Access granted by server")
        else
            debugPrint("Access denied by server")
        end
    end)
end)

RegisterNetEvent('Lc-firstaim:PrintInfo', function(resName, resVersion, author, discord)
    if AboMalak then return end
    print(("^5[Lc-firstaim]^7 ^3Resource: ^0%s"):format(resName))
    print(("^5[Lc-firstaim]^7 ^3Version: ^0%s"):format(resVersion))
    print(("^5[Lc-firstaim]^7 ^3Author: ^0%s"):format(author))
    print(("^5[Lc-firstaim]^7 ^3Discord: ^0%s"):format(discord))
    AboMalak = true
end)

local function resetState()
    SetFollowVehicleCamViewMode(1)
    shot, check, check2, count, currentVeh, lastSeat = false, false, false, 0, nil, nil
end

lib.onCache('vehicle', function(veh)
    if not AboMalak then return end
    local ped = PlayerPedId()

    if veh then
        currentVeh = veh
        local seat = -2
        for i = -1, GetVehicleMaxNumberOfPassengers(veh) - 1 do
            if GetPedInVehicleSeat(veh, i) == ped then
                seat = i
                break
            end
        end
        lastSeat = seat

        if seat == -1 then
            debugPrint("Player entered vehicle as driver")
        else
            debugPrint("Player entered vehicle but not driver")
        end
    else
        if currentVeh then
            debugPrint("Player left vehicle")
            resetState()
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1)
        if not AboMalak then goto continue end

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh and veh ~= 0 then
            local seat = -2
            for i = -1, GetVehicleMaxNumberOfPassengers(veh) - 1 do
                if GetPedInVehicleSeat(veh, i) == ped then
                    seat = i
                    break
                end
            end

            if seat ~= lastSeat then
                debugPrint("Seat changed from " .. tostring(lastSeat) .. " to " .. tostring(seat))
                lastSeat = seat
                if seat == -1 then
                    debugPrint("Player is now driver")
                    currentVeh = veh
                else
                    if currentVeh then
                        debugPrint("Player left driver seat")
                        resetState()
                    end
                end
            end

            if seat == -1 then
                if IsPlayerFreeAiming(PlayerId()) then
                    if not check then
                        debugPrint("Player is aiming")
                        SetFollowVehicleCamViewMode(4)
                        check = true
                    end
                elseif check then
                    debugPrint("Player stopped aiming")
                    SetFollowVehicleCamViewMode(1)
                    check = false
                end

                if IsPedShooting(ped) then
                    if not shot then
                        debugPrint("Player is shooting (first shot)")
                        SetFollowVehicleCamViewMode(4)
                        shot = true
                        check2 = true
                        count = 0
                    else
                        count = 0
                        debugPrint("Player is shooting")
                    end
                elseif shot then
                    count = count + 1
                    if count > 20 and check2 then
                        debugPrint("Shooting ended, reset camera")
                        resetState()
                    end
                end
            end
        else
            if currentVeh then
                debugPrint("Player left vehicle")
                resetState()
            end
        end

        ::continue::
    end
end)

-- Script By AboMalak | https://discord.gg/LcStore | https://discord.gg/8w8r6Vx8ZJ