#!/bin/bash
set -e

EXPORTS_FILE="/etc/exports"
TEMP_EXPORTS="/tmp/exports.new"

# Adjust interface and subnet as needed
NET_IF="enp0s1"
SUBNET="192.168.64."

# Detect macOS IP by checking ARP cache from the Linux UTM
mac_ip=$(arp -an | grep "$SUBNET" | awk '{print $2}' | tr -d '()' | head -n1)
if [[ -z "$mac_ip" ]]; then
  echo "Could not auto-detect macOS IP on subnet $SUBNET."
  read -rp "Please enter your macOS IP manually: " mac_ip
fi

# Detect this Linux UTM IP for mounting from macOS
utm_ip=$(ip addr show "$NET_IF" | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1 | head -n1)
if [[ -z "$utm_ip" ]]; then
  echo "Could not detect Linux UTM IP on interface $NET_IF."
  read -rp "Please enter Linux UTM IP manually (used to mount from macOS): " utm_ip
fi

echo "Using macOS IP: $mac_ip"
echo "Using UTM (Linux) IP: $utm_ip"

# Backup existing exports file
cp "$EXPORTS_FILE" "${EXPORTS_FILE}.bak.$(date +%s)"

# Preserve existing exports except those under /exported_mnt
grep -v '^/exported_mnt' "$EXPORTS_FILE" > "$TEMP_EXPORTS" || true

# Assuming UID and GID of file owner is 1000; change if needed
USER_UID=1000
USER_GID=1000

for dev in /dev/sd*[0-9]; do
  fstype=$(blkid -s TYPE -o value "$dev" 2>/dev/null || echo "")
  [[ -z "$fstype" || "$fstype" == "swap" ]] && echo "Skipping $dev of type '$fstype'" && continue

  label=$(blkid -s LABEL -o value "$dev" 2>/dev/null || echo "")
  uuid=$(blkid -s UUID -o value "$dev" 2>/dev/null || echo "")
  name="${label:-$uuid}"
  [[ -z "$name" ]] && name=$(basename "$dev")
  name="${name// /_}"

  if [[ "$name" == EFI* ]]; then
    echo "Skipping $dev because label starts with EFI"
    continue
  fi

  mount_path="/mnt/$name"
  export_path="/exported_mnt/$name"

  if mount | grep -qw "$dev"; then
    echo "$dev is already mounted"
  else
    mkdir -p "$mount_path"
    echo "Mounting $dev at $mount_path"
    mount "$dev" "$mount_path" || { echo "Failed to mount $dev"; continue; }
  fi

  if mount | grep -qw "$export_path"; then
    echo "$export_path is already bind-mounted"
  else
    mkdir -p "$export_path"
    echo "Bind-mounting $mount_path to $export_path"
    mount --bind "$mount_path" "$export_path" || { echo "Failed to bind-mount $mount_path"; continue; }
  fi

  if ! grep -q "^$export_path" "$TEMP_EXPORTS"; then
    echo "Adding export for $export_path"
    echo "$export_path $mac_ip(rw,sync,no_subtree_check,all_squash,anonuid=$USER_UID,anongid=$USER_GID)" >> "$TEMP_EXPORTS"
  fi

  echo
  echo "To mount from macOS, run:"
  echo "  sudo mkdir -p /Volumes/$name"
  echo "  sudo mount -t nfs -o resvport,nolock $utm_ip:$export_path /Volumes/$name"
  echo
done

echo "Updating $EXPORTS_FILE and reloading NFS exports..."
cp "$TEMP_EXPORTS" "$EXPORTS_FILE"
exportfs -ra

echo "Done."
