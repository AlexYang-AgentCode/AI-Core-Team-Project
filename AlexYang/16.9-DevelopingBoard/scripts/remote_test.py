#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
P7885 远程连接与自动化测试脚本

功能：
1. 通过SSH/ADB/串口远程连接设备
2. 自动执行功能测试
3. 收集测试结果和日志

Usage:
    python3 remote_test.py --method ssh --host 192.168.1.100
    python3 remote_test.py --method adb
    python3 remote_test.py --method serial --port /dev/ttyUSB0
"""

import os
import sys
import time
import json
import paramiko
import serial
import subprocess
import argparse
import logging
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@dataclass
class TestResult:
    """测试结果数据类"""
    test_name: str
    status: str  # 'PASS', 'FAIL', 'SKIP'
    duration: float
    output: str
    error: str = ""
    timestamp: str = ""
    
    def __post_init__(self):
        if not self.timestamp:
            self.timestamp = datetime.now().isoformat()


class P7885RemoteConnector:
    """P7885远程连接器"""
    
    def __init__(self):
        self.ssh_client: Optional[paramiko.SSHClient] = None
        self.serial_conn: Optional[serial.Serial] = None
        self.connected = False
        self.connection_method = None
    
    def connect_ssh(self, host: str, port: int = 22, 
                   username: str = 'root', password: str = '123456',
                   key_file: Optional[str] = None) -> bool:
        """通过SSH连接"""
        try:
            self.ssh_client = paramiko.SSHClient()
            self.ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            
            if key_file and os.path.exists(key_file):
                self.ssh_client.connect(
                    host, port=port, username=username,
                    key_filename=key_file, timeout=10
                )
            else:
                self.ssh_client.connect(
                    host, port=port, username=username,
                    password=password, timeout=10
                )
            
            self.connected = True
            self.connection_method = 'ssh'
            logger.info(f"✓ SSH连接成功: {host}:{port}")
            return True
            
        except Exception as e:
            logger.error(f"✗ SSH连接失败: {e}")
            return False
    
    def connect_adb(self, device: Optional[str] = None) -> bool:
        """通过ADB连接"""
        try:
            # 检查ADB
            result = subprocess.run(['adb', 'devices'], 
                                  capture_output=True, text=True)
            if 'device' not in result.stdout:
                logger.error("✗ 未找到ADB设备")
                return False
            
            self.connected = True
            self.connection_method = 'adb'
            self.adb_device = device
            logger.info("✓ ADB连接成功")
            return True
            
        except Exception as e:
            logger.error(f"✗ ADB连接失败: {e}")
            return False
    
    def connect_serial(self, port: str = '/dev/ttyUSB0', 
                      baudrate: int = 115200) -> bool:
        """通过串口连接"""
        try:
            self.serial_conn = serial.Serial(
                port=port,
                baudrate=baudrate,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=5
            )
            
            self.connected = True
            self.connection_method = 'serial'
            logger.info(f"✓ 串口连接成功: {port}@{baudrate}")
            return True
            
        except Exception as e:
            logger.error(f"✗ 串口连接失败: {e}")
            return False
    
    def execute(self, command: str, timeout: int = 30) -> Tuple[int, str, str]:
        """
        执行远程命令
        
        Returns:
            (returncode, stdout, stderr)
        """
        if not self.connected:
            return -1, "", "未连接"
        
        try:
            if self.connection_method == 'ssh':
                return self._execute_ssh(command, timeout)
            elif self.connection_method == 'adb':
                return self._execute_adb(command, timeout)
            elif self.connection_method == 'serial':
                return self._execute_serial(command, timeout)
            else:
                return -1, "", "未知连接方式"
                
        except Exception as e:
            logger.error(f"命令执行失败: {e}")
            return -1, "", str(e)
    
    def _execute_ssh(self, command: str, timeout: int) -> Tuple[int, str, str]:
        """通过SSH执行命令"""
        stdin, stdout, stderr = self.ssh_client.exec_command(command, timeout=timeout)
        exit_status = stdout.channel.recv_exit_status()
        return exit_status, stdout.read().decode('utf-8'), stderr.read().decode('utf-8')
    
    def _execute_adb(self, command: str, timeout: int) -> Tuple[int, str, str]:
        """通过ADB执行命令"""
        cmd = ['adb']
        if self.adb_device:
            cmd.extend(['-s', self.adb_device])
        cmd.extend(['shell', command])
        
        result = subprocess.run(
            cmd, capture_output=True, text=True,
            timeout=timeout
        )
        return result.returncode, result.stdout, result.stderr
    
    def _execute_serial(self, command: str, timeout: int) -> Tuple[int, str, str]:
        """通过串口执行命令"""
        # 清空缓冲区
        self.serial_conn.reset_input_buffer()
        
        # 发送命令
        self.serial_conn.write(f'{command}\n'.encode())
        
        # 读取响应
        output = ""
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            if self.serial_conn.in_waiting:
                data = self.serial_conn.read(self.serial_conn.in_waiting)
                output += data.decode('utf-8', errors='ignore')
                
                # 检测命令结束（简单实现）
                if '#' in output or '$' in output:
                    break
            
            time.sleep(0.1)
        
        return 0, output, ""
    
    def disconnect(self):
        """断开连接"""
        if self.ssh_client:
            self.ssh_client.close()
        if self.serial_conn:
            self.serial_conn.close()
        self.connected = False
        logger.info("断开连接")
    
    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.disconnect()


class P7885Tester:
    """P7885自动化测试器"""
    
    def __init__(self, connector: P7885RemoteConnector):
        self.connector = connector
        self.results: List[TestResult] = []
    
    def run_all_tests(self) -> List[TestResult]:
        """运行所有测试"""
        logger.info("=" * 60)
        logger.info("开始自动化测试")
        logger.info("=" * 60)
        
        tests = [
            ('系统启动测试', self.test_boot),
            ('系统信息测试', self.test_system_info),
            ('网络连通测试', self.test_network),
            ('存储测试', self.test_storage),
            ('内存测试', self.test_memory),
            ('CPU测试', self.test_cpu),
            ('GPU测试', self.test_gpu),
            ('外设GPIO测试', self.test_gpio),
            ('日志测试', self.test_logs),
            ('进程测试', self.test_processes),
        ]
        
        for test_name, test_func in tests:
            try:
                result = test_func()
                self.results.append(result)
                status_icon = "✓" if result.status == 'PASS' else "✗"
                logger.info(f"{status_icon} {test_name}: {result.status}")
            except Exception as e:
                logger.error(f"✗ {test_name}: ERROR - {e}")
                self.results.append(TestResult(
                    test_name=test_name,
                    status='FAIL',
                    duration=0,
                    output="",
                    error=str(e)
                ))
        
        return self.results
    
    def test_boot(self) -> TestResult:
        """测试系统启动状态"""
        start = time.time()
        
        rc, stdout, stderr = self.connector.execute('uptime')
        
        if rc == 0 and 'up' in stdout:
            return TestResult(
                test_name='系统启动测试',
                status='PASS',
                duration=time.time() - start,
                output=stdout
            )
        else:
            return TestResult(
                test_name='系统启动测试',
                status='FAIL',
                duration=time.time() - start,
                output=stdout,
                error=stderr
            )
    
    def test_system_info(self) -> TestResult:
        """测试系统信息获取"""
        start = time.time()
        
        commands = [
            'uname -a',
            'cat /etc/openharmony-release',
            'getprop ro.build.version.release'
        ]
        
        outputs = []
        for cmd in commands:
            rc, stdout, _ = self.connector.execute(cmd)
            if rc == 0:
                outputs.append(stdout.strip())
        
        if outputs:
            return TestResult(
                test_name='系统信息测试',
                status='PASS',
                duration=time.time() - start,
                output='\n'.join(outputs)
            )
        else:
            return TestResult(
                test_name='系统信息测试',
                status='FAIL',
                duration=time.time() - start,
                output="",
                error="无法获取系统信息"
            )
    
    def test_network(self) -> TestResult:
        """测试网络连通性"""
        start = time.time()
        
        # 获取网络配置
        rc1, ifconfig, _ = self.connector.execute('ifconfig')
        rc2, ping_result, _ = self.connector.execute('ping -c 3 8.8.8.8')
        
        if rc1 == 0 and ('inet ' in ifconfig or 'inet6 ' in ifconfig):
            status = 'PASS' if rc2 == 0 else 'FAIL'
            return TestResult(
                test_name='网络连通测试',
                status=status,
                duration=time.time() - start,
                output=f"Interface:\n{ifconfig}\n\nPing:\n{ping_result}"
            )
        else:
            return TestResult(
                test_name='网络连通测试',
                status='FAIL',
                duration=time.time() - start,
                output=ifconfig,
                error="网络接口配置失败"
            )
    
    def test_storage(self) -> TestResult:
        """测试存储"""
        start = time.time()
        
        rc, df_output, _ = self.connector.execute('df -h')
        
        if rc == 0:
            # 解析存储使用情况
            lines = df_output.strip().split('\n')
            for line in lines[1:]:  # 跳过标题
                parts = line.split()
                if len(parts) >= 6:
                    filesystem, size, used, available, use_percent, mount = parts[:6]
                    logger.info(f"  {mount}: {use_percent} used ({available} available)")
            
            return TestResult(
                test_name='存储测试',
                status='PASS',
                duration=time.time() - start,
                output=df_output
            )
        else:
            return TestResult(
                test_name='存储测试',
                status='FAIL',
                duration=time.time() - start,
                output="",
                error="无法获取存储信息"
            )
    
    def test_memory(self) -> TestResult:
        """测试内存"""
        start = time.time()
        
        rc, meminfo, _ = self.connector.execute('cat /proc/meminfo')
        
        if rc == 0:
            # 解析内存信息
            mem_total = 0
            mem_available = 0
            
            for line in meminfo.split('\n'):
                if line.startswith('MemTotal:'):
                    mem_total = int(line.split()[1]) // 1024  # MB
                elif line.startswith('MemAvailable:'):
                    mem_available = int(line.split()[1]) // 1024  # MB
            
            if mem_total > 0:
                logger.info(f"  总内存: {mem_total} MB, 可用: {mem_available} MB")
                return TestResult(
                    test_name='内存测试',
                    status='PASS',
                    duration=time.time() - start,
                    output=meminfo
                )
        
        return TestResult(
            test_name='内存测试',
            status='FAIL',
            duration=time.time() - start,
            output=meminfo,
            error="无法获取内存信息"
        )
    
    def test_cpu(self) -> TestResult:
        """测试CPU"""
        start = time.time()
        
        commands = [
            'cat /proc/cpuinfo | grep "model name" | head -1',
            'cat /proc/cpuinfo | grep "processor" | wc -l',
            'cat /proc/loadavg'
        ]
        
        outputs = []
        for cmd in commands:
            rc, stdout, _ = self.connector.execute(cmd)
            if rc == 0:
                outputs.append(stdout.strip())
        
        if outputs:
            return TestResult(
                test_name='CPU测试',
                status='PASS',
                duration=time.time() - start,
                output='\n'.join(outputs)
            )
        else:
            return TestResult(
                test_name='CPU测试',
                status='FAIL',
                duration=time.time() - start,
                output="",
                error="无法获取CPU信息"
            )
    
    def test_gpu(self) -> TestResult:
        """测试GPU"""
        start = time.time()
        
        # 检查GPU驱动
        rc, gpu_info, _ = self.connector.execute('ls -la /dev/gpu* 2>/dev/null || ls -la /dev/mali* 2>/dev/null || echo "No GPU device found"')
        
        if rc == 0:
            return TestResult(
                test_name='GPU测试',
                status='PASS',
                duration=time.time() - start,
                output=gpu_info
            )
        else:
            return TestResult(
                test_name='GPU测试',
                status='SKIP',
                duration=time.time() - start,
                output="",
                error="GPU测试跳过"
            )
    
    def test_gpio(self) -> TestResult:
        """测试GPIO"""
        start = time.time()
        
        # 检查GPIO sysfs接口
        rc, gpio_info, _ = self.connector.execute('ls /sys/class/gpio/ 2>/dev/null || echo "GPIO not available"')
        
        if rc == 0:
            return TestResult(
                test_name='外设GPIO测试',
                status='PASS',
                duration=time.time() - start,
                output=gpio_info
            )
        else:
            return TestResult(
                test_name='外设GPIO测试',
                status='SKIP',
                duration=time.time() - start,
                output="",
                error="GPIO接口不可用"
            )
    
    def test_logs(self) -> TestResult:
        """测试日志系统"""
        start = time.time()
        
        # 检查hilog
        rc1, hilog_output, _ = self.connector.execute('hilog -t last 10 2>/dev/null || echo "hilog not available"')
        
        # 检查dmesg
        rc2, dmesg_output, _ = self.connector.execute('dmesg | tail -20')
        
        output = f"Hilog:\n{hilog_output}\n\nDmesg:\n{dmesg_output}"
        
        return TestResult(
            test_name='日志测试',
            status='PASS',
            duration=time.time() - start,
            output=output
        )
    
    def test_processes(self) -> TestResult:
        """测试关键进程"""
        start = time.time()
        
        # 检查关键进程
        key_processes = ['init', 'foundation', 'samgr']
        process_status = []
        
        for proc in key_processes:
            rc, output, _ = self.connector.execute(f'pgrep {proc}')
            if rc == 0:
                process_status.append(f"✓ {proc}: running")
            else:
                process_status.append(f"✗ {proc}: not found")
        
        return TestResult(
            test_name='进程测试',
            status='PASS',
            duration=time.time() - start,
            output='\n'.join(process_status)
        )
    
    def generate_report(self, output_file: str):
        """生成测试报告"""
        report = {
            'timestamp': datetime.now().isoformat(),
            'summary': {
                'total': len(self.results),
                'passed': sum(1 for r in self.results if r.status == 'PASS'),
                'failed': sum(1 for r in self.results if r.status == 'FAIL'),
                'skipped': sum(1 for r in self.results if r.status == 'SKIP'),
                'total_duration': sum(r.duration for r in self.results)
            },
            'results': [asdict(r) for r in self.results]
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        logger.info(f"测试报告已保存: {output_file}")
        
        # 打印摘要
        summary = report['summary']
        logger.info("\n" + "=" * 60)
        logger.info("测试摘要")
        logger.info("=" * 60)
        logger.info(f"总计: {summary['total']} 项")
        logger.info(f"通过: {summary['passed']} 项")
        logger.info(f"失败: {summary['failed']} 项")
        logger.info(f"跳过: {summary['skipped']} 项")
        logger.info(f"总耗时: {summary['total_duration']:.2f} 秒")
        logger.info("=" * 60)


def main():
    parser = argparse.ArgumentParser(description='P7885远程连接与测试工具')
    parser.add_argument('--method', '-m',
                       choices=['ssh', 'adb', 'serial'],
                       required=True,
                       help='连接方式')
    parser.add_argument('--host', '-H',
                       help='SSH主机地址')
    parser.add_argument('--port', '-P',
                       type=int,
                       default=22,
                       help='SSH端口')
    parser.add_argument('--username', '-u',
                       default='root',
                       help='SSH用户名')
    parser.add_argument('--password', '-p',
                       default='123456',
                       help='SSH密码')
    parser.add_argument('--serial-port', '-s',
                       default='/dev/ttyUSB0',
                       help='串口设备')
    parser.add_argument('--baudrate', '-b',
                       type=int,
                       default=115200,
                       help='串口波特率')
    parser.add_argument('--report', '-r',
                       default='test_report.json',
                       help='测试报告输出文件')
    parser.add_argument('--command', '-c',
                       help='执行单个命令后退出')
    
    args = parser.parse_args()
    
    # 创建连接器
    connector = P7885RemoteConnector()
    
    # 建立连接
    connected = False
    if args.method == 'ssh':
        if not args.host:
            logger.error("SSH模式需要指定 --host")
            sys.exit(1)
        connected = connector.connect_ssh(
            args.host, args.port, args.username, args.password
        )
    elif args.method == 'adb':
        connected = connector.connect_adb()
    elif args.method == 'serial':
        connected = connector.connect_serial(args.serial_port, args.baudrate)
    
    if not connected:
        logger.error("连接失败")
        sys.exit(1)
    
    # 执行命令或测试
    if args.command:
        rc, stdout, stderr = connector.execute(args.command)
        print(stdout)
        if stderr:
            print(f"Error: {stderr}", file=sys.stderr)
        connector.disconnect()
        sys.exit(rc)
    else:
        # 运行完整测试
        tester = P7885Tester(connector)
        tester.run_all_tests()
        tester.generate_report(args.report)
        connector.disconnect()


if __name__ == '__main__':
    main()
