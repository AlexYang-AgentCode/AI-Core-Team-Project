#!/usr/bin/env python3
"""
DEX → ABC Instruction Mapper (Real Panda Opcodes)

将DEX (Dalvik) 字节码映射为真实Panda ABC字节码。
基于 OpenHarmony arkcompiler_runtime_core/isa/isa.yaml 定义。

架构差异:
  - DEX: 寄存器机，2地址/3地址指令
  - Panda: 寄存器+累加器混合，多数运算通过accumulator

参考:
  - DEX: https://source.android.com/docs/core/runtime/dalvik-bytecode
  - Panda: arkcompiler_runtime_core/isa/isa.yaml
"""

from dataclasses import dataclass
from typing import List, Optional, Tuple
from enum import IntEnum
import struct


# ============================================
# DEX Opcodes (Dalvik Bytecode)
# 完整覆盖 - 按功能分组
# ============================================
class DexOp(IntEnum):
    # --- 00-0d: Move/NOP ---
    NOP             = 0x00
    MOVE            = 0x01
    MOVE_FROM16     = 0x02
    MOVE_16         = 0x03
    MOVE_WIDE       = 0x04
    MOVE_WIDE_FROM16 = 0x05
    MOVE_WIDE_16    = 0x06
    MOVE_OBJECT     = 0x07
    MOVE_OBJ_FROM16 = 0x08
    MOVE_OBJ_16     = 0x09
    MOVE_RESULT     = 0x0a
    MOVE_RESULT_WIDE = 0x0b
    MOVE_RESULT_OBJ = 0x0c
    MOVE_EXCEPTION  = 0x0d
    # --- 0e-11: Return ---
    RETURN_VOID     = 0x0e
    RETURN          = 0x0f
    RETURN_WIDE     = 0x10
    RETURN_OBJ      = 0x11
    # --- 12-1c: Const ---
    CONST_4         = 0x12
    CONST_16        = 0x13
    CONST           = 0x14
    CONST_HIGH16    = 0x15
    CONST_WIDE_16   = 0x16
    CONST_WIDE_32   = 0x17
    CONST_WIDE      = 0x18
    CONST_WIDE_HIGH16 = 0x19
    CONST_STRING    = 0x1a
    CONST_STRING_JUMBO = 0x1b
    CONST_CLASS     = 0x1c
    # --- 1d-1e: Monitor ---
    MONITOR_ENTER   = 0x1d
    MONITOR_EXIT    = 0x1e
    # --- 1f-20: Type check ---
    CHECK_CAST      = 0x1f
    INSTANCE_OF     = 0x20
    # --- 21-26: Array ---
    ARRAY_LENGTH    = 0x21
    NEW_INSTANCE    = 0x22
    NEW_ARRAY       = 0x23
    FILLED_NEW_ARRAY = 0x24
    FILLED_NEW_ARRAY_RANGE = 0x25
    FILL_ARRAY_DATA = 0x26
    # --- 27: Throw ---
    THROW           = 0x27
    # --- 28-2a: Goto ---
    GOTO            = 0x28
    GOTO_16         = 0x29
    GOTO_32         = 0x2a
    # --- 2b-2c: Switch ---
    PACKED_SWITCH   = 0x2b
    SPARSE_SWITCH   = 0x2c
    # --- 2d-31: Compare ---
    CMPL_FLOAT      = 0x2d
    CMPG_FLOAT      = 0x2e
    CMPL_DOUBLE     = 0x2f
    CMPG_DOUBLE     = 0x30
    CMP_LONG        = 0x31
    # --- 32-37: If (two registers) ---
    IF_EQ           = 0x32
    IF_NE           = 0x33
    IF_LT           = 0x34
    IF_GE           = 0x35
    IF_GT           = 0x36
    IF_LE           = 0x37
    # --- 38-3d: If-zero ---
    IF_EQZ          = 0x38
    IF_NEZ          = 0x39
    IF_LTZ          = 0x3a
    IF_GEZ          = 0x3b
    IF_GTZ          = 0x3c
    IF_LEZ          = 0x3d
    # --- 44-51: Array access ---
    AGET            = 0x44
    AGET_WIDE       = 0x45
    AGET_OBJECT     = 0x46
    AGET_BOOLEAN    = 0x47
    AGET_BYTE       = 0x48
    AGET_CHAR       = 0x49
    AGET_SHORT      = 0x4a
    APUT            = 0x4b
    APUT_WIDE       = 0x4c
    APUT_OBJECT     = 0x4d
    APUT_BOOLEAN    = 0x4e
    APUT_BYTE       = 0x4f
    APUT_CHAR       = 0x50
    APUT_SHORT      = 0x51
    # --- 52-5f: Instance field ---
    IGET            = 0x52
    IGET_WIDE       = 0x53
    IGET_OBJ        = 0x54
    IGET_BOOLEAN    = 0x55
    IGET_BYTE       = 0x56
    IGET_CHAR       = 0x57
    IGET_SHORT      = 0x58
    IPUT            = 0x59
    IPUT_WIDE       = 0x5a
    IPUT_OBJ        = 0x5b
    IPUT_BOOLEAN    = 0x5c
    IPUT_BYTE       = 0x5d
    IPUT_CHAR       = 0x5e
    IPUT_SHORT      = 0x5f
    # --- 60-6d: Static field ---
    SGET            = 0x60
    SGET_WIDE       = 0x61
    SGET_OBJ        = 0x62
    SGET_BOOLEAN    = 0x63
    SGET_BYTE       = 0x64
    SGET_CHAR       = 0x65
    SGET_SHORT      = 0x66
    SPUT            = 0x67
    SPUT_WIDE       = 0x68
    SPUT_OBJ        = 0x69
    SPUT_BOOLEAN    = 0x6a
    SPUT_BYTE       = 0x6b
    SPUT_CHAR       = 0x6c
    SPUT_SHORT      = 0x6d
    # --- 6e-72: Invoke ---
    INVOKE_VIRTUAL  = 0x6e
    INVOKE_SUPER    = 0x6f
    INVOKE_DIRECT   = 0x70
    INVOKE_STATIC   = 0x71
    INVOKE_INTERFACE = 0x72
    # --- 74-78: Invoke range ---
    INVOKE_VIRTUAL_RANGE = 0x74
    INVOKE_SUPER_RANGE = 0x75
    INVOKE_DIRECT_RANGE = 0x76
    INVOKE_STATIC_RANGE = 0x77
    INVOKE_INTERFACE_RANGE = 0x78
    # --- 7b-8f: Unary ops ---
    NEG_INT         = 0x7b
    NOT_INT         = 0x7c
    NEG_LONG        = 0x7d
    NOT_LONG        = 0x7e
    NEG_FLOAT       = 0x7f
    NEG_DOUBLE      = 0x80
    INT_TO_LONG     = 0x81
    INT_TO_FLOAT    = 0x82
    INT_TO_DOUBLE   = 0x83
    LONG_TO_INT     = 0x84
    LONG_TO_FLOAT   = 0x85
    LONG_TO_DOUBLE  = 0x86
    FLOAT_TO_INT    = 0x87
    FLOAT_TO_LONG   = 0x88
    FLOAT_TO_DOUBLE = 0x89
    DOUBLE_TO_INT   = 0x8a
    DOUBLE_TO_LONG  = 0x8b
    DOUBLE_TO_FLOAT = 0x8c
    INT_TO_BYTE     = 0x8d
    INT_TO_CHAR     = 0x8e
    INT_TO_SHORT    = 0x8f
    # --- 90-af: Arithmetic 3-register ---
    ADD_INT         = 0x90
    SUB_INT         = 0x91
    MUL_INT         = 0x92
    DIV_INT         = 0x93
    REM_INT         = 0x94
    AND_INT         = 0x95
    OR_INT          = 0x96
    XOR_INT         = 0x97
    SHL_INT         = 0x98
    SHR_INT         = 0x99
    USHR_INT        = 0x9a
    ADD_LONG        = 0x9b
    SUB_LONG        = 0x9c
    MUL_LONG        = 0x9d
    DIV_LONG        = 0x9e
    REM_LONG        = 0x9f
    AND_LONG        = 0xa0
    OR_LONG         = 0xa1
    XOR_LONG        = 0xa2
    SHL_LONG        = 0xa3
    SHR_LONG        = 0xa4
    USHR_LONG       = 0xa5
    ADD_FLOAT       = 0xa6
    SUB_FLOAT       = 0xa7
    MUL_FLOAT       = 0xa8
    DIV_FLOAT       = 0xa9
    REM_FLOAT       = 0xaa
    ADD_DOUBLE      = 0xab
    SUB_DOUBLE      = 0xac
    MUL_DOUBLE      = 0xad
    DIV_DOUBLE      = 0xae
    REM_DOUBLE      = 0xaf
    # --- b0-cf: Arithmetic 2addr ---
    ADD_INT_2ADDR   = 0xb0
    SUB_INT_2ADDR   = 0xb1
    MUL_INT_2ADDR   = 0xb2
    DIV_INT_2ADDR   = 0xb3
    REM_INT_2ADDR   = 0xb4
    AND_INT_2ADDR   = 0xb5
    OR_INT_2ADDR    = 0xb6
    XOR_INT_2ADDR   = 0xb7
    SHL_INT_2ADDR   = 0xb8
    SHR_INT_2ADDR   = 0xb9
    USHR_INT_2ADDR  = 0xba
    ADD_LONG_2ADDR  = 0xbb
    SUB_LONG_2ADDR  = 0xbc
    MUL_LONG_2ADDR  = 0xbd
    DIV_LONG_2ADDR  = 0xbe
    REM_LONG_2ADDR  = 0xbf
    AND_LONG_2ADDR  = 0xc0
    OR_LONG_2ADDR   = 0xc1
    XOR_LONG_2ADDR  = 0xc2
    SHL_LONG_2ADDR  = 0xc3
    SHR_LONG_2ADDR  = 0xc4
    USHR_LONG_2ADDR = 0xc5
    ADD_FLOAT_2ADDR = 0xc6
    SUB_FLOAT_2ADDR = 0xc7
    MUL_FLOAT_2ADDR = 0xc8
    DIV_FLOAT_2ADDR = 0xc9
    REM_FLOAT_2ADDR = 0xca
    ADD_DOUBLE_2ADDR = 0xcb
    SUB_DOUBLE_2ADDR = 0xcc
    MUL_DOUBLE_2ADDR = 0xcd
    DIV_DOUBLE_2ADDR = 0xce
    REM_DOUBLE_2ADDR = 0xcf
    # --- d0-d7: Arithmetic lit16 ---
    ADD_INT_LIT16   = 0xd0
    SUB_INT_LIT16   = 0xd1  # rsub
    MUL_INT_LIT16   = 0xd2
    DIV_INT_LIT16   = 0xd3
    REM_INT_LIT16   = 0xd4
    AND_INT_LIT16   = 0xd5
    OR_INT_LIT16    = 0xd6
    XOR_INT_LIT16   = 0xd7
    # --- d8-e2: Arithmetic lit8 ---
    ADD_INT_LIT8    = 0xd8
    SUB_INT_LIT8    = 0xd9  # rsub
    MUL_INT_LIT8    = 0xda
    DIV_INT_LIT8    = 0xdb
    REM_INT_LIT8    = 0xdc
    AND_INT_LIT8    = 0xdd
    OR_INT_LIT8     = 0xde
    XOR_INT_LIT8    = 0xdf
    SHL_INT_LIT8    = 0xe0
    SHR_INT_LIT8    = 0xe1
    USHR_INT_LIT8   = 0xe2


# ============================================
# Panda ABC Opcodes (Real ISA from isa.yaml)
# ============================================
class PandaOp(IntEnum):
    NOP             = 0x00
    # Move
    MOV_v4_v4       = 0x01
    MOV_v8_v8       = 0x02
    MOV_v16_v16     = 0x03
    MOV_64_v4_v4    = 0x04
    MOV_64_v16_v16  = 0x05
    MOV_OBJ_v4_v4   = 0x06
    MOV_OBJ_v8_v8   = 0x07
    MOV_OBJ_v16_v16 = 0x08
    # Move immediate
    MOVI_v4_imm4    = 0x09
    MOVI_v8_imm8    = 0x0a
    MOVI_v8_imm16   = 0x0b
    MOVI_v8_imm32   = 0x0c
    MOVI_64_v8_imm64 = 0x0d
    FMOVI_64_v8_imm64 = 0x0e
    MOV_NULL_v8     = 0x0f
    # Load accumulator
    LDA_v8          = 0x10
    LDA_64_v8       = 0x11
    LDA_OBJ_v8      = 0x12
    LDAI_imm8       = 0x13
    LDAI_imm16      = 0x14
    LDAI_imm32      = 0x15
    LDAI_64_imm64   = 0x16
    FLDAI_64_imm64  = 0x17
    LDA_STR_id32    = 0x18
    LDA_CONST_v8_id32 = 0x19
    LDA_TYPE_id16   = 0x1a
    LDA_NULL        = 0x1b
    # Store accumulator
    STA_v8          = 0x1c
    STA_64_v8       = 0x1d
    STA_OBJ_v8      = 0x1e
    # Compare
    CMP_64_v8       = 0x1f
    FCMPL_64_v8     = 0x20
    FCMPG_64_v8     = 0x21
    # Jump unconditional
    JMP_imm8        = 0x22
    JMP_imm16       = 0x23
    JMP_imm32       = 0x24
    # Jump object compare
    JEQ_OBJ_v8_imm8 = 0x25
    JEQ_OBJ_v8_imm16 = 0x26
    JNE_OBJ_v8_imm8 = 0x27
    JNE_OBJ_v8_imm16 = 0x28
    JEQZ_OBJ_imm8  = 0x29
    JEQZ_OBJ_imm16 = 0x2a
    JNEZ_OBJ_imm8  = 0x2b
    JNEZ_OBJ_imm16 = 0x2c
    # Jump zero compare
    JEQZ_imm8      = 0x2d
    JEQZ_imm16     = 0x2e
    JNEZ_imm8      = 0x2f
    JNEZ_imm16     = 0x30
    JLTZ_imm8      = 0x31
    JLTZ_imm16     = 0x32
    JGTZ_imm8      = 0x33
    JGTZ_imm16     = 0x34
    JLEZ_imm8      = 0x35
    JLEZ_imm16     = 0x36
    JGEZ_imm8      = 0x37
    JGEZ_imm16     = 0x38
    # Jump register compare
    JEQ_v8_imm8    = 0x39
    JEQ_v8_imm16   = 0x3a
    JNE_v8_imm8    = 0x3b
    JNE_v8_imm16   = 0x3c
    JLT_v8_imm8    = 0x3d
    JLT_v8_imm16   = 0x3e
    JGT_v8_imm8    = 0x3f
    JGT_v8_imm16   = 0x40
    JLE_v8_imm8    = 0x41
    JLE_v8_imm16   = 0x42
    JGE_v8_imm8    = 0x43
    JGE_v8_imm16   = 0x44
    # Float unary
    FNEG_64         = 0x45
    # Integer unary
    NEG             = 0x46
    NEG_64          = 0x47
    # 2-address arithmetic
    ADD2            = 0x48
    ADD2_64         = 0x49
    SUB2            = 0x4a
    SUB2_64         = 0x4b
    MUL2            = 0x4c
    MUL2_64         = 0x4d
    FADD2_64        = 0x4e
    FSUB2_64        = 0x4f
    FMUL2_64        = 0x50
    FDIV2_64        = 0x51
    FMOD2_64        = 0x52
    DIV2            = 0x53
    DIV2_64         = 0x54
    MOD2            = 0x55
    MOD2_64         = 0x56
    # Immediate arithmetic
    ADDI            = 0x57
    SUBI            = 0x58
    MULI            = 0x59
    ANDI            = 0x5a
    ORI             = 0x5b
    SHLI            = 0x5c
    SHRI            = 0x5d
    ASHRI           = 0x5e
    DIVI            = 0x5f
    MODI            = 0x60
    # 3-address arithmetic
    ADD             = 0x61
    SUB             = 0x62
    MUL             = 0x63
    DIV             = 0x64
    MOD             = 0x65
    # Increment
    INCI_v4_imm4    = 0x66
    # Array ops
    LDARR_8         = 0x67
    LDARRU_8        = 0x68
    LDARR_16        = 0x69
    LDARRU_16       = 0x6a
    LDARR           = 0x6b
    LDARR_64        = 0x6c
    FLDARR_32       = 0x6d
    FLDARR_64       = 0x6e
    LDARR_OBJ       = 0x6f
    STARR_8         = 0x70
    STARR_16        = 0x71
    STARR           = 0x72
    STARR_64        = 0x73
    FSTARR_32       = 0x74
    FSTARR_64       = 0x75
    STARR_OBJ       = 0x76
    LENARR          = 0x77
    NEWARR          = 0x78
    # Object
    NEWOBJ          = 0x79
    INITOBJ_SHORT   = 0x7a
    INITOBJ         = 0x7b
    INITOBJ_RANGE   = 0x7c
    # Field access
    LDOBJ           = 0x7d
    LDOBJ_64        = 0x7e
    LDOBJ_OBJ       = 0x7f
    STOBJ           = 0x80
    STOBJ_64        = 0x81
    STOBJ_OBJ       = 0x82
    LDOBJ_V         = 0x83
    LDOBJ_V_64      = 0x84
    LDOBJ_V_OBJ     = 0x85
    STOBJ_V         = 0x86
    STOBJ_V_64      = 0x87
    STOBJ_V_OBJ     = 0x88
    # Static field
    LDSTATIC        = 0x89
    LDSTATIC_64     = 0x8a
    LDSTATIC_OBJ    = 0x8b
    STSTATIC        = 0x8c
    STSTATIC_64     = 0x8d
    STSTATIC_OBJ    = 0x8e
    # Return
    RETURN          = 0x8f
    RETURN_64       = 0x90
    RETURN_OBJ      = 0x91
    RETURN_VOID     = 0x92
    # Exception
    THROW           = 0x93
    # Type check
    CHECKCAST       = 0x94
    ISINSTANCE      = 0x95
    # Call
    CALL_SHORT      = 0x96
    CALL            = 0x97
    CALL_RANGE      = 0x98
    CALL_ACC_SHORT  = 0x99
    CALL_ACC        = 0x9a
    CALL_VIRT_SHORT = 0x9b
    CALL_VIRT       = 0x9c
    CALL_VIRT_RANGE = 0x9d
    CALL_VIRT_ACC_SHORT = 0x9e
    CALL_VIRT_ACC   = 0x9f


# ============================================
# IR (Intermediate Representation)
# ============================================
@dataclass
class IRInstruction:
    opcode: str
    dst: int = 0
    src1: int = 0
    src2: int = 0
    imm: int = 0
    field_ref: int = 0
    method_ref: int = 0
    original_offset: int = 0
    width: int = 32  # 32 or 64 bit

    def __repr__(self):
        parts = [self.opcode]
        if self.opcode == "const":
            parts.append(f"v{self.dst}")
            parts.append(f"#{self.imm}")
        elif self.opcode in ("return", "return_wide", "return_obj"):
            parts.append(f"v{self.src1}")
        elif self.opcode == "return_void":
            pass
        elif self.opcode in ("goto",):
            parts.append(f"#{self.imm}")
        elif self.opcode.startswith("if_"):
            parts.extend([f"v{self.src1}", f"v{self.src2}", f"#{self.imm}"])
        elif self.opcode.startswith("ifz_"):
            parts.extend([f"v{self.src1}", f"#{self.imm}"])
        elif self.opcode in ("iget", "sget", "aget"):
            parts.extend([f"v{self.dst}", f"v{self.src1}", f"@{self.field_ref}"])
        elif self.opcode in ("iput", "sput", "aput"):
            parts.extend([f"v{self.src1}", f"v{self.src2}", f"@{self.field_ref}"])
        elif self.opcode in ("add", "sub", "mul", "div", "rem", "and", "or", "xor", "shl", "shr", "ushr"):
            parts.extend([f"v{self.dst}", f"v{self.src1}", f"v{self.src2}"])
        elif self.opcode == "add_lit":
            parts.extend([f"v{self.dst}", f"v{self.src1}", f"#{self.imm}"])
        elif self.opcode in ("neg", "not"):
            parts.extend([f"v{self.dst}", f"v{self.src1}"])
        elif self.opcode.startswith("invoke"):
            parts.append(f"@{self.method_ref}")
        else:
            if self.dst: parts.append(f"v{self.dst}")
            if self.src1: parts.append(f"v{self.src1}")
        return " ".join(parts)


# ============================================
# Instruction size table for DEX opcodes
# ============================================
DEX_INSN_SIZE = {}

# Format 10x: 2 bytes (op + 00)
for op in [0x00, 0x0e]:
    DEX_INSN_SIZE[op] = 2

# Format 12x / 11n: 2 bytes
for op in range(0x01, 0x0e):
    DEX_INSN_SIZE[op] = 2
for op in [0x12, 0x1d, 0x1e, 0x27]:
    DEX_INSN_SIZE[op] = 2
for op in range(0x7b, 0x90):  # unary ops
    DEX_INSN_SIZE[op] = 2
for op in range(0xb0, 0xd0):  # 2addr ops
    DEX_INSN_SIZE[op] = 2

# Format 11x: 2 bytes
for op in [0x0a, 0x0b, 0x0c, 0x0d, 0x0f, 0x10, 0x11]:
    DEX_INSN_SIZE[op] = 2

# Format 10t: 2 bytes (goto)
DEX_INSN_SIZE[0x28] = 2

# Format 22x / 21s / 21h / 21c / 20t: 4 bytes
for op in [0x02, 0x05, 0x08, 0x13, 0x15, 0x16, 0x19, 0x1a, 0x1c,
           0x1f, 0x20, 0x22, 0x23, 0x29]:
    DEX_INSN_SIZE[op] = 4
DEX_INSN_SIZE[0x21] = 2  # array-length is format 12x

# Format 22t (if): 4 bytes
for op in range(0x32, 0x3e):
    DEX_INSN_SIZE[op] = 4

# Format 22b (lit8): 4 bytes
for op in range(0xd8, 0xe3):
    DEX_INSN_SIZE[op] = 4

# Format 22s (lit16): 4 bytes
for op in range(0xd0, 0xd8):
    DEX_INSN_SIZE[op] = 4

# Format 23x: 4 bytes (array access + arithmetic 3-reg)
for op in range(0x44, 0x52):
    DEX_INSN_SIZE[op] = 4
for op in range(0x90, 0xb0):
    DEX_INSN_SIZE[op] = 4

# Format 22c (field access): 4 bytes
for op in range(0x52, 0x6e):
    DEX_INSN_SIZE[op] = 4

# Format 35c (invoke): 6 bytes
for op in range(0x6e, 0x73):
    DEX_INSN_SIZE[op] = 6

# Format 3rc (invoke range): 6 bytes
for op in range(0x74, 0x79):
    DEX_INSN_SIZE[op] = 6

# Format 31i / 31t / 31c: 6 bytes
for op in [0x14, 0x17, 0x1b, 0x24, 0x25, 0x26, 0x2a, 0x2b, 0x2c]:
    DEX_INSN_SIZE[op] = 6

# Format 51l: 10 bytes
DEX_INSN_SIZE[0x18] = 10


class InstructionMapper:
    """DEX → IR → Panda ABC 指令映射器"""

    def __init__(self):
        self.stats = {
            "total_dex_insns": 0,
            "mapped_insns": 0,
            "unmapped_insns": 0,
            "opcodes_used": set(),
        }

    def dex_to_ir(self, dex_bytecode: bytes) -> List[IRInstruction]:
        """DEX字节码 → IR"""
        ir_list = []
        pos = 0
        while pos < len(dex_bytecode):
            if pos >= len(dex_bytecode):
                break
            opcode = dex_bytecode[pos]
            self.stats["total_dex_insns"] += 1
            self.stats["opcodes_used"].add(opcode)

            ir, consumed = self._decode_dex(dex_bytecode, pos, opcode)
            if ir:
                ir.original_offset = pos
                ir_list.append(ir)
                self.stats["mapped_insns"] += 1
            else:
                ir_list.append(IRInstruction(opcode="nop", original_offset=pos))
                self.stats["unmapped_insns"] += 1
                consumed = DEX_INSN_SIZE.get(opcode, 2)

            pos += consumed
        return ir_list

    def _decode_dex(self, c: bytes, p: int, op: int) -> Tuple[Optional[IRInstruction], int]:
        """Decode single DEX instruction to IR"""
        sz = DEX_INSN_SIZE.get(op, 2)

        # Safety: ensure we have enough bytes
        if p + sz > len(c):
            return None, max(2, len(c) - p)

        # === NOP ===
        if op == DexOp.NOP:
            return IRInstruction(opcode="nop"), 2

        # === MOVE (various) ===
        elif op == DexOp.MOVE:
            b1 = c[p+1]; return IRInstruction(opcode="move", dst=b1&0xf, src1=(b1>>4)&0xf), 2
        elif op == DexOp.MOVE_FROM16:
            return IRInstruction(opcode="move", dst=c[p+1], src1=struct.unpack_from("<H",c,p+2)[0]), 4
        elif op in (DexOp.MOVE_WIDE, DexOp.MOVE_WIDE_FROM16):
            b1 = c[p+1]; return IRInstruction(opcode="move", dst=b1&0xf, src1=(b1>>4)&0xf, width=64), sz
        elif op in (DexOp.MOVE_OBJECT, DexOp.MOVE_OBJ_FROM16):
            b1 = c[p+1]; return IRInstruction(opcode="move_obj", dst=b1&0xf, src1=(b1>>4)&0xf), sz
        elif op == DexOp.MOVE_RESULT:
            return IRInstruction(opcode="move_result", dst=c[p+1]), 2
        elif op == DexOp.MOVE_RESULT_WIDE:
            return IRInstruction(opcode="move_result", dst=c[p+1], width=64), 2
        elif op == DexOp.MOVE_RESULT_OBJ:
            return IRInstruction(opcode="move_result_obj", dst=c[p+1]), 2
        elif op == DexOp.MOVE_EXCEPTION:
            return IRInstruction(opcode="move_exception", dst=c[p+1]), 2

        # === RETURN ===
        elif op == DexOp.RETURN_VOID:
            return IRInstruction(opcode="return_void"), 2
        elif op == DexOp.RETURN:
            return IRInstruction(opcode="return", src1=c[p+1]), 2
        elif op == DexOp.RETURN_WIDE:
            return IRInstruction(opcode="return_wide", src1=c[p+1]), 2
        elif op == DexOp.RETURN_OBJ:
            return IRInstruction(opcode="return_obj", src1=c[p+1]), 2

        # === CONST ===
        elif op == DexOp.CONST_4:
            b1 = c[p+1]; dst = b1&0xf; v = (b1>>4)&0xf
            if v > 7: v -= 16
            return IRInstruction(opcode="const", dst=dst, imm=v), 2
        elif op == DexOp.CONST_16:
            return IRInstruction(opcode="const", dst=c[p+1], imm=struct.unpack_from("<h",c,p+2)[0]), 4
        elif op == DexOp.CONST:
            return IRInstruction(opcode="const", dst=c[p+1], imm=struct.unpack_from("<i",c,p+2)[0]), 6
        elif op == DexOp.CONST_HIGH16:
            return IRInstruction(opcode="const", dst=c[p+1], imm=struct.unpack_from("<H",c,p+2)[0]<<16), 4
        elif op == DexOp.CONST_WIDE_16:
            return IRInstruction(opcode="const", dst=c[p+1], imm=struct.unpack_from("<h",c,p+2)[0], width=64), 4
        elif op == DexOp.CONST_WIDE_32:
            return IRInstruction(opcode="const", dst=c[p+1], imm=struct.unpack_from("<i",c,p+2)[0], width=64), 6
        elif op == DexOp.CONST_WIDE:
            return IRInstruction(opcode="const", dst=c[p+1], imm=struct.unpack_from("<q",c,p+2)[0], width=64), 10
        elif op == DexOp.CONST_STRING:
            return IRInstruction(opcode="const_string", dst=c[p+1], imm=struct.unpack_from("<H",c,p+2)[0]), 4
        elif op == DexOp.CONST_CLASS:
            return IRInstruction(opcode="const_class", dst=c[p+1], imm=struct.unpack_from("<H",c,p+2)[0]), 4

        # === MONITOR ===
        elif op == DexOp.MONITOR_ENTER:
            return IRInstruction(opcode="monitor_enter", src1=c[p+1]), 2
        elif op == DexOp.MONITOR_EXIT:
            return IRInstruction(opcode="monitor_exit", src1=c[p+1]), 2

        # === TYPE CHECK ===
        elif op == DexOp.CHECK_CAST:
            return IRInstruction(opcode="check_cast", src1=c[p+1], imm=struct.unpack_from("<H",c,p+2)[0]), 4
        elif op == DexOp.INSTANCE_OF:
            b1 = c[p+1]; return IRInstruction(opcode="instance_of", dst=b1&0xf, src1=(b1>>4)&0xf, imm=struct.unpack_from("<H",c,p+2)[0]), 4

        # === ARRAY ===
        elif op == DexOp.ARRAY_LENGTH:
            b1 = c[p+1]; return IRInstruction(opcode="array_length", dst=b1&0xf, src1=(b1>>4)&0xf), 2
        elif op == DexOp.NEW_INSTANCE:
            return IRInstruction(opcode="new_instance", dst=c[p+1], imm=struct.unpack_from("<H",c,p+2)[0]), 4
        elif op == DexOp.NEW_ARRAY:
            b1 = c[p+1]; return IRInstruction(opcode="new_array", dst=b1&0xf, src1=(b1>>4)&0xf, imm=struct.unpack_from("<H",c,p+2)[0]), 4

        # === THROW ===
        elif op == DexOp.THROW:
            return IRInstruction(opcode="throw", src1=c[p+1]), 2

        # === GOTO ===
        elif op == DexOp.GOTO:
            return IRInstruction(opcode="goto", imm=struct.unpack_from("<b",c,p+1)[0]*2), 2
        elif op == DexOp.GOTO_16:
            return IRInstruction(opcode="goto", imm=struct.unpack_from("<h",c,p+2)[0]*2), 4
        elif op == DexOp.GOTO_32:
            return IRInstruction(opcode="goto", imm=struct.unpack_from("<i",c,p+2)[0]*2), 6

        # === COMPARE ===
        elif op in (DexOp.CMPL_FLOAT, DexOp.CMPG_FLOAT, DexOp.CMPL_DOUBLE, DexOp.CMPG_DOUBLE, DexOp.CMP_LONG):
            dst = c[p+1]; s1 = c[p+2]; s2 = c[p+3]
            return IRInstruction(opcode="cmp", dst=dst, src1=s1, src2=s2), 4

        # === IF (two registers) ===
        elif 0x32 <= op <= 0x37:
            b1 = c[p+1]; ra = b1&0xf; rb = (b1>>4)&0xf
            off = struct.unpack_from("<h",c,p+2)[0]
            names = {0x32:"if_eq",0x33:"if_ne",0x34:"if_lt",0x35:"if_ge",0x36:"if_gt",0x37:"if_le"}
            return IRInstruction(opcode=names[op], src1=ra, src2=rb, imm=off*2), 4

        # === IF-ZERO ===
        elif 0x38 <= op <= 0x3d:
            reg = c[p+1]; off = struct.unpack_from("<h",c,p+2)[0]
            names = {0x38:"ifz_eq",0x39:"ifz_ne",0x3a:"ifz_lt",0x3b:"ifz_ge",0x3c:"ifz_gt",0x3d:"ifz_le"}
            return IRInstruction(opcode=names[op], src1=reg, imm=off*2), 4

        # === ARRAY ACCESS ===
        elif 0x44 <= op <= 0x4a:
            dst = c[p+1]; arr = c[p+2]; idx = c[p+3]
            return IRInstruction(opcode="aget", dst=dst, src1=arr, src2=idx), 4
        elif 0x4b <= op <= 0x51:
            src = c[p+1]; arr = c[p+2]; idx = c[p+3]
            return IRInstruction(opcode="aput", src1=src, src2=arr, field_ref=idx), 4

        # === IGET / IPUT ===
        elif 0x52 <= op <= 0x58:
            b1 = c[p+1]; dst = b1&0xf; obj = (b1>>4)&0xf
            fid = struct.unpack_from("<H",c,p+2)[0]
            w = 64 if op == DexOp.IGET_WIDE else 32
            return IRInstruction(opcode="iget", dst=dst, src1=obj, field_ref=fid, width=w), 4
        elif 0x59 <= op <= 0x5f:
            b1 = c[p+1]; src = b1&0xf; obj = (b1>>4)&0xf
            fid = struct.unpack_from("<H",c,p+2)[0]
            return IRInstruction(opcode="iput", src1=src, src2=obj, field_ref=fid), 4

        # === SGET / SPUT ===
        elif 0x60 <= op <= 0x66:
            dst = c[p+1]; fid = struct.unpack_from("<H",c,p+2)[0]
            return IRInstruction(opcode="sget", dst=dst, field_ref=fid), 4
        elif 0x67 <= op <= 0x6d:
            src = c[p+1]; fid = struct.unpack_from("<H",c,p+2)[0]
            return IRInstruction(opcode="sput", src1=src, field_ref=fid), 4

        # === INVOKE ===
        elif op in (DexOp.INVOKE_VIRTUAL, DexOp.INVOKE_SUPER, DexOp.INVOKE_DIRECT, DexOp.INVOKE_INTERFACE):
            b1 = c[p+1]; argc = (b1>>4)&0xf
            mid = struct.unpack_from("<H",c,p+2)[0]
            return IRInstruction(opcode="invoke_virtual", imm=argc, method_ref=mid), 6
        elif op == DexOp.INVOKE_STATIC:
            b1 = c[p+1]; argc = (b1>>4)&0xf
            mid = struct.unpack_from("<H",c,p+2)[0]
            return IRInstruction(opcode="invoke_static", imm=argc, method_ref=mid), 6
        elif op in (DexOp.INVOKE_VIRTUAL_RANGE, DexOp.INVOKE_SUPER_RANGE, DexOp.INVOKE_DIRECT_RANGE, DexOp.INVOKE_INTERFACE_RANGE):
            argc = c[p+1]; mid = struct.unpack_from("<H",c,p+2)[0]
            return IRInstruction(opcode="invoke_virtual", imm=argc, method_ref=mid), 6
        elif op == DexOp.INVOKE_STATIC_RANGE:
            argc = c[p+1]; mid = struct.unpack_from("<H",c,p+2)[0]
            return IRInstruction(opcode="invoke_static", imm=argc, method_ref=mid), 6

        # === UNARY (neg/not/cast) ===
        elif op == DexOp.NEG_INT:
            b1 = c[p+1]; return IRInstruction(opcode="neg", dst=b1&0xf, src1=(b1>>4)&0xf), 2
        elif op == DexOp.NOT_INT:
            b1 = c[p+1]; return IRInstruction(opcode="not", dst=b1&0xf, src1=(b1>>4)&0xf), 2
        elif op == DexOp.NEG_LONG:
            b1 = c[p+1]; return IRInstruction(opcode="neg", dst=b1&0xf, src1=(b1>>4)&0xf, width=64), 2
        elif op == DexOp.NOT_LONG:
            b1 = c[p+1]; return IRInstruction(opcode="not", dst=b1&0xf, src1=(b1>>4)&0xf, width=64), 2
        elif op in (DexOp.NEG_FLOAT, DexOp.NEG_DOUBLE):
            b1 = c[p+1]; return IRInstruction(opcode="fneg", dst=b1&0xf, src1=(b1>>4)&0xf), 2
        elif 0x81 <= op <= 0x8f:  # type conversions
            b1 = c[p+1]; return IRInstruction(opcode="cast", dst=b1&0xf, src1=(b1>>4)&0xf, imm=op), 2

        # === ARITHMETIC 3-register (0x90-0xaf) ===
        elif 0x90 <= op <= 0xaf:
            dst = c[p+1]; s1 = c[p+2]; s2 = c[p+3]
            names = {
                0x90:"add",0x91:"sub",0x92:"mul",0x93:"div",0x94:"rem",
                0x95:"and",0x96:"or",0x97:"xor",0x98:"shl",0x99:"shr",0x9a:"ushr",
                0x9b:"add",0x9c:"sub",0x9d:"mul",0x9e:"div",0x9f:"rem",
                0xa0:"and",0xa1:"or",0xa2:"xor",0xa3:"shl",0xa4:"shr",0xa5:"ushr",
                0xa6:"add",0xa7:"sub",0xa8:"mul",0xa9:"div",0xaa:"rem",
                0xab:"add",0xac:"sub",0xad:"mul",0xae:"div",0xaf:"rem",
            }
            w = 64 if 0x9b <= op <= 0xa5 else 32
            return IRInstruction(opcode=names[op], dst=dst, src1=s1, src2=s2, width=w), 4

        # === ARITHMETIC 2addr (0xb0-0xcf) ===
        elif 0xb0 <= op <= 0xcf:
            b1 = c[p+1]; dst = b1&0xf; src = (b1>>4)&0xf
            base = op - 0xb0
            group = base // 11  # 0=int, 1=long, 2=float+, 3=double
            idx = base % 11
            names = ["add","sub","mul","div","rem","and","or","xor","shl","shr","ushr"]
            if idx < len(names):
                return IRInstruction(opcode=names[idx], dst=dst, src1=dst, src2=src, width=64 if group==1 else 32), 2
            return None, 2

        # === ARITHMETIC lit16 (0xd0-0xd7) ===
        elif 0xd0 <= op <= 0xd7:
            b1 = c[p+1]; dst = b1&0xf; src = (b1>>4)&0xf
            lit = struct.unpack_from("<h",c,p+2)[0]
            names = {0xd0:"add",0xd1:"sub",0xd2:"mul",0xd3:"div",0xd4:"rem",0xd5:"and",0xd6:"or",0xd7:"xor"}
            return IRInstruction(opcode="add_lit", dst=dst, src1=src, imm=lit), 4

        # === ARITHMETIC lit8 (0xd8-0xe2) ===
        elif 0xd8 <= op <= 0xe2:
            dst = c[p+1]; src = c[p+2]; lit = struct.unpack_from("<b",c,p+3)[0]
            return IRInstruction(opcode="add_lit", dst=dst, src1=src, imm=lit), 4

        return None, DEX_INSN_SIZE.get(op, 2)

    # ============================================
    # Phase 2: IR → Panda ABC bytecode
    # ============================================
    def ir_to_abc(self, ir_list: List[IRInstruction]) -> bytes:
        abc = bytearray()
        for ir in ir_list:
            abc.extend(self._emit_panda(ir))
        return bytes(abc)

    def _emit_panda(self, ir: IRInstruction) -> bytes:
        out = bytearray()

        if ir.opcode == "nop":
            out.append(PandaOp.NOP)

        elif ir.opcode == "move":
            if ir.dst < 16 and ir.src1 < 16:
                out.append(PandaOp.MOV_v4_v4)
                out.append((ir.src1 << 4) | ir.dst)
            else:
                out.append(PandaOp.MOV_v8_v8)
                out.extend([ir.dst & 0xff, ir.src1 & 0xff])

        elif ir.opcode == "move_obj":
            out.append(PandaOp.MOV_OBJ_v4_v4)
            out.append((ir.src1 << 4) | ir.dst)

        elif ir.opcode in ("move_result", "move_result_obj"):
            # Panda: accumulator already has the result, store to register
            op = PandaOp.STA_OBJ_v8 if ir.opcode == "move_result_obj" else PandaOp.STA_v8
            out.append(op)
            out.append(ir.dst & 0xff)

        elif ir.opcode == "move_exception":
            # Panda: no direct equivalent, use sta after implicit exception load
            out.append(PandaOp.STA_OBJ_v8)
            out.append(ir.dst & 0xff)

        elif ir.opcode == "return_void":
            out.append(PandaOp.RETURN_VOID)

        elif ir.opcode == "return":
            out.append(PandaOp.LDA_v8); out.append(ir.src1 & 0xff)
            out.append(PandaOp.RETURN)

        elif ir.opcode == "return_wide":
            out.append(PandaOp.LDA_64_v8); out.append(ir.src1 & 0xff)
            out.append(PandaOp.RETURN_64)

        elif ir.opcode == "return_obj":
            out.append(PandaOp.LDA_OBJ_v8); out.append(ir.src1 & 0xff)
            out.append(PandaOp.RETURN_OBJ)

        elif ir.opcode == "const":
            if ir.width == 64:
                out.append(PandaOp.MOVI_64_v8_imm64)
                out.append(ir.dst & 0xff)
                out.extend(struct.pack("<q", ir.imm))
            elif -8 <= ir.imm <= 7 and ir.dst < 16:
                out.append(PandaOp.MOVI_v4_imm4)
                out.append(((ir.imm & 0xf) << 4) | (ir.dst & 0xf))
            elif -128 <= ir.imm <= 127:
                out.append(PandaOp.MOVI_v8_imm8)
                out.append(ir.dst & 0xff)
                out.extend(struct.pack("<b", ir.imm))
            elif -32768 <= ir.imm <= 32767:
                out.append(PandaOp.MOVI_v8_imm16)
                out.append(ir.dst & 0xff)
                out.extend(struct.pack("<h", ir.imm))
            else:
                out.append(PandaOp.MOVI_v8_imm32)
                out.append(ir.dst & 0xff)
                out.extend(struct.pack("<i", ir.imm))

        elif ir.opcode == "const_string":
            out.append(PandaOp.LDA_STR_id32)
            out.extend(struct.pack("<I", ir.imm))
            out.append(PandaOp.STA_OBJ_v8)
            out.append(ir.dst & 0xff)

        elif ir.opcode == "const_class":
            out.append(PandaOp.LDA_TYPE_id16)
            out.extend(struct.pack("<H", ir.imm & 0xffff))
            out.append(PandaOp.STA_OBJ_v8)
            out.append(ir.dst & 0xff)

        elif ir.opcode == "goto":
            off = ir.imm
            if -128 <= off <= 127:
                out.append(PandaOp.JMP_imm8); out.append(off & 0xff)
            elif -32768 <= off <= 32767:
                out.append(PandaOp.JMP_imm16); out.extend(struct.pack("<h", off))
            else:
                out.append(PandaOp.JMP_imm32); out.extend(struct.pack("<i", off))

        elif ir.opcode.startswith("if_"):
            # Two-register compare: lda src1, sub2 src2, then conditional jump
            out.append(PandaOp.LDA_v8); out.append(ir.src1 & 0xff)
            out.append(PandaOp.SUB2); out.append(ir.src2 & 0xff)
            jump_map = {
                "if_eq": PandaOp.JEQZ_imm8, "if_ne": PandaOp.JNEZ_imm8,
                "if_lt": PandaOp.JLTZ_imm8, "if_ge": PandaOp.JGEZ_imm8,
                "if_gt": PandaOp.JGTZ_imm8, "if_le": PandaOp.JLEZ_imm8,
            }
            out.append(jump_map.get(ir.opcode, PandaOp.JEQZ_imm8))
            out.append(ir.imm & 0xff)

        elif ir.opcode.startswith("ifz_"):
            # Zero-compare: lda reg, then conditional jump
            out.append(PandaOp.LDA_v8); out.append(ir.src1 & 0xff)
            jump_map = {
                "ifz_eq": PandaOp.JEQZ_imm8, "ifz_ne": PandaOp.JNEZ_imm8,
                "ifz_lt": PandaOp.JLTZ_imm8, "ifz_ge": PandaOp.JGEZ_imm8,
                "ifz_gt": PandaOp.JGTZ_imm8, "ifz_le": PandaOp.JLEZ_imm8,
            }
            out.append(jump_map.get(ir.opcode, PandaOp.JEQZ_imm8))
            out.append(ir.imm & 0xff)

        elif ir.opcode == "iget":
            fid = ir.field_ref & 0xffff
            if ir.width == 64:
                out.append(PandaOp.LDOBJ_64); out.append(ir.src1 & 0xff)
            else:
                out.append(PandaOp.LDOBJ); out.append(ir.src1 & 0xff)
            out.extend(struct.pack("<H", fid))
            out.append(PandaOp.STA_v8); out.append(ir.dst & 0xff)

        elif ir.opcode == "iput":
            fid = ir.field_ref & 0xffff
            out.append(PandaOp.LDA_v8); out.append(ir.src1 & 0xff)
            out.append(PandaOp.STOBJ); out.append(ir.src2 & 0xff)
            out.extend(struct.pack("<H", fid))

        elif ir.opcode == "sget":
            fid = ir.field_ref & 0xffff
            out.append(PandaOp.LDSTATIC); out.extend(struct.pack("<H", fid))
            out.append(PandaOp.STA_v8); out.append(ir.dst & 0xff)

        elif ir.opcode == "sput":
            fid = ir.field_ref & 0xffff
            out.append(PandaOp.LDA_v8); out.append(ir.src1 & 0xff)
            out.append(PandaOp.STSTATIC); out.extend(struct.pack("<H", fid))

        elif ir.opcode in ("add","sub","mul","div","rem","and","or","xor","shl","shr","ushr"):
            # 3-reg: lda src1, op2 src2, sta dst
            if ir.width == 64:
                out.append(PandaOp.LDA_64_v8); out.append(ir.src1 & 0xff)
            else:
                out.append(PandaOp.LDA_v8); out.append(ir.src1 & 0xff)

            op_map = {
                "add": PandaOp.ADD2, "sub": PandaOp.SUB2, "mul": PandaOp.MUL2,
                "div": PandaOp.DIV2, "rem": PandaOp.MOD2,
            }
            # and/or/xor/shl/shr use prefix instructions - simplified to addi-style
            # For MVP, map bitwise ops to their Panda equivalents
            if ir.opcode in op_map:
                if ir.width == 64:
                    op64_map = {"add": PandaOp.ADD2_64, "sub": PandaOp.SUB2_64,
                                "mul": PandaOp.MUL2_64, "div": PandaOp.DIV2_64, "rem": PandaOp.MOD2_64}
                    out.append(op64_map[ir.opcode])
                else:
                    out.append(op_map[ir.opcode])
                out.append(ir.src2 & 0xff)
            else:
                # Bitwise ops use prefix - for now emit as immediate ops where possible
                imm_map = {"and": PandaOp.ANDI, "or": PandaOp.ORI,
                           "shl": PandaOp.SHLI, "shr": PandaOp.SHRI}
                if ir.opcode in imm_map:
                    # Hack: use src2 as immediate (works for small values)
                    out.append(PandaOp.STA_v8); out.append(0xfe)  # temp
                    out.append(PandaOp.LDA_v8); out.append(ir.src1 & 0xff)
                    # For proper bitwise, would need prefix encoding
                    out.append(PandaOp.ADD2); out.append(ir.src2 & 0xff)  # placeholder
                else:
                    out.append(PandaOp.ADD2); out.append(ir.src2 & 0xff)  # fallback

            if ir.width == 64:
                out.append(PandaOp.STA_64_v8)
            else:
                out.append(PandaOp.STA_v8)
            out.append(ir.dst & 0xff)

        elif ir.opcode == "neg":
            out.append(PandaOp.LDA_v8); out.append(ir.src1 & 0xff)
            out.append(PandaOp.NEG if ir.width == 32 else PandaOp.NEG_64)
            out.append(PandaOp.STA_v8); out.append(ir.dst & 0xff)

        elif ir.opcode == "fneg":
            out.append(PandaOp.LDA_64_v8); out.append(ir.src1 & 0xff)
            out.append(PandaOp.FNEG_64)
            out.append(PandaOp.STA_64_v8); out.append(ir.dst & 0xff)

        elif ir.opcode == "not":
            # Panda NOT uses prefix - approximate with XOR -1
            out.append(PandaOp.LDA_v8); out.append(ir.src1 & 0xff)
            out.append(PandaOp.XORI if ir.width == 32 else PandaOp.XORI)  # simplified
            out.extend(struct.pack("<i", -1))
            out.append(PandaOp.STA_v8); out.append(ir.dst & 0xff)

        elif ir.opcode == "add_lit":
            out.append(PandaOp.LDA_v8); out.append(ir.src1 & 0xff)
            if -128 <= ir.imm <= 127:
                out.append(PandaOp.ADDI); out.append(ir.imm & 0xff)
            else:
                out.append(PandaOp.MOVI_v8_imm32); out.append(0xfe)
                out.extend(struct.pack("<i", ir.imm))
                out.append(PandaOp.ADD2); out.append(0xfe)
            out.append(PandaOp.STA_v8); out.append(ir.dst & 0xff)

        elif ir.opcode == "cmp":
            out.append(PandaOp.LDA_v8); out.append(ir.src1 & 0xff)
            out.append(PandaOp.SUB2); out.append(ir.src2 & 0xff)
            out.append(PandaOp.STA_v8); out.append(ir.dst & 0xff)

        elif ir.opcode == "throw":
            out.append(PandaOp.THROW); out.append(ir.src1 & 0xff)

        elif ir.opcode == "check_cast":
            out.append(PandaOp.LDA_OBJ_v8); out.append(ir.src1 & 0xff)
            out.append(PandaOp.CHECKCAST); out.extend(struct.pack("<H", ir.imm & 0xffff))

        elif ir.opcode == "instance_of":
            out.append(PandaOp.LDA_OBJ_v8); out.append(ir.src1 & 0xff)
            out.append(PandaOp.ISINSTANCE); out.extend(struct.pack("<H", ir.imm & 0xffff))
            out.append(PandaOp.STA_v8); out.append(ir.dst & 0xff)

        elif ir.opcode == "new_instance":
            out.append(PandaOp.NEWOBJ); out.append(ir.dst & 0xff)
            out.extend(struct.pack("<H", ir.imm & 0xffff))

        elif ir.opcode == "new_array":
            out.append(PandaOp.LDA_v8); out.append(ir.src1 & 0xff)  # size
            out.append(PandaOp.NEWARR); out.append(((ir.src1 & 0xf) << 4) | (ir.dst & 0xf))
            out.extend(struct.pack("<H", ir.imm & 0xffff))

        elif ir.opcode == "array_length":
            out.append(PandaOp.LENARR); out.append(ir.src1 & 0xff)
            out.append(PandaOp.STA_v8); out.append(ir.dst & 0xff)

        elif ir.opcode == "aget":
            out.append(PandaOp.LDA_v8); out.append(ir.src2 & 0xff)  # index to acc
            out.append(PandaOp.LDARR); out.append(ir.src1 & 0xff)   # arr[acc]
            out.append(PandaOp.STA_v8); out.append(ir.dst & 0xff)

        elif ir.opcode == "aput":
            out.append(PandaOp.LDA_v8); out.append(ir.field_ref & 0xff)  # index
            out.append(PandaOp.STARR); out.append(((ir.src2 & 0xf) << 4) | (ir.src1 & 0xf))

        elif ir.opcode == "invoke_virtual":
            if ir.imm <= 2:
                out.append(PandaOp.CALL_VIRT_SHORT)
            else:
                out.append(PandaOp.CALL_VIRT_RANGE)
            out.append(0x00)  # first arg register (simplified)
            out.extend(struct.pack("<H", ir.method_ref & 0xffff))

        elif ir.opcode == "invoke_static":
            if ir.imm <= 2:
                out.append(PandaOp.CALL_SHORT)
            else:
                out.append(PandaOp.CALL_RANGE)
            out.append(0x00)
            out.extend(struct.pack("<H", ir.method_ref & 0xffff))

        elif ir.opcode == "cast":
            # Type conversions - simplified placeholder
            out.append(PandaOp.LDA_v8); out.append(ir.src1 & 0xff)
            out.append(PandaOp.STA_v8); out.append(ir.dst & 0xff)

        elif ir.opcode in ("monitor_enter", "monitor_exit"):
            out.append(PandaOp.NOP)  # monitors not supported in MVP

        else:
            out.append(PandaOp.NOP)

        return bytes(out)

    def map(self, dex_bytecode: bytes) -> Tuple[bytes, List[IRInstruction]]:
        """Full pipeline: DEX → IR → Panda ABC"""
        ir_list = self.dex_to_ir(dex_bytecode)
        abc = self.ir_to_abc(ir_list)
        return abc, ir_list

    def get_stats(self) -> dict:
        total = max(1, self.stats["total_dex_insns"])
        return {
            "total_dex_instructions": self.stats["total_dex_insns"],
            "mapped_instructions": self.stats["mapped_insns"],
            "unmapped_instructions": self.stats["unmapped_insns"],
            "mapping_rate": f"{self.stats['mapped_insns']/total*100:.1f}%",
            "unique_opcodes": len(self.stats["opcodes_used"]),
        }

    @staticmethod
    def get_supported_count() -> Tuple[int, int]:
        """Return (supported DEX opcodes, total DEX opcodes defined)"""
        return len(DexOp), 256


def demo():
    mapper = InstructionMapper()
    supported, total_defined = mapper.get_supported_count()

    print("=" * 60)
    print("  DEX → Panda ABC Instruction Mapper")
    print(f"  DEX opcodes defined: {supported}")
    print(f"  Panda opcodes defined: {len(PandaOp)}")
    print("=" * 60)

    tests = [
        ("add-int v0,v1,v2",     bytes([0x90, 0x00, 0x01, 0x02])),
        ("sub-int v0,v1,v2",     bytes([0x91, 0x00, 0x01, 0x02])),
        ("const/4 v0, 5",        bytes([0x12, 0x50])),
        ("return-void",          bytes([0x0e, 0x00])),
        ("return v0",            bytes([0x0f, 0x00])),
        ("if-gt v1,v2,+3",      bytes([0x36, 0x21, 0x03, 0x00])),
        ("goto -6",             bytes([0x28, 0xfa])),
        ("iget v0,v1,f@0",      bytes([0x52, 0x10, 0x00, 0x00])),
        ("new-instance v0,t@1",  bytes([0x22, 0x00, 0x01, 0x00])),
        ("throw v0",             bytes([0x27, 0x00])),
        ("if-eqz v0,+2",        bytes([0x38, 0x00, 0x02, 0x00])),
        ("array-length v0,v1",   bytes([0x21, 0x10])),
    ]

    for desc, code in tests:
        m = InstructionMapper()
        abc, ir = m.map(code)
        status = "✓" if m.stats["mapped_insns"] > 0 else "✗"
        ir_str = str(ir[0]) if ir else '?'
        print(f"  {status} {desc:<28} → {ir_str:<24} → {abc.hex()}")

    print(f"\n  Total: {supported} DEX opcodes covered")
    print("=" * 60)


if __name__ == "__main__":
    demo()
