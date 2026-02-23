````markdown
# 📘 Bahmni Docker RTL – Installation & Database Restoration Guide

This guide describes the complete step-by-step procedure to install **Bahmni (RTL version)** using **Docker** on **Ubuntu**, verify services, and perform required **post-installation database fixes** for OpenMRS, OpenELIS, Odoo, Patient Documents, and Bed Management.

---

# 📋 1. Prerequisites

## 1.1 Operating System
- Ubuntu LTS (Recommended 20.04 / 22.04)

Verify:
```bash
cat /etc/os-release
```

## 1.2 Required Packages
- Docker Engine
- Docker Compose (plugin + standalone)
- Git

---

# 🐳 2. Docker Installation (Ubuntu)

## 2.1 Install Docker Engine

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
```

Add Docker GPG key:

```bash
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
-o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc
```

Add Docker repository:

```bash
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Install Docker components:

```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
docker-buildx-plugin docker-compose-plugin
```

---

## 2.2 Install Docker Compose (Standalone)

```bash
sudo curl -SL https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64 \
-o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

Verify:

```bash
docker version
docker compose version
```

---

# 🔧 3. Install Git

```bash
sudo apt update
sudo apt install -y git
git --version
```

---

# 📁 4. Bahmni Docker Setup

## 4.1 Create Base Directory

```bash
mkdir -p /App
cd /App
```

## 4.2 Clone Bahmni Docker RTL Repository

```bash
git clone https://github.com/RAEng-FoD-Bahmni-project/bahmni-docker-RTL.git
cd /App/bahmni-docker-RTL/
```

Set permissions:

```bash
chmod -R 0755 /App/bahmni-docker-RTL/
chown -R root:root /App/bahmni-docker-RTL/
```

---

# 📦 5. Clone & Configure Odoo Modules

```bash
mkdir -p /opt/bahmni-erp/
cd /opt/bahmni-erp/
```

Clone Odoo RTL modules:

```bash
git clone https://github.com/RAEng-FoD-Bahmni-project/odoo-modules-rtl.git
mv odoo-modules-rtl bahmni-addons
```

Set permissions:

```bash
chmod -R 0755 /opt/bahmni-erp/bahmni-addons
chown -R root:root /opt/bahmni-erp/bahmni-addons
```

---

# ▶️ 6. Start Bahmni Services

```bash
cd /App/bahmni-docker-RTL/
docker compose up -d
```

If containers fail during first run:

```bash
docker compose restart <container-name>
docker compose up -d
```

---

# ⏳ 7. Mandatory Wait Time (Before Database Fixes)

⚠️ IMPORTANT

After all containers are running, wait **at least 30 minutes**.

This allows:
- Database initialization
- Inter-service communication
- Full startup of OpenMRS, Odoo, OpenELIS, DCM4CHEE

❗ Do NOT skip this step.

---

# 🎨 8. Fix: Odoo CSS Missing Issue

**Cause:** Invalid attachments after database restoration.

```bash
docker compose exec -it odoodb sh
psql -U odoo odoo
```

Run:

```sql
DELETE FROM ir_attachment WHERE name LIKE '%web/content%';
```

Exit:

```bash
\q
exit
```

Restart Odoo:

```bash
docker compose restart odoo
```

---

# 📂 9. Fix: Patient Documents Error (If Occurs Later)

⚠️ Apply only if patient document upload/view errors occur.

### Step 1: Access Container

```bash
docker compose exec -it patient-documents sh
```

Install ACL:

```bash
apk add acl
```

### Step 2: Fix Permissions

```bash
setfacl -dRm o::rwx /usr/share/nginx/html/document_images/
chmod -R 777 /usr/share/nginx/html/document_images/
```

Verify:

```bash
ls -al /usr/share/nginx/html/document_images/
```

### Step 3: Restart Service

```bash
docker compose restart patient-documents
```

---

# 🛏 10. Fix: Bed Management Issue

⚠️ Apply only if Bed Management errors occur.

### Step 1: Access OpenMRS DB

```bash
docker compose exec -it openmrsdb sh
mysql -uroot -padminAdmin!123 openmrs
```

### Step 2: Update Table

```sql
ALTER TABLE bed_location_map 
ADD COLUMN row_number INT NULL AFTER location_id;

ALTER TABLE bed_location_map 
ADD COLUMN column_number INT NULL AFTER row_number;

UPDATE bed_location_map 
SET row_number = bed_row_number,
    column_number = bed_column_number;
```

Exit:

```bash
exit
```

Restart OpenMRS:

```bash
docker compose restart openmrs
```

---

# 🔁 11. Fix: OpenMRS Sync Issue (Markers Table)

```bash
docker compose exec -it openmrsdb sh
mysql -uroot -padminAdmin!123 openmrs
```

Run:

```sql
DELETE FROM markers WHERE feed_uri LIKE '%feed/patient/recent%';
```

Exit:

```bash
exit
```

---

# 🔄 12. Restart All Bahmni Services

```bash
docker compose down
docker compose build
docker compose up -d
```

---

# ⏳ 13. Mandatory Wait Time (After Restart)

Wait another **30 minutes**.

Keep refreshing the UI until all services are stable.

---

# 🧪 14. Post-Restoration Steps

1. Access OpenMRS  
   ```
   https://<server-ip>/openmrs
   ```

2. Rebuild Search Index  
   - OpenMRS → Admin  
   - Search Index  
   - Click **Rebuild Search Index**

---

# ⚠️ Important Notes

- Sections 8, 10, and 11 are required only once after:
  - First image pull
  - Database restoration
- Patient document and bed management fixes are only required if those specific errors occur.
- Do NOT repeat cleanup steps on every restart.

---

# ✅ Completion & Verification

Bahmni should now be fully functional.

## 🔍 Application Access Details

| Application | URL | Credentials |
|------------|-----|------------|
| Bahmni App | https://localhost/ | — |
| OpenMRS | https://localhost/openmrs | superman / Admin123 |
| Odoo ERP | http://localhost:8069 | admin / admin |
| DCM4CHEE | https://localhost/dcm4chee-web3/ | admin / admin |
| OpenELIS | https://localhost/openelis/LoginPage.do | admin / adminADMIN! |

---

# 🎉 Installation Complete

Your Bahmni RTL Docker environment is now ready.
````

