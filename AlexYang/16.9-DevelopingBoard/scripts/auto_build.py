#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
P7885 OpenHarmony 自动编译脚本

功能：
1. 自动下载源码
2. 自动编译镜像
3. 自动打包输出
4. 自动触发烧录测试

Usage:
    python3 auto_build.py --source-dir ~/ohos-p7885
    python3 auto_build.py --clean --build
    python3 auto_build.py --incremental
"""

import os
import sys
import time
import shutil
import argparse
import subprocess
import logging
from pathlib import Path
from datetime import datetime
from typing import Optional, List, Tuple

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(f'/var/log/p7885-build-{datetime.now():%Y%m%d}.log')
    ]
)
logger = logging.getLogger(__name__)


class P7885Builder:
    """P7885编译器"""
    
    PRODUCT = 'hihope_p7885'
    
    def __init__(self, source_dir: str, jobs: int = 8, ccache: bool = True):
        self.source_dir = Path(source_dir).expanduser().resolve()
        self.jobs = jobs
        self.use_ccache = ccache
        self.build_log = []
        
        # 检查源码目录
        if not self.source_dir.exists():
            logger.warning(f"源码目录不存在: {self.source_dir}")
    
    def setup_environment(self) -> bool:
        """设置编译环境"""
        logger.info("=" * 60)
        logger.info("设置编译环境")
        logger.info("=" * 60)
        
        checks = [
            ('Python 3.8+', self._check_python),
            ('Node.js 14+', self._check_nodejs),
            ('Git', self._check_git),
            ('GN', self._check_gn),
            ('Ninja', self._check_ninja),
            ('Clang', self._check_clang),
            ('磁盘空间', self._check_disk_space),
        ]
        
        all_passed = True
        for name, check_func in checks:
            if check_func():
                logger.info(f"✓ {name}")
            else:
                logger.error(f"✗ {name}")
                all_passed = False
        
        return all_passed
    
    def _check_python(self) -> bool:
        try:
            result = subprocess.run(
                ['python3', '--version'],
                capture_output=True, text=True
            )
            version = result.stdout.strip() or result.stderr.strip()
            logger.info(f"  Python: {version}")
            return '3.' in version
        except:
            return False
    
    def _check_nodejs(self) -> bool:
        try:
            result = subprocess.run(
                ['node', '--version'],
                capture_output=True, text=True
            )
            version = result.stdout.strip()
            logger.info(f"  Node.js: {version}")
            return version.startswith('v14') or version.startswith('v16') or version.startswith('v18')
        except:
            return False
    
    def _check_git(self) -> bool:
        try:
            result = subprocess.run(
                ['git', '--version'],
                capture_output=True, text=True
            )
            logger.info(f"  Git: {result.stdout.strip()}")
            return True
        except:
            return False
    
    def _check_gn(self) -> bool:
        try:
            result = subprocess.run(
                ['gn', '--version'],
                capture_output=True, text=True
            )
            logger.info(f"  GN: {result.stdout.strip()}")
            return True
        except:
            return False
    
    def _check_ninja(self) -> bool:
        try:
            result = subprocess.run(
                ['ninja', '--version'],
                capture_output=True, text=True
            )
            logger.info(f"  Ninja: {result.stdout.strip()}")
            return True
        except:
            return False
    
    def _check_clang(self) -> bool:
        try:
            result = subprocess.run(
                ['clang', '--version'],
                capture_output=True, text=True
            )
            version = result.stdout.split('\n')[0]
            logger.info(f"  Clang: {version}")
            return True
        except:
            return False
    
    def _check_disk_space(self) -> bool:
        try:
            stat = shutil.disk_usage(self.source_dir.parent)
            free_gb = stat.free / (1024**3)
            total_gb = stat.total / (1024**3)
            logger.info(f"  磁盘空间: {free_gb:.1f} GB 可用 / {total_gb:.1f} GB 总计")
            return free_gb > 100  # 至少需要100GB
        except:
            return False
    
    def download_source(self, branch: str = 'OpenHarmony-4.1-Release') -> bool:
        """下载源码"""
        logger.info("=" * 60)
        logger.info(f"下载OpenHarmony源码: {branch}")
        logger.info("=" * 60)
        
        if self.source_dir.exists() and any(self.source_dir.iterdir()):
            logger.warning("源码目录已存在且非空，跳过下载")
            return True
        
        self.source_dir.mkdir(parents=True, exist_ok=True)
        
        try:
            # 初始化repo
            cmd = [
                'repo', 'init',
                '-u', 'https://gitee.com/openharmony/manifest.git',
                '-b', branch,
                '--no-repo-verify'
            ]
            logger.info(f"执行: {' '.join(cmd)}")
            result = subprocess.run(cmd, cwd=self.source_dir, capture_output=True, text=True)
            
            if result.returncode != 0:
                logger.error(f"repo init 失败: {result.stderr}")
                return False
            
            # 同步代码
            logger.info("同步源码中，这可能需要30-60分钟...")
            cmd = ['repo', 'sync', '-c', '--no-tags', '-j4']
            result = subprocess.run(cmd, cwd=self.source_dir, capture_output=True, text=True)
            
            if result.returncode != 0:
                logger.error(f"repo sync 失败: {result.stderr}")
                return False
            
            logger.info("✓ 源码下载完成")
            return True
            
        except Exception as e:
            logger.error(f"下载源码失败: {e}")
            return False
    
    def download_prebuilts(self) -> bool:
        """下载预编译工具"""
        logger.info("=" * 60)
        logger.info("下载预编译工具")
        logger.info("=" * 60)
        
        script = self.source_dir / 'build' / 'prebuilts_download.sh'
        if not script.exists():
            logger.error(f"找不到脚本: {script}")
            return False
        
        try:
            cmd = [str(script), '--skip-ssl', '--no-check-certificate']
            logger.info(f"执行: {' '.join(cmd)}")
            result = subprocess.run(cmd, cwd=self.source_dir, capture_output=True, text=True)
            
            if result.returncode != 0:
                logger.error(f"下载失败: {result.stderr}")
                return False
            
            logger.info("✓ 预编译工具下载完成")
            return True
            
        except Exception as e:
            logger.error(f"下载预编译工具失败: {e}")
            return False
    
    def clean_build(self) -> bool:
        """清理编译输出"""
        logger.info("=" * 60)
        logger.info("清理编译输出")
        logger.info("=" * 60)
        
        out_dir = self.source_dir / 'out'
        if out_dir.exists():
            try:
                shutil.rmtree(out_dir)
                logger.info("✓ 清理完成")
                return True
            except Exception as e:
                logger.error(f"清理失败: {e}")
                return False
        else:
            logger.info("无需清理")
            return True
    
    def build(self, incremental: bool = False) -> bool:
        """
        执行编译
        
        Args:
            incremental: 是否增量编译
        """
        logger.info("=" * 60)
        logger.info(f"开始编译: {self.PRODUCT}")
        logger.info(f"编译模式: {'增量' if incremental else '全量'}")
        logger.info(f"并行任务: {self.jobs}")
        logger.info(f"CCache: {'启用' if self.use_ccache else '禁用'}")
        logger.info("=" * 60)
        
        # 加载环境
        env_setup = self.source_dir / 'build' / 'envsetup.sh'
        if not env_setup.exists():
            logger.error(f"找不到环境脚本: {env_setup}")
            return False
        
        # 构建编译命令
        build_cmd = f"""
        source {env_setup} &&
        lunch {self.PRODUCT}-userdebug &&
        ./build.sh --product {self.PRODUCT} --jobs {self.jobs}
        """
        
        if self.use_ccache:
            build_cmd += " --ccache"
        
        if not incremental:
            # 全量编译时确保out目录不存在
            self.clean_build()
        
        # 执行编译
        start_time = time.time()
        
        try:
            logger.info("编译进行中，请耐心等待...")
            result = subprocess.run(
                build_cmd,
                shell=True,
                cwd=self.source_dir,
                executable='/bin/bash',
                capture_output=False  # 实时输出
            )
            
            duration = time.time() - start_time
            
            if result.returncode == 0:
                logger.info(f"✓ 编译成功，耗时: {duration/60:.1f} 分钟")
                return True
            else:
                logger.error(f"✗ 编译失败，耗时: {duration/60:.1f} 分钟")
                return False
                
        except Exception as e:
            logger.error(f"编译异常: {e}")
            return False
    
    def package_output(self, output_dir: str) -> Optional[Path]:
        """
        打包编译输出
        
        Returns:
            打包文件路径
        """
        logger.info("=" * 60)
        logger.info("打包编译输出")
        logger.info("=" * 60)
        
        # 查找编译输出
        image_dir = self.source_dir / 'out' / self.PRODUCT / 'packages' / 'phone' / 'images'
        if not image_dir.exists():
            logger.error(f"找不到镜像目录: {image_dir}")
            return None
        
        # 创建输出目录
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        # 生成版本号
        version = datetime.now().strftime('%Y%m%d-%H%M%S')
        build_name = f"{self.PRODUCT}-{version}"
        package_dir = output_path / build_name
        package_dir.mkdir(exist_ok=True)
        
        # 复制镜像文件
        image_files = list(image_dir.glob('*.img'))
        if not image_files:
            logger.error("没有找到镜像文件")
            return None
        
        for img in image_files:
            shutil.copy2(img, package_dir)
            logger.info(f"  复制: {img.name}")
        
        # 复制构建信息
        build_info = package_dir / 'build_info.txt'
        with open(build_info, 'w') as f:
            f.write(f"Build Time: {datetime.now().isoformat()}\n")
            f.write(f"Product: {self.PRODUCT}\n")
            f.write(f"Source: {self.source_dir}\n")
            
            # 获取Git信息
            try:
                result = subprocess.run(
                    ['git', 'log', '-1', '--oneline'],
                    cwd=self.source_dir,
                    capture_output=True, text=True
                )
                f.write(f"Git Commit: {result.stdout.strip()}\n")
            except:
                pass
        
        logger.info(f"✓ 打包完成: {package_dir}")
        return package_dir
    
    def trigger_flash_test(self, image_dir: Path, test_config: dict) -> bool:
        """触发烧录和测试"""
        logger.info("=" * 60)
        logger.info("触发烧录和测试")
        logger.info("=" * 60)
        
        # 这里可以调用 flash_p7885.py 和 remote_test.py
        flash_script = Path(__file__).parent / 'flash_p7885.py'
        test_script = Path(__file__).parent / 'remote_test.py'
        
        if not flash_script.exists():
            logger.warning(f"找不到烧录脚本: {flash_script}")
            return False
        
        try:
            # 执行烧录
            logger.info("开始自动烧录...")
            cmd = [
                'python3', str(flash_script),
                '--method', test_config.get('flash_method', 'fel'),
                '--image-dir', str(image_dir)
            ]
            
            if test_config.get('serial_port'):
                cmd.extend(['--serial', test_config['serial_port']])
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode != 0:
                logger.error(f"烧录失败: {result.stderr}")
                return False
            
            logger.info("✓ 烧录成功")
            
            # 执行测试
            logger.info("开始自动测试...")
            cmd = [
                'python3', str(test_script),
                '--method', test_config.get('test_method', 'ssh'),
                '--host', test_config.get('host', '192.168.1.100'),
                '--report', str(image_dir / 'test_report.json')
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode != 0:
                logger.error(f"测试失败: {result.stderr}")
                return False
            
            logger.info("✓ 测试完成")
            return True
            
        except Exception as e:
            logger.error(f"烧录测试失败: {e}")
            return False


def main():
    parser = argparse.ArgumentParser(description='P7885自动编译工具')
    parser.add_argument('--source-dir', '-s',
                       default='~/ohos-p7885',
                       help='源码目录')
    parser.add_argument('--jobs', '-j',
                       type=int,
                       default=8,
                       help='并行编译任务数')
    parser.add_argument('--no-ccache',
                       action='store_true',
                       help='禁用ccache')
    parser.add_argument('--clean', '-c',
                       action='store_true',
                       help='清理编译输出')
    parser.add_argument('--build', '-b',
                       action='store_true',
                       help='执行编译')
    parser.add_argument('--incremental', '-i',
                       action='store_true',
                       help='增量编译')
    parser.add_argument('--download',
                       action='store_true',
                       help='下载源码')
    parser.add_argument('--branch',
                       default='OpenHarmony-4.1-Release',
                       help='源码分支')
    parser.add_argument('--output-dir', '-o',
                       default='/opt/ohos-images',
                       help='输出目录')
    parser.add_argument('--flash-test',
                       action='store_true',
                       help='编译后自动烧录测试')
    parser.add_argument('--test-config',
                       help='测试配置文件(JSON)')
    
    args = parser.parse_args()
    
    # 创建编译器
    builder = P7885Builder(
        args.source_dir,
        jobs=args.jobs,
        ccache=not args.no_ccache
    )
    
    # 设置环境
    if not builder.setup_environment():
        logger.error("环境检查失败，请修复后重试")
        sys.exit(1)
    
    # 下载源码
    if args.download:
        if not builder.download_source(args.branch):
            logger.error("源码下载失败")
            sys.exit(1)
        
        if not builder.download_prebuilts():
            logger.error("预编译工具下载失败")
            sys.exit(1)
    
    # 清理
    if args.clean:
        builder.clean_build()
    
    # 编译
    if args.build or (not args.clean and not args.download):
        if not builder.build(incremental=args.incremental):
            logger.error("编译失败")
            sys.exit(1)
        
        # 打包输出
        package_dir = builder.package_output(args.output_dir)
        
        if package_dir and args.flash_test:
            # 加载测试配置
            test_config = {}
            if args.test_config and os.path.exists(args.test_config):
                import json
                with open(args.test_config) as f:
                    test_config = json.load(f)
            
            # 触发烧录测试
            builder.trigger_flash_test(package_dir, test_config)
    
    logger.info("=" * 60)
    logger.info("任务完成")
    logger.info("=" * 60)


if __name__ == '__main__':
    main()
