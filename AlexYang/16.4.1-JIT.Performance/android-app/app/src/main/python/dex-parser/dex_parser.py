#!/usr/bin/env python3
"""
DEX Parser - MVP版本
解析Android DEX文件格式

作者: 16.4.1-JIT.Performance团队
日期: 2026-03-11
"""

import struct
from dataclasses import dataclass
from typing import List, Dict, Optional, Tuple
from enum import IntEnum

class AccessFlags(IntEnum):
    """访问权限标志"""
    PUBLIC = 0x1
    PRIVATE = 0x2
    PROTECTED = 0x4
    STATIC = 0x8
    FINAL = 0x10
    SYNCHRONIZED = 0x20
    VOLATILE = 0x40
    BRIDGE = 0x40
    TRANSIENT = 0x80
    VARARGS = 0x80
    NATIVE = 0x100
    INTERFACE = 0x200
    ABSTRACT = 0x400
    STRICTFP = 0x800
    SYNTHETIC = 0x1000
    ANNOTATION = 0x2000
    ENUM = 0x4000
    CONSTRUCTOR = 0x10000
    DECLARED_SYNCHRONIZED = 0x20000

@dataclass
class DexHeader:
    """DEX文件头"""
    magic: bytes
    checksum: int
    signature: bytes
    file_size: int
    header_size: int
    endian_tag: int
    link_size: int
    link_off: int
    map_off: int
    string_ids_size: int
    string_ids_off: int
    type_ids_size: int
    type_ids_off: int
    proto_ids_size: int
    proto_ids_off: int
    field_ids_size: int
    field_ids_off: int
    method_ids_size: int
    method_ids_off: int
    class_defs_size: int
    class_defs_off: int
    data_size: int
    data_off: int

@dataclass
class FieldDef:
    """字段定义"""
    class_idx: int
    type_idx: int
    name_idx: int
    access_flags: int
    
    def __repr__(self):
        return f"FieldDef(name_idx={self.name_idx}, type_idx={self.type_idx}, access_flags={hex(self.access_flags)})"

@dataclass
class MethodDef:
    """方法定义"""
    class_idx: int
    proto_idx: int
    name_idx: int
    access_flags: int
    code_off: int
    
    def __repr__(self):
        return f"MethodDef(name_idx={self.name_idx}, class_idx={self.class_idx}, access_flags={hex(self.access_flags)})"

@dataclass
class ClassDef:
    """类定义"""
    class_idx: int
    access_flags: int
    superclass_idx: int
    interfaces_off: int
    source_file_idx: int
    annotations_off: int
    class_data_off: int
    static_values_off: int
    
    # 解析后的数据
    fields: Optional[List[FieldDef]] = None
    methods: Optional[List[MethodDef]] = None
    
    def __post_init__(self):
        if self.fields is None:
            self.fields = []
        if self.methods is None:
            self.methods = []
    
    def __repr__(self):
        return f"ClassDef(class_idx={self.class_idx}, fields={len(self.fields)}, methods={len(self.methods)})"

class DexParser:
    """DEX文件解析器"""
    
    def __init__(self, data: bytes):
        self.data = data
        self.position = 0
        
        # 解析后的数据
        self.header: Optional[DexHeader] = None
        self.strings: List[str] = []
        self.types: List[int] = []  # 指向string_ids的索引
        self.class_defs: List[ClassDef] = []
        self.field_ids: List[Tuple[int, int, int]] = []  # (class_idx, type_idx, name_idx)
        self.method_ids: List[Tuple[int, int, int]] = []  # (class_idx, proto_idx, name_idx)
    
    def parse(self) -> bool:
        """解析DEX文件"""
        try:
            self._parse_header()
            self._parse_strings()
            self._parse_types()
            self._parse_field_ids()
            self._parse_method_ids()
            self._parse_class_defs()
            self._parse_class_data()
            return True
        except Exception as e:
            print(f"解析失败: {e}")
            return False
    
    def _parse_header(self):
        """解析文件头"""
        self.position = 0
        
        magic = self._read_bytes(8)
        if magic[:4] != b'dex\n':
            raise ValueError(f"无效的DEX文件magic: {magic[:4]}")
        
        checksum = self._read_uint32()
        signature = self._read_bytes(20)
        file_size = self._read_uint32()
        header_size = self._read_uint32()
        endian_tag = self._read_uint32()
        link_size = self._read_uint32()
        link_off = self._read_uint32()
        map_off = self._read_uint32()
        string_ids_size = self._read_uint32()
        string_ids_off = self._read_uint32()
        type_ids_size = self._read_uint32()
        type_ids_off = self._read_uint32()
        proto_ids_size = self._read_uint32()
        proto_ids_off = self._read_uint32()
        field_ids_size = self._read_uint32()
        field_ids_off = self._read_uint32()
        method_ids_size = self._read_uint32()
        method_ids_off = self._read_uint32()
        class_defs_size = self._read_uint32()
        class_defs_off = self._read_uint32()
        data_size = self._read_uint32()
        data_off = self._read_uint32()
        
        self.header = DexHeader(
            magic=magic,
            checksum=checksum,
            signature=signature,
            file_size=file_size,
            header_size=header_size,
            endian_tag=endian_tag,
            link_size=link_size,
            link_off=link_off,
            map_off=map_off,
            string_ids_size=string_ids_size,
            string_ids_off=string_ids_off,
            type_ids_size=type_ids_size,
            type_ids_off=type_ids_off,
            proto_ids_size=proto_ids_size,
            proto_ids_off=proto_ids_off,
            field_ids_size=field_ids_size,
            field_ids_off=field_ids_off,
            method_ids_size=method_ids_size,
            method_ids_off=method_ids_off,
            class_defs_size=class_defs_size,
            class_defs_off=class_defs_off,
            data_size=data_size,
            data_off=data_off
        )
        
        print(f"DEX文件头解析成功:")
        print(f"  文件大小: {file_size} bytes")
        print(f"  字符串数量: {string_ids_size}")
        print(f"  类型数量: {type_ids_size}")
        print(f"  字段数量: {field_ids_size}")
        print(f"  方法数量: {method_ids_size}")
        print(f"  类定义数量: {class_defs_size}")
    
    def _parse_strings(self):
        """解析字符串池"""
        self.position = self.header.string_ids_off
        string_offsets = []
        
        for _ in range(self.header.string_ids_size):
            offset = self._read_uint32()
            string_offsets.append(offset)
        
        # 读取字符串内容
        for offset in string_offsets:
            self.position = offset
            # MUTF-8编码，第一个字节是长度（uleb128）
            length, _ = self._read_uleb128()
            # 读取字符串内容（以\0结尾）
            string_data = b''
            while True:
                byte = self._read_bytes(1)
                if byte == b'\x00':
                    break
                string_data += byte
            
            try:
                self.strings.append(string_data.decode('utf-8'))
            except:
                self.strings.append(string_data.decode('utf-8', errors='replace'))
        
        print(f"字符串池解析完成: {len(self.strings)} 个字符串")
    
    def _parse_types(self):
        """解析类型池"""
        self.position = self.header.type_ids_off
        
        for _ in range(self.header.type_ids_size):
            descriptor_idx = self._read_uint32()
            self.types.append(descriptor_idx)
        
        print(f"类型池解析完成: {len(self.types)} 个类型")
    
    def _parse_field_ids(self):
        """解析字段ID列表"""
        self.position = self.header.field_ids_off
        
        for _ in range(self.header.field_ids_size):
            class_idx = self._read_uint16()
            type_idx = self._read_uint16()
            name_idx = self._read_uint32()
            self.field_ids.append((class_idx, type_idx, name_idx))
        
        print(f"字段ID解析完成: {len(self.field_ids)} 个字段")
    
    def _parse_method_ids(self):
        """解析方法ID列表"""
        self.position = self.header.method_ids_off
        
        for _ in range(self.header.method_ids_size):
            class_idx = self._read_uint16()
            proto_idx = self._read_uint16()
            name_idx = self._read_uint32()
            self.method_ids.append((class_idx, proto_idx, name_idx))
        
        print(f"方法ID解析完成: {len(self.method_ids)} 个方法")
    
    def _parse_class_defs(self):
        """解析类定义"""
        self.position = self.header.class_defs_off
        
        for _ in range(self.header.class_defs_size):
            class_idx = self._read_uint32()
            access_flags = self._read_uint32()
            superclass_idx = self._read_uint32()
            interfaces_off = self._read_uint32()
            source_file_idx = self._read_uint32()
            annotations_off = self._read_uint32()
            class_data_off = self._read_uint32()
            static_values_off = self._read_uint32()
            
            class_def = ClassDef(
                class_idx=class_idx,
                access_flags=access_flags,
                superclass_idx=superclass_idx,
                interfaces_off=interfaces_off,
                source_file_idx=source_file_idx,
                annotations_off=annotations_off,
                class_data_off=class_data_off,
                static_values_off=static_values_off
            )
            self.class_defs.append(class_def)
        
        print(f"类定义解析完成: {len(self.class_defs)} 个类")
    
    def _parse_class_data(self):
        """解析类的字段和方法数据"""
        for class_def in self.class_defs:
            if class_def.class_data_off == 0:
                continue
            
            self.position = class_def.class_data_off
            
            # 读取头信息（uleb128）
            static_fields_size, _ = self._read_uleb128()
            instance_fields_size, _ = self._read_uleb128()
            direct_methods_size, _ = self._read_uleb128()
            virtual_methods_size, _ = self._read_uleb128()
            
            # 解析静态字段
            field_idx = 0
            for _ in range(static_fields_size):
                field_idx_diff, _ = self._read_uleb128()
                access_flags, _ = self._read_uleb128()
                field_idx += field_idx_diff
                
                if field_idx < len(self.field_ids):
                    class_idx, type_idx, name_idx = self.field_ids[field_idx]
                    field = FieldDef(
                        class_idx=class_idx,
                        type_idx=type_idx,
                        name_idx=name_idx,
                        access_flags=access_flags
                    )
                    class_def.fields.append(field)
            
            # 解析实例字段
            field_idx = 0
            for _ in range(instance_fields_size):
                field_idx_diff, _ = self._read_uleb128()
                access_flags, _ = self._read_uleb128()
                field_idx += field_idx_diff
                
                if field_idx < len(self.field_ids):
                    class_idx, type_idx, name_idx = self.field_ids[field_idx]
                    field = FieldDef(
                        class_idx=class_idx,
                        type_idx=type_idx,
                        name_idx=name_idx,
                        access_flags=access_flags
                    )
                    class_def.fields.append(field)
            
            # 解析直接方法
            method_idx = 0
            for _ in range(direct_methods_size):
                method_idx_diff, _ = self._read_uleb128()
                access_flags, _ = self._read_uleb128()
                code_off, _ = self._read_uleb128()
                method_idx += method_idx_diff
                
                if method_idx < len(self.method_ids):
                    class_idx, proto_idx, name_idx = self.method_ids[method_idx]
                    method = MethodDef(
                        class_idx=class_idx,
                        proto_idx=proto_idx,
                        name_idx=name_idx,
                        access_flags=access_flags,
                        code_off=code_off
                    )
                    class_def.methods.append(method)
            
            # 解析虚方法
            method_idx = 0
            for _ in range(virtual_methods_size):
                method_idx_diff, _ = self._read_uleb128()
                access_flags, _ = self._read_uleb128()
                code_off, _ = self._read_uleb128()
                method_idx += method_idx_diff
                
                if method_idx < len(self.method_ids):
                    class_idx, proto_idx, name_idx = self.method_ids[method_idx]
                    method = MethodDef(
                        class_idx=class_idx,
                        proto_idx=proto_idx,
                        name_idx=name_idx,
                        access_flags=access_flags,
                        code_off=code_off
                    )
                    class_def.methods.append(method)
        
        print(f"类数据解析完成")
    
    def _read_bytes(self, size: int) -> bytes:
        """读取指定字节数"""
        result = self.data[self.position:self.position + size]
        self.position += size
        return result
    
    def _read_uint8(self) -> int:
        """读取1字节无符号整数"""
        return struct.unpack('<B', self._read_bytes(1))[0]
    
    def _read_uint16(self) -> int:
        """读取2字节无符号整数（小端）"""
        return struct.unpack('<H', self._read_bytes(2))[0]
    
    def _read_uint32(self) -> int:
        """读取4字节无符号整数（小端）"""
        return struct.unpack('<I', self._read_bytes(4))[0]
    
    def _read_uleb128(self) -> Tuple[int, int]:
        """读取uleb128编码的整数，返回（值，字节数）"""
        result = 0
        shift = 0
        count = 0
        
        while True:
            byte = self._read_uint8()
            count += 1
            result |= (byte & 0x7f) << shift
            if (byte & 0x80) == 0:
                break
            shift += 7
        
        return result, count
    
    def get_string(self, idx: int) -> str:
        """获取字符串"""
        if 0 <= idx < len(self.strings):
            return self.strings[idx]
        return f"<invalid_string_{idx}>"
    
    def get_type(self, idx: int) -> str:
        """获取类型描述符"""
        if 0 <= idx < len(self.types):
            return self.get_string(self.types[idx])
        return f"<invalid_type_{idx}>"
    
    def print_summary(self):
        """打印解析摘要"""
        print("\n=== DEX文件解析摘要 ===")
        print(f"文件大小: {self.header.file_size} bytes")
        print(f"字符串数量: {len(self.strings)}")
        print(f"类型数量: {len(self.types)}")
        print(f"字段数量: {len(self.field_ids)}")
        print(f"方法数量: {len(self.method_ids)}")
        print(f"类定义数量: {len(self.class_defs)}")
        
        print("\n=== 类列表 ===")
        for i, class_def in enumerate(self.class_defs):
            class_name = self.get_type(class_def.class_idx)
            superclass_name = self.get_type(class_def.superclass_idx) if class_def.superclass_idx != 0xffffffff else "java/lang/Object"
            print(f"\n类 {i+1}: {class_name}")
            print(f"  父类: {superclass_name}")
            print(f"  访问权限: {hex(class_def.access_flags)}")
            print(f"  字段数: {len(class_def.fields)}")
            print(f"  方法数: {len(class_def.methods)}")
            
            if class_def.fields:
                print("  字段:")
                for field in class_def.fields:
                    field_name = self.get_string(field.name_idx)
                    field_type = self.get_type(field.type_idx)
                    print(f"    {field_type} {field_name}")
            
            if class_def.methods:
                print("  方法:")
                for method in class_def.methods:
                    method_name = self.get_string(method.name_idx)
                    print(f"    {method_name}()")


def main():
    """主函数 - 测试DEX解析器"""
    import sys
    
    if len(sys.argv) < 2:
        print("用法: python dex_parser.py <dex文件路径>")
        print("示例: python dex_parser.py TestCase.dex")
        sys.exit(1)
    
    dex_path = sys.argv[1]
    
    try:
        with open(dex_path, 'rb') as f:
            data = f.read()
        
        print(f"读取DEX文件: {dex_path} ({len(data)} bytes)")
        print()
        
        parser = DexParser(data)
        if parser.parse():
            parser.print_summary()
        else:
            print("解析失败")
            sys.exit(1)
    
    except FileNotFoundError:
        print(f"错误: 找不到文件 {dex_path}")
        sys.exit(1)
    except Exception as e:
        print(f"错误: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()