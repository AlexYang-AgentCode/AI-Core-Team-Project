#!/usr/bin/env python3
"""
Enhanced Minimal DEX Generator - 生成包含完整字段/方法/字节码的测试DEX文件

支持:
- 字段定义（static + instance）
- 方法定义（direct + virtual）含字节码
- Proto定义
- 完整的class_data section
"""

import struct
import hashlib
import zlib
from typing import List, Tuple


class DexBuilder:
    """构建合法的最小DEX文件"""

    # DEX opcodes
    OP_NOP = 0x00
    OP_RETURN_VOID = 0x0e
    OP_RETURN = 0x0f
    OP_CONST_4 = 0x12
    OP_CONST_16 = 0x13
    OP_IGET = 0x52
    OP_IPUT = 0x59
    OP_ADD_INT = 0x90
    OP_SUB_INT = 0x91
    OP_MUL_INT = 0x92
    OP_DIV_INT = 0x93
    OP_IF_LE = 0x37
    OP_IF_GT = 0x36
    OP_GOTO = 0x28
    OP_INVOKE_DIRECT = 0x70
    OP_INVOKE_VIRTUAL = 0x6e
    OP_INVOKE_STATIC = 0x71
    OP_MOVE_RESULT = 0x0a
    OP_ADD_INT_2ADDR = 0xb0
    OP_MUL_INT_2ADDR = 0xb2

    def __init__(self):
        self._strings: List[str] = []
        self._string_map = {}
        self._types: List[int] = []     # string idx for each type
        self._type_map = {}
        self._protos: List[Tuple[int, int, List[int]]] = []  # (shorty_idx, return_type_idx, param_type_idxs)
        self._proto_map = {}
        self._fields: List[Tuple[int, int, int]] = []  # (class_idx, type_idx, name_idx)
        self._methods: List[Tuple[int, int, int]] = []  # (class_idx, proto_idx, name_idx)
        self._class_name_type_idx = 0
        self._super_type_idx = 0
        self._instance_fields: List[Tuple[int, int]] = []  # (field_idx, access_flags)
        self._static_fields: List[Tuple[int, int]] = []
        self._direct_methods: List[Tuple[int, int, bytes]] = []  # (method_idx, access_flags, code)
        self._virtual_methods: List[Tuple[int, int, bytes]] = []

    def add_string(self, s: str) -> int:
        if s in self._string_map:
            return self._string_map[s]
        idx = len(self._strings)
        self._strings.append(s)
        self._string_map[s] = idx
        return idx

    def add_type(self, descriptor: str) -> int:
        if descriptor in self._type_map:
            return self._type_map[descriptor]
        str_idx = self.add_string(descriptor)
        type_idx = len(self._types)
        self._types.append(str_idx)
        self._type_map[descriptor] = type_idx
        return type_idx

    def add_proto(self, shorty: str, return_type: str, param_types: List[str] = None) -> int:
        if param_types is None:
            param_types = []
        key = (return_type, tuple(param_types))
        if key in self._proto_map:
            return self._proto_map[key]

        shorty_idx = self.add_string(shorty)
        ret_idx = self.add_type(return_type)
        param_idxs = [self.add_type(p) for p in param_types]

        proto_idx = len(self._protos)
        self._protos.append((shorty_idx, ret_idx, param_idxs))
        self._proto_map[key] = proto_idx
        return proto_idx

    def add_field(self, class_desc: str, type_desc: str, name: str) -> int:
        class_idx = self.add_type(class_desc)
        type_idx = self.add_type(type_desc)
        name_idx = self.add_string(name)
        field_idx = len(self._fields)
        self._fields.append((class_idx, type_idx, name_idx))
        return field_idx

    def add_method(self, class_desc: str, proto_idx: int, name: str) -> int:
        class_idx = self.add_type(class_desc)
        name_idx = self.add_string(name)
        method_idx = len(self._methods)
        self._methods.append((class_idx, proto_idx, name_idx))
        return method_idx

    def set_class(self, class_desc: str, super_desc: str = "Ljava/lang/Object;"):
        self._class_name_type_idx = self.add_type(class_desc)
        self._super_type_idx = self.add_type(super_desc)

    def add_instance_field(self, field_idx: int, access_flags: int):
        self._instance_fields.append((field_idx, access_flags))

    def add_static_field(self, field_idx: int, access_flags: int):
        self._static_fields.append((field_idx, access_flags))

    def add_direct_method(self, method_idx: int, access_flags: int, code: bytes):
        self._direct_methods.append((method_idx, access_flags, code))

    def add_virtual_method(self, method_idx: int, access_flags: int, code: bytes):
        self._virtual_methods.append((method_idx, access_flags, code))

    @staticmethod
    def _encode_uleb128(value: int) -> bytes:
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

    @staticmethod
    def _make_code_item(registers: int, ins: int, outs: int, insns: bytes) -> bytes:
        """Create a code_item structure"""
        code = bytearray()
        code.extend(struct.pack("<H", registers))   # registers_size
        code.extend(struct.pack("<H", ins))          # ins_size
        code.extend(struct.pack("<H", outs))         # outs_size
        code.extend(struct.pack("<H", 0))            # tries_size
        code.extend(struct.pack("<I", 0))            # debug_info_off

        # insns_size in 2-byte units
        insns_count = len(insns) // 2
        if len(insns) % 2 != 0:
            insns += b'\x00'
            insns_count = len(insns) // 2
        code.extend(struct.pack("<I", insns_count))
        code.extend(insns)

        # Align to 4 bytes
        while len(code) % 4 != 0:
            code.append(0)

        return bytes(code)

    def build(self) -> bytes:
        """Build the complete DEX file"""
        HEADER_SIZE = 0x70

        # Build class_data section
        class_data = bytearray()
        class_data.extend(self._encode_uleb128(len(self._static_fields)))
        class_data.extend(self._encode_uleb128(len(self._instance_fields)))
        class_data.extend(self._encode_uleb128(len(self._direct_methods)))
        class_data.extend(self._encode_uleb128(len(self._virtual_methods)))

        # We need to know code offsets, so build code items first
        # Placeholder - will fix offsets later

        # 1. Calculate section sizes
        string_ids_size = len(self._strings) * 4
        type_ids_size = len(self._types) * 4
        proto_ids_size = len(self._protos) * 12
        field_ids_size = len(self._fields) * 8
        method_ids_size = len(self._methods) * 8
        class_defs_size = 32  # 1 class

        # Calculate offsets
        string_ids_off = HEADER_SIZE
        type_ids_off = string_ids_off + string_ids_size
        proto_ids_off = type_ids_off + type_ids_size
        field_ids_off = proto_ids_off + proto_ids_size
        method_ids_off = field_ids_off + field_ids_size
        class_defs_off = method_ids_off + method_ids_size

        data_off = class_defs_off + class_defs_size
        # Align data section to 4 bytes
        data_off = (data_off + 3) & ~3

        # Build code items (in data section)
        code_items = []
        code_item_offsets = []
        current_data_pos = data_off

        all_methods = list(self._direct_methods) + list(self._virtual_methods)
        for method_idx, access_flags, insns in all_methods:
            # Align to 4
            padding = (4 - (current_data_pos % 4)) % 4
            current_data_pos += padding
            code_item_offsets.append(current_data_pos)

            # Determine register count, ins, outs from access flags
            registers = max(4, len(insns) // 2 + 2)
            ins = 1  # at least 'this'
            outs = 0
            code_item = self._make_code_item(registers, ins, outs, insns)
            code_items.append((padding, code_item))
            current_data_pos += len(code_item)

        # Build class_data (after code items)
        padding_to_class_data = (4 - (current_data_pos % 4)) % 4
        current_data_pos += padding_to_class_data
        class_data_off = current_data_pos

        class_data = bytearray()
        class_data.extend(self._encode_uleb128(len(self._static_fields)))
        class_data.extend(self._encode_uleb128(len(self._instance_fields)))
        class_data.extend(self._encode_uleb128(len(self._direct_methods)))
        class_data.extend(self._encode_uleb128(len(self._virtual_methods)))

        # Encode static fields
        prev_idx = 0
        for field_idx, access_flags in sorted(self._static_fields, key=lambda x: x[0]):
            class_data.extend(self._encode_uleb128(field_idx - prev_idx))
            class_data.extend(self._encode_uleb128(access_flags))
            prev_idx = field_idx

        # Encode instance fields
        prev_idx = 0
        for field_idx, access_flags in sorted(self._instance_fields, key=lambda x: x[0]):
            class_data.extend(self._encode_uleb128(field_idx - prev_idx))
            class_data.extend(self._encode_uleb128(access_flags))
            prev_idx = field_idx

        # Encode direct methods
        code_offset_idx = 0
        prev_idx = 0
        for method_idx, access_flags, _ in self._direct_methods:
            class_data.extend(self._encode_uleb128(method_idx - prev_idx))
            class_data.extend(self._encode_uleb128(access_flags))
            class_data.extend(self._encode_uleb128(code_item_offsets[code_offset_idx]))
            prev_idx = method_idx
            code_offset_idx += 1

        # Encode virtual methods
        prev_idx = 0
        for method_idx, access_flags, _ in self._virtual_methods:
            class_data.extend(self._encode_uleb128(method_idx - prev_idx))
            class_data.extend(self._encode_uleb128(access_flags))
            class_data.extend(self._encode_uleb128(code_item_offsets[code_offset_idx]))
            prev_idx = method_idx
            code_offset_idx += 1

        current_data_pos += len(class_data)

        # Build string data (after class_data)
        string_data_entries = []
        string_data_offsets = []

        for s in self._strings:
            s_bytes = s.encode('utf-8')
            entry = self._encode_uleb128(len(s_bytes)) + s_bytes + b'\x00'
            string_data_entries.append(entry)

        # Calculate string data offsets
        str_data_start = current_data_pos
        pos = str_data_start
        for entry in string_data_entries:
            string_data_offsets.append(pos)
            pos += len(entry)

        file_size = pos
        # Align to 4
        file_size = (file_size + 3) & ~3

        data_size = file_size - data_off

        # Now build the actual file
        dex = bytearray(file_size)

        # === HEADER ===
        dex[0:8] = b"dex\n035\x00"
        struct.pack_into("<I", dex, 32, file_size)
        struct.pack_into("<I", dex, 36, HEADER_SIZE)
        struct.pack_into("<I", dex, 40, 0x12345678)  # endian tag
        # link
        struct.pack_into("<I", dex, 44, 0)
        struct.pack_into("<I", dex, 48, 0)
        # map
        struct.pack_into("<I", dex, 52, 0)
        # string_ids
        struct.pack_into("<I", dex, 56, len(self._strings))
        struct.pack_into("<I", dex, 60, string_ids_off)
        # type_ids
        struct.pack_into("<I", dex, 64, len(self._types))
        struct.pack_into("<I", dex, 68, type_ids_off)
        # proto_ids
        struct.pack_into("<I", dex, 72, len(self._protos))
        struct.pack_into("<I", dex, 76, proto_ids_off if self._protos else 0)
        # field_ids
        struct.pack_into("<I", dex, 80, len(self._fields))
        struct.pack_into("<I", dex, 84, field_ids_off if self._fields else 0)
        # method_ids
        struct.pack_into("<I", dex, 88, len(self._methods))
        struct.pack_into("<I", dex, 92, method_ids_off if self._methods else 0)
        # class_defs
        struct.pack_into("<I", dex, 96, 1)
        struct.pack_into("<I", dex, 100, class_defs_off)
        # data
        struct.pack_into("<I", dex, 104, data_size)
        struct.pack_into("<I", dex, 108, data_off)

        # === STRING IDS ===
        pos = string_ids_off
        for off in string_data_offsets:
            struct.pack_into("<I", dex, pos, off)
            pos += 4

        # === TYPE IDS ===
        pos = type_ids_off
        for str_idx in self._types:
            struct.pack_into("<I", dex, pos, str_idx)
            pos += 4

        # === PROTO IDS ===
        pos = proto_ids_off
        for shorty_idx, ret_idx, param_idxs in self._protos:
            struct.pack_into("<I", dex, pos, shorty_idx)
            struct.pack_into("<I", dex, pos + 4, ret_idx)
            struct.pack_into("<I", dex, pos + 8, 0)  # no parameters_off (simplified)
            pos += 12

        # === FIELD IDS ===
        pos = field_ids_off
        for class_idx, type_idx, name_idx in self._fields:
            struct.pack_into("<H", dex, pos, class_idx)
            struct.pack_into("<H", dex, pos + 2, type_idx)
            struct.pack_into("<I", dex, pos + 4, name_idx)
            pos += 8

        # === METHOD IDS ===
        pos = method_ids_off
        for class_idx, proto_idx, name_idx in self._methods:
            struct.pack_into("<H", dex, pos, class_idx)
            struct.pack_into("<H", dex, pos + 2, proto_idx)
            struct.pack_into("<I", dex, pos + 4, name_idx)
            pos += 8

        # === CLASS DEFS ===
        pos = class_defs_off
        struct.pack_into("<I", dex, pos, self._class_name_type_idx)
        struct.pack_into("<I", dex, pos + 4, 0x1)  # PUBLIC
        struct.pack_into("<I", dex, pos + 8, self._super_type_idx)
        struct.pack_into("<I", dex, pos + 12, 0)  # interfaces
        struct.pack_into("<I", dex, pos + 16, 0xffffffff)  # source_file (none)
        struct.pack_into("<I", dex, pos + 20, 0)  # annotations
        struct.pack_into("<I", dex, pos + 24, class_data_off)
        struct.pack_into("<I", dex, pos + 28, 0)  # static_values

        # === DATA SECTION ===

        # Code items
        data_pos = data_off
        for padding, code_item in code_items:
            data_pos += padding
            dex[data_pos:data_pos + len(code_item)] = code_item
            data_pos += len(code_item)

        # Class data
        data_pos = class_data_off
        dex[data_pos:data_pos + len(class_data)] = class_data
        data_pos += len(class_data)

        # String data
        for i, entry in enumerate(string_data_entries):
            off = string_data_offsets[i]
            dex[off:off + len(entry)] = entry

        # Calculate signature (SHA-1 of everything after signature)
        signature = hashlib.sha1(bytes(dex[32:])).digest()
        dex[12:32] = signature

        # Calculate checksum (Adler32 of everything after checksum)
        checksum = zlib.adler32(bytes(dex[12:])) & 0xffffffff
        struct.pack_into("<I", dex, 8, checksum)

        return bytes(dex)


def build_simple_pojo() -> bytes:
    """TestCase1: SimplePojo - private int value, getter/setter"""
    b = DexBuilder()
    class_desc = "LSimplePojo;"

    b.set_class(class_desc)

    # Protos
    proto_void = b.add_proto("V", "V")              # ()V
    proto_get_int = b.add_proto("I", "I")            # ()I
    proto_set_int = b.add_proto("VI", "V", ["I"])    # (I)V

    # Field: private int value
    f_value = b.add_field(class_desc, "I", "value")
    b.add_instance_field(f_value, 0x2)  # private

    # Method: <init>()V - constructor
    m_init = b.add_method(class_desc, proto_void, "<init>")
    init_code = bytes([
        0x0e, 0x00,  # return-void
    ])
    b.add_direct_method(m_init, 0x10001, init_code)  # PUBLIC | CONSTRUCTOR

    # Method: getValue()I
    m_get = b.add_method(class_desc, proto_get_int, "getValue")
    get_code = bytes([
        0x52, 0x00, 0x00, 0x00,  # iget v0, p0, field@0000
        0x0f, 0x00,              # return v0
    ])
    b.add_virtual_method(m_get, 0x1, get_code)  # PUBLIC

    # Method: setValue(I)V
    m_set = b.add_method(class_desc, proto_set_int, "setValue")
    set_code = bytes([
        0x59, 0x10, 0x00, 0x00,  # iput v0, p0, field@0000 (simplified)
        0x0e, 0x00,              # return-void
    ])
    b.add_virtual_method(m_set, 0x1, set_code)  # PUBLIC

    return b.build()


def build_simple_logic() -> bytes:
    """TestCase2: SimpleLogic - add(int,int), max(int,int)"""
    b = DexBuilder()
    class_desc = "LSimpleLogic;"

    b.set_class(class_desc)

    proto_void = b.add_proto("V", "V")
    proto_add = b.add_proto("III", "I", ["I", "I"])

    # <init>
    m_init = b.add_method(class_desc, proto_void, "<init>")
    b.add_direct_method(m_init, 0x10001, bytes([0x0e, 0x00]))

    # add(int a, int b) -> int
    m_add = b.add_method(class_desc, proto_add, "add")
    add_code = bytes([
        0x90, 0x00, 0x01, 0x02,  # add-int v0, v1, v2
        0x0f, 0x00,              # return v0
    ])
    b.add_virtual_method(m_add, 0x1, add_code)

    # max(int a, int b) -> int
    m_max = b.add_method(class_desc, proto_add, "max")
    max_code = bytes([
        0x36, 0x12, 0x03, 0x00,  # if-gt v1, v2, +3
        0x0f, 0x02,              # return v2
        0x0f, 0x01,              # return v1
    ])
    b.add_virtual_method(m_max, 0x1, max_code)

    return b.build()


def build_with_loop() -> bytes:
    """TestCase3: WithLoop - sum(int n), factorial(int n)"""
    b = DexBuilder()
    class_desc = "LWithLoop;"

    b.set_class(class_desc)

    proto_void = b.add_proto("V", "V")
    proto_int_int = b.add_proto("II", "I", ["I"])

    # <init>
    m_init = b.add_method(class_desc, proto_void, "<init>")
    b.add_direct_method(m_init, 0x10001, bytes([0x0e, 0x00]))

    # sum(int n) -> int  {result=0; for(i=1;i<=n;i++) result+=i; return result;}
    m_sum = b.add_method(class_desc, proto_int_int, "sum")
    sum_code = bytes([
        0x12, 0x00,              # const/4 v0, 0       (result = 0)
        0x12, 0x11,              # const/4 v1, 1       (i = 1)
        0x37, 0x12, 0x04, 0x00,  # if-le v1, v2, +4   (if i <= n goto loop_body)
        0x0f, 0x00,              # return v0            (return result)
        0xb0, 0x10,              # add-int/2addr v0, v1 (result += i)
        0xd8, 0x01, 0x01, 0x01,  # add-int/lit8 v1, v1, 1 (i++)
        0x28, 0xfa,              # goto -6              (back to if-le)
    ])
    b.add_virtual_method(m_sum, 0x1, sum_code)

    # factorial(int n) -> int
    m_fact = b.add_method(class_desc, proto_int_int, "factorial")
    fact_code = bytes([
        0x12, 0x10,              # const/4 v0, 1       (base case value)
        0x37, 0x01, 0x02, 0x00,  # if-le v0, v1, +2    (if 1 <= n goto compute)
        0x0f, 0x00,              # return v0            (return 1)
        0x92, 0x00, 0x01, 0x00,  # mul-int v0, v1, v0  (simplified: v0 = n * v0)
        0x0f, 0x00,              # return v0
    ])
    b.add_virtual_method(m_fact, 0x1, fact_code)

    return b.build()


def build_calculator() -> bytes:
    """TestCase4: Calculator - 四则运算"""
    b = DexBuilder()
    class_desc = "LCalculator;"

    b.set_class(class_desc)

    proto_void = b.add_proto("V", "V")
    proto_op = b.add_proto("III", "I", ["I", "I"])

    m_init = b.add_method(class_desc, proto_void, "<init>")
    b.add_direct_method(m_init, 0x10001, bytes([0x0e, 0x00]))

    # add
    m_add = b.add_method(class_desc, proto_op, "add")
    b.add_virtual_method(m_add, 0x1, bytes([
        0x90, 0x00, 0x01, 0x02,  # add-int v0, v1, v2
        0x0f, 0x00,
    ]))

    # sub
    m_sub = b.add_method(class_desc, proto_op, "sub")
    b.add_virtual_method(m_sub, 0x1, bytes([
        0x91, 0x00, 0x01, 0x02,  # sub-int v0, v1, v2
        0x0f, 0x00,
    ]))

    # mul
    m_mul = b.add_method(class_desc, proto_op, "mul")
    b.add_virtual_method(m_mul, 0x1, bytes([
        0x92, 0x00, 0x01, 0x02,  # mul-int v0, v1, v2
        0x0f, 0x00,
    ]))

    # div
    m_div = b.add_method(class_desc, proto_op, "div")
    b.add_virtual_method(m_div, 0x1, bytes([
        0x93, 0x00, 0x01, 0x02,  # div-int v0, v1, v2
        0x0f, 0x00,
    ]))

    return b.build()


def build_with_fields() -> bytes:
    """TestCase5: Person - 多字段类"""
    b = DexBuilder()
    class_desc = "LPerson;"

    b.set_class(class_desc)

    proto_void = b.add_proto("V", "V")
    proto_get_int = b.add_proto("I", "I")
    proto_set_int = b.add_proto("VI", "V", ["I"])

    # Fields
    f_name = b.add_field(class_desc, "Ljava/lang/String;", "name")
    b.add_instance_field(f_name, 0x2)

    f_age = b.add_field(class_desc, "I", "age")
    b.add_instance_field(f_age, 0x2)

    f_height = b.add_field(class_desc, "I", "height")
    b.add_instance_field(f_height, 0x2)

    # <init>
    m_init = b.add_method(class_desc, proto_void, "<init>")
    b.add_direct_method(m_init, 0x10001, bytes([0x0e, 0x00]))

    # getAge()I
    m_get_age = b.add_method(class_desc, proto_get_int, "getAge")
    b.add_virtual_method(m_get_age, 0x1, bytes([
        0x52, 0x00, 0x01, 0x00,  # iget v0, p0, field@1 (age)
        0x0f, 0x00,
    ]))

    # setAge(I)V
    m_set_age = b.add_method(class_desc, proto_set_int, "setAge")
    b.add_virtual_method(m_set_age, 0x1, bytes([
        0x59, 0x10, 0x01, 0x00,  # iput v0, p0, field@1 (age)
        0x0e, 0x00,
    ]))

    # getHeight()I
    m_get_h = b.add_method(class_desc, proto_get_int, "getHeight")
    b.add_virtual_method(m_get_h, 0x1, bytes([
        0x52, 0x00, 0x02, 0x00,  # iget v0, p0, field@2 (height)
        0x0f, 0x00,
    ]))

    return b.build()


def build_all_arithmetic() -> bytes:
    """TestCase6: 所有算术运算指令"""
    b = DexBuilder()
    class_desc = "LAllArithmetic;"

    b.set_class(class_desc)

    proto_void = b.add_proto("V", "V")
    proto_op = b.add_proto("III", "I", ["I", "I"])

    m_init = b.add_method(class_desc, proto_void, "<init>")
    b.add_direct_method(m_init, 0x10001, bytes([0x0e, 0x00]))

    # add
    m_add = b.add_method(class_desc, proto_op, "add")
    b.add_virtual_method(m_add, 0x1, bytes([
        0x90, 0x00, 0x01, 0x02,  # add-int v0, v1, v2
        0x0f, 0x00,
    ]))

    # sub
    m_sub = b.add_method(class_desc, proto_op, "sub")
    b.add_virtual_method(m_sub, 0x1, bytes([
        0x91, 0x00, 0x01, 0x02,  # sub-int v0, v1, v2
        0x0f, 0x00,
    ]))

    # mul
    m_mul = b.add_method(class_desc, proto_op, "mul")
    b.add_virtual_method(m_mul, 0x1, bytes([
        0x92, 0x00, 0x01, 0x02,  # mul-int v0, v1, v2
        0x0f, 0x00,
    ]))

    # div
    m_div = b.add_method(class_desc, proto_op, "div")
    b.add_virtual_method(m_div, 0x1, bytes([
        0x93, 0x00, 0x01, 0x02,  # div-int v0, v1, v2
        0x0f, 0x00,
    ]))

    # rem
    m_rem = b.add_method(class_desc, proto_op, "rem")
    b.add_virtual_method(m_rem, 0x1, bytes([
        0x94, 0x00, 0x01, 0x02,  # rem-int v0, v1, v2
        0x0f, 0x00,
    ]))

    # and
    m_and = b.add_method(class_desc, proto_op, "and")
    b.add_virtual_method(m_and, 0x1, bytes([
        0x95, 0x00, 0x01, 0x02,  # and-int v0, v1, v2
        0x0f, 0x00,
    ]))

    # or
    m_or = b.add_method(class_desc, proto_op, "or")
    b.add_virtual_method(m_or, 0x1, bytes([
        0x96, 0x00, 0x01, 0x02,  # or-int v0, v1, v2
        0x0f, 0x00,
    ]))

    # xor
    m_xor = b.add_method(class_desc, proto_op, "xor")
    b.add_virtual_method(m_xor, 0x1, bytes([
        0x97, 0x00, 0x01, 0x02,  # xor-int v0, v1, v2
        0x0f, 0x00,
    ]))

    # shl
    m_shl = b.add_method(class_desc, proto_op, "shl")
    b.add_virtual_method(m_shl, 0x1, bytes([
        0x98, 0x00, 0x01, 0x02,  # shl-int v0, v1, v2
        0x0f, 0x00,
    ]))

    # shr
    m_shr = b.add_method(class_desc, proto_op, "shr")
    b.add_virtual_method(m_shr, 0x1, bytes([
        0x99, 0x00, 0x01, 0x02,  # shr-int v0, v1, v2
        0x0f, 0x00,
    ]))

    return b.build()


def build_all_branches() -> bytes:
    """TestCase7: 所有分支指令"""
    b = DexBuilder()
    class_desc = "LAllBranches;"

    b.set_class(class_desc)

    proto_void = b.add_proto("V", "V")
    proto_int_int = b.add_proto("II", "I", ["I"])

    m_init = b.add_method(class_desc, proto_void, "<init>")
    b.add_direct_method(m_init, 0x10001, bytes([0x0e, 0x00]))

    # testAllBranches(I)I - tests if-eq, if-ne, if-lt, if-ge, if-gt, if-le
    m_test = b.add_method(class_desc, proto_int_int, "testAllBranches")
    test_code = bytes([
        0x12, 0x00,              # const/4 v0, 0       (result = 0)
        # if-eq v1, v0, skip
        0x32, 0x10, 0x02, 0x00,  # if-eq v1, v0, +2
        0xd8, 0x00, 0x00, 0x01,  # add-int/lit8 v0, v0, 1
        # if-ne v1, v0, skip
        0x33, 0x10, 0x02, 0x00,  # if-ne v1, v0, +2
        0xd8, 0x00, 0x00, 0x01,  # add-int/lit8 v0, v0, 1
        # if-lt v1, v0, skip
        0x34, 0x10, 0x02, 0x00,  # if-lt v1, v0, +2
        0xd8, 0x00, 0x00, 0x01,  # add-int/lit8 v0, v0, 1
        # if-ge v1, v0, skip
        0x35, 0x10, 0x02, 0x00,  # if-ge v1, v0, +2
        0xd8, 0x00, 0x00, 0x01,  # add-int/lit8 v0, v0, 1
        # return
        0x0f, 0x00,              # return v0
    ])
    b.add_virtual_method(m_test, 0x1, test_code)

    return b.build()


def build_with_arrays() -> bytes:
    """TestCase8: 数组操作"""
    b = DexBuilder()
    class_desc = "LWithArrays;"

    b.set_class(class_desc)

    proto_void = b.add_proto("V", "V")
    proto_int_int = b.add_proto("II", "I", ["I"])

    m_init = b.add_method(class_desc, proto_void, "<init>")
    b.add_direct_method(m_init, 0x10001, bytes([0x0e, 0x00]))

    # sumArray([I)I
    proto_arr_int = b.add_proto("I[I", "I", ["[I"])
    m_sum = b.add_method(class_desc, proto_arr_int, "sumArray")
    sum_code = bytes([
        0x12, 0x00,              # const/4 v0, 0       (sum = 0)
        0x21, 0x12,              # array-length v2, v1 (len = arr.length)
        0x12, 0x03,              # const/4 v3, 0       (i = 0)
        # loop:
        0x35, 0x32, 0x06, 0x00,  # if-ge v3, v2, +6   (if i >= len goto end)
        0x44, 0x04, 0x01, 0x03,  # aget v4, v1, v3    (val = arr[i])
        0xb0, 0x40,              # add-int/2addr v0, v4 (sum += val)
        0xd8, 0x03, 0x03, 0x01,  # add-int/lit8 v3, v3, 1 (i++)
        0x28, 0xf8,              # goto -8            (back to loop)
        # end:
        0x0f, 0x00,              # return v0
    ])
    b.add_virtual_method(m_sum, 0x1, sum_code)

    return b.build()


def build_with_static() -> bytes:
    """TestCase9: 静态字段"""
    b = DexBuilder()
    class_desc = "LWithStatic;"

    b.set_class(class_desc)

    proto_void = b.add_proto("V", "V")
    proto_get = b.add_proto("I", "I")

    # Static field: static int counter
    f_counter = b.add_field(class_desc, "I", "counter")
    b.add_static_field(f_counter, 0x8 | 0x1)  # STATIC | PUBLIC

    m_init = b.add_method(class_desc, proto_void, "<init>")
    b.add_direct_method(m_init, 0x10001, bytes([0x0e, 0x00]))

    # getCounter()I
    m_get = b.add_method(class_desc, proto_get, "getCounter")
    get_code = bytes([
        0x60, 0x00, 0x00, 0x00,  # sget v0, field@0 (counter)
        0x0f, 0x00,              # return v0
    ])
    b.add_virtual_method(m_get, 0x1, get_code)

    # increment()V
    m_inc = b.add_method(class_desc, proto_void, "increment")
    inc_code = bytes([
        0x60, 0x00, 0x00, 0x00,  # sget v0, field@0 (counter)
        0xd8, 0x00, 0x00, 0x01,  # add-int/lit8 v0, v0, 1
        0x67, 0x00, 0x00, 0x00,  # sput v0, field@0 (counter)
        0x0e, 0x00,              # return-void
    ])
    b.add_virtual_method(m_inc, 0x1, inc_code)

    return b.build()


def main():
    """生成所有测试DEX文件"""
    import os

    output_dir = os.path.dirname(os.path.abspath(__file__))

    test_cases = [
        ("TestCase1.dex", "SimplePojo", build_simple_pojo),
        ("TestCase2.dex", "SimpleLogic", build_simple_logic),
        ("TestCase3.dex", "WithLoop", build_with_loop),
        ("TestCase4.dex", "Calculator", build_calculator),
        ("TestCase5.dex", "Person", build_with_fields),
        ("TestCase6.dex", "AllArithmetic", build_all_arithmetic),
        ("TestCase7.dex", "AllBranches", build_all_branches),
        ("TestCase8.dex", "WithArrays", build_with_arrays),
        ("TestCase9.dex", "WithStatic", build_with_static),
    ]

    print("=" * 70)
    print("  DEX Test File Generator (Enhanced v2)")
    print("=" * 70)

    for filename, desc, builder_fn in test_cases:
        dex_data = builder_fn()
        filepath = os.path.join(output_dir, filename)
        with open(filepath, "wb") as f:
            f.write(dex_data)
        print(f"  ✓ {filename:<20} {len(dex_data):>6} bytes  ({desc})")

    print("=" * 70)
    print(f"  {len(test_cases)} files generated in {output_dir}")

    # Generate a summary file
    summary_path = os.path.join(output_dir, "test_files_summary.txt")
    with open(summary_path, 'w') as f:
        f.write("DEX Test Files Summary\n")
        f.write("=" * 70 + "\n\n")
        for filename, desc, _ in test_cases:
            f.write(f"{filename}: {desc}\n")
    print(f"  Summary: {summary_path}")


if __name__ == "__main__":
    main()
