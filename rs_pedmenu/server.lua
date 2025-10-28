local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent("rs_pedmenu:attack")
AddEventHandler("rs_pedmenu:attack", function(target, entity)
    TriggerClientEvent("rs_pedmenu:attack", target, source, entity)
end)

RegisterServerEvent("rs_pedmenu:requestPed")
AddEventHandler("rs_pedmenu:requestPed", function(pedName)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    local identifier = Player.PlayerData.citizenid

    exports.oxmysql:insert(
        "INSERT INTO ped_requests (identifier, playerName, ped) VALUES (?,?,?)",
        {identifier, playerName, pedName},
        function()
            TriggerClientEvent('ox_lib:notify', src, {
                title = Config.Text.Notify.Title,
                description = Config.Text.Notify.SentAdmin,
                type = 'success',
                position = 'top-center'
            })
        end
    )
end)

RegisterServerEvent("rs_pedmenu:getPendingRequests")
AddEventHandler("rs_pedmenu:getPendingRequests", function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if not RSGCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Text.Notify.Title,
            description = Config.Text.Notify.NotPermission,
            type = 'error',
            position = 'top-center'
        })
        return
    end

    exports.oxmysql:execute("SELECT id, playerName, ped FROM ped_requests WHERE status='pending'", {}, function(result)
        TriggerClientEvent("rs_pedmenu:returnPendingRequests", src, result)
    end)
end)

RegisterServerEvent("rs_pedmenu:authorizePed")
AddEventHandler("rs_pedmenu:authorizePed", function(requestId)
    local src = source
    exports.oxmysql:execute("SELECT * FROM ped_requests WHERE id = ? AND status='pending'", {requestId}, function(result)
        if result[1] then
            local req = result[1]
            exports.oxmysql:insert("INSERT INTO user_peds (identifier, playerName, ped) VALUES (?,?,?)", {
                req.identifier, req.playerName, req.ped
            })
            exports.oxmysql:execute("DELETE FROM ped_requests WHERE id = ?", {requestId})
            TriggerClientEvent('ox_lib:notify', src, {
                title = Config.Text.Notify.Title,
                description = Config.Text.Notify.AuthorizedCorrected,
                type = 'success',
                position = 'top-center'
            })
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = Config.Text.Notify.Title,
                description = Config.Text.Notify.AuthorizedError,
                type = 'error',
                position = 'top-center'
            })
        end
    end)
end)

RegisterServerEvent("rs_pedmenu:rejectPed")
AddEventHandler("rs_pedmenu:rejectPed", function(requestId)
    local src = source
    exports.oxmysql:execute("DELETE FROM ped_requests WHERE id = ?", {requestId}, function(affected)
        if affected and affected.affectedRows > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = Config.Text.Notify.Title,
                description = Config.Text.Notify.DeleteCorrected,
                type = 'success',
                position = 'top-center'
            })
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = Config.Text.Notify.Title,
                description = Config.Text.Notify.DeleteError,
                type = 'error',
                position = 'top-center'
            })
        end
    end)
end)

RegisterServerEvent("rs_pedmenu:getMyPeds")
AddEventHandler("rs_pedmenu:getMyPeds", function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local identifier = Player.PlayerData.citizenid
    exports.oxmysql:execute("SELECT ped FROM user_peds WHERE identifier = ?", {identifier}, function(result)
        local peds = {}
        for _, row in ipairs(result) do
            table.insert(peds, row.ped)
        end
        TriggerClientEvent("rs_pedmenu:returnMyPeds", src, peds)
    end)
end)

RegisterServerEvent("rs_pedmenu:getUserPeds")
AddEventHandler("rs_pedmenu:getUserPeds", function()
    local src = source
    if not RSGCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Text.Notify.Title,
            description = Config.Text.Notify.NotPermission,
            type = 'error',
            position = 'top-center'
        })
        return
    end

    exports.oxmysql:execute("SELECT identifier, playerName, ped FROM user_peds", {}, function(result)
        TriggerClientEvent("rs_pedmenu:returnUserPeds", src, result)
    end)
end)

RegisterServerEvent("rs_pedmenu:removePed")
AddEventHandler("rs_pedmenu:removePed", function(playerName, pedName)
    local src = source
    exports.oxmysql:execute("DELETE FROM user_peds WHERE playerName = ? AND ped = ?", {playerName, pedName}, function(affected)
        if affected and affected.affectedRows > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = Config.Text.Notify.Title,
                description = Config.Text.Notify.DeletePedCorrected,
                type = 'success',
                position = 'top-center'
            })
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = Config.Text.Notify.Title,
                description = Config.Text.Notify.DeletePedError,
                type = 'error',
                position = 'top-center'
            })
        end
    end)
end)

RegisterCommand(Config.Command.Admin, function(source)
    if RSGCore.Functions.HasPermission(source, 'admin') then
        TriggerClientEvent("rs_pedmenu:openAdminMenu", source)
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = Config.Text.Notify.Title,
            description = Config.Text.Notify.NotPermission,
            type = 'error',
            position = 'top-center'
        })
    end
end)