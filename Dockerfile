FROM ghcr.io/eooce/firefox:latest
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
# [FIX] 关键修复：除了 chmod 777，必须使用 chown 将 /data 所有权给 vncuser
# 这样脚本里的 rm -rf /data 才能成功清理目录内的文件（虽然删除 /data 本身仍会报错，但不影响流程）
RUN mkdir -p /tmp/app /tmp/app/frp /.kaggle /data /root/.kaggle && \
    chmod -R 777 /tmp/app /tmp/app/frp /.kaggle /data /root/.kaggle && \
    chown -R vncuser:vncuser /data /tmp/app /.kaggle

# 安装必要依赖
# 注意：如果 COPY / / 破坏了 apk 的源配置，这里可能会失败。
# 假设源环境兼容，继续执行安装。
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
    tini \
    procps \
    py3-psutil

# 设置工作目录
WORKDIR /home/vncuser
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
        gradio \
        websockify \
        ipykernel && \
    pip3 install --upgrade huggingface_hub --break-system-packages

# 下载文件
# 此时 /home/vncuser 已经确保存由上面的 RUN 指令处理好，不会报错
RUN wget -t 3 --retry-connrefused --timeout=30 -O "/home/vncuser/ff.sh" "https://huggingface.co/datasets/Qilan2/ff/raw/main/ff.sh" && \
    wget -t 3 --retry-connrefused --timeout=30 -O "/home/vncuser/bf.py" "https://huggingface.co/datasets/Qilan2/ff/raw/main/bf.py" && \
    wget -t 3 --retry-connrefused --timeout=30 -O "/home/vncuser/ff.py" "https://huggingface.co/datasets/Qilan2/ff/raw/main/ff_sap.py" && \
    wget -t 3 --retry-connrefused --timeout=30 -O "/server-ff.sh" "https://huggingface.co/datasets/Qilan2/ff/raw/main/server-ff.sh" && \
    chmod 777 /home/vncuser/ff.sh /server-ff.sh

RUN touch /data/config.yaml && chown vncuser:vncuser /data/config.yaml
# 切换到 vncuser
USER vncuser

# 调试信息：确认文件位置和权限
RUN ls -l /home/vncuser/ff.sh && ls -l /server-ff.sh

CMD ["/server-ff.sh"]

# CMD ["jupyter", "lab", \
#     "--ip=0.0.0.0", \
#     "--port=7860", \
#     "--no-browser", \
#     "--allow-root", \
#     "--notebook-dir=/data", \
#     "--NotebookApp.token='qilan'", \
#     "--ServerApp.disable_check_xsrf=True"]
