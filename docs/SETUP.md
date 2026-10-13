# SETUP — dari HP

## Prasyarat
- Akun GitHub
- Akun Supabase (gratis)
- Termux (dari F-Droid, bukan Play Store — versi Play Store usang)

## 1. Bikin repo

1. Buka github.com/new dari browser HP
2. Nama: `arched-merchant`
3. Private (wajib — ini proyek duit)
4. Centang "Add a README file"
5. Create

## 2. Masukin semua file

Dari browser HP, tinggal klik "Add file" → "Create new file",
copy path + isi dari daftar file di atas satu-satu. Repot tapi jalan.

Alternatif lebih cepet: pakai Termux (langkah 3).

## 3. Termux — clone repo & setup

```bash
pkg update && pkg upgrade -y
pkg install -y git nodejs-lts openjdk-17

git clone https://github.com/USERNAME/arched-merchant.git
cd arched-merchant
