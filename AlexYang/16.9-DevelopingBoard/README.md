# P7885 鸿蒙开发板自动化开发测试方案

## 项目概述

本项目提供完整的 P7885 (全志 T527) 鸿蒙开发板自动化开发、烧录、测试解决方案。

### 功能特性

- **自动编译**: OpenHarmony 源码自动编译，支持增量编译和分布式编译
- **自动烧录**: 支持 FEL 模式、TF 卡、Fastboot 多种烧录方式
- **自动测试**: 系统启动、网络、存储、CPU、GPU、外设等全面测试
- **远程访问**: 支持 SSH、ADB、串口多种远程连接方式
- **CI/CD 集成**: 完整的 Jenkins/GitLab CI 流水线支持

---

## 项目结构

```
16.9-DevelopingBoard/
├── docs/                          # 文档目录
│   ├── 01-可行性分析.md           # 技术可行性分析
│   ├── 02-编译环境搭建.md         # 编译环境搭建指南
│   └── ...
├── scripts/                       # 自动化脚本
│   ├── auto_build.py             # 自动编译脚本
│   ├── flash_p7885.py            # 自动烧录脚本
│   ├── remote_test.py            # 远程测试脚本
│   └── cicd_pipeline.sh          # CI/CD 流水线脚本
├── config/                        # 配置文件
│   └── test_config.json          # 测试配置
├── Jenkinsfile                   # Jenkins Pipeline
└── README.md                     # 本文档
```

---

## 快速开始

### 1. 环境准备

#### 硬件要求
- **编译服务器**: Ubuntu 22.04 LTS, 16GB+ RAM, 200GB+ SSD
- **开发板**: P7885 (润和 HiHope) + 电源 + USB 线 + 串口模块
- **网络**: 开发板可接入局域网

#### 安装依赖
```bash
sudo apt-get update
sudo apt-get install -y \
    python3 python3-pip python3-venv \
    git git-lfs gnupg \
    build-essential \
    nodejs npm \
    sunxi-tools \
    android-tools-adb \
    android-tools-fastboot

# Python 依赖
pip3 install paramiko pyserial
```

### 2. 编译镜像

```bash
# 下载并编译
python3 scripts/auto_build.py \
    --source-dir ~/ohos-p7885 \
    --download \
    --branch OpenHarmony-4.1-Release \
    --build

# 或分步执行
cd ~/ohos-p7885
./build/prebuilts_download.sh
source build/envsetup.sh
lunch hihope_p7885-userdebug
./build.sh --product hihope_p7885 --ccache
```

### 3. 烧录镜像

```bash
# FEL 模式自动烧录
python3 scripts/flash_p7885.py \
    --method fel \
    --image-dir ~/ohos-p7885/out/hihope_p7885/packages/phone/images \
    --serial /dev/ttyUSB0

# TF 卡烧录
python3 scripts/flash_p7885.py \
    --method tf \
    --device /dev/sdb \
    --image-dir ~/ohos-p7885/out/hihope_p7885/packages/phone/images
```

### 4. 远程测试

```bash
# SSH 方式测试
python3 scripts/remote_test.py \
    --method ssh \
    --host 192.168.1.100 \
    --report test_report.json

# 串口方式测试
python3 scripts/remote_test.py \
    --method serial \
    --serial-port /dev/ttyUSB0
```

---

## CI/CD 流水线

### Jenkins 集成

1. **安装 Jenkins**: https://www.jenkins.io/doc/book/installing/linux/

2. **安装插件**:
   - Pipeline
   - Git
   - Email Extension

3. **创建 Pipeline 任务**:
   - 新建 Item → Pipeline
   - Pipeline script from SCM → Git
   - 填入仓库地址和 Jenkinsfile 路径

4. **配置环境变量**:
   ```groovy
   SOURCE_DIR = "${HOME}/ohos-p7885"
   OUTPUT_DIR = "/opt/ohos-images"
   DEVICE_IP = "192.168.1.100"
   ```

### GitLab CI 集成

创建 `.gitlab-ci.yml`:

```yaml
stages:
  - build
  - flash
  - test

variables:
  SOURCE_DIR: "${HOME}/ohos-p7885"
  OUTPUT_DIR: "/opt/ohos-images"

build:
  stage: build
  script:
    - python3 scripts/auto_build.py --build
  artifacts:
    paths:
      - /opt/ohos-images/latest/*.img
    expire_in: 1 week

flash:
  stage: flash
  script:
    - python3 scripts/flash_p7885.py --method fel --image-dir ${OUTPUT_DIR}/latest
  only:
    - master

test:
  stage: test
  script:
    - python3 scripts/remote_test.py --method ssh --host ${DEVICE_IP}
  only:
    - master
```

### 本地一键执行

```bash
# 赋予执行权限
chmod +x scripts/cicd_pipeline.sh

# 完整流程
./scripts/cicd_pipeline.sh --full

# 只编译
./scripts/cicd_pipeline.sh --compile-only

# 只烧录测试
./scripts/cicd_pipeline.sh --flash-only
./scripts/cicd_pipeline.sh --test-only

# 清理重新编译
./scripts/cicd_pipeline.sh --clean --full
```

---

## 远程命令行访问

### SSH 访问

```bash
# 默认配置
ssh root@192.168.1.100
# 密码: 123456

# 执行远程命令
ssh root@192.168.1.100 "uname -a"

# 使用脚本
python3 scripts/remote_test.py \
    --method ssh \
    --host 192.168.1.100 \
    --command "cat /proc/cpuinfo"
```

### ADB 访问

```bash
# 连接设备
adb devices

# 进入 shell
adb shell

# 执行命令
adb shell ps
adb shell dmesg | tail -20
adb shell bm dump -a
```

### 串口访问

```bash
# 使用 minicom
minicom -D /dev/ttyUSB0 -b 115200

# 使用 picocom
picocom -b 115200 /dev/ttyUSB0

# 使用脚本
python3 scripts/remote_test.py \
    --method serial \
    --serial-port /dev/ttyUSB0 \
    --command "ls -la /"
```

---

## 自动化测试项

### 已实现的测试

| 测试项 | 说明 | 状态 |
|--------|------|------|
| 系统启动 | 检查系统是否正常启动 | ✅ |
| 系统信息 | 获取内核版本、OH版本 | ✅ |
| 网络连通 | ping 测试、接口检查 | ✅ |
| 存储 | 磁盘空间、挂载点 | ✅ |
| 内存 | 总内存、可用内存 | ✅ |
| CPU | 核心数、负载 | ✅ |
| GPU | 驱动检测 | ✅ |
| GPIO | 接口可用性 | ✅ |
| 日志 | hilog、dmesg | ✅ |
| 进程 | 关键进程检查 | ✅ |

### 扩展测试

编辑 `scripts/remote_test.py` 添加自定义测试:

```python
def test_custom(self) -> TestResult:
    start = time.time()
    
    # 执行自定义测试
    rc, stdout, stderr = self.connector.execute('your-command')
    
    return TestResult(
        test_name='自定义测试',
        status='PASS' if rc == 0 else 'FAIL',
        duration=time.time() - start,
        output=stdout,
        error=stderr
    )
```

---

## 常见问题

### Q1: 编译报错 "out of memory"

```bash
# 增加 swap
sudo fallocate -l 16G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 或减少并行任务
./build.sh --product hihope_p7885 --jobs 4
```

### Q2: 无法进入 FEL 模式

```bash
# 手动进入 FEL 模式
1. 断开开发板电源
2. 短接 FEL 引脚到 GND (查看原理图)
3. 插入 USB 线供电
4. 松开 FEL 引脚

# 检查设备
lsusb | grep 1f3a
```

### Q3: 网络不通无法 SSH

```bash
# 使用串口配置网络
ifconfig eth0 192.168.1.100 netmask 255.255.255.0
route add default gw 192.168.1.1

# 或检查 DHCP
udhcpc -i eth0
```

### Q4: 权限不足

```bash
# 添加用户到 dialout 组 (串口)
sudo usermod -a -G dialout $USER

# 添加 udev 规则
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="1f3a", MODE="0666"' | sudo tee /etc/udev/rules.d/50-allwinner.rules
sudo udevadm control --reload-rules
```

---

## 相关资源

- **OpenHarmony 官方文档**: https://gitee.com/openharmony/docs
- **P7885 开发板资料**: https://gitee.com/hihope_iot/docs
- **全志 T527 芯片手册**: https://linux-sunxi.org/T527
- **OpenHarmony 社区**: https://gitee.com/openharmony

---

## 许可证

Apache License 2.0

---

## 更新日志

### v1.0 (2026-03-12)
- 初始版本
- 支持自动编译、烧录、测试
- 完整 CI/CD 流水线
