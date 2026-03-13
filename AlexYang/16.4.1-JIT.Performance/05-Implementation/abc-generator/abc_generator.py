#!/usr/bin/env python3
"""
ABC Generator - 真实Panda格式
生成符合OpenHarmony ArkCompiler规范的ABC (Ark Bytecode) 文件

文件格式参考: arkcompiler_runtime_core/docs/file_format.md
Magic: "PANDA\\0\\0\\0"
架构: 寄存器+累加器混合模式
"""

import struct
import hashlib
import zlib
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, field


# ============================================
# Panda ABC Constants
# ============================================
PANDA_MAGIC = b"PANDA\x00\x00\x00"
PANDA_VERSION = bytes([0, 0, 0, 1])  # version 0.0.0.1
HEADER_SIZE = 60  # 15 fields × 4 bytes (after magic+checksum+isa_checksum+version = 20 bytes prefix)

# TaggedValue tags for Class
TAG_NOTHING = 0x00
TAG_INTERFACES = 0x01
TAG_SOURCE_LANG = 0x02
TAG_RUNTIME_ANNOTATION = 0x03
TAG_ANNOTATION = 0x04
TAG_SOURCE_FILE = 0x05

# TaggedValue tags for Method
TAG_CODE = 0x01
TAG_METHOD_SOURCE_LANG = 0x02
TAG_METHOD_RUNTIME_ANNOTATION = 0x03
TAG_METHOD_DEBUG_INFO = 0x04

# TaggedValue tags for Field
TAG_INT_VALUE = 0x01
TAG_FIELD_VALUE = 0x02
TAG_FIELD_RUNTIME_ANNOTATION = 0x03

# Access flags
ACC_PUBLIC = 0x0001
ACC_PRIVATE = 0x0002
ACC_PROTECTED = 0x0004
ACC_STATIC = 0x0008
ACC_FINAL = 0x0010
ACC_SUPER = 0x0020
ACC_INTERFACE = 0x0200
ACC_ABSTRACT = 0x0400
ACC_SYNTHETIC = 0x1000
ACC_ANNOTATION = 0x2000
ACC_ENUM = 0x4000


@dataclass
class PandaString:
    """Panda MUTF-8 String"""
    content: str

    def encode(self) -> bytes:
        """Encode as Panda string: uleb128(utf16_length) + mutf8_data + \\0"""
        utf8_bytes = self.content.encode('utf-8')
        utf16_len = len(self.content)  # simplified: assume BMP
        return encode_uleb128(utf16_len) + utf8_bytes + b'\x00'


@dataclass
class PandaField:
    """Panda Field definition"""
    name: str
    type_descriptor: str  # e.g. "I", "Ljava/lang/String;"
    access_flags: int
    class_idx: int = 0
    type_idx: int = 0


@dataclass
class PandaMethod:
    """Panda Method definition"""
    name: str
    access_flags: int
    params: List[str] = field(default_factory=list)
    return_type: str = "V"
    bytecode: bytes = b''
    num_vregs: int = 4
    num_args: int = 1
    class_idx: int = 0
    proto_idx: int = 0


@dataclass
class PandaClass:
    """Panda Class definition"""
    name: str  # TypeDescriptor: "LClassName;"
    super_class: str = "Ljava/lang/Object;"
    access_flags: int = ACC_PUBLIC | ACC_SUPER
    fields: List[PandaField] = field(default_factory=list)
    methods: List[PandaMethod] = field(default_factory=list)


def encode_uleb128(value: int) -> bytes:
    """Encode unsigned integer as ULEB128"""
    result = bytearray()
    while True:
        byte = value & 0x7f
        value >>= 7
        if value != 0:
            byte |= 0x80
        result.append(byte)
        if value == 0:
            break
    return bytes(result)


def align4(offset: int) -> int:
    """Align to 4-byte boundary"""
    return (offset + 3) & ~3


class AbcGenerator:
    """生成真实Panda ABC格式文件"""

    def __init__(self):
        self.strings: List[PandaString] = []
        self.string_map: Dict[str, int] = {}
        self.classes: List[PandaClass] = []
        self._current_class: Optional[PandaClass] = None

    def set_class(self, name: str, super_class: str = 'Object'):
        """设置当前类"""
        # Convert to TypeDescriptor format if needed
        if not name.startswith('L'):
            name = f'L{name};'
        if not super_class.startswith('L') and super_class != 'Object':
            super_class = f'L{super_class};'
        elif super_class == 'Object':
            super_class = 'Ljava/lang/Object;'

        cls = PandaClass(name=name, super_class=super_class)
        self.classes.append(cls)
        self._current_class = cls

        # Register strings
        self.add_string(name)
        self.add_string(super_class)

    def add_string(self, s: str) -> int:
        """Add string to pool, return index"""
        if s in self.string_map:
            return self.string_map[s]
        idx = len(self.strings)
        self.strings.append(PandaString(s))
        self.string_map[s] = idx
        return idx

    def add_field(self, name: str, type_name: str, access_flags: int = 0):
        """Add field to current class"""
        self.add_string(name)
        self.add_string(type_name)
        f = PandaField(name=name, type_descriptor=type_name, access_flags=access_flags)
        self._current_class.fields.append(f)

    def add_method(self, name: str, access_flags: int = 0,
                   params: Optional[List[str]] = None, return_type: str = 'V',
                   bytecode: bytes = b''):
        """Add method to current class"""
        if params is None:
            params = []
        self.add_string(name)
        self.add_string(return_type)
        for p in params:
            self.add_string(p)

        m = PandaMethod(
            name=name, access_flags=access_flags,
            params=params, return_type=return_type,
            bytecode=bytecode,
            num_args=len(params) + 1,  # +1 for this
        )
        self._current_class.methods.append(m)

    def generate(self) -> bytes:
        """生成完整的Panda ABC文件"""
        # Strategy: build all sections, then assemble with correct offsets

        # 1. Build string data
        string_data_list = []
        for s in self.strings:
            string_data_list.append(s.encode())

        # 2. Calculate layout
        # Header: 60 bytes (magic=8, checksum=4, isa_checksum=4, version=4, + 10 fields × 4)
        header_size = 60

        # ClassIndex: right after header
        class_idx_off = align4(header_size)
        num_classes = len(self.classes)
        class_index_size = num_classes * 4  # array of uint32_t offsets

        # String data: after class index
        string_data_off = align4(class_idx_off + class_index_size)
        string_offsets = []
        pos = string_data_off
        for sd in string_data_list:
            string_offsets.append(pos)
            pos += len(sd)

        # Class data: after string data
        class_data_off = align4(pos)

        # Build each class's binary representation
        class_binaries = []
        class_offsets = []
        current_off = class_data_off

        for cls in self.classes:
            current_off = align4(current_off)
            class_offsets.append(current_off)
            cls_bin = self._build_class(cls, string_offsets)
            class_binaries.append(cls_bin)
            current_off += len(cls_bin)

        file_size = align4(current_off)

        # 3. Assemble file
        abc = bytearray(file_size)

        # Header
        abc[0:8] = PANDA_MAGIC
        # checksum placeholder (offset 8, 4 bytes) - fill later
        struct.pack_into("<I", abc, 12, 0)  # isa_checksum
        abc[16:20] = PANDA_VERSION
        struct.pack_into("<I", abc, 20, file_size)
        struct.pack_into("<I", abc, 24, 0)  # foreign_off
        struct.pack_into("<I", abc, 28, 0)  # foreign_size
        struct.pack_into("<I", abc, 32, num_classes)
        struct.pack_into("<I", abc, 36, class_idx_off)
        struct.pack_into("<I", abc, 40, 0)  # num_lnps
        struct.pack_into("<I", abc, 44, 0)  # lnp_idx_off
        struct.pack_into("<I", abc, 48, 0)  # num_literalarrays
        struct.pack_into("<I", abc, 52, 0)  # literalarray_idx_off
        struct.pack_into("<I", abc, 56, 0)  # num_index_regions (simplified: 0)

        # ClassIndex
        for i, off in enumerate(class_offsets):
            struct.pack_into("<I", abc, class_idx_off + i * 4, off)

        # String data
        for i, sd in enumerate(string_data_list):
            off = string_offsets[i]
            abc[off:off + len(sd)] = sd

        # Class data
        for i, cls_bin in enumerate(class_binaries):
            off = class_offsets[i]
            abc[off:off + len(cls_bin)] = cls_bin

        # Calculate checksum (Adler32 of everything after magic+checksum, i.e. from offset 12)
        checksum = zlib.adler32(bytes(abc[12:])) & 0xffffffff
        struct.pack_into("<I", abc, 8, checksum)

        return bytes(abc)

    def _build_class(self, cls: PandaClass, string_offsets: List[int]) -> bytes:
        """Build binary representation of a class"""
        buf = bytearray()

        # Class name (String reference - offset to string data)
        name_idx = self.string_map[cls.name]
        name_off = string_offsets[name_idx]

        # Write class name as String (inline reference via offset)
        # In real Panda format, class name is a String at the start
        buf.extend(encode_uleb128(len(cls.name.encode('utf-8'))))
        buf.extend(cls.name.encode('utf-8'))
        buf.append(0x00)  # null terminator

        # super_class_off (uint32) - offset to super class definition or 0
        # For simplicity, encode as string offset
        super_idx = self.string_map.get(cls.super_class, 0)
        super_off = string_offsets[super_idx] if super_idx < len(string_offsets) else 0
        buf.extend(struct.pack("<I", super_off))

        # access_flags (uleb128)
        buf.extend(encode_uleb128(cls.access_flags))

        # num_fields (uleb128)
        buf.extend(encode_uleb128(len(cls.fields)))

        # num_methods (uleb128)
        buf.extend(encode_uleb128(len(cls.methods)))

        # class_data tagged values: end with TAG_NOTHING
        buf.append(TAG_NOTHING)

        # Fields
        for f in cls.fields:
            buf.extend(self._build_field(f, string_offsets))

        # Methods
        for m in cls.methods:
            buf.extend(self._build_method(m, string_offsets))

        return bytes(buf)

    def _build_field(self, f: PandaField, string_offsets: List[int]) -> bytes:
        """Build binary representation of a field"""
        buf = bytearray()

        # class_idx (uint16) - simplified: 0
        buf.extend(struct.pack("<H", f.class_idx))

        # type_idx (uint16) - simplified: index
        type_idx = self.string_map.get(f.type_descriptor, 0)
        buf.extend(struct.pack("<H", type_idx))

        # name_off (uint32) - offset to field name string
        name_idx = self.string_map.get(f.name, 0)
        buf.extend(struct.pack("<I", string_offsets[name_idx] if name_idx < len(string_offsets) else 0))

        # access_flags (uleb128)
        buf.extend(encode_uleb128(f.access_flags))

        # field_data tagged values: end with TAG_NOTHING
        buf.append(TAG_NOTHING)

        return bytes(buf)

    def _build_method(self, m: PandaMethod, string_offsets: List[int]) -> bytes:
        """Build binary representation of a method"""
        buf = bytearray()

        # class_idx (uint16)
        buf.extend(struct.pack("<H", m.class_idx))

        # proto_idx (uint16)
        buf.extend(struct.pack("<H", m.proto_idx))

        # name_off (uint32)
        name_idx = self.string_map.get(m.name, 0)
        buf.extend(struct.pack("<I", string_offsets[name_idx] if name_idx < len(string_offsets) else 0))

        # access_flags (uleb128)
        buf.extend(encode_uleb128(m.access_flags))

        # method_data tagged values
        if m.bytecode:
            # TAG_CODE followed by code item
            buf.append(TAG_CODE)
            buf.extend(self._build_code_item(m))

        # End tag
        buf.append(TAG_NOTHING)

        return bytes(buf)

    def _build_code_item(self, m: PandaMethod) -> bytes:
        """Build Panda CodeItem"""
        buf = bytearray()

        # num_vregs (uleb128)
        buf.extend(encode_uleb128(m.num_vregs))

        # num_args (uleb128)
        buf.extend(encode_uleb128(m.num_args))

        # code_size (uleb128) - size of instructions in bytes
        buf.extend(encode_uleb128(len(m.bytecode)))

        # tries_size (uleb128) - 0 for MVP
        buf.extend(encode_uleb128(0))

        # instructions
        buf.extend(m.bytecode)

        return bytes(buf)


class SimpleAbcBuilder:
    """简化ABC构建器 - 用于快速生成测试ABC"""

    @staticmethod
    def build_simple_pojo(class_name: str = 'SimplePojo') -> bytes:
        gen = AbcGenerator()
        gen.set_class(class_name)
        gen.add_field('value', 'I', ACC_PRIVATE)

        # <init>: return.void
        gen.add_method('<init>', ACC_PUBLIC, [], 'V', bytes([0x92]))

        # getValue: lda v0, return
        gen.add_method('getValue', ACC_PUBLIC, [], 'I', bytes([0x10, 0x00, 0x8f]))

        # setValue: sta v0, return.void
        gen.add_method('setValue', ACC_PUBLIC, ['I'], 'V', bytes([0x1c, 0x00, 0x92]))

        return gen.generate()

    @staticmethod
    def build_simple_logic(class_name: str = 'SimpleLogic') -> bytes:
        gen = AbcGenerator()
        gen.set_class(class_name)

        gen.add_method('<init>', ACC_PUBLIC, [], 'V', bytes([0x92]))

        # add: lda v1, add2 v2, return
        gen.add_method('add', ACC_PUBLIC, ['I', 'I'], 'I',
                        bytes([0x10, 0x01, 0x48, 0x02, 0x8f]))

        # max: lda v1, sub2 v2, jgtz +2, lda v2, return, lda v1, return
        gen.add_method('max', ACC_PUBLIC, ['I', 'I'], 'I',
                        bytes([0x10, 0x01, 0x4a, 0x02, 0x33, 0x03, 0x10, 0x02, 0x8f, 0x10, 0x01, 0x8f]))

        return gen.generate()


def main():
    """测试ABC生成器"""
    import os

    print("=== Panda ABC Generator Test ===\n")

    output_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'output')
    os.makedirs(output_dir, exist_ok=True)

    # Test 1: SimplePojo
    abc1 = SimpleAbcBuilder.build_simple_pojo()
    out1 = os.path.join(output_dir, 'SimplePojo.abc')
    with open(out1, 'wb') as f:
        f.write(abc1)
    print(f"  SimplePojo.abc: {len(abc1)} bytes")
    print(f"    Magic: {abc1[:8]}")
    print(f"    Version: {abc1[16:20].hex()}")

    # Test 2: SimpleLogic
    abc2 = SimpleAbcBuilder.build_simple_logic()
    out2 = os.path.join(output_dir, 'SimpleLogic.abc')
    with open(out2, 'wb') as f:
        f.write(abc2)
    print(f"  SimpleLogic.abc: {len(abc2)} bytes")

    print(f"\n  Output: {output_dir}")
    print("=== Done ===")


if __name__ == '__main__':
    main()
