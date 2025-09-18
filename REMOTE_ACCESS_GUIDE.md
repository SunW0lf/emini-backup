# 🔐 REMOTE ACCESS GUIDE: SSH & RDP

**System**: EliteMini Development Environment  
**IP Address**: 192.168.1.173  
**Hostname**: rdp2.immovablerod.quest (via Cloudflare tunnel)

---

## 🌐 **CURRENT ACCESS METHODS**

### **Method 1: RDP via Cloudflare Tunnel** ⭐ **RECOMMENDED**
- **URL**: `rdp2.immovablerod.quest`
- **Port**: 3389 (standard RDP)
- **Security**: Encrypted tunnel, firewall protected
- **Authentication**: Username/password
- **Best for**: Remote desktop work, development

### **Method 2: SSH via Local Network**
- **Address**: `ssh sunwolf@192.168.1.173`
- **Port**: 22 (standard SSH)
- **Security**: Socket-activated, currently password-based
- **Authentication**: Username/password (can be upgraded to keys)
- **Best for**: Command line access, file transfers

### **Method 3: RDP via Local Network** 
- **Address**: `192.168.1.173:3389`
- **Security**: Local network only
- **Authentication**: Username/password
- **Best for**: Local network remote desktop access

---

## 🔑 **SSH CERTIFICATE-BASED AUTHENTICATION SETUP**

### **🎯 BENEFITS OF SSH KEY AUTHENTICATION:**
- **🛡️ More Secure**: No password transmission over network
- **⚡ Faster Login**: No password typing required
- **🔒 Non-Repudiation**: Cryptographic proof of identity
- **🚫 Brute Force Resistant**: Keys can't be guessed
- **🎛️ Granular Control**: Different keys for different purposes

---

## 📋 **STEP-BY-STEP SSH KEY SETUP**

### **STEP 1: Generate SSH Key Pair (On Your Client Machine)**

#### **Option A: Ed25519 Key (RECOMMENDED - Most Secure)**
```bash
# Generate Ed25519 key pair
ssh-keygen -t ed25519 -b 4096 -C "elitemini-access-$(date +%Y%m%d)" -f ~/.ssh/elitemini_ed25519

# Key details:
# - Algorithm: Ed25519 (most secure, fastest)
# - Comment: Includes date for tracking
# - Location: ~/.ssh/elitemini_ed25519 (private) and ~/.ssh/elitemini_ed25519.pub (public)
```

#### **Option B: RSA Key (Compatible with Older Systems)**
```bash
# Generate RSA key pair
ssh-keygen -t rsa -b 4096 -C "elitemini-access-$(date +%Y%m%d)" -f ~/.ssh/elitemini_rsa

# Key details:
# - Algorithm: RSA 4096-bit (widely compatible)
# - Secure but larger than Ed25519
```

### **STEP 2: Copy Public Key to EliteMini**

#### **Method A: Using ssh-copy-id (EASIEST)**
```bash
# Copy Ed25519 public key
ssh-copy-id -i ~/.ssh/elitemini_ed25519.pub sunwolf@192.168.1.173

# Or copy RSA public key
ssh-copy-id -i ~/.ssh/elitemini_rsa.pub sunwolf@192.168.1.173

# This will prompt for your password one last time
```

#### **Method B: Manual Copy**
```bash
# Display public key content
cat ~/.ssh/elitemini_ed25519.pub

# Then on EliteMini, add to authorized_keys:
echo "your-public-key-content-here" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### **STEP 3: Test Key Authentication**
```bash
# Test connection with specific key
ssh -i ~/.ssh/elitemini_ed25519 sunwolf@192.168.1.173

# Should connect without password prompt
```

### **STEP 4: Configure SSH Client (Optional)**
```bash
# Add to ~/.ssh/config on client machine:
cat >> ~/.ssh/config << 'EOF'
Host elitemini
    HostName 192.168.1.173
    User sunwolf
    IdentityFile ~/.ssh/elitemini_ed25519
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF

# Now you can connect with just: ssh elitemini
```

---

## 🔒 **SSH SERVER HARDENING (On EliteMini)**

### **STEP 1: Harden SSH Configuration**
```bash
# Edit SSH daemon configuration
sudo nano /etc/ssh/sshd_config

# Add/modify these settings for security:
Port 22                          # Keep standard port (or change if desired)
PermitRootLogin no              # Disable root SSH access
PasswordAuthentication yes      # Keep enabled initially, disable after key setup
PubkeyAuthentication yes        # Enable key-based authentication
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3                  # Limit failed attempts
ClientAliveInterval 300         # Keep connections alive
ClientAliveCountMax 2           # Disconnect after 2 missed keepalives
X11Forwarding no               # Disable X11 forwarding (security)
AllowUsers sunwolf             # Only allow specific user
Protocol 2                     # Use SSH protocol version 2 only
```

### **STEP 2: Advanced Security Options**
```bash
# Additional security settings:
PubkeyAcceptedKeyTypes ssh-ed25519,rsa-sha2-512,rsa-sha2-256
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
```

### **STEP 3: Restart SSH Service**
```bash
# Test configuration first
sudo sshd -t

# If test passes, restart SSH
sudo systemctl restart ssh
```

### **STEP 4: Disable Password Authentication (After Key Setup)**
```bash
# Once SSH key authentication is working:
sudo nano /etc/ssh/sshd_config

# Change this setting:
PasswordAuthentication no

# Restart SSH
sudo systemctl restart ssh
```

---

## 🖥️ **RDP ACCESS METHODS**

### **Current RDP Setup:**
- **Service**: xrdp (already running)
- **Port**: 3389
- **Access**: Via Cloudflare tunnel and local network
- **Authentication**: Username/password

### **RDP Security Considerations:**
- **Tunnel Access**: Encrypted via Cloudflare tunnel
- **Local Access**: Unencrypted over local network
- **Authentication**: Currently password-based only

### **RDP Connection Examples:**

#### **Windows RDP Client:**
```
Computer: rdp2.immovablerod.quest
User: sunwolf
Password: [your-password]
```

#### **macOS RDP Client:**
```
PC Name: rdp2.immovablerod.quest
User Account: sunwolf
Password: [your-password]
```

#### **Linux RDP Client (Remmina):**
```
Protocol: RDP
Server: rdp2.immovablerod.quest:3389
Username: sunwolf
Password: [your-password]
```

---

## 🛡️ **SECURITY BEST PRACTICES**

### **SSH Security:**
1. **Use Ed25519 keys** (strongest, fastest)
2. **Unique keys per device** (laptop, desktop, phone)
3. **Passphrase protect keys** for extra security
4. **Regular key rotation** (annually)
5. **Monitor SSH logs** (`sudo tail -f /var/log/auth.log`)

### **RDP Security:**
1. **Use tunnel access** when possible (encrypted)
2. **Strong passwords** (already implemented)
3. **Monitor RDP sessions** (check who's connected)
4. **Local network only** for direct RDP access
5. **Consider VPN** for additional security layer

### **General Access Security:**
1. **Multi-factor authentication** (future enhancement)
2. **Connection monitoring** (already implemented via health monitor)
3. **Regular security audits** (completed)
4. **Backup access methods** (multiple options available)
5. **Emergency access procedures** (documented)

---

## 📊 **ACCESS METHOD COMPARISON**

| Method | Security | Speed | Ease of Use | Best For |
|--------|----------|--------|-------------|----------|
| **SSH Keys** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Command line, automation |
| **SSH Password** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Quick access, beginners |
| **RDP Tunnel** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Remote desktop work |
| **RDP Local** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Local network desktop |

---

## 🚀 **ADVANCED CONFIGURATIONS**

### **SSH Tunneling for Additional Services:**
```bash
# Forward local ports through SSH tunnel
ssh -L 8080:localhost:8080 -L 9000:localhost:9000 sunwolf@192.168.1.173

# Access Grafana/Portainer securely through tunnel:
# http://localhost:3000 -> Grafana (if running)
# http://localhost:9000 -> Portainer (if running)
```

### **SSH Multiplexing (Faster Reconnections):**
```bash
# Add to ~/.ssh/config:
Host elitemini
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
    
# Creates persistent connection for faster subsequent connects
```

### **Fail2ban for SSH Protection (Future Enhancement):**
```bash
# Install fail2ban to block brute force attempts
sudo apt update && sudo apt install fail2ban

# Configure SSH protection
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
# Edit jail.local to enable SSH protection
```

---

## 🎯 **RECOMMENDED SETUP SEQUENCE**

### **For Maximum Security:**

1. **✅ Setup SSH Key Authentication**
   - Generate Ed25519 key pair
   - Copy public key to EliteMini
   - Test key-based login

2. **🔒 Harden SSH Configuration**
   - Update /etc/ssh/sshd_config
   - Disable password authentication
   - Restart SSH service

3. **📊 Monitor Access**
   - Check auth logs regularly
   - Use health monitor alerts
   - Implement connection monitoring

4. **🛡️ Additional Security (Optional)**
   - Install fail2ban
   - Setup SSH multiplexing  
   - Implement port knocking

Your EliteMini will then have **ENTERPRISE-GRADE** remote access security with multiple authentication methods and comprehensive monitoring! 🚀

---

## 📞 **EMERGENCY ACCESS**

**If SSH/RDP becomes unavailable:**
- **Physical access**: Direct console on EliteMini
- **Recovery mode**: Boot into recovery for SSH reset
- **Cloudflare tunnel**: Should maintain RDP access even if local network fails
- **Health monitor**: Will attempt to restart failed services automatically