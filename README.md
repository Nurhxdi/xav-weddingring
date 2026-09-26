# 💍 Xav Wedding Ring - Dokumentasi & Instalasi

Script cincin pernikahan super ringan dan teroptimasi penuh untuk Qbox & ox_inventory.
Dibuat dengan fitur pelacak GPS, status pernikahan tersinkronisasi, dan proteksi anti-spam tingkat lanjut (0.00ms resmon).

## 📦 1. Tambahkan Item ke `ox_inventory`

Buka file pengaturan item ox_inventory kamu yang terletak di:
`ox_inventory/data/items.lua`

Lalu tambahkan kode item di bawah ini ke dalam daftarnya:

```lua
['wedding_ring'] = {
    label = 'Cincin Pernikahan',
    weight = 10,
    stack = true,
    close = true,
    description = 'Cincin pernikahan polos yang bisa didaftarkan ke pasangan.',
    server = {
        export = 'xav-weddingring.useRing'
    }
}
```

> **Catatan Penting:** 
> Pastikan ada bagian `server = { export = 'xav-weddingring.useRing' }`. Ini adalah *hook* wajib agar saat item diklik di tas, script kita yang memprosesnya!

## 🖼️ 2. Gambar Item
Jangan lupa siapkan gambar cincin bernama `wedding_ring.png` lalu masukkan ke dalam folder:
`ox_inventory/web/images/`

## ⚙️ 3. Menyalakan Script
Tambahkan baris berikut di dalam file `server.cfg` milikmu:
```text
ensure xav-weddingring
```

---

## 🎮 Cara Penggunaan (Panduan Roleplay)

**1. Mendaftarkan Pernikahan (Ukir Cincin)**
- Pastikan kamu sebagai admin/petugas memiliki **2 Cincin Polos** di dalam tas.
- Ketik command `/weddingring` di chat.
- Pilih menu **Ukir Cincin Pernikahan**.
- Pilih nama Pengantin Pria, Pengantin Wanita, dan Tanggal.
- Pilih siapa yang akan memegang cincin pasangannya (bisa diserahkan langsung).
- Sistem akan otomatis membuatkan *Nomor Seri Kembar* dan menyuntikkannya ke dalam metadata cincin!

**2. Memakai Cincin & Pelacak GPS**
- Gunakan item cincin dari tas untuk memakainya (cincin akan muncul secara fisik di jari karakter).
- Saat dipasang, pasangan yang memegang cincin kembarannya (dengan nomor seri yang sama) akan menerima **Notifikasi Cinta**.
- Pasangan juga akan melihat **Blip Hati Merah (GPS)** di mapnya selama 15 detik, menunjukkan lokasi tepat di mana pasangannya memasang cincin! *(Terdapat cooldown 10 menit agar tidak spam).*

**3. Pembatalan Pernikahan (Cerai)**
- Jika pasangan bercerai, admin dapat mengetik `/weddingring`.
- Pilih menu **Pembatalan Pernikahan (Cerai)**.
- Sistem akan mereset cincin yang ada di dalam tas admin menjadi cincin polos kembali tanpa error.

---
**💡 Tips:** Jika posisi cincin terlihat tidak pas (melayang/tembus), kamu bisa mengaturnya di dalam file `config.lua` (terdapat settingan terpisah untuk offset pria dan wanita).
