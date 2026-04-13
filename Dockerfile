# 强制指定为 amd64 架构，防止 QEMU 模拟器崩溃
FROM --platform=linux/amd64 qilan28/ff:v1.0
USER root

# 1. [修复核心问题] 智能创建 vncuser 用户
# 逻辑：检查 vncuser 是否存在。如果不存在则创建；
# 无论是否创建，都强制创建 /home/vncuser 并修正权限，解决 wget 报错。
RUN if ! id -u vncuser > /dev/null 2>&1; then \
        adduser -D -u 1000 vncuser; \
        echo "Created vncuser"; \
    else \
        echo "User vncuser already exists, skipping creation"; \
    fi && \
    mkdir -p /home/vncuser && \
    chown -R vncuser:vncuser /home/vncuser

# 创建必要的目录并设置权限
RUN mkdir -p /tmp/app /tmp/app/frp /.kaggle /data /root/.kaggle && \
    chmod -R 777 /tmp/app /tmp/app/frp /.kaggle /data /root/.kaggle

# 安装必要依赖
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

# 设置工作目录
WORKDIR /data

# 直接使用系统Python环境安装包
RUN pip3 install --upgrade pip --break-system-packages && \
    pip3 install --no-cache-dir --break-system-packages \
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
        ipykernel && \
    pip3 install --upgrade huggingface_hub --break-system-packages

# 7. 创建工作目录和权限 (确保权限正确)
RUN mkdir -p /tmp/app /tmp/app/frp /.kaggle /data /root/.kaggle && \
    chmod -R 777 /tmp/app /tmp/app/frp /.kaggle /data /root/.kaggle

# 下载文件
RUN wget -t 3 --retry-connrefused --timeout=30 -O "/home/vncuser/ff.sh" "https://huggingface.co/datasets/Qilan2/ff/raw/main/ff-jm.sh" && \
    wget -t 3 --retry-connrefused --timeout=30 -O "/data/bf.py" "https://huggingface.co/datasets/Qilan2/ff/raw/main/bf.py" && \
    wget -t 3 --retry-connrefused --timeout=30 -O "/data/ff.py" "https://huggingface.co/datasets/Qilan2/ff/raw/main/ff_sap.py" && \
    wget -t 3 --retry-connrefused --timeout=30 -O "/server-ff.sh" "https://huggingface.co/datasets/Qilan2/ff/raw/main/server-ff.sh" && \
    wget -t 3 --retry-connrefused --timeout=30 -O "/data/b.py" "https://huggingface.co/datasets/Qilan2/st-server/raw/main/sbx/b.py" && \
    wget -O '/data/f1' -q 'https://huggingface.co/datasets/Qilan2/ff/resolve/main/f-linux-amd64?download=true' && \
    chmod 777 /home/vncuser/ff.sh /server-ff.sh /data/f1

# 设置工作目录
WORKDIR /data

# 切换到 vncuser
USER vncuser

# 调试信息：确认文件位置和权限
RUN ls -l /home/vncuser/ff.sh && ls -l /server-ff.sh

CMD ["/server-ff.sh"]
