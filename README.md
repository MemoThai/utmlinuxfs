# utmlinuxfs

This project is inspired by the amazing [anylinuxfs](https://github.com/nohajc/anylinuxfs),  
but since anylinuxfs has a limitation (only one drive can be mounted at a time, file owner and permissions issue 777),  
I tried to come up with a workaround to enable mounting multiple drives/disks simultaneously inside UTM.

# A Humble Disclaimer

Honestly, this project is still pretty rough and far from perfect.  
It might be bad compared to anylinuxfs or other solutions out there.  
I’m just an amateur tinkering around and sharing what I made in case it helps someone.

Please consider this a work in progress and use at your own risk.

# Issues
### USB Limitation with UTM
Since **UTM does not yet support USB 3.2**, you have two options:

- Use **USB 3.1** instead.  
  *(In my case, I only have a USB 3.1 hub with a Type-A plug, so I had to connect the enclosure to a USB 3.1 hub (Type-A), then into a USB 3.2 hub (Type-C), and finally to my MacBook Air.)*

- Or use **USB 2.0**,  
  but the transfer speed will be much slower.

# Requirements

- macOS running on Apple Silicon with **sudo** privileges  
- [UTM](https://mac.getutm.app)  
- [Arch Linux ARM](https://mac.getutm.app/gallery/archlinux-arm) image 
- stable internet 

## inside UTM

- Network: Use normal **Shared Network** with **virtio-net-pci** driver

## inside Arch Linux VM

### Initial setup

1. Install NFS server:
    ```
    pacman -S nfs-utils
    ```

2. Enable and start NFS server:
    ```
    systemctl enable nfs-server
    systemctl start nfs-server
    ````

3. Get the bash scripts from [`bash/`](bash/) directory to your Arch Linux VM and make them executable:
    ```
    chmod +x ./mountdisk.sh ./umountdisk.sh
    ```

# Mounting drives

When running Linux in the UTM window, there will be a **USB menu at the top right**.  
Use this menu to attach USB drives to Linux.

Then run the mount script:
```
./mountdisk.sh
```
You will see output similar to this:
```
[root@alarm ~]# ./mountdisk.sh 
Using Mac IP: 192.168.<MAC IP>
Using UTM (Linux) IP: 192.168.<UTM IP>
Skipping /dev/sda1 because label starts with EFI
Skipping /dev/sda2 of type 'swap'
Mounting /dev/sda3 at /mnt/<UUID>
Bind-mounting /mnt/<UUID> to /exported_mnt/<UUID>
Adding export for /exported_mnt/<UUID>

To mount from macOS, run:
  sudo mkdir -p /Volumes/<UUID>
  sudo mount -t nfs -o resvport,nolock 192.168.<UTM IP>:/exported_mnt/<UUID> /Volumes/<UUID>

Mounting /dev/sda4 at /mnt/<UUID>
Bind-mounting /mnt/<UUID> to /exported_mnt/<UUID>
Adding export for /exported_mnt/<UUID>

To mount from macOS, run:
  sudo mkdir -p /Volumes/<UUID>
  sudo mount -t nfs -o resvport,nolock 192.168.<UTM IP>:/exported_mnt/<UUID> /Volumes/<UUID>
````
This exports the drive over NFS from Linux. On macOS, mount it using the commands shown.

### Accessing the Mounted Drives on macOS
1. In Finder sidebar under **Network**, click your UTM VM's IP.
2. Browse the shared folders (named by UUID) exported via NFS.
3. Access files as usual.

## Unmounting drives
To unmount, run:
```
./umountdisk.sh
```
which performs the reverse operation.
