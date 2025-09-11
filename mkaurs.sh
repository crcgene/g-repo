#!/usr/bin/env bash
# update-repo.sh
# Build packages from AUR and update local repository

# Absolute path to the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CUSTOM_REPO=$(basename "$SCRIPT_DIR")
DB_FILE="$CUSTOM_REPO.db.tar.zst"
AUR_DIR="$SCRIPT_DIR/aur"

set -u
shopt -s nullglob

if [[ ! -d "$AUR_DIR" ]]; then
  echo "Error: AUR directory not found: $AUR_DIR" >&2
  exit 1
fi

new_pkg_added=false

for pkgdir in "$AUR_DIR"/* ; do
  [[ -d "$pkgdir" ]] || continue
  pkgname="$(basename "$pkgdir")"
  echo "---- Processing package: $pkgname ----"

  # run makepkg -s, suppress errors and ignore exit code
  ( cd "$pkgdir" && makepkg -s 2>/dev/null ) || true

  pkgfiles=( "$pkgdir/${pkgname}-"*.pkg.tar.zst )
  if (( ${#pkgfiles[@]} == 0 )); then
    echo "  No built packages found — skipping."
    continue
  fi

  for pkgfile in "${pkgfiles[@]}"; do
    fname="$(basename "$pkgfile")"
    base="${fname%.pkg.tar.zst}"
    pkgarch="${base##*-}"

    if [[ -z "$pkgarch" ]]; then
      echo "  Failed to detect architecture for $fname — skipping."
      continue
    fi

    repo_arch_dir="$SCRIPT_DIR/$pkgarch"
    mkdir -p "$repo_arch_dir"

    # skip if the package already exists
    if [[ -e "$repo_arch_dir/$fname" ]]; then
      echo "  Found $fname in $repo_arch_dir — skipping."
      continue
    fi

    # copy package to repo directory
    cp "$pkgfile" "$repo_arch_dir/" || { 
      echo "  Copy failed for $fname"; 
      continue; 
    }

    # update repository database
    db_path="$repo_arch_dir/$DB_FILE"
    pkg_path="$repo_arch_dir/$fname"
    if repo-add --prevent-downgrade "$db_path" "$pkg_path"; then
      echo "New package added $pkgname"
      new_pkg_added=true
    else
      echo "  repo-add failed for $fname (continuing)"
    fi
  done
done

if [[ "$new_pkg_added" = false ]]; then
  echo "No new packages have been added"
fi
