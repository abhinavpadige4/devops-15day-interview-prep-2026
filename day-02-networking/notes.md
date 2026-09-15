# Day 2: Networking Fundamentals

## Topics Covered
- OSI and TCP/IP models
- IP addressing (IPv4/IPv6), subnetting, CIDR
- DNS resolution and configuration
- DHCP, ARP, ICMP protocols
- Ports and services (well-known, registered, dynamic)
- TCP vs UDP characteristics
- Network tools: ping, traceroute, netstat, ss, tcpdump, wireshark
- Basic network configuration (ifconfig, ip, route, nmcli)
- Firewall basics (iptables, firewalld, ufw)
- NAT, proxy, load balancing concepts
- WiFi fundamentals (for completeness)

## Resources
- [Computer Networking: Principles, Protocols and Practice](https://github.com/obinnet/tcpip-guide)
- [Khan Academy - Computer Networking](https://www.khanacademy.org/computing/computers-and-internet/xcae6f4a7ff015e7d:the-internet)
- [Linux Networking Concepts - YouTube](https://www.youtube.com/watch?v=qiQR5rTSshw)
- [Subnetting Practice](https://www.subnetpractice.com/)
- [DNS Fundamentals](https://www.nginx.com/resources/learn/dns/)
- [TCP/IP Guide](https://www.tcpipguide.com/free/t_toc.htm)

## Hands-on Exercises

### Exercise 1: IP Addressing and Subnetting
1. Calculate subnet masks, network addresses, broadcast addresses
2. Practice CIDR notation conversions
3. Determine valid host ranges in subnets
4. Configure static IP addresses on network interfaces
5. Test connectivity between configured hosts

### Exercise 2: DNS Configuration and Testing
1. Configure /etc/resolv.conf with custom DNS servers
2. Test DNS resolution with nslookup, dig, host
3. Configure local DNS caching with dnsmasq or systemd-resolved
4. Test reverse DNS lookups
5. Troubleshoot common DNS issues

### Exercise 3: Network Troubleshooting Tools
1. Use ping to test basic connectivity and measure latency
2. Use traceroute to map network paths
3. Use netstat/ss to monitor connections and listening ports
4. Use tcpdump to capture and analyze network traffic
5. Use nmap for port scanning and host discovery

### Exercise 4: Firewall Configuration
1. Configure basic firewall rules with ufw (Ubuntu) or firewalld (RHEL)
2. Allow/block specific ports and services
3. Configure NAT and port forwarding
4. Test firewall effectiveness
5. Save and restore firewall configurations

### Exercise 5: Network Services and Protocols
1. Set up and test SSH connectivity
2. Configure and test HTTP/HTTPS services
3. Test FTP/SFTP file transfers
4. Configure email relay testing (SMTP)
5. Monitor network performance with basic tools

## Solutions

<details>
<summary>Exercise 1 Solutions: IP Addressing and Subnetting</summary>

```bash
# Subnetting practice examples

# Example 1: Given 192.168.1.0/24
# Network: 192.168.1.0
# Broadcast: 192.168.1.255
# Host range: 192.168.1.1 - 192.168.1.254
# Total hosts: 254

# Example 2: Given 10.0.0.0/16
# Network: 10.0.0.0
# Broadcast: 10.0.255.255
# Host range: 10.0.0.1 - 10.0.255.254
# Total hosts: 65,534

# Example 3: Given 172.16.0.0/12
# Network: 172.16.0.0
# Broadcast: 172.31.255.255
# Host range: 172.16.0.1 - 172.31.255.254
# Total hosts: 1,048,574

# CIDR to subnet mask conversion
# /8  = 255.0.0.0
# /16 = 255.255.0.0
# /24 = 255.255.255.0
# /30 = 255.255.255.252 (point-to-point links)

# Practical subnetting exercise
echo "Subnetting Practice:"
echo "Network: 192.168.10.0/24"
echo "Required: 6 subnets with at least 20 hosts each"
echo ""
echo "Solution:"
echo "- Need 3 bits for subnets (2^3 = 8 >= 6)"
echo "- Need 5 bits for hosts (2^5 - 2 = 30 >= 20)"
echo "- New subnet mask: /27 (255.255.255.224)"
echo "- Subnets:"
for i in {0..7}; do
    base=$((i * 32))
    echo "  192.168.10.$base - 192.168.10.$((base + 31))"
done
```
</details>

<details>
<summary>Exercise 2 Solutions: DNS Configuration and Testing</summary>

```bash
# 1. Configure /etc/resolv.conf with custom DNS servers
echo "Configuring DNS servers..."
sudo cp /etc/resolv.conf /etc/resolv.conf.backup
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf

# 2. Test DNS resolution with nslookup, dig, host
echo "Testing DNS resolution..."
nslookup google.com
dig google.com
host google.com

# Test specific record types
dig google.com A
dig google.com MX
dig google.com TXT

# 3. Configure local DNS caching (systemd-resolved example)
echo "Checking systemd-resolved status..."
systemctl status systemd-resolved
sudo systemctl restart systemd-resolved
resolvectl status

# 4. Test reverse DNS lookups
echo "Testing reverse DNS..."
dig -x 8.8.8.8
host 8.8.8.8

# 5. Troubleshoot common DNS issues
echo "DNS troubleshooting commands:"
echo "dig +trace google.com        # Trace DNS resolution path"
echo "dig @8.8.8.8 google.com      # Query specific DNS server"
echo "nslookup -type=any google.com # Get all record types"
```
</details>

<details>
<summary>Exercise 3 Solutions: Network Troubleshooting Tools</summary>

```bash
# 1. Use ping to test basic connectivity and measure latency
echo "Testing connectivity with ping..."
ping -c 4 8.8.8.8
ping -c 4 google.com
ping -i 0.2 -c 10 8.8.8.8  # Faster ping interval

# 2. Use traceroute to map network paths
echo "Mapping network path with traceroute..."
traceroute 8.8.8.8
# On some systems, might need:
# tracepath 8.8.8.8
# mtr 8.8.8.8  # Combines ping and traceroute

# 3. Use netstat/ss to monitor connections and listening ports
echo "Checking listening ports..."
ss -tuln
netstat -tuln

echo "Checking established connections..."
ss -tulnp | grep ESTAB
netstat -tulnp | grep ESTAB

# 4. Use tcpdump to capture and analyze network traffic
echo "Capturing network traffic (first 10 packets)..."
sudo tcpdump -c 10 -nn
sudo tcpdump -c 10 -nn port 80
sudo tcpdump -c 10 -nn host 8.8.8.8

# Save capture to file for later analysis
sudo tcpdump -w capture.pcap -c 100
tcpdump -r capture.pcap  # Read saved capture

# 5. Use nmap for port scanning and host discovery
echo "Scanning localhost for open ports..."
nmap -sT localhost
nmap -sS localhost  # Stealth scan (requires root)
nmap -sU localhost  # UDP scan
nmap -p 80,443,22,21 localhost  # Specific ports
nmap -sn 192.168.1.0/24  # Ping sweep (host discovery)
```
</details>

<details>
<summary>Exercise 4 Solutions: Firewall Configuration</summary>

```bash
# Detect firewall system and configure accordingly

# Check if ufw is available (Ubuntu/Debian)
if command -v ufw &> /dev/null; then
    echo "Configuring UFW firewall..."
    
    # Reset to known state
    sudo ufw reset
    
    # Set default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow specific services
    sudo ufw allow ssh          # Port 22
    sudo ufw allow http         # Port 80
    sudo ufw allow https        # Port 443
    sudo ufw allow 8080/tcp     # Custom application port
    
    # Allow from specific IP ranges
    sudo ufw allow from 192.168.1.0/24
    
    # Enable firewall
    sudo ufw enable
    
    # Check status
    sudo ufw status verbose
    
elif command -v firewall-cmd &> /dev/null; then
    echo "Configuring firewalld..."
    
    # Reset to known state
    sudo firewall-cmd --reload
    
    # Set default zone to drop (more secure)
    sudo firewall-cmd --set-default-zone=drop
    
    # Add services to trusted zones
    sudo firewall-cmd --zone=public --add-service=ssh --permanent
    sudo firewall-cmd --zone=public --add-service=http --permanent
    sudo firewall-cmd --zone=public --add-service=https --permanent
    
    # Add custom port
    sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
    
    # Reload to apply changes
    sudo firewall-cmd --reload
    
    # Check status
    sudo firewall-cmd --list-all
    
elif command -v iptables &> /dev/null; then
    echo "Configuring iptables directly..."
    
    # Flush existing rules
    sudo iptables -F
    sudo iptables -X
    sudo iptables -t nat -F
    sudo iptables -t nat -X
    sudo iptables -t mangle -F
    sudo iptables -t mangle -X
    
    # Set default policies
    sudo iptables -P INPUT DROP
    sudo iptables -P FORWARD DROP
    sudo iptables -P OUTPUT ACCEPT
    
    # Allow loopback traffic
    sudo iptables -A INPUT -i lo -j ACCEPT
    sudo iptables -A OUTPUT -o lo -j ACCEPT
    
    # Allow established and related connections
    sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    sudo iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Allow SSH
    sudo iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT
    
    # Allow HTTP/HTTPS
    sudo iptables -A INPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT
    
    # Allow custom application port
    sudo iptables -A INPUT -p tcp --dport 8080 -m state --state NEW -j ACCEPT
    
    # Save rules (method varies by distribution)
    # Ubuntu: sudo netfilter-persistent save
    # RHEL/CentOS: sudo service iptables save
    
else
    echo "No supported firewall system found"
fi
```
</details>

<details>
<summary>Exercise 5 Solutions: Network Services and Protocols</summary>

```bash
# 1. Set up and test SSH connectivity
echo "Testing SSH setup..."
# Check if SSH server is running
sudo systemctl status ssh
# or on some systems:
# sudo systemctl status sshd

# Test SSH to localhost
ssh localhost 'echo "SSH connection successful"'
# or with specific user
ssh $USER@localhost 'echo "SSH connection successful"'

# 2. Configure and test HTTP/HTTPS services
echo "Testing web server connectivity..."
# Install and test Apache/Nginx if not present
if ! command -v apache2 &> /dev/null && ! command -v nginx &> /dev/null; then
    echo "Installing nginx for testing..."
    sudo apt update && sudo apt install -y nginx
fi

# Test if web server is responding
curl -I http://localhost
curl -I https://localhost --insecure  # Ignore cert warnings for self-signed

# 3. Test FTP/SFTP file transfers
echo "Testing SFTP (SSH file transfer)..."
# Create test file
echo "Hello from SFTP test" > /tmp/testfile.txt

# Test SFTP connection
sftp $USER@localhost << EOF
put /tmp/testfile.txt /tmp/testfile_sftp.txt
ls -l /tmp/testfile_sftp.txt
quit
EOF

# 4. Configure email relay testing (SMTP)
echo "Testing SMTP connectivity..."
# Test if we can reach SMTP port (usually 25 or 587)
nc -zv localhost 25
nc -zv localhost 587

# Test with mailutils if available
if command -v mail &> /dev/null; then
    echo "Test email sent" | mail -s "Test Subject" $USER@localhost
fi

# 5. Monitor network performance with basic tools
echo "Monitoring network performance..."
# Check bandwidth usage
if command -v iftop &> /dev/null; then
    sudo iftop -t -s 10  # Run for 10 seconds
fi

# Check network statistics
cat /proc/net/dev
netstat -i

# Monitor specific interface
IFACE=$(ip route get 8.8.8.8 | awk -- '{printf $5; exit}')
echo "Monitoring interface: $IFACE"
watch -n 1 "cat /sys/class/net/$IFACE/statistics/{rx_tx}_bytes"
```
</details>