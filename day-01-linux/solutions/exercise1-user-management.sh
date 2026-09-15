#!/bin/bash
# Solution for Exercise 1: User Management

echo "=== Exercise 1: User Management Solutions ==="

# 1. Create user 'devops'
echo "1. Creating user 'devops'..."
sudo adduser devops || sudo useradd -m devops

# 2. Set password for the user
echo "2. Setting password for devops..."
echo "devops:DevOps123!" | sudo chpasswd
# Note: In production, use a strong, unique password and consider password expiration

# 3. Add the user to the sudoers group
echo "3. Adding devops to sudoers group..."
if [ "$(uname -o)" = "GNU/Linux" ]; then
    # Detect distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
            sudo usermod -aG sudo devops
        elif [[ "$ID" == "centos" || "$ID" == "rhel" || "$ID" == "fedora" ]]; then
            sudo usermod -aG wheel devops
        fi
    fi
fi

# 4. Explore /etc/passwd and /etc/shadow files
echo "4. Exploring user files..."
echo "Contents of /etc/passwd for devops:"
grep devops /etc/passwd
echo ""
echo "Contents of /etc/shadow for devops (requires sudo):"
sudo grep devops /etc/shadow

# 5. Demonstrate su and sudo usage
echo "5. Demonstrating su and sudo usage..."
echo "Switching to devops user..."
su - devops -c "whoami"
echo "Testing sudo access as devops..."
su - devops -c "sudo whoami"

# 6. Switch to the devops user and verify sudo access
echo "6. Final verification..."
su - devops -c "
    echo 'Current user:'
    whoami
    echo 'Testing sudo:'
    sudo whoami
    echo 'User groups:'
    groups
"

echo "=== Exercise 1 Complete ==="