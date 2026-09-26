local ringObj = nil
local isWearingRing = false
local ringMetadata = nil

local function attachRing()
    local hash = type(Config.RingProp) == 'string' and joaat(Config.RingProp) or Config.RingProp
    if not IsModelValid(hash) or not lib.requestModel(hash, 5000) then return end

    local ped = PlayerPedId()

    local objects = GetGamePool('CObject')
    for _, obj in ipairs(objects) do
        if GetEntityModel(obj) == hash and GetEntityAttachedTo(obj) == ped then
            DeleteEntity(obj)
        end
    end

    if ringObj and DoesEntityExist(ringObj) then
        DeleteEntity(ringObj)
    end
    ringObj = nil

    local boneIndex
    if type(Config.AttachBone) == 'number' then
        boneIndex = GetPedBoneIndex(ped, Config.AttachBone)
    else
        boneIndex = GetEntityBoneIndexByName(ped, Config.AttachBone)
    end
    
    ringObj = CreateObject(hash, GetEntityCoords(ped), true, true, false)
    SetEntityCollision(ringObj, false, false)

    local pedModel = GetEntityModel(ped)
    local offset = Config.AttachOffsetMale
    if pedModel == `mp_f_freemode_01` then
        offset = Config.AttachOffsetFemale
    end

    AttachEntityToEntity(
        ringObj, ped, boneIndex,
        offset.pos.x, offset.pos.y, offset.pos.z,
        offset.rot.x, offset.rot.y, offset.rot.z,
        false, false, false, false, 0, true
    )

    SetModelAsNoLongerNeeded(hash)
end

local function detachRing()
    if ringObj and DoesEntityExist(ringObj) then
        DeleteEntity(ringObj)
    end
    ringObj = nil
end

RegisterNetEvent('wedding_ring:client:setRing', function(worn, metadata)
    isWearingRing = worn
    ringMetadata = metadata

    local ped = PlayerPedId()
    local dict = "nmt_3_rcm-10"
    local anim = "cs_nigel_dual-10"

    if lib.requestAnimDict(dict, 2000) then
        -- Mainkan animasi memakai cincin
        TaskPlayAnim(ped, dict, anim, 8.0, -8.0, 1200, 51, 0, false, false, false)
        Wait(1200)
    end

    if worn then
        attachRing()
        local desc = metadata and metadata.description
        if desc then
            TriggerEvent('chat:addMessage', {
                args = { '^5Cincin', ('Kamu memakai: %s'):format(desc) }
            })
        else
            TriggerEvent('chat:addMessage', {
                args = { '^5Cincin', 'Kamu memakai cincin pernikahan (belum diukir).' }
            })
        end
    else
        detachRing()
        TriggerEvent('chat:addMessage', {
            args = { '^5Cincin', 'Kamu melepas cincin.' }
        })
    end
end)

-- Bersihkan cincin saat script direstart
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        detachRing()
    end
end)

-- Pasang ulang cincin saat pemain respawn/mati
AddEventHandler('playerSpawned', function()
    if isWearingRing then
        Wait(500)
        attachRing()
    end
end)

RegisterNetEvent('wedding_ring:client:pingPartner', function(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 436) -- Icon Hati
    SetBlipColour(blip, 1)   -- Merah
    SetBlipScale(blip, 1.2)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Sinyal Pasangan")
    EndTextCommandSetBlipName(blip)

    -- Hapus blip setelah 15 detik menggunakan SetTimeout (0.00ms resmon, tanpa Wait loop)
    SetTimeout(15000, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)

exports('IsWearingRing', function()
    return isWearingRing, ringMetadata
end)



RegisterCommand('ringoffset', function(source, args)
    if not ringObj or not DoesEntityExist(ringObj) then
        print("Kamu sedang tidak memakai cincin!")
        return
    end
    
    local ped = PlayerPedId()
    local pedModel = GetEntityModel(ped)
    local defaultOffset = Config.AttachOffsetMale
    if pedModel == `mp_f_freemode_01` then
        defaultOffset = Config.AttachOffsetFemale
    end

    local px = tonumber(args[1]) or defaultOffset.pos.x
    local py = tonumber(args[2]) or defaultOffset.pos.y
    local pz = tonumber(args[3]) or defaultOffset.pos.z
    local rx = tonumber(args[4]) or defaultOffset.rot.x
    local ry = tonumber(args[5]) or defaultOffset.rot.y
    local rz = tonumber(args[6]) or defaultOffset.rot.z
    
    local boneIndex = type(Config.AttachBone) == 'number' and GetPedBoneIndex(ped, Config.AttachBone) or GetEntityBoneIndexByName(ped, Config.AttachBone)
    
    AttachEntityToEntity(
        ringObj, ped, boneIndex,
        px, py, pz,
        rx, ry, rz,
        false, false, false, false, 0, true
    )
    
    print(('Offset baru: pos = vector3(%s, %s, %s), rot = vector3(%s, %s, %s)'):format(px, py, pz, rx, ry, rz))
end, false)

local function openEngraveDialog()
    local playerOptions = {}
    local players = GetActivePlayers()
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)

    for i = 1, #players do
        local targetPed = GetPlayerPed(players[i])
        local targetCoords = GetEntityCoords(targetPed)
        if #(pCoords - targetCoords) <= 10.0 then
            local serverId = GetPlayerServerId(players[i])
            table.insert(playerOptions, {
                label = 'ID #' .. serverId .. (players[i] == PlayerId() and ' (Kamu)' or ''),
                value = serverId
            })
        end
    end

    if #playerOptions == 0 then
        lib.notify({title = 'Cincin', description = 'Tidak ada orang di sekitarmu.', type = 'error'})
        return
    end

    local input = lib.inputDialog('Pendaftaran Pernikahan', {
        {type = 'select', label = 'Pengantin Pria', description = 'Pilih ID Pengantin Pria', required = true, options = playerOptions},
        {type = 'select', label = 'Pengantin Wanita', description = 'Pilih ID Pengantin Wanita', required = true, options = playerOptions},
        {type = 'date', label = 'Tanggal Pernikahan', format = 'DD/MM/YYYY', required = true},
        {type = 'select', label = 'Penerima Cincin Kedua', description = 'Siapa yang akan memegang cincin pasangan?', required = true, options = playerOptions}
    })

    if not input then return end
    
    local groomId = input[1]
    local brideId = input[2]
    local dateRaw = input[3]
    local targetId = input[4]
    
    TriggerServerEvent('wedding_ring:server:engraveRings', groomId, brideId, dateRaw, targetId)
end

RegisterNetEvent('wedding_ring:client:openMenu', function(fromCommand)
    -- Jika dari tas (use item cincin polos), langsung buka form ukir cincin
    if not fromCommand then
        openEngraveDialog()
        return
    end

    -- Jika dari command (Admin /weddingring), buka menu lengkap
    local menuOptions = {
        {
            title = 'Ukir Cincin Pernikahan',
            description = 'Membutuhkan 2 cincin polos di inventory untuk didaftarkan.',
            icon = 'pen',
            onSelect = function()
                openEngraveDialog()
            end
        },
        {
            title = 'Pembatalan Pernikahan (Cerai)',
            description = 'Menghapus status pernikahan dari semua cincin di tasmu.',
            icon = 'heart-crack',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Konfirmasi Perceraian',
                    content = 'Apakah kamu yakin ingin membatalkan pernikahan dan menghapus nama pasangan dari **semua cincin** di tasmu?\n\nTindakan ini permanen.',
                    centered = true,
                    cancel = true,
                    labels = {
                        confirm = 'Ya, Batalkan Pernikahan',
                        cancel = 'Tutup'
                    }
                })

                if alert == 'confirm' then
                    TriggerServerEvent('wedding_ring:server:clearRings')
                end
            end
        }
    }

    lib.registerContext({
        id = 'wedding_ring_menu',
        title = 'Cincin Pernikahan',
        options = menuOptions
    })
    lib.showContext('wedding_ring_menu')
end)
