#!/bin/bash

echo
echo "===== Step 1: Unmount these paths on macOS (only the ones you mounted) ====="
while IFS= read -r mountpoint; do
  folder=$(basename "$mountpoint")
  echo "sudo umount /Volumes/$folder"
done < <(mount | awk '{print $3}' | grep -E '^/mnt/' | grep -v '^/mnt$')

echo
read -rp "Press ENTER after you've unmounted all from macOS..."

echo
echo "===== Step 2: Unmount bind mounts under /exported_mnt (depends on /mnt) ====="
mountpoints=$(mount | awk '{print $3}' | grep '^/exported_mnt/')
while IFS= read -r mountpoint; do
  echo "Unmounting bind mount $mountpoint"
  if ! umount "$mountpoint"; then
    echo "Failed to unmount $mountpoint normally, trying lazy unmount"
    umount -l "$mountpoint" || echo "Lazy unmount also failed: $mountpoint"
  fi
done <<< "$mountpoints"

echo
echo "===== Step 3: Unmount device mounts under /mnt ====="
mountpoints=$(mount | awk '{print $3}' | grep '^/mnt/')
while IFS= read -r mountpoint; do
  if [[ "$mountpoint" == "/mnt" ]]; then
    echo "Skipping root /mnt mount"
    continue
  fi

  echo "Unmounting device mount $mountpoint"
  if ! umount "$mountpoint"; then
    echo "Failed to unmount $mountpoint normally, trying lazy unmount"
    umount -l "$mountpoint" || echo "Lazy unmount also failed: $mountpoint"
  fi
done <<< "$mountpoints"

echo
echo "All done."
