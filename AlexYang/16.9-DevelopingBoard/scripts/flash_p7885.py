#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
P7885 自动烧录脚本
支持多种烧录方式: FEL模式、TF卡、Fastboot

Usage:
    python3 flash_p7885.py --method fel --image-dir ./images
    python3 flash_p7885.py --method tf --device /dev/sdb --image-dir ./images
    python3 flash_p7885.py --method fastboot --image-dir ./images
"""

import os
import sys
import time
import subprocess
import argparse
import serial
import serial.tools.list_ports
from pathlib import Path
from typing import Optional, List
import logging

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('/var/log/p7885_flash.log')
    ]
)
logger = logging.getLogger(__name__)


class P7885Flasher:
    """P7885开发板烧录器"""
    
    # 镜像文件映射
    IMAGE_MAP = {
        'boot': 'boot.img',
        'system': 'system.img',
        'vendor': 'vendor.img',
        'userdata': 'userdata.img',
        'ramdisk': 'ramdisk.img',
        'updater': 'updater.img'
    }
    
    def __init__(self, image_dir: str, serial_port: Optional[str] = None):
        self.image_dir = Path(image_dir)
        self.serial_port = serial_port
        self.ser: Optional[serial.Serial] = None
        
        if not self.image_dir.exists():
            raise FileNotFoundError(f"镜像目录不存在: {image_dir}")
    
    def _check_images(self) -> bool:
        """检查镜像文件是否完整"""
        missing = []
        for name, filename in self.IMAGE_MAP.items():
            path = self.image_dir / filename
            if not path.exists():
                missing.append(filename)
                logger.error(f"缺少镜像文件: {filename}")
            else:
                size = path.stat().st_size / (1024*1024)
                logger.info(f"✓ {filename} ({size:.1f} MB)")
        
        return len(missing) == 0
    
    def _find_fel_device(self) -> Optional[str]:
        """查找FEL模式的USB设备"""
        try:
            result = subprocess.run(
                ['lsusb'], 
                capture_output=True, 
                text=True
            )
            # 全志芯片FEL模式Vendor ID: 1f3a
            for line in result.stdout.split('\n'):
                if '1f3a' in line.lower():
                    logger.info(f"找到FEL设备: {line.strip()}")
                    return line.strip()
            return None
        except Exception as e:
            logger.error(f"查找FEL设备失败: {e}")
            return None
    
    def _enter_fel_mode(self) -> bool:
        """通过串口发送命令进入FEL模式"""
        if not self.serial_port:
            logger.error("未指定串口")
            return False
        
        try:
            self.ser = serial.Serial(
                self.serial_port,
                baudrate=115200,
                timeout=5
            )
            
            logger.info("等待设备启动...")
            time.sleep(2)
            
            # 发送进入FEL模式的命令
            # 不同固件可能有不同的进入方式
            commands = [
                b'\n',  # 先发一个换行
                b'reboot efex\n',  # 全志通用命令
                b'\x03',  # Ctrl+C
            ]
            
            for cmd in commands:
                self.ser.write(cmd)
                time.sleep(0.5)
            
            # 等待设备进入FEL模式
            time.sleep(3)
            
            # 检查是否进入FEL模式
            if self._find_fel_device():
                logger.info("✓ 设备已进入FEL模式")
                return True
            else:
                logger.error("✗ 设备未能进入FEL模式")
                return False
                
        except Exception as e:
            logger.error(f"进入FEL模式失败: {e}")
            return False
        finally:
            if self.ser:
                self.ser.close()
    
    def flash_fel(self, force_fel: bool = False) -> bool:
        """
        使用FEL模式烧录
        
        Args:
            force_fel: 是否强制进入FEL模式
        """
        logger.info("=== 开始FEL模式烧录 ===")
        
        # 检查镜像
        if not self._check_images():
            return False
        
        # 检查sunxi-fel工具
        try:
            subprocess.run(['sunxi-fel', '--version'], check=True, capture_output=True)
        except:
            logger.error("未安装sunxi-fel工具，正在安装...")
            self._install_sunxi_tools()
        
        # 进入FEL模式
        if force_fel or not self._find_fel_device():
            if not self._enter_fel_mode():
                logger.error("无法进入FEL模式，请手动操作:")
                logger.error("1. 断开开发板电源")
                logger.error("2. 短接FEL引脚到GND")
                logger.error("3. 插入USB线供电")
                logger.error("4. 松开FEL引脚")
                return False
        
        try:
            # 烧录各分区
            flash_commands = [
                ('boot', 'sunxi-fel -p spl boot.img'),
                ('boot', 'sunxi-fel write 0x41000000 boot.img'),
                ('rootfs', 'sunxi-fel write 0x42000000 system.img'),
            ]
            
            for part, cmd_template in flash_commands:
                img_file = self.image_dir / self.IMAGE_MAP.get(part, f'{part}.img')
                if img_file.exists():
                    cmd = cmd_template.replace(f'{part}.img', str(img_file))
                    logger.info(f"烧录 {part}...")
                    result = subprocess.run(cmd.split(), capture_output=True, text=True)
                    if result.returncode != 0:
                        logger.error(f"烧录 {part} 失败: {result.stderr}")
                        return False
                    logger.info(f"✓ {part} 烧录完成")
            
            # 重启设备
            logger.info("重启设备...")
            subprocess.run(['sunxi-fel', 'reset'], capture_output=True)
            
            logger.info("=== FEL烧录完成 ===")
            return True
            
        except Exception as e:
            logger.error(f"FEL烧录失败: {e}")
            return False
    
    def flash_tf(self, device: str) -> bool:
        """
        烧录到TF卡
        
        Args:
            device: TF卡设备路径，如 /dev/sdb
        """
        logger.info(f"=== 开始TF卡烧录到 {device} ===")
        
        # 检查镜像
        if not self._check_images():
            return False
        
        # 确认设备
        if not os.path.exists(device):
            logger.error(f"设备不存在: {device}")
            return False
        
        # 安全检查：防止写入系统盘
        if device in ['/dev/sda', '/dev/nvme0n1']:
            logger.error(f"禁止写入系统盘: {device}")
            return False
        
        try:
            # 卸载分区
            logger.info("卸载TF卡分区...")
            subprocess.run(['umount', f'{device}*'], capture_output=True)
            
            # 使用dd写入镜像（假设有完整的卡镜像）
            full_img = self.image_dir / 'full_image.img'
            if full_img.exists():
                logger.info("写入完整镜像...")
                cmd = f'dd if={full_img} of={device} bs=4M status=progress conv=fsync'
                result = subprocess.run(cmd.split(), capture_output=True, text=True)
                if result.returncode != 0:
                    logger.error(f"写入失败: {result.stderr}")
                    return False
            else:
                # 分别写入各分区
                logger.info("分别写入分区镜像...")
                partitions = [
                    ('boot', 1),
                    ('system', 2),
                    ('userdata', 3)
                ]
                
                for part_name, part_num in partitions:
                    img_file = self.image_dir / self.IMAGE_MAP.get(part_name, f'{part_name}.img')
                    if img_file.exists():
                        part_dev = f"{device}{part_num}"
                        logger.info(f"写入 {part_name} 到 {part_dev}...")
                        cmd = f'dd if={img_file} of={part_dev} bs=4M status=progress conv=fsync'
                        subprocess.run(cmd.split(), capture_output=True)
            
            # 同步缓存
            subprocess.run(['sync'])
            
            logger.info("=== TF卡烧录完成 ===")
            return True
            
        except Exception as e:
            logger.error(f"TF卡烧录失败: {e}")
            return False
    
    def flash_fastboot(self) -> bool:
        """使用Fastboot模式烧录（需设备已进入Fastboot）"""
        logger.info("=== 开始Fastboot烧录 ===")
        
        # 检查镜像
        if not self._check_images():
            return False
        
        # 检查fastboot
        try:
            subprocess.run(['fastboot', '--version'], check=True, capture_output=True)
        except:
            logger.error("未安装fastboot工具")
            return False
        
        # 检查设备
        result = subprocess.run(['fastboot', 'devices'], capture_output=True, text=True)
        if not result.stdout.strip():
            logger.error("未找到Fastboot设备，请通过以下方式进入Fastboot:")
            logger.error("1. adb reboot bootloader")
            logger.error("2. 开机时按住特定按键")
            return False
        
        logger.info(f"找到设备: {result.stdout.strip()}")
        
        try:
            # 烧录各分区
            partitions = [
                ('boot', 'boot'),
                ('system', 'system'),
                ('vendor', 'vendor'),
                ('userdata', 'userdata')
            ]
            
            for img_name, part_name in partitions:
                img_file = self.image_dir / self.IMAGE_MAP.get(img_name, f'{img_name}.img')
                if img_file.exists():
                    logger.info(f"烧录 {part_name}...")
                    cmd = ['fastboot', 'flash', part_name, str(img_file)]
                    result = subprocess.run(cmd, capture_output=True, text=True)
                    if result.returncode != 0:
                        logger.error(f"烧录 {part_name} 失败: {result.stderr}")
                        return False
                    logger.info(f"✓ {part_name} 烧录完成")
            
            # 重启
            logger.info("重启设备...")
            subprocess.run(['fastboot', 'reboot'], capture_output=True)
            
            logger.info("=== Fastboot烧录完成 ===")
            return True
            
        except Exception as e:
            logger.error(f"Fastboot烧录失败: {e}")
            return False
    
    def _install_sunxi_tools(self):
        """安装sunxi-tools"""
        try:
            logger.info("安装sunxi-tools...")
            subprocess.run(['apt-get', 'update'], check=True)
            subprocess.run(['apt-get', 'install', '-y', 'sunxi-tools'], check=True)
            logger.info("✓ sunxi-tools安装完成")
        except Exception as e:
            logger.error(f"安装sunxi-tools失败: {e}")
            logger.error("请手动安装: sudo apt-get install sunxi-tools")
    
    def wait_for_device(self, timeout: int = 60) -> bool:
        """等待设备就绪"""
        logger.info(f"等待设备就绪（超时{timeout}秒）...")
        start = time.time()
        
        while time.time() - start < timeout:
            # 检查串口
            if self.serial_port and os.path.exists(self.serial_port):
                try:
                    ser = serial.Serial(self.serial_port, 115200, timeout=2)
                    ser.write(b'\n')
                    time.sleep(0.5)
                    response = ser.read(ser.in_waiting or 1)
                    ser.close()
                    if response:
                        logger.info("✓ 串口设备已就绪")
                        return True
                except:
                    pass
            
            # 检查USB设备
            if self._find_fel_device():
                logger.info("✓ USB设备已就绪")
                return True
            
            time.sleep(1)
        
        logger.error("✗ 等待设备超时")
        return False


def auto_detect_serial() -> Optional[str]:
    """自动检测串口设备"""
    ports = list(serial.tools.list_ports.comports())
    
    # 优先找USB转串口
    for port in ports:
        if 'USB' in port.description or 'usb' in port.device.lower():
            logger.info(f"检测到串口: {port.device} - {port.description}")
            return port.device
    
    # 返回第一个可用串口
    if ports:
        return ports[0].device
    
    return None


def main():
    parser = argparse.ArgumentParser(description='P7885自动烧录工具')
    parser.add_argument('--method', '-m', 
                       choices=['fel', 'tf', 'fastboot', 'auto'],
                       default='auto',
                       help='烧录方式')
    parser.add_argument('--image-dir', '-i',
                       default='./images',
                       help='镜像目录路径')
    parser.add_argument('--device', '-d',
                       help='TF卡设备路径 (如 /dev/sdb)')
    parser.add_argument('--serial', '-s',
                       help='串口设备路径')
    parser.add_argument('--force-fel', '-f',
                       action='store_true',
                       help='强制进入FEL模式')
    parser.add_argument('--wait', '-w',
                       type=int,
                       default=0,
                       help='烧录前等待设备就绪的秒数')
    
    args = parser.parse_args()
    
    # 自动检测串口
    serial_port = args.serial
    if not serial_port:
        serial_port = auto_detect_serial()
    
    # 创建烧录器
    try:
        flasher = P7885Flasher(args.image_dir, serial_port)
    except FileNotFoundError as e:
        logger.error(e)
        sys.exit(1)
    
    # 等待设备
    if args.wait > 0:
        if not flasher.wait_for_device(args.wait):
            sys.exit(1)
    
    # 执行烧录
    success = False
    
    if args.method == 'fel' or args.method == 'auto':
        success = flasher.flash_fel(force_fel=args.force_fel)
    elif args.method == 'tf':
        if not args.device:
            logger.error("TF卡烧录需要指定 --device 参数")
            sys.exit(1)
        success = flasher.flash_tf(args.device)
    elif args.method == 'fastboot':
        success = flasher.flash_fastboot()
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
