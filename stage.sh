#!/bin/bash
# enhanced-commit.sh

echo "=== SMART GIT COMMIT ==="
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
./autopush.sh