MenuData = {}
TriggerEvent("rsg-menubase:getData", function(call)
    MenuData = call
end)

local selectedPed = nil
local previewPed = nil

function OpenPedMenu()
    MenuData.CloseAll()

    local menuElements = {}
    for categoryName, _ in pairs(Config.PedList) do
        table.insert(menuElements, {
            label = categoryName,
            value = categoryName,
            desc = Config.Text.Menu.Open .. " " .. categoryName
        })
    end

    table.insert(menuElements, {
        label = Config.Text.Menu.MyPeds,
        value = "my_peds",
        desc = Config.Text.Menu.AutorPeds
    })

    MenuData.Open('default', GetCurrentResourceName(), 'MainPedMenu', {
        title = Config.Text.Menu.Menupeds,
        subtext = Config.Text.Menu.Sellect,
        align = Config.MenuAlign,
        elements = menuElements,
    }, 
    function(data, menu)
        if data.current.value == "my_peds" then
            TriggerServerEvent("rs_pedmenu:getMyPeds")
        else
            OpenPedSubMenu(data.current.value)
        end
    end, 
    function(data, menu)
        ClosePreviewPed()
        menu.close()
    end)
end

function OpenPedSubMenu(categoryName)
    local pedList = Config.PedList[categoryName]
    if not pedList or #pedList == 0 then return end

    local elements = {}
    for _, ped in ipairs(pedList) do
        table.insert(elements, {
            label = ped,
            value = ped,
            desc = Config.Text.Menu.Request
        })
    end

    MenuData.CloseAll()
    MenuData.Open('default', GetCurrentResourceName(), 'PedSubMenu', {
        title = categoryName,
        subtext = Config.Text.Menu.Select,
        align = Config.MenuAlign,
        elements = elements,
    },
    function(data, menu)
        selectedPed = data.current.value
        OpenPedRequestMenu(selectedPed)
    end,
    function(data, menu)
        ClosePreviewPed()
        menu.close()
        OpenPedMenu()
    end,
    function(data, menu)
        PrevisualizarPed(data.current.value)
    end)
end

RegisterNetEvent("rs_pedmenu:returnMyPeds")
AddEventHandler("rs_pedmenu:returnMyPeds", function(peds)
    local elements = {}
    for _, ped in ipairs(peds) do
        table.insert(elements, {
            label = ped,
            value = ped,
            desc = Config.Text.Menu.YourPeds
        })
    end

    MenuData.CloseAll()

    MenuData.Open('default', GetCurrentResourceName(), 'MyPedsMenu', {
        title = Config.Text.Menu.MyPeds,
        subtext = Config.Text.Menu.Authorized,
        align = Config.MenuAlign,
        elements = elements
    }, 
    function(data, menu)
        SetMonModel(data.current.value)
        menu.close()
    end, 
    function(data, menu)
        menu.close()
        OpenPedMenu()
    end)
end)

function PrevisualizarPed(ped)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local model = GetHashKey(ped)

    if previewPed and DoesEntityExist(previewPed) then
        if GetEntityModel(previewPed) == model then
            local previewCoords = GetEntityCoords(previewPed)
            local dx = playerCoords.x - previewCoords.x
            local dy = playerCoords.y - previewCoords.y
            local heading = math.deg(math.atan2(dy, dx)) + 180.0
            SetEntityHeading(previewPed, heading)
            return
        else
            ClosePreviewPed()
        end
    end

    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) do
        Citizen.Wait(10)
        timeout = timeout + 1
        if timeout > 100 then return end
    end

    local spawnCoords = playerCoords + GetEntityForwardVector(playerPed) * 3.0
    local heading = GetEntityHeading(playerPed) + 180.0

    previewPed = CreatePed(model, spawnCoords.x, spawnCoords.y, spawnCoords.z - 0.8, heading, true, true, false, false)
    if not DoesEntityExist(previewPed) then return end

    SetPedOutfitPreset(previewPed, 0)
    SetEntityAsMissionEntity(previewPed, true, true)
    SetEntityVisible(previewPed, true)
    SetEntityInvincible(previewPed, true)
    FreezeEntityPosition(previewPed, true)
    SetBlockingOfNonTemporaryEvents(previewPed, true)
    SetPedCanRagdoll(previewPed, false)
    SetEntityCollision(previewPed, true, true)
    NetworkRegisterEntityAsNetworked(previewPed)
    SetModelAsNoLongerNeeded(model)
end

function ClosePreviewPed()
    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
        previewPed = nil
    end
end

function OpenPedRequestMenu(ped)
    local elements = {
        {
            label = Config.Text.Menu.RequestAdmin,
            value = "request",
            desc = Config.Text.Menu.SendRequest
        }
    }

    MenuData.Open('default', GetCurrentResourceName(), 'PedRequestMenu', {
        title = Config.Text.Menu.RequestPed,
        subtext = Config.Text.Menu.Options,
        align = Config.MenuAlign,
        elements = elements
    }, 
    function(data, menu)
        if data.current.value == "request" then
            TriggerServerEvent("rs_pedmenu:requestPed", ped)
            ClosePreviewPed()
            menu.close()
        end
    end, 
    function(data, menu)
        ClosePreviewPed()
        menu.close()
        OpenPedSubMenu(GetPedCategory(ped))
    end)
end

function SetMonModel(name)
    local model = GetHashKey(name)
    local player = PlayerId()
    if not IsModelValid(model) then return end
    PerformRequest(model)
    if HasModelLoaded(model) then
        Citizen.InvokeNative(0xED40380076A31506, player, model, false)
        Citizen.InvokeNative(0x283978A15512B2FE, PlayerPedId(), true)
        SetModelAsNoLongerNeeded(model)
    end
end

function PerformRequest(hash)
    RequestModel(hash, 0)
    local attempts = 0
    while not HasModelLoaded(hash) do
        Citizen.Wait(10)
        attempts = attempts + 1
        if attempts > 100 then break end
    end
end

function GetPedCategory(pedName)
    for categoryName, pedList in pairs(Config.PedList) do
        for _, ped in ipairs(pedList) do
            if ped == pedName then return categoryName end
        end
    end
    return nil
end

RegisterCommand(Config.Command.Player, function()
    OpenPedMenu()
end)

RegisterNetEvent("rs_pedmenu:attack")

function SetControlContext(pad, context)
	Citizen.InvokeNative(0x2804658EB7D8A50B, pad, context)
end

function GetPedCrouchMovement(ped)
	return Citizen.InvokeNative(0xD5FE956C70FF370B, ped)
end

function SetPedCrouchMovement(ped, state, immediately)
	Citizen.InvokeNative(0x7DE9692C6F64CFE8, ped, state, immediately)
end

function PlayAnimation(anim)
	if not DoesAnimDictExist(anim.dict) then
		print("Invalid animation dictionary: " .. anim.dict)
		return
	end

	RequestAnimDict(anim.dict)

	while not HasAnimDictLoaded(anim.dict) do
		Citizen.Wait(0)
	end

	TaskPlayAnim(PlayerPedId(), anim.dict, anim.name, 4.0, 4.0, -1, 0, 0.0, false, false, false, "", false)

	RemoveAnimDict(anim.dict)
end

function IsPvpEnabled()
	return GetRelationshipBetweenGroups(`PLAYER`, `PLAYER`) == 5
end

function IsValidTarget(ped)
	return not IsPedDeadOrDying(ped) and not (IsPedAPlayer(ped) and not IsPvpEnabled())
end

function GetClosestPed(playerPed, radius)
	local playerCoords = GetEntityCoords(playerPed)

	local itemset = CreateItemset(true)
	local size = Citizen.InvokeNative(0x59B57C4B06531E1E, playerCoords, radius, itemset, 1, Citizen.ResultAsInteger())

	local closestPed
	local minDist = radius

	if size > 0 then
		for i = 0, size - 1 do
			local ped = GetIndexedItemInItemset(i, itemset)

			if playerPed ~= ped and IsValidTarget(ped) then
				local pedCoords = GetEntityCoords(ped)
				local distance = #(playerCoords - pedCoords)

				if distance < minDist then
					closestPed = ped
					minDist = distance
				end
			end
		end
	end

	if IsItemsetValid(itemset) then
		DestroyItemset(itemset)
	end

	return closestPed
end

function MakeEntityFaceEntity(entity1, entity2)
	local p1 = GetEntityCoords(entity1)
	local p2 = GetEntityCoords(entity2)

	local dx = p2.x - p1.x
	local dy = p2.y - p1.y

	local heading = GetHeadingFromVector_2d(dx, dy)

	SetEntityHeading(entity1, heading)
end

function GetAttackType(playerPed)
	local playerModel = GetEntityModel(playerPed)

	for _, attackType in ipairs(Config.AttackTypes) do
		for _, model in ipairs(attackType.models) do
			if playerModel == model then
				return attackType
			end
		end
	end
end

function ApplyAttackToTarget(attacker, target, attackType)
	if attackType.force > 0 then
		SetPedToRagdoll(target, 1000, 1000, 0, 0, 0, 0)
		SetEntityVelocity(target, GetEntityForwardVector(attacker) * attackType.force)
	end

	if attackType.damage > 0 then
		ApplyDamageToPed(target, attackType.damage, 1, -1, 0)
	end
end

function GetPlayerServerIdFromPed(ped)
	for _, player in ipairs(GetActivePlayers()) do
		if GetPlayerPed(player) == ped then
			return GetPlayerServerId(player)
		end
	end
end

function Attack()
	if IsAttacking then
		return
	end

	local playerPed = PlayerPedId()

	if IsPedDeadOrDying(playerPed) or IsPedRagdoll(playerPed) then
		return
	end

	local attackType = GetAttackType(playerPed)

	if attackType then
		local target = GetClosestPed(playerPed, attackType.radius)

		if target then
			IsAttacking = true

			MakeEntityFaceEntity(playerPed, target)

			PlayAnimation(attackType.animation)

			if IsPedAPlayer(target) then
				TriggerServerEvent("rs_pedmenu:attack", GetPlayerServerIdFromPed(target), -1)
			elseif NetworkGetEntityIsNetworked(target) and not NetworkHasControlOfEntity(target) then
				TriggerServerEvent("rs_pedmenu:attack", -1, PedToNet(target))
			else
				ApplyAttackToTarget(playerPed, target, attackType)
			end

			Citizen.SetTimeout(Config.AttackCooldown, function()
				IsAttacking = false
			end)
		end
	end
end

function ToggleCrouch()
	local playerPed = PlayerPedId()

	SetPedCrouchMovement(playerPed, not GetPedCrouchMovement(playerPed), true)
end

AddEventHandler("rs_pedmenu:attack", function(attacker, entity)
	local attackerPed = GetPlayerPed(GetPlayerFromServerId(attacker))
	local attackType = GetAttackType(attackerPed)

	if entity == -1 then
		if IsPvpEnabled() then
			ApplyAttackToTarget(attackerPed, PlayerPedId(), attackType)
		end
	else
		ApplyAttackToTarget(attackerPed, NetToPed(entity), attackType)
	end
end)


Citizen.CreateThread(function()
	local lastPed = 0

	while true do
		local ped = PlayerPedId()

		if ped ~= lastPed then
			if IsPedHuman(ped) then
				SetControlContext(2, 0)
				IsAnimal = false
			else

				SetPedConfigFlag(ped, 43, true)
				IsAnimal = true
			end

			lastPed = ped
		end

		Citizen.Wait(1000)
	end
end)


Citizen.CreateThread(function()
	while true do
		if IsAnimal then

			SetControlContext(2, `OnMount`)

			DisableFirstPersonCamThisFrame()


			if IsControlJustPressed(0, Config.Controls.Attack) then
				Attack()
			end

			if IsControlJustPressed(0, Config.Controls.Stalk) then
				ToggleCrouch()
			end
		end

		Citizen.Wait(0)
	end
end)

function ForceReload(ped)
    local hasWeapon, weaponHash = GetCurrentPedWeapon(ped, true)
    if hasWeapon and weaponHash ~= GetHashKey("WEAPON_UNARMED") then
        local ammoTotal = GetAmmoInPedWeapon(ped, weaponHash)

        if ammoTotal > 0 and not IsPedReloading(ped) and not IsPedShooting(ped) then
            SetPedAmmo(ped, weaponHash, 0)
            Citizen.Wait(120)

            if not IsPedUsingAnyScenario(ped) then
                ClearPedSecondaryTask(ped)
                TaskReloadWeapon(ped)
            end

            Citizen.Wait(0)

            RefillAmmoInCurrentPedWeapon(ped)
        end
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if IsControlJustPressed(0, 0xE30CD707) then
            local ped = PlayerPedId()

            if IsPedHuman(ped) and not IsPedInAnyVehicle(ped, false) and not IsPedOnMount(ped) then
                ForceReload(ped)
            end
        end
    end
end)
