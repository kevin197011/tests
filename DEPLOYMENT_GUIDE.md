# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# ELK 集群按角色部署指南

## 🎯 概述

本 ELK 集群部署方案已重构为**按角色部署**模式，确保每个服务只部署到对应的主机上，避免在所有主机上部署所有服务的问题。

## 🏗️ 架构设计

### 主机分组
- **elasticsearch**: Elasticsearch 集群节点
- **logstash**: Logstash 服务节点
- **kibana**: Kibana 界面节点

### 部署结构
```
ansible-elk-cluster.yml
├── Play 1: System Configuration (hosts: all)
├── Play 2: Elasticsearch Deployment (hosts: elasticsearch)
├── Play 3: Logstash Deployment (hosts: logstash)
└── Play 4: Kibana Deployment (hosts: kibana)
```

## 🚀 部署方式

### 1. 一键完整部署
```bash
# 自动生成密码并部署完整集群
./deploy-elk.sh

# 或明确指定完整部署
./deploy-elk.sh --full
```

### 2. 分步部署
```bash
# 1. 仅生成密码
./deploy-elk.sh --passwords

# 2. 仅部署完整集群（需要已存在的密码）
./deploy-elk.sh --deploy
```

### 3. 按角色部署（推荐用于生产环境）
```bash
# 1. 生成密码
./deploy-elk.sh --passwords

# 2. 按顺序部署各个角色
./deploy-elk.sh --role system          # 基础系统配置（所有主机）
./deploy-elk.sh --role elasticsearch   # Elasticsearch 集群
./deploy-elk.sh --role logstash        # Logstash 服务
./deploy-elk.sh --role kibana          # Kibana 界面
```

### 4. 手动执行
```bash
# 1. 生成密码
ansible-playbook generate-passwords.yml --vault-password-file .vault_pass.txt

# 2. 按标签部署特定服务
ansible-playbook ansible-elk-cluster.yml -i inventory/hosts.yml \
  --vault-password-file .vault_pass.txt \
  --extra-vars @passwords/elastic_password.yml \
  --extra-vars @passwords/kibana_password.yml \
  --extra-vars @passwords/logstash_password.yml \
  --extra-vars @passwords/beats_password.yml \
  --extra-vars @passwords/monitoring_password.yml \
  --extra-vars @passwords/remote_monitoring_password.yml \
  --tags system

ansible-playbook ansible-elk-cluster.yml -i inventory/hosts.yml \
  --vault-password-file .vault_pass.txt \
  --extra-vars @passwords/elastic_password.yml \
  --extra-vars @passwords/kibana_password.yml \
  --extra-vars @passwords/logstash_password.yml \
  --extra-vars @passwords/beats_password.yml \
  --extra-vars @passwords/monitoring_password.yml \
  --extra-vars @passwords/remote_monitoring_password.yml \
  --tags elasticsearch

ansible-playbook ansible-elk-cluster.yml -i inventory/hosts.yml \
  --vault-password-file .vault_pass.txt \
  --extra-vars @passwords/elastic_password.yml \
  --extra-vars @passwords/kibana_password.yml \
  --extra-vars @passwords/logstash_password.yml \
  --extra-vars @passwords/beats_password.yml \
  --extra-vars @passwords/monitoring_password.yml \
  --extra-vars @passwords/remote_monitoring_password.yml \
  --tags logstash

ansible-playbook ansible-elk-cluster.yml -i inventory/hosts.yml \
  --vault-password-file .vault_pass.txt \
  --extra-vars @passwords/elastic_password.yml \
  --extra-vars @passwords/kibana_password.yml \
  --extra-vars @passwords/logstash_password.yml \
  --extra-vars @passwords/beats_password.yml \
  --extra-vars @passwords/monitoring_password.yml \
  --extra-vars @passwords/remote_monitoring_password.yml \
  --tags kibana
```

## 📋 部署内容

### Play 1: 系统基础配置 (hosts: all)
- 禁用 firewalld 和 SELinux
- 安装基础软件包
- 配置时区和 chrony
- 优化内核参数
- 创建 elasticsearch 用户
- 配置系统限制

### Play 2: Elasticsearch 部署 (hosts: elasticsearch)
- 创建 Elasticsearch 目录
- 下载和安装 Elasticsearch
- 生成和分发 SSL 证书
- 配置 Elasticsearch 服务
- 启动 Elasticsearch
- 设置用户密码

### Play 3: Logstash 部署 (hosts: logstash)
- 创建 Logstash 目录
- 下载和安装 Logstash
- 配置 Logstash 服务
- 启动 Logstash

### Play 4: Kibana 部署 (hosts: kibana)
- 创建 Kibana 目录
- 下载和安装 Kibana
- 配置 Kibana 服务
- 启动 Kibana

## 🔐 密码管理

### 自动生成的用户
- `elastic` - 超级管理员
- `kibana_system` - Kibana 系统用户
- `logstash_system` - Logstash 系统用户
- `beats_system` - Beats 系统用户
- `monitoring_agent` - 监控代理用户
- `remote_monitoring_user` - 远程监控用户

### 密码文件结构
```
passwords/
├── elastic_password.yml          # elastic 用户密码
├── kibana_password.yml           # kibana_system 用户密码
├── logstash_password.yml         # logstash_system 用户密码
├── beats_password.yml            # beats_system 用户密码
├── monitoring_password.yml       # monitoring_agent 用户密码
└── remote_monitoring_password.yml # remote_monitoring_user 用户密码
```

## 🎯 使用场景

### 开发环境
```bash
# 快速部署完整集群
./deploy-elk.sh --full
```

### 生产环境
```bash
# 1. 先部署系统配置
./deploy-elk.sh --role system

# 2. 部署 Elasticsearch 集群
./deploy-elk.sh --role elasticsearch

# 3. 验证 Elasticsearch 集群健康后，部署 Logstash
./deploy-elk.sh --role logstash

# 4. 最后部署 Kibana
./deploy-elk.sh --role kibana
```

### 故障恢复
```bash
# 如果某个服务出现问题，可以单独重新部署
./deploy-elk.sh --role kibana
```

### 扩展部署
```bash
# 添加新的 Elasticsearch 节点后
./deploy-elk.sh --role elasticsearch

# 添加新的 Logstash 节点后
./deploy-elk.sh --role logstash
```

## 🔍 验证部署

### 检查服务状态
```bash
# 检查 Elasticsearch 集群健康
curl -u elastic:password http://localhost:9200/_cluster/health

# 检查 Logstash 状态
curl http://localhost:9600/_node/stats

# 检查 Kibana 状态
curl http://localhost:5601/api/status
```

### 检查系统服务
```bash
# 检查服务状态
systemctl status elasticsearch
systemctl status logstash
systemctl status kibana
```

## 🛠️ 故障排除

### 常见问题

1. **密码文件问题**
   ```bash
   # 重新生成密码
   ./deploy-elk.sh --passwords
   ```

2. **证书问题**
   ```bash
   # 重新部署 Elasticsearch（会重新生成证书）
   ./deploy-elk.sh --role elasticsearch
   ```

3. **服务启动失败**
   ```bash
   # 检查日志
   journalctl -u elasticsearch -f
   journalctl -u logstash -f
   journalctl -u kibana -f
   ```

4. **权限问题**
   ```bash
   # 重新部署系统配置
   ./deploy-elk.sh --role system
   ```

## 📝 注意事项

1. **部署顺序**: 建议按 system → elasticsearch → logstash → kibana 的顺序部署
2. **密码安全**: `.vault_pass.txt` 文件包含敏感信息，请妥善保管
3. **网络连通性**: 确保主机间网络连通性正常
4. **资源要求**: 确保主机满足最低资源要求
5. **备份**: 生产环境部署前请备份重要数据

## 🤝 支持

如有问题，请参考：
- [README.md](README.md) - 项目概述
- [PASSWORD_MANAGEMENT.md](PASSWORD_MANAGEMENT.md) - 密码管理详情