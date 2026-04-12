FROM alpine:latest

USER root

ENV CPU_CORES=8
ENV MEMORY=32Gi

# 1. 安装 NGINX 编译所需的依赖
RUN apk update && \
    apk add --no-cache \
    wget \
    gcc \
    g++ \
    make \
    pcre-dev \
    openssl-dev \
    zlib-dev \
    linux-headers

# 2. 下载并解压 NGINX 源码
RUN mkdir -p /data/tools && \
    wget -P /data/tools/ http://nginx.org/download/nginx-1.24.0.tar.gz && \
    tar -xf /data/tools/nginx-1.24.0.tar.gz -C /data/tools/

# 3. 编译和安装 NGINX
# 修复说明: 添加了 --with-cc-opt="-Wno-error" 以解决 GCC 编译报错
RUN cd /data/tools/nginx-1.24.0 && \
    ./configure --prefix=/data/nginx1.24 \
            --with-http_ssl_module \
            --with-http_v2_module \
            --with-http_stub_status_module \
            --with-threads \
            --with-file-aio \
            --with-cc-opt="-Wno-error" \
            --error-log-path=/data/nginx1.24/logs/error.log \
            --http-log-path=/data/nginx1.24/logs/access.log \
            --pid-path=/data/nginx1.24/nginx.pid \
            --http-client-body-temp-path=/data/nginx1.24/client_body_temp \
            --http-proxy-temp-path=/data/nginx1.24/proxy_temp \
            --http-fastcgi-temp-path=/data/nginx1.24/fastcgi_temp \
            --http-uwsgi-temp-path=/data/nginx1.24/uwsgi_temp \
            --http-scgi-temp-path=/data/nginx1.24/scgi_temp && \
    make && \
    make install

# 4. 设置权限
RUN chmod -R 777 /data/nginx1.24 && \
    chown -R nobody:nobody /data/nginx1.24

# 5. 创建基本的 nginx.conf 配置文件
# 修复说明: 修正了最后几行的文件名 (原为 conf/nginx) 并补全了缺少的闭合括号 "}"
RUN echo "user nobody nobody;" > /data/nginx1.24/conf/nginx.conf && \
    echo "worker_processes auto;" >> /data/nginx1.24/conf/nginx.conf && \
    echo "error_log /data/nginx1.24/logs/error.log;" >> /data/nginx1.24/conf/nginx.conf && \
    echo "pid /data/nginx1.24/nginx.pid;" >> /data/nginx1.24/conf/nginx.conf && \
    echo "" >> /data/nginx1.24/conf/nginx.conf && \
    echo "events {" >> /data/nginx1.24/conf/nginx.conf && \
    echo "    worker_connections 1024;" >> /data/nginx1.24/conf/nginx.conf && \
    echo "}" >> /data/nginx1.24/conf/nginx.conf && \
    echo "" >> /data/nginx1.24/conf/nginx.conf && \
    echo "http {" >> /data/nginx1.24/conf/nginx.conf && \
    echo "    include mime.types;" >> /data/nginx1.24/conf/nginx.conf && \
    echo "    default_type application/octet-stream;" >> /data/nginx1.24/conf/nginx.conf && \
    echo "    server {" >> /data/nginx1.24/conf/nginx.conf && \
    echo "        listen 80;" >> /data/nginx1.24/conf/nginx.conf && \
    echo "    }" >> /data/nginx1.24/conf/nginx.conf && \
    echo "}" >> /data/nginx1.24/conf/nginx.conf

# 6. 安装 Python 环境及其他工具依赖
RUN apk update && \
    apk add --no-cache \
    ca-certificates \
    curl \
    wget \
    bzip2 \
    p7zip \
    pigz \
    pv \
    git \
    git-lfs \
    sudo \
    python3 \
    python3-dev \
    py3-pip \
    build-base \
    linux-headers \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev \
    nodejs \
    npm \
    bash \
    py3-requests \
    py3-flask \
    py3-pexpect \
    py3-psutil

# 7. 创建工作目录和权限
RUN mkdir -p /tmp/app /tmp/app/frp /.kaggle /data /root/.kaggle && \
    chmod -R 777 /tmp/app /tmp/app/frp /.kaggle /data /root/.kaggle

# 8. 设置工作目录
WORKDIR /data

# 9. 创建虚拟环境并安装 Python 包
RUN python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --upgrade pip && \
    pip install --no-cache-dir \
    jupyterlab \
    notebook \
    pexpect \
    psutil \
    requests \
    pytz \
    flask \
    kaggle \
    PyYAML \
    huggingface_hub \
    ipykernel

# 10. 安装 configurable-http-proxy
RUN npm install -g configurable-http-proxy

# 11. 配置 sudo
RUN echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chmod 0440 /etc/sudoers

# 12. 设置环境变量
ENV JUPYTER_RUNTIME_DIR=/tmp/app/runtime
ENV JUPYTER_DATA_DIR=/tmp/app/data
ENV HOME=/tmp/app
ENV PATH="/opt/venv/bin:$PATH"
ENV JUPYTER_TOKEN=${JUPYTER_TOKEN}

# 13. 创建运行时目录
RUN mkdir -p /tmp/app/runtime && \
    chmod 777 /tmp/app/runtime

# 14. 暴露端口及启动脚本
EXPOSE 7860

RUN wget -O '/data/start_server.sh' 'https://huggingface.co/datasets/Qilan2/ff/raw/main/nv1/start_server.sh' && \
    wget -O '/data/app.py' 'https://huggingface.co/datasets/Qilan2/ff/raw/main/nv1/app.py' && \
    chmod +x /data/start_server.sh

CMD ["/data/start_server.sh"]

# CMD ["jupyter", "lab", \
#     "--ip=0.0.0.0", \
#     "--port=7860", \
#     "--no-browser", \
#     "--allow-root", \
#     "--notebook-dir=/data", \
#     "--NotebookApp.token='qilan'", \
#     "--ServerApp.disable_check_xsrf=True"]
