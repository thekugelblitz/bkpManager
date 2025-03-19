# **bkpManager v2.4 - Advanced Backup Enforcement & Protection for cPanel Servers** 🚀

**Version:** 2.4 (Nuclear Fix)  
**Author:** Developed by **Dhruval Joshi from [HostingSpell.com](https://hostingspell.com/)**. | Personal: [TheDhruval.com](https://thedhruval.com/)
**GitHub:** [@thekugelblitz](https://github.com/thekugelblitz)  

---

## **📌 Overview**
`bkpManager` is a robust and highly optimized Bash script designed to **enforce strict backup policies** for cPanel servers by:
- **Automatically detecting** unauthorized backup directories.
- **Deleting backup files** while keeping the directory intact.
- **Restricting** the directory (`chmod 0000`) to prevent users from storing new backups.
- **Ensuring proper permission restoration** using the `-d` flag.

This script is designed specifically for **web hosting providers** who already have **automated server backups** and want to **prevent customers from storing additional large backup files** that waste disk space.

---

## **🛠️ Features**
✔️ **Detects known backup directories** (e.g., `ai1wm-backups`, `updraft`, `backuply`, `softaculous_backups`, etc.).  
✔️ **Deletes backup files safely** while retaining the folder structure.  
✔️ **Multiple deletion passes** (`rm`, `find`, `unlink`) to ensure files are actually removed.  
✔️ **Logs actions performed**, including disk space recovered.  
✔️ **Restricts folders after cleanup** to prevent users from creating backups again.  
✔️ **Permission restoration** feature to undo restrictions if required.  

---

## **📦 Installation**
1. **Download & Save** the script on your cPanel server:
   ```bash
   wget -O /usr/local/bin/bkpManager.sh https://raw.githubusercontent.com/thekugelblitz/bkpManager/main/bkpManager.sh
   chmod +x /usr/local/bin/bkpManager.sh
   ```
2. **Run manually or schedule it via cron**.

---

## **🚀 Usage**
### **🔍 Scan & Enforce Backup Policy**
To scan a single cPanel user and remove backup files:
```bash
./bkpManager.sh USERNAME
```
For example:
```bash
./bkpManager.sh USERNAME
```

### **🔄 Restore Permissions**
If needed, you can restore permissions using:
```bash
./bkpManager.sh USERNAME -d
```

### **🚀 Apply to all cPanel Users**
To enforce backup policies for all users:
```bash
./bkpManager.sh
```
To restore permissions for all:
```bash
./bkpManager.sh -d
```

---

## **📜 Logging**
- Logs are stored in `/var/log/bkpManager/`
- Example log output:
  ```
  🔍 Scanning user: USERNAME
  ⚠️ Backup directories found under USERNAME:
    📂 /home/USERNAME/public_html/wp-content/ai1wm-backups
  🗑️ Removed backup files from /home/USERNAME/public_html/wp-content/ai1wm-backups
  🔒 Restricted: /home/USERNAME/public_html/wp-content/ai1wm-backups (Permissions: 0000)
  📊 Disk usage before: 12GB | After: 9GB
  ```

---

## **🛑 Why `chmod 0000`?**
After deleting backup files, the directory is **set to `0000` permissions**, making it:
1. **Unreadable** by the WordPress backup plugins (e.g., UpdraftPlus, All-in-One WP Migration).
2. **Impossible for users to create new backups**.
3. **Still exists** (instead of being deleted), preventing the backup plugin from regenerating it.

**This ensures backups are not stored locally while allowing the hosting provider’s backup solution to operate.**

---

## **🤝 Contribution**
Developed by **Dhruval Joshi** from **[HostingSpell](https://hostingspell.com)**  
GitHub Profile: [@thekugelblitz](https://github.com/thekugelblitz)

If you want to contribute, feel free to fork and submit a PR! 🚀

---

## **📜 License**
This script is released under the **GNU GENERAL PUBLIC LICENSE Version 3**. You are free to modify and use it for commercial or personal use. Attribution is appreciated! 😊

---
