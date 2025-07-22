# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# ELK Cluster Password Management

## 📋 概述

本 ELK 集群部署方案包含完整的密码自动生成和管理功能，确保生产环境的安全性。

## 🔐 生成的密码

系统会自动生成以下用户的密码：

| 用户名 | 角色 | 用途 |
|--------|------|------|
| `elastic` | 超级管理员 | Elasticsearch 集群管理 |
| `kibana_system` | 系统用户 | Kibana 访问 Elasticsearch |
| `logstash_system` | 系统用户 | Logstash 写入 Elasticsearch |
| `beats_system` | 系统用户 | Beats 写入 Elasticsearch |
| `monitoring_agent` | 系统用户 | 监控数据写入 |
| `remote_monitoring_user` | 系统用户 | 远程监控访问 |

## 🚀 使用方法

### 方法一：一键部署（推荐）

```bash
# 自动生成密码并部署 ELK 集群
./deploy-elk.sh

# 或明确指定完整部署
./deploy-elk.sh --full
```

### 方法二：分步执行

```bash
# 1. 仅生成密码
./deploy-elk.sh --passwords

# 2. 仅部署集群（需要已存在的密码）
./deploy-elk.sh --deploy
```

### 方法三：手动执行

```bash
# 1. 生成密码
ansible-playbook generate-passwords.yml

# 2. 部署集群
ansible-playbook ansible-elk-cluster.yml --extra-vars "@./passwords/vault.yml"
```

## 📁 密码文件结构

```
./passwords/
├── vault.yml                    # 主密码文件（用于 Ansible）
├── elasticsearch_password.txt   # elastic 用户密码
├── kibana_password.txt         # kibana_system 用户密码
├── logstash_password.txt       # logstash_system 用户密码
├── beats_password.txt          # beats_system 用户密码
├── monitoring_password.txt     # monitoring_agent 用户密码
└── remote_monitoring_password.txt # remote_monitoring_user 用户密码
```

## 🔒 安全特性

### 密码强度
- **长度**: 16 字符
- **字符集**: 大小写字母 + 数字 + 特殊字符
- **复杂度**: 包含 `!@#$%^&*` 等特殊字符

### 文件权限
- **目录权限**: 700 (`./passwords/`)
- **文件权限**: 600 (所有密码文件)
- **所有者**: 当前用户

### 存储安全
- 密码以明文形式存储在本地文件
- 生产环境建议使用 Ansible Vault 加密
- 部署完成后可删除本地密码文件

## 🔧 密码重置

### 重新生成所有密码
```bash
# 删除现有密码
rm -rf ./passwords/

# 重新生成
./deploy-elk.sh --passwords
```

### 重置特定用户密码
```bash
# 1. 编辑 vault.yml 文件
vim ./passwords/vault.yml

# 2. 重新运行密码设置任务
ansible-playbook ansible-elk-cluster.yml --extra-vars "@./passwords/vault.yml" --tags "elasticsearch,security"
```

## 📊 密码验证

部署完成后，可以使用以下命令验证密码：

```bash
# 测试 elastic 用户
curl -u elastic:$(cat ./passwords/elasticsearch_password.txt) \
  http://localhost:9200/_cluster/health

# 测试 kibana_system 用户
curl -u kibana_system:$(cat ./passwords/kibana_password.txt) \
  http://localhost:9200/_cluster/health
```

## ⚠️ 注意事项

1. **备份密码**: 部署前请备份生成的密码文件
2. **权限管理**: 确保密码文件不被其他用户访问
3. **生产环境**: 建议使用 Ansible Vault 加密密码文件
4. **定期更换**: 建议定期更换密码以提高安全性
5. **访问控制**: 限制对密码文件的访问权限

## 🔄 生产环境建议

### 使用 Ansible Vault 加密

```bash
# 1. 创建加密的 vault 文件
ansible-vault create group_vars/all/vault.yml

# 2. 在 vault 文件中添加密码变量
vault_elasticsearch_password: "your_secure_password"
vault_kibana_password: "your_secure_password"
# ... 其他密码

# 3. 使用加密文件部署
ansible-playbook ansible-elk-cluster.yml --ask-vault-pass
```

### 密码轮换策略

1. **定期更换**: 每 90 天更换一次密码
2. **分阶段更新**: 先更新配置文件，再更新服务
3. **备份验证**: 更换前备份，更换后验证
4. **监控告警**: 设置密码过期监控

## 📞 故障排除

### 常见问题

1. **密码文件不存在**
   ```bash
   # 重新生成密码
   ./deploy-elk.sh --passwords
   ```

2. **权限错误**
   ```bash
   # 修复文件权限
   chmod 600 ./passwords/*
   chmod 700 ./passwords/
   ```

3. **密码验证失败**
   ```bash
   # 检查密码文件内容
   cat ./passwords/vault.yml

   # 重新设置密码
   ansible-playbook ansible-elk-cluster.yml --extra-vars "@./passwords/vault.yml" --tags "elasticsearch,security"
   ```

---

**注意**: 本密码管理系统专为自动化部署设计，生产环境请根据安全策略进行调整。