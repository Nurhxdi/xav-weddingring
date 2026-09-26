Config = {}

-- Nama item cincin di ox_inventory (harus sama persis dengan yang didaftarkan di items.lua)
Config.RingItemName = 'wedding_ring'

-- Nama model = nama file tanpa ekstensi, jadi HARUS 'weddingring'
Config.RingProp = 'weddingring'

-- Bone tempat cincin dipasang (4137 = Jari manis kiri bagian tengah / SKEL_L_Finger31)
Config.AttachBone = 4137
Config.AttachOffsetMale = {
    pos = vector3(-0.015, -0.035, 0.017),
    rot = vector3(-10.0, -180.0, -130.0)
}

Config.AttachOffsetFemale = {
    pos = vector3(-0.003, -0.032, 0.018),
    rot = vector3(-15.0, -180.0, -125.0)
}

-- Command untuk membuka menu cincin pernikahan
Config.EngraveCommand = 'weddingring'

-- Format teks deskripsi hasil ukiran, %s pertama = nama pria, %s kedua = nama wanita
Config.DescriptionFormat = 'Cincin pernikahan antara %s & %s'
