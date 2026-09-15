# Day 1: Linux Fundamentals

## Topics Covered
- Linux file system hierarchy
- User and group management
- File permissions (chmod, chown, chgrp)
- Essential commands (ls, cd, cp, mv, rm, find, grep, sed, awk)
- Process management (ps, top, kill, nice, renice)
- Package management (apt, yum, dnf)
- Basic networking (ifconfig, ip, ping, netstat, ss)
- Shell scripting basics
- Systemd services
- Log management

## Resources
- [Linux Journey – Fundamentals](https://linuxjourney.com/)
- [Zero To Mastery – Linux Interview Questions](https://zerotomastery.io/blog/linux-interview-questions)
- [Linux Essentials for DevOps – YouTube](https://www.youtube.com/watch?v=tS_zLaH-tew)
- [The Linux Command Line (TLCL) - Free PDF](https://linuxcommand.org/tlcl.php)
- [ExplainShell.com](https://explainshell.com/) - Great for understanding complex commands

## Hands-on Exercises

### Exercise 1: User Management
1. Create a user named 'devops'
2. Set a password for the user
3. Add the user to the sudoers group
4. Explore /etc/passwd and /etc/shadow files
5. Demonstrate su and sudo usage
6. Switch to the devops user and verify sudo access

### Exercise 2: File Permissions
1. Create a directory `/home/devops/practice` with subdirectories
2. Create various files with different permission sets
3. Practice changing ownership (chown) and groups (chgrp)
4. Practice changing permissions using both symbolic and numeric notation
5. Set special permissions (SUID, SGID, sticky bit)

### Exercise 3: Process Management
1. List all running processes using ps and top
2. Start a background process (e.g., `sleep 300 &`)
3. Find the PID of the background process
4. Send different signals to the process (SIGTERM, SIGKILL)
5. Use nice and renice to adjust process priority
6. Kill processes using pkill and killall

### Exercise 4: Package Management
1. Update package repositories
2. Install a package (e.g., htop, tree, vim)
3. Remove a package
4. Search for available packages
5. List installed packages
6. Hold and unhold packages from being upgraded

### Exercise 5: Networking Basics
1. Check network interfaces and IP addresses
2. Test connectivity with ping to various hosts
3. Use traceroute to trace network path
4. Check open ports and listening services
5. Download files using curl and wget
6. Basic SSH key generation and usage

## Solutions

<details>
<summary>Exercise 1 Solutions: User Management</summary>

```bash
# 1. Create user 'devops'
sudo adduser devops

# 2. Set password (you'll be prompted during adduser, or use:)
sudo passwd devops

# 3. Add to sudoers group (Ubuntu/Debian)
sudo usermod -aG sudo devops
# For RHEL/CentOS/Fedora:
# sudo usermod -aG wheel devops

# 4. Explore user files
cat /etc/passwd | grep devops
sudo cat /etc/shadow | grep devops  # Requires sudo

# 5. Demonstrate su/sudo
su - devops  # Switch to devops user
whoami       # Should show 'devops'
sudo ls /root # Test sudo access (will prompt for password)
exit         # Return to original user

# 6. Verify sudo access as devops
su - devops
sudo whoami  # Should return 'root'
exit
```
</details>

<details>
<summary>Exercise 2 Solutions: File Permissions</summary>

```bash
# 1. Create practice directory structure
mkdir -p /home/devops/practice/{dir1,dir2,dir3}
cd /home/devops/practice

# 2. Create test files
touch file1.txt file2.txt file3.txt script.sh
echo "Hello World" > file1.txt
echo "#!/bin/bash" > script.sh
echo "echo 'Hello from script'" >> script.sh

# 3. Practice ownership changes
sudo chown devops:devops file1.txt
sudo chown root:root file2.txt
sudo chgrp devops file3.txt

# 4. Practice permission changes
# Symbolic notation
chmod u+x script.sh          # Add execute for user
chmod go-rwx file1.txt       # Remove all permissions for group/others
chmod u+rw,g+r,o-r file2.txt # Set specific permissions

# Numeric notation
chmod 755 script.sh          # rwx for user, rx for group/others
chmod 644 file1.txt          # rw for user, r for group/others
chmod 600 file2.txt          # rw only for user

# 5. Special permissions
# SUID - runs as file owner
sudo chown root:root /usr/bin/passwd
sudo chmod u+s /usr/bin/passwd  # Already set typically

# SGID - runs as group owner, new files inherit group
mkdir shared_dir
sudo chgrp devops shared_dir
sudo chmod g+s shared_dir

# Sticky bit - only file owner can delete/rename
mkdir /tmp/sticky_test
sudo chmod +t /tmp/sticky_test
```
</details>

<details>
<summary>Exercise 3 Solutions: Process Management</summary>

```bash
# 1. List processes
ps aux                    # Detailed view
ps -ef                    # Full format
top                       # Interactive (press q to quit)
htop                      # Enhanced version (if installed)

# 2. Start background process
sleep 300 &               # Sleep for 5 minutes in background
echo "Background job started with PID: $!"

# 3. Find PID
jobs -l                   # List jobs with PIDs
pgrep sleep               # Find PID by name
pidof sleep               # Alternative

# 4. Send signals
kill -TERM <PID>          # Graceful termination
kill -INT <PID>           # Interrupt (Ctrl+C equivalent)
kill -KILL <PID>          # Force kill

# 5. Nice and renice
nice -n 10 sleep 300 &    # Start with lower priority
renice +5 -p <PID>        # Increase nice value (lower priority)
renice -5 -p <PID>        # Decrease nice value (higher priority)

# 6. Kill processes
pkill sleep               # Kill by name
killall sleep             # Alternative
```
</details>

<details>
<summary>Exercise 4 Solutions: Package Management</summary>

```bash
# Ubuntu/Debian (apt)
sudo apt update           # Update package lists
sudo apt upgrade          # Upgrade installed packages

# Install package
sudo apt install htop tree vim -y

# Remove package
sudo apt remove htop      # Remove but keep config files
sudo apt purge htop       # Remove package and config files
sudo apt autoremove       # Remove unused dependencies

# Search packages
apt search nginx          # Search for nginx-related packages
apt show nginx            # Show detailed info about nginx package

# List installed packages
apt list --installed      # List all installed packages
apt list --upgradable     # List packages that can be upgraded

# Hold/unhold packages
sudo apt-mark hold nginx  # Prevent nginx from being upgraded
sudo apt-mark unhold nginx # Allow nginx to be upgraded

# RHEL/CentOS/Fedora equivalents (yum/dnf)
# sudo yum check-update
# sudo yum install htop
# sudo yum remove htop
# sudo yum list installed
```

</details>

<details>
<summary>Exercise 5 Solutions: Networking Basics</summary>

```bash
# 1. Check network interfaces
ip addr show              # Modern replacement for ifconfig
ip link show              # Show link layer info
ifconfig -a               # Deprecated but still works

# 2. Test connectivity
ping -c 4 8.8.8.8         # Ping Google DNS 4 times
ping -c 4 google.com      # Ping by hostname

# 3. Traceroute
traceroute 8.8.8.8        # Show network path
# or on some systems:
tracepath 8.8.8.8

# 4. Check open ports and services
ss -tuln                  # Show listening TCP/UDP ports
netstat -tuln             # Older equivalent
sudo lsof -i              # Show all network connections

# 5. Download files
curl -O https://example.com/file.txt
wget https://example.com/file.txt

# 6. SSH key generation
ssh-keygen -t rsa -b 4096 -C "devops@example.com"
# Follow prompts, saves to ~/.ssh/id_rsa and ~/.ssh/id_rsa.pub

# Copy public key to remote server
ssh-copy-id user@remote-server
# or manually:
cat ~/.ssh/id_rsa.pub | ssh user@remote-server 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
```
</details>