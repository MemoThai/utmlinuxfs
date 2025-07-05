#!/bin/bash

# Function to check if a path matches UUID-like pattern (or your naming pattern)
is_target_mount() {
  local path="$1"
  [[ "$path" =~ ^/mnt/[0-9a-fA-F-]{8,}$ ]]
}

echo
echo "===== Step 1: Unmount these paths on macOS FIRST ====="
while IFS= read -r mountpoint; do
  folder=$(basename "$mountpoint")
  echo "sudo umount /Volumes/$folder"
done < <(mount | grep '/mnt/' | awk '{print $3}' | grep -E '^/mnt/[0-9a-fA-F-]{8,}$')

echo
read -rp "Press ENTER after you've unmounted all from macOS..."

echo
echo "===== Step 2: Unmount bind mounts under /exported_mnt (depends on /mnt) ====="
mountpoints=$(mount | grep '/exported_mnt/' | awk '{print $3}')
while IFS= read -r mountpoint; do
  echo "Unmounting bind mount $mountpoint"
  if ! umount "$mountpoint"; then
    echo "Failed to unmount $mountpoint normally, trying lazy unmount"
    umount -l "$mountpoint" || echo "Lazy unmount also failed: $mountpoint"
  fi
done <<< "$mountpoints"

echo
echo "===== Step 3: Unmount device mounts under /mnt matching target pattern ====="
mountpoints=$(mount | grep '/mnt/' | awk '{print $3}')
while IFS= read -r mountpoint; do
  if [[ "$mountpoint" == "/mnt" ]]; then
    echo "Skipping root /mnt mount"
    continue
  fi

  if is_target_mount "$mountpoint"; then
    echo "Unmounting device mount $mountpoint"
    if ! umount "$mountpoint"; then
      echo "Failed to unmount $mountpoint normally, trying lazy unmount"
      umount -l "$mountpoint" || echo "Lazy unmount also failed: $mountpoint"
    fi
  else
    echo "Skipping mount point $mountpoint (does not match target pattern)"
  fi
done <<< "$mountpoints"

echo
echo "All done."
