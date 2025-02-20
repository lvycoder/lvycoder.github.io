## **Let's Encrypt 免费证书**

- (通过 Certbot 工具)结合 Nginx 的详细步骤

### **1. 安装 Certbot**

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装 Certbot 和 Nginx 插件
sudo apt install certbot python3-certbot-nginx -y
```

### **2. 生成证书并自动配置 Nginx**

```bash
# 执行 Certbot 命令(自动修改 Nginx 配置)
sudo certbot --nginx -d example.com -d www.example.com
sudo certbot --nginx -d proxy-image.top -d www.proxy-image.top

sudo certbot --nginx -d hq.gabrielwang.com
```

- **参数说明**:
    - `d`: 指定域名(可多个,如主域名和子域名).
    - Certbot 会自动验证域名所有权(需确保域名已解析到服务器 IP,且 80/443 端口开放).

### **交互步骤:**

1. **输入邮箱**:用于接收证书到期提醒.
2. **同意服务条款**:输入 `A` 同意.
3. **是否共享邮箱**:输入 `N` 拒绝.
4. **自动配置 HTTPS**:选择 `2`(强制将所有 HTTP 流量重定向到 HTTPS).

### **3. 验证证书生成**

### **查看证书文件**

证书默认存储在 `/etc/letsencrypt/live/example.com/` 目录:

- `fullchain.pem`: 证书链(公钥).
- `privkey.pem`: 私钥.

### **检查 Nginx 配置**

Certbot 会自动修改 Nginx 配置文件(如 `/etc/nginx/sites-available/default`),生成类似以下配置:

```bash
server {
    listen 443 ssl;
    server_name example.com www.example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # 其他配置...
}

server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$host$request_uri;  # 强制跳转 HTTPS
}
```

### **4. 手动配置证书(可选)**

如果 Certbot 自动配置失败,可手动修改 Nginx 配置文件:

```bash
server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # 优化 SSL 配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # 其他配置...
}

```

重启 nginx

```bash
sudo systemctl restart nginx
```

### **5. 自动续期证书**

Let's Encrypt 证书有效期为 **90 天**,需定期续期.Certbot 会自动创建定时任务:

```bash
# 测试续期命令(手动执行)
sudo certbot renew --dry-run

# 查看定时任务
sudo systemctl list-timers | grep certbot
```

### **6. 验证 HTTPS 生效**

访问 `https://example.com`,检查浏览器地址栏是否显示锁标志.

```bash
# 使用 OpenSSL 测试
openssl s_client -connect example.com:443 -servername example.com
```

### **常见问题处理**

### **1. 证书申请失败**

- **原因**:域名未解析、Nginx 未运行、防火墙阻止 80/443 端口.
- **解决**:

    ```

    # 检查 Nginx 状态
    sudo systemctl status nginx# 检查端口开放
    sudo ufw allow 80/tcpsudo ufw allow 443/tcp

    ```


### **2. 续期失败**

- **原因**:Nginx 配置错误或域名解析变更.
- **解决**:

    ```bash
    # 手动续期并查看日志
    sudo certbot renew --force-renewal
    tail -f /var/log/letsencrypt/letsencrypt.log

    ```


### **总结**

通过 Certbot 自动化工具,可以快速为 Nginx 部署 Let's Encrypt 免费证书,并实现以下目标:

1. **一键生成证书**:自动验证域名并配置 Nginx.
2. **强制 HTTPS**:提升安全性和 SEO 排名.
3. **自动续期**:避免证书过期导致服务中断.

建议定期检查证书状态(`sudo certbot certificates`)和 Nginx 日志(`/var/log/nginx/error.log`)
