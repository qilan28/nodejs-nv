FROM node:alpine3.20

# 使用更明确的工作目录
WORKDIR /app

# 复制 package.json 和 package-lock.json
COPY package*.json ./

# 安装依赖
RUN npm install

# 复制所有源代码
COPY . .

EXPOSE 3000

# 使用 npm 脚本或直接使用 node
# CMD ["npm", "start"]
# 或
CMD ["node", "index.js"]

