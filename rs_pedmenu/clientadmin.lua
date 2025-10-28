MenuData = {}
TriggerEvent("rsg-menubase:getData", function(call)
    MenuData = call
end)

function OpenAdminPedMenu()
    MenuData.CloseAll()
    TriggerServerEvent("rs_pedmenu:getPendingRequests")
end

RegisterNetEvent("rs_pedmenu:returnPendingRequests")
AddEventHandler("rs_pedmenu:returnPendingRequests", function(requests)
    local elements = {}

    for _, req in ipairs(requests) do
        table.insert(elements, {
            label = Config.Text.Menu.Player .. " " .. req.playerName,
            value = req.id,
            desc = req.ped
        })
    end

    table.insert(elements, {
        label = Config.Text.Menu.SeeAuthorized,
        value = "view_user_peds"
    })

    MenuData.CloseAll()
    MenuData.Open('default', GetCurrentResourceName(), 'AdminPedMenu', {
        title = Config.Text.Menu.Applications,
        subtext = Config.Text.Menu.AdminOptions,
        align = Config.MenuAlign,
        elements = elements
    },
    function(data, menu)
        if data.current.value == "view_user_peds" then
            MenuData.CloseAll()
            TriggerServerEvent("rs_pedmenu:getUserPeds")
            return
        end

        local pedId = data.current.value
        local pedName = data.current.desc
        local opts = {
            {label = Config.Text.Menu.Approve, value = "approve"},
            {label = Config.Text.Menu.Reject, value = "reject"}
        }

        MenuData.CloseAll()
        MenuData.Open('default', GetCurrentResourceName(), 'AdminPedOptions', {
            title = Config.Text.Menu.Grant,
            subtext = pedName,
            align = Config.MenuAlign,
            elements = opts
        },
        function(optData, optMenu)
            if optData.current.value == "approve" then
                TriggerServerEvent("rs_pedmenu:authorizePed", pedId)
            elseif optData.current.value == "reject" then
                TriggerServerEvent("rs_pedmenu:rejectPed", pedId)
            end
            MenuData.CloseAll()
        end,
        function(data, menu)
            menu.close()
        end)
    end,
    function(data, menu)
        menu.close()
    end)
end)

RegisterNetEvent("rs_pedmenu:returnUserPeds")
AddEventHandler("rs_pedmenu:returnUserPeds", function(peds)
    local pedMap = {}

    for _, row in ipairs(peds) do
        if not pedMap[row.playerName] then pedMap[row.playerName] = {} end
        table.insert(pedMap[row.playerName], row.ped)
    end

    local playerElements = {}
    for playerName, _ in pairs(pedMap) do
        table.insert(playerElements, {label = playerName, value = playerName})
    end

    MenuData.CloseAll()
    MenuData.Open('default', GetCurrentResourceName(), 'UserPedList', {
        title = Config.Text.Menu.Authorized,
        subtext = Config.Text.Menu.SelectPlayer,
        align = Config.MenuAlign,
        elements = playerElements
    },
    function(data, menu)
        local selected = data.current.value
        local pedList = pedMap[selected] or {}
        local pedElements = {}

        for _, ped in ipairs(pedList) do
            table.insert(pedElements, {label = ped, value = ped})
        end

        MenuData.CloseAll()
        MenuData.Open('default', GetCurrentResourceName(), 'PlayerPeds', {
            title = selected,
            subtext = Config.Text.Menu.Delete,
            align = Config.MenuAlign,
            elements = pedElements
        },
        function(pedData, pedMenu)
            TriggerServerEvent("rs_pedmenu:removePed", selected, pedData.current.value)
            MenuData.CloseAll()
        end,
        function(data, menu)
            menu.close()
        end)
    end,
    function(data, menu)
        menu.close()
    end)
end)

RegisterNetEvent("rs_pedmenu:openAdminMenu")
AddEventHandler("rs_pedmenu:openAdminMenu", function()
    OpenAdminPedMenu()
end)