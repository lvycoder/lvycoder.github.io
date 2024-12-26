# 使用官方 Nginx 轻量级镜像作为基础
FROM nginx:alpine

# 移除默认的 Nginx 网站内容
RUN rm -rf /usr/share/nginx/html/*

# 将本地网站文件复制到 Nginx 的 HTML 目录
COPY site/ /usr/share/nginx/html

# 暴露端口 80
EXPOSE 80

# 启动 Nginx
CMD ["nginx", "-g", "daemon off;"]
