# 🚀 ELITEMINI MONITORING & MANAGEMENT DASHBOARD

## 🎯 **SERVICE ACCESS (Local Network)**

### **🐳 PORTAINER - Container Management**
- **URL**: http://192.168.1.173:9000
- **Purpose**: Manage all Docker containers with beautiful UI
- **Login**: Create admin account on first visit
- **Features**: Start/stop containers, view logs, manage volumes

### **📊 GRAFANA - System Dashboards** 
- **URL**: http://192.168.1.173:3000
- **Login**: admin / admin123
- **Purpose**: Beautiful system monitoring dashboards
- **Features**: CPU, memory, disk, network, container metrics

### **🔍 PROMETHEUS - Metrics Database**
- **URL**: http://192.168.1.173:9090
- **Purpose**: Time-series metrics collection
- **Features**: Query system metrics, alert rules

### **📈 NODE EXPORTER - System Metrics**
- **URL**: http://192.168.1.173:9100/metrics
- **Purpose**: Exports system hardware/OS metrics
- **Features**: Raw metrics in Prometheus format

### **🐋 CADVISOR - Container Analytics**
- **URL**: http://192.168.1.173:8080
- **Purpose**: Container resource usage and performance
- **Features**: Docker container monitoring

### **🚨 ALERTMANAGER - Alert Management**
- **URL**: http://192.168.1.173:9093
- **Purpose**: Alert routing and notifications
- **Features**: Alert grouping, silencing, routing rules

## 🌐 **ACCESS VIA CLOUDFLARE TUNNEL**

*Coming soon: dashboard.immovablerod.quest → Grafana*
*Coming soon: portainer.immovablerod.quest → Portainer*

## 🛠️ **MANAGEMENT COMMANDS**

### **Start All Services**
```bash
cd /home/sunwolf/emini-backup/emini-backup/docker-stacks
sudo /usr/local/bin/docker-compose up -d
```

### **Stop All Services**
```bash
cd /home/sunwolf/emini-backup/emini-backup/docker-stacks
sudo /usr/local/bin/docker-compose down
```

### **View Service Status**
```bash
sudo docker ps
```

### **View Service Logs**
```bash
sudo docker logs grafana
sudo docker logs portainer
sudo docker logs prometheus
```

### **Restart Individual Service**
```bash
sudo docker restart grafana
sudo docker restart portainer
```

## 📊 **GRAFANA DASHBOARD SETUP**

### **Step 1: Initial Login**
1. Go to http://192.168.1.173:3000
2. Login: admin / admin123
3. Skip password change for now

### **Step 2: Import System Dashboard**
1. Click "+" → Import
2. Use ID: 1860 (Node Exporter Full)
3. Select Prometheus datasource
4. Click Import

### **Step 3: Import Docker Dashboard**
1. Click "+" → Import  
2. Use ID: 193 (Docker Monitoring)
3. Select Prometheus datasource
4. Click Import

## 🎯 **WHAT YOU'LL SEE**

### **In Portainer:**
- All running containers
- Container resource usage
- Easy start/stop controls
- Container logs viewer
- Volume management
- Network management

### **In Grafana:**
- Real-time system metrics
- CPU usage graphs
- Memory consumption
- Disk I/O statistics  
- Network throughput
- Container resource usage
- Temperature monitoring (if available)

## 🚀 **NEXT STEPS TO ADD SERVICES**

### **Add Jellyfin Media Server**
```bash
# Add to docker-compose.yml
  jellyfin:
    image: jellyfin/jellyfin:latest
    ports:
      - "8096:8096"
    volumes:
      - jellyfin_config:/config
      - /media:/media
```

### **Add Home Assistant**
```bash
# Add to docker-compose.yml  
  homeassistant:
    image: homeassistant/home-assistant:stable
    ports:
      - "8123:8123"
    volumes:
      - ha_config:/config
```

## 🔧 **TROUBLESHOOTING**

### **Container Won't Start**
```bash
sudo docker logs <container_name>
sudo docker restart <container_name>
```

### **Port Already in Use**
```bash
sudo netstat -tulpn | grep :<port>
# Kill the process using the port
sudo kill -9 <PID>
```

### **Grafana Dashboard Not Loading**
1. Check Prometheus is running: http://192.168.1.173:9090
2. Verify data source in Grafana settings
3. Check container logs: `sudo docker logs grafana`

### **Reset Everything**
```bash
cd /home/sunwolf/emini-backup/emini-backup/docker-stacks
sudo /usr/local/bin/docker-compose down -v
sudo /usr/local/bin/docker-compose up -d
```

---

## 🎉 **CONGRATULATIONS!**

You now have a **PROFESSIONAL-GRADE** monitoring and management stack running on your EliteMini! 

**Your Ryzen 9 6900HX is barely breaking a sweat running all these services simultaneously.** 

This is just the foundation - you can now add dozens more services through Portainer with just a few clicks!