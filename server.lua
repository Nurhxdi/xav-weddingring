local ox_inventory = exports.ox_inventory

-- Variabel Global
local wornRing = {}     -- Menyimpan slot cincin yang sedang dipakai pemain
local spamCooldown = {} -- Mencegah spam klik cincin (cooldown 3 detik)
local blipCooldown = {} -- Mencegah spam sinyal GPS (cooldown 10 menit)

--------------------------------------------------
-- Event: Memakai & Melepas Cincin
--------------------------------------------------
exports('useRing', function(event, item, inventory, slot, data)
    if event == 'usingItem' then
        local src = inventory.id
        if type(src) ~= 'number' then return end

        -- Proteksi Spam
        local now = os.time()
        if spamCooldown[src] and (now - spamCooldown[src]) < 3 then
            TriggerClientEvent('ox_lib:notify', src, { type = 'warning', description = 'Jangan terburu-buru! (Cooldown 3 detik)' })
            return false
        end
        spamCooldown[src] = now

        -- Tarik data item langsung dari server agar metadata 100% akurat
        local realItem = ox_inventory:GetSlot(src, slot)
        if not realItem then return false end

        local metadata = realItem.metadata or {}
        local isEngraved = metadata.serial or metadata.groom or (metadata.description and string.find(metadata.description, 'Tanggal:'))

        -- Jika cincin masih polos, buka menu pendaftaran
        if not isEngraved then
            TriggerClientEvent('wedding_ring:client:openMenu', src, false)
            return false
        end

        local currentlyWorn = wornRing[src]

        -- Logika Lepas/Pakai
        if currentlyWorn and currentlyWorn.slot == slot then
            wornRing[src] = nil
            TriggerClientEvent('wedding_ring:client:setRing', src, false, nil)
        else
            wornRing[src] = { slot = slot }
            TriggerClientEvent('wedding_ring:client:setRing', src, true, metadata)
            -- Sinyal Pasangan (Menggunakan Thread Yielding agar server tetap ringan)
            if metadata.serial then
                local nowTime = os.time()
                if not blipCooldown[metadata.serial] or (nowTime - blipCooldown[metadata.serial]) >= 600 then
                    blipCooldown[metadata.serial] = nowTime
                    
                    CreateThread(function()
                        local allPlayers = GetPlayers()
                        for i, pId in ipairs(allPlayers) do
                            pId = tonumber(pId)
                            if pId ~= src then
                                -- Cari pasangan yang memiliki cincin dengan nomor seri yang sama
                                local count = exports.ox_inventory:Search(pId, 'count', Config.RingItemName, { serial = metadata.serial })
                                if count and count > 0 then
                                    local wearerPed = GetPlayerPed(src)
                                    local coords = GetEntityCoords(wearerPed)
                                    TriggerClientEvent('ox_lib:notify', pId, { type = 'info', title = 'Sinyal Cincin', description = 'Pasanganmu baru saja memakai cincinnya! Sinyalnya terekam di GPS selama 15 detik.' })
                                    TriggerClientEvent('wedding_ring:client:pingPartner', pId, coords)
                                    break
                                end
                            end
                            -- Eksekusi instan tanpa delay untuk 100 pemain pertama
                            if i % 100 == 0 then Wait(0) end
                        end
                    end)
                else
                    TriggerClientEvent('ox_lib:notify', src, { type = 'warning', description = 'Sinyal ke pasangan baru bisa dikirim lagi dalam beberapa menit (Cooldown 10 Menit).' })
                end
            end
        end
        return true
    end
end)

--------------------------------------------------
-- Event: Pelepasan Cincin Otomatis (Saat item pindah/hilang)
--------------------------------------------------
AddEventHandler('ox_inventory:updateSlots', function(source, slots, inventory)
    local worn = wornRing[source]
    if not worn then return end

    -- Cek langsung ke slot bersangkutan
    local item = exports.ox_inventory:GetSlot(source, worn.slot)
    
    if not item or item.name ~= Config.RingItemName then
        wornRing[source] = nil
        TriggerClientEvent('wedding_ring:client:setRing', source, false, nil)
    end
end)

-- Pembersihan memory saat player keluar
AddEventHandler('playerDropped', function()
    local src = source
    wornRing[src] = nil
    spamCooldown[src] = nil
end)


--------------------------------------------------
-- Command & Pendaftaran Pernikahan
--------------------------------------------------
RegisterCommand(Config.EngraveCommand, function(source, args, rawCommand)
    if source == 0 then return end
    
    -- Cek otorisasi admin melalui Qbox (mendukung God & Admin)
    if not exports.qbx_core:HasPermission(source, 'admin') then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Kamu tidak memiliki akses ke command ini.' })
        return
    end

    TriggerClientEvent('wedding_ring:client:openMenu', source, true)
end, false)

RegisterNetEvent('wedding_ring:server:engraveRings', function(groomId, brideId, date, targetId)
    local src = source
    targetId = tonumber(targetId)
    
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Gagal', description = 'ID Penerima tidak valid atau offline.' })
        return
    end

    -- Cek ketersediaan cincin polos di tas pendaftar
    local ringSlots = exports.ox_inventory:Search(src, 'slots', Config.RingItemName)
    local totalPlainRings = 0
    
    if ringSlots then
        for _, item in ipairs(ringSlots) do
            if not item.metadata or not item.metadata.serial then
                totalPlainRings = totalPlainRings + item.count
            end
        end
    end
    
    if totalPlainRings < 2 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Gagal', description = 'Dibutuhkan minimal 2 cincin POLOS di tas.' })
        return
    end
    
    -- Tarik nama karakter Qbox (Fallback ke ID jika offline)
    local groomPlayer = exports.qbx_core:GetPlayer(tonumber(groomId))
    local bridePlayer = exports.qbx_core:GetPlayer(tonumber(brideId))

    local groomName = groomPlayer and groomPlayer.PlayerData.charinfo.firstname or ('ID #' .. groomId)
    local brideName = bridePlayer and bridePlayer.PlayerData.charinfo.firstname or ('ID #' .. brideId)

    -- Format tanggal & Pembuatan Metadata
    local dateString = type(date) == 'number' and os.date('%d/%m/%Y', math.floor(date / 1000)) or tostring(date)
    local serial = 'WD-' .. math.random(10000, 99999)
    local description = string.format(Config.DescriptionFormat, groomName, brideName) .. '\nTanggal: ' .. dateString
    
    local metadata = {
        description = description,
        groom = groomName,
        bride = brideName,
        date = dateString,
        serial = serial
    }

    -- Tarik 2 cincin polos dari inventory pendaftar
    local removedCount = 0
    if ringSlots then
        for _, item in ipairs(ringSlots) do
            if removedCount < 2 then
                if not item.metadata or not item.metadata.serial then
                    local toRemove = math.min(item.count, 2 - removedCount)
                    if exports.ox_inventory:RemoveItem(src, Config.RingItemName, toRemove, nil, item.slot) then
                        removedCount = removedCount + toRemove
                    end
                end
            end
        end
    end
    
    if removedCount < 2 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Error', description = 'Gagal menarik cincin dari tas.' })
        return
    end

    -- Distribusi cincin berukir
    if targetId == src then
        -- Simpan ke diri sendiri
        ox_inventory:AddItem(src, Config.RingItemName, 2, metadata)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', title = 'Berhasil', description = ('Cincin berhasil diukir! Keduanya disimpan di tasmu. (Serial: %s)'):format(serial) })
    else
        -- Bagi ke diri sendiri & pasangan
        ox_inventory:AddItem(src, Config.RingItemName, 1, metadata)
        local success = ox_inventory:AddItem(targetId, Config.RingItemName, 1, metadata)
        
        if success then
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', title = 'Berhasil', description = ('1 Cincin masuk tasmu, 1 lagi diberikan ke ID %s!'):format(targetId) })
            TriggerClientEvent('ox_lib:notify', targetId, { type = 'info', title = 'Hadiah Cincin', description = ('ID %s mendaftarkan cincin pernikahan di tasmu!'):format(src) })
        else
            -- Jika tas pasangan penuh, tarik kembali cincin
            ox_inventory:AddItem(src, Config.RingItemName, 1, metadata)
            TriggerClientEvent('ox_lib:notify', src, { type = 'warning', title = 'Peringatan', description = 'Tas penerima penuh! Kedua cincin dikembalikan kepadamu.' })
        end
    end
end)

--------------------------------------------------
-- Event: Membatalkan Pernikahan (Cerai)
--------------------------------------------------
RegisterNetEvent('wedding_ring:server:clearRings', function()
    local src = source
    local ringSlots = exports.ox_inventory:Search(src, 'slots', Config.RingItemName)
    local cleared = false
    
    if ringSlots and #ringSlots > 0 then
        for _, item in ipairs(ringSlots) do
            -- Dikosongkan agar ox_inventory mengembalikan deskripsi default items.lua
            exports.ox_inventory:SetMetadata(src, item.slot, {
                description = nil,
                groom = nil,
                bride = nil,
                date = nil,
                serial = nil
            })
            cleared = true
            
            local worn = wornRing[src]
            if worn and worn.slot == item.slot then
                wornRing[src] = nil
                TriggerClientEvent('wedding_ring:client:setRing', src, false, nil)
            end
        end
    end
    
    if cleared then
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', title = 'Berhasil', description = 'Status pernikahan dari semua cincin di tasmu telah dibatalkan.' })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Gagal', description = 'Kamu tidak memiliki cincin pernikahan di dalam tas.' })
    end
end)
