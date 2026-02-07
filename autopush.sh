
echo ""

# Tampilkan perubahan
echo "📋 PERUBAHAN SAAT INI:"
git status --short

echo ""
echo "📦 PILIHAN STAGING:"
echo "1) Stage SEMUA perubahan (git add .)"
echo "2) Stage PER FILE (pilih manual)"
echo "3) Stage PER FOLDER (berdasarkan struktur)"
echo "4) INTERACTIVE mode (git add -p)"
echo "5) BATALKAN"
echo ""

read -p "Pilihan [1-5]: " stage_choice

case $stage_choice in
  1)
    echo "🔄 Staging semua perubahan..."
    git add .
    ;;
    
  2)
    echo ""
    echo "📁 File yang bisa di-stage:"
    # Hanya tampilkan modified/deleted/added, bukan untracked
    git ls-files --modified --deleted --others --exclude-standard | while read file; do
      echo "  $file"
    done
    
    echo ""
    read -p "🔤 Masukkan nama file (pisah dengan spasi): " selected_files
    if [ -n "$selected_files" ]; then
      for file in $selected_files; do
        if [ -f "$file" ] || [ -d "$file" ]; then
          git add "$file"
          echo "  ✓ Staged: $file"
        else
          echo "  ✗ File tidak ditemukan: $file"
        fi
      done
    fi
    ;;
    
  3)
    echo ""
    echo "🗂  Folder dalam proyek:"
    find . -type d -name "src" -o -name "components" -o -name "services" \
           -o -name "utils" -o -name "tests" -o -name "docs" | \
           grep -v node_modules | grep -v .git | head -10
    
    read -p "📂 Masukkan nama folder: " folder
    if [ -d "$folder" ]; then
      git add "$folder"
      echo "✓ Staged folder: $folder"
    else
      echo "Folder tidak ditemukan"
    fi
    ;;
    
  4)
    echo "🔍 Mode Interactive - Pilih perubahan secara granular"
    git add -p
    ;;
    
  5)
    echo "❌ Dibatalkan"
    exit 0
    ;;
esac

# Lanjut ke commit
echo ""
echo "✅ Staging selesai. Melanjutkan ke commit..."

#!/bin/bash

# Warna untuk output
MERAH='\033[0;31m'
HIJAU='\033[0;32m'
KUNING='\033[1;33m'
BIRU='\033[0;34m'
UNGU='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =========================
# Dapatkan branch saat ini
# =========================
BRANCH_SAAT_INI=$(git branch --show-current)

# =========================
# Periksa perubahan yang di-staged
# =========================
echo -e "${BIRU}=== Memeriksa perubahan yang di-staged... ===${NC}"

PERUBAHAN=$(git diff --cached --unified=0 | head -n 100)
FILE=$(git diff --cached --name-only)

if [ -z "$FILE" ]; then
  echo -e "${MERAH}Tidak ada perubahan yang di-staged.${NC}"
  echo -e "${KUNING}Anda perlu men-stage file terlebih dahulu:${NC}"
  echo "  git add <file>"
  echo "  atau"
  echo "  git add ."
  exit 1
fi

echo -e "${HIJAU}✓ Perubahan ditemukan${NC}"
echo ""

# =========================
# Tampilkan ringkasan perubahan
# =========================
echo -e "${CYAN}=== Ringkasan Perubahan ===${NC}"
echo -e "${KUNING}Branch Saat Ini:${NC} $BRANCH_SAAT_INI"
echo ""
echo -e "${KUNING}File yang akan di-commit:${NC}"
echo "$FILE" | while read file; do
  STATUS=$(git diff --cached --name-status "$file" | cut -f1)
  case $STATUS in
    A) WARNA=$HIJAU; STATUS_TEKS="Ditambahkan   ";;
    M) WARNA=$KUNING; STATUS_TEKS="Dimodifikasi ";;
    D) WARNA=$MERAH; STATUS_TEKS="Dihapus      ";;
    R) WARNA=$UNGU; STATUS_TEKS="Direname    ";;
    C) WARNA=$CYAN; STATUS_TEKS="Disalin     ";;
    *) WARNA=$NC; STATUS_TEKS="Tidak diketahui";;
  esac
  echo -e "  ${WARNA}${STATUS_TEKS}${NC} - $file"
done

echo ""
echo -e "${KUNING}Preview perubahan:${NC}"
if [ -n "$PERUBAHAN" ]; then
  echo "$PERUBAHAN" | head -n 30
  if [ $(echo "$PERUBAHAN" | wc -l) -gt 30 ]; then
    echo -e "${KUNING}... (masih ada perubahan yang tidak ditampilkan)${NC}"
  fi
else
  echo -e "${KUNING}(Tidak ada preview perubahan)${NC}"
fi
echo -e "${CYAN}================================${NC}"
echo ""

# =========================
# Minta pesan commit dari pengguna
# =========================
echo -e "${BIRU}=== Pesan Commit ===${NC}"
echo -e "${KUNING}Format yang direkomendasikan:${NC}"
echo "  feat: menambahkan fitur baru"
echo "  fix: memperbaiki bug atau masalah"
echo "  refactor: restrukturisasi kode tanpa mengubah fungsionalitas"
echo "  chore: tugas pemeliharaan, update dependency"
echo "  docs: memperbarui dokumentasi"
echo "  style: formatting kode, tidak mempengaruhi logika"
echo "  test: menambah atau memperbarui test case"
echo "  perf: optimasi performa"
echo "  build: perubahan pada build system"
echo "  ci: perubahan konfigurasi CI/CD"
echo ""
echo -e "${KUNING}Contoh untuk programmer profesional:${NC}"
echo "  feat: implementasi autentikasi JWT dengan refresh token"
echo "  fix: resolve race condition pada service payment"
echo "  refactor: ekstrak business logic ke module terpisah"
echo "  chore: update react-dom ke versi 18.2.0"
echo "  docs: tambahkan dokumentasi API endpoint /users"
echo "  perf: optimasi query database dengan indexing"
echo "  test: tambahkan unit test untuk utils/validation"
echo "  style: format kode dengan prettier sesuai eslint config"
echo ""

while true; do
  read -p "Masukkan pesan commit: " PESAN_COMMIT
  
  # Trim whitespace
  PESAN_COMMIT=$(echo "$PESAN_COMMIT" | xargs)
  
  if [ -z "$PESAN_COMMIT" ]; then
    echo -e "${MERAH}Pesan commit tidak boleh kosong.${NC}"
    continue
  fi
  
  # Validasi format conventional commit
  if ! echo "$PESAN_COMMIT" | grep -E '^(feat|fix|refactor|chore|docs|style|test|perf|build|ci|revert):' >/dev/null; then
    echo -e "${KUNING}⚠  Warning: Pesan commit tidak mengikuti format conventional.${NC}"
    echo -e "${KUNING}   Contoh format: 'tipe: deskripsi' (feat:, fix:, dll)${NC}"
    echo -e "${KUNING}   Lanjutkan? [y/N]: ${NC}\c"
    read -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      continue
    fi
  fi
  
  break
done

# =========================
# Tambahkan timestamp secara otomatis
# =========================
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
PESAN_AKHIR="$PESAN_COMMIT | $TIMESTAMP"

# =========================
# Tampilkan konfirmasi akhir
# =========================
echo -e "\n${UNGU}=== Review Akhir ===${NC}"
echo -e "${KUNING}Branch:${NC} $BRANCH_SAAT_INI"
echo -e "${KUNING}Jumlah file:${NC} $(echo "$FILE" | wc -l | tr -d ' ')"
echo -e "${KUNING}Pesan commit:${NC}"
echo -e "  ${HIJAU}$PESAN_AKHIR${NC}"
echo ""

echo -e "${MERAH}Eksekusi commit? [y/N]: ${NC}\c"
read -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${KUNING}Commit dibatalkan.${NC}"
  exit 0
fi

# =========================
# Eksekusi commit
# =========================
echo -e "${BIRU}Menjalankan commit...${NC}"
if git commit -m "$PESAN_AKHIR"; then
  echo -e "${HIJAU}✓ Berhasil commit ke branch $BRANCH_SAAT_INI${NC}"
  echo ""
  
  # =========================
  # Tanya tentang push
  # =========================
  echo -e "${CYAN}=== Push ke Remote Repository ===${NC}"
  echo "1) Push ke origin/$BRANCH_SAAT_INI"
  echo "2) Push ke branch lain"
  echo "3) Push dengan force (hati-hati!)"
  echo "4) Jangan push sekarang"
  echo ""
  
  read -p "Pilih opsi [1-4]: " PILIHAN_PUSH
  
  case $PILIHAN_PUSH in
    1)
      echo -e "${BIRU}Push ke origin/$BRANCH_SAAT_INI...${NC}"
      if git push origin "$BRANCH_SAAT_INI"; then
        echo -e "${HIJAU}✓ Berhasil push ke origin/$BRANCH_SAAT_INI${NC}"
      else
        echo -e "${MERAH}✗ Push gagal${NC}"
        echo -e "${KUNING}Coba manual: git push origin $BRANCH_SAAT_INI${NC}"
      fi
      ;;
      
    2)
      # Tampilkan branch remote yang tersedia
      echo -e "${BIRU}Branch remote yang tersedia:${NC}"
      git branch -r | head -15
      echo ""
      
      read -p "Masukkan nama branch target (tanpa 'origin/'): " BRANCH_TARGET
      
      if [ -z "$BRANCH_TARGET" ]; then
        echo -e "${MERAH}Tidak ada branch yang ditentukan.${NC}"
        exit 1
      fi
      
      echo -e "${BIRU}Push ke origin/$BRANCH_TARGET...${NC}"
      
      # Cek apakah branch ada di remote
      if git ls-remote --exit-code --heads origin "$BRANCH_TARGET" >/dev/null 2>&1; then
        # Push ke branch yang sudah ada
        if git push origin "$BRANCH_SAAT_INI:$BRANCH_TARGET"; then
          echo -e "${HIJAU}✓ Berhasil push ke origin/$BRANCH_TARGET${NC}"
        else
          echo -e "${MERAH}✗ Push gagal${NC}"
        fi
      else
        echo -e "${KUNING}Branch 'origin/$BRANCH_TARGET' belum ada.${NC}"
        echo -e "${KUNING}Buat branch baru di remote? [y/N]: ${NC}\c"
        read -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          if git push origin "$BRANCH_SAAT_INI:refs/heads/$BRANCH_TARGET"; then
            echo -e "${HIJAU}✓ Berhasil membuat dan push ke origin/$BRANCH_TARGET${NC}"
          else
            echo -e "${MERAH}✗ Gagal membuat branch${NC}"
          fi
        else
          echo -e "${KUNING}Push dibatalkan.${NC}"
        fi
      fi
      ;;
      
    3)
      echo -e "${MERAH}⚠  PERINGATAN: Force push akan menimpa history remote!${NC}"
      echo -e "${KUNING}   Hanya gunakan jika Anda yakin.${NC}"
      echo -e "${KUNING}   Force push ke origin/$BRANCH_SAAT_INI? [y/N]: ${NC}\c"
      read -n 1 -r
      echo ""
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BIRU}Force pushing ke origin/$BRANCH_SAAT_INI...${NC}"
        if git push origin "$BRANCH_SAAT_INI" --force; then
          echo -e "${HIJAU}✓ Berhasil force push${NC}"
        else
          echo -e "${MERAH}✗ Force push gagal${NC}"
        fi
      else
        echo -e "${KUNING}Force push dibatalkan.${NC}"
      fi
      ;;
      
    4)
      echo -e "${KUNING}Tidak push sekarang. Anda bisa push nanti dengan:${NC}"
      echo "  git push origin $BRANCH_SAAT_INI"
      ;;
      
    *)
      echo -e "${KUNING}Opsi tidak valid. Tidak melakukan push.${NC}"
      ;;
  esac
  
  # Tampilkan status git setelah commit
  echo -e "\n${CYAN}=== Status Terkini ===${NC}"
  git status --short
  
  # Tampilkan log commit terakhir
  echo -e "\n${CYAN}=== Log Commit Terakhir ===${NC}"
  git log --oneline -3
  
else
  echo -e "${MERAH}✗ Commit gagal${NC}"
  echo -e "${KUNING}Periksa error di atas.${NC}"
  exit 1
fi

echo -e "\n${HIJAU}✓ Selesai!${NC}"
echo -e "${KUNING}Waktu: $(date '+%H:%M:%S')${NC}"