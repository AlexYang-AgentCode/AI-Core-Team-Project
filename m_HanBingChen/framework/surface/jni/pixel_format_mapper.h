/*
 * pixel_format_mapper.h
 *
 * Maps Android pixel formats and buffer usage flags to OH equivalents.
 * Used by OHGraphicBufferProducer for buffer allocation.
 */
#ifndef PIXEL_FORMAT_MAPPER_H
#define PIXEL_FORMAT_MAPPER_H

#include <cstdint>

namespace oh_adapter {

/**
 * Android pixel format constants (from android/pixel_format.h and graphics.h).
 */
enum AndroidPixelFormat {
    ANDROID_PIXEL_FORMAT_UNKNOWN        = 0,
    ANDROID_PIXEL_FORMAT_RGBA_8888      = 1,
    ANDROID_PIXEL_FORMAT_RGBX_8888      = 2,
    ANDROID_PIXEL_FORMAT_RGB_888        = 3,
    ANDROID_PIXEL_FORMAT_RGB_565        = 4,
    ANDROID_PIXEL_FORMAT_BGRA_8888      = 5,
    ANDROID_PIXEL_FORMAT_RGBA_1010102   = 43,
    ANDROID_PIXEL_FORMAT_RGBA_FP16      = 22,
};

/**
 * OH pixel format constants (from graphic_surface/interfaces/inner_api/common/).
 */
enum OHPixelFormat {
    OH_PIXEL_FMT_RGBA_8888     = 12,
    OH_PIXEL_FMT_RGBX_8888     = 13,
    OH_PIXEL_FMT_RGB_888       = 14,
    OH_PIXEL_FMT_RGB_565       = 15,
    OH_PIXEL_FMT_BGRA_8888     = 16,
    OH_PIXEL_FMT_RGBA_1010102  = 36,
    OH_PIXEL_FMT_RGBA_FP16     = 35,
};

/**
 * Android buffer usage flags (from gralloc/hardware/gralloc.h).
 */
enum AndroidBufferUsage : uint64_t {
    ANDROID_USAGE_SW_READ_RARELY    = 0x00000002ULL,
    ANDROID_USAGE_SW_READ_OFTEN     = 0x00000003ULL,
    ANDROID_USAGE_SW_WRITE_RARELY   = 0x00000020ULL,
    ANDROID_USAGE_SW_WRITE_OFTEN    = 0x00000030ULL,
    ANDROID_USAGE_HW_TEXTURE        = 0x00000100ULL,
    ANDROID_USAGE_HW_RENDER         = 0x00000200ULL,
    ANDROID_USAGE_HW_COMPOSER       = 0x00000800ULL,
    ANDROID_USAGE_GPU_DATA_BUFFER   = 0x01000000ULL,
};

/**
 * OH buffer usage flags (from graphic_surface surface_type.h).
 */
enum OHBufferUsage : uint64_t {
    OH_USAGE_CPU_READ           = (1ULL << 0),
    OH_USAGE_CPU_WRITE          = (1ULL << 1),
    OH_USAGE_MEM_DMA            = (1ULL << 3),
    OH_USAGE_HW_RENDER          = (1ULL << 8),
    OH_USAGE_HW_TEXTURE         = (1ULL << 9),
    OH_USAGE_HW_COMPOSER        = (1ULL << 12),
};

/**
 * Convert Android pixel format to OH pixel format.
 */
inline int32_t androidToOHPixelFormat(int32_t androidFormat) {
    switch (androidFormat) {
        case ANDROID_PIXEL_FORMAT_RGBA_8888:     return OH_PIXEL_FMT_RGBA_8888;
        case ANDROID_PIXEL_FORMAT_RGBX_8888:     return OH_PIXEL_FMT_RGBX_8888;
        case ANDROID_PIXEL_FORMAT_RGB_888:       return OH_PIXEL_FMT_RGB_888;
        case ANDROID_PIXEL_FORMAT_RGB_565:       return OH_PIXEL_FMT_RGB_565;
        case ANDROID_PIXEL_FORMAT_BGRA_8888:     return OH_PIXEL_FMT_BGRA_8888;
        case ANDROID_PIXEL_FORMAT_RGBA_1010102:  return OH_PIXEL_FMT_RGBA_1010102;
        case ANDROID_PIXEL_FORMAT_RGBA_FP16:     return OH_PIXEL_FMT_RGBA_FP16;
        default:                                 return OH_PIXEL_FMT_RGBA_8888;
    }
}

/**
 * Convert OH pixel format to Android pixel format.
 */
inline int32_t ohToAndroidPixelFormat(int32_t ohFormat) {
    switch (ohFormat) {
        case OH_PIXEL_FMT_RGBA_8888:     return ANDROID_PIXEL_FORMAT_RGBA_8888;
        case OH_PIXEL_FMT_RGBX_8888:     return ANDROID_PIXEL_FORMAT_RGBX_8888;
        case OH_PIXEL_FMT_RGB_888:       return ANDROID_PIXEL_FORMAT_RGB_888;
        case OH_PIXEL_FMT_RGB_565:       return ANDROID_PIXEL_FORMAT_RGB_565;
        case OH_PIXEL_FMT_BGRA_8888:     return ANDROID_PIXEL_FORMAT_BGRA_8888;
        case OH_PIXEL_FMT_RGBA_1010102:  return ANDROID_PIXEL_FORMAT_RGBA_1010102;
        case OH_PIXEL_FMT_RGBA_FP16:     return ANDROID_PIXEL_FORMAT_RGBA_FP16;
        default:                         return ANDROID_PIXEL_FORMAT_RGBA_8888;
    }
}

/**
 * Convert Android buffer usage to OH buffer usage.
 */
inline uint64_t androidToOHUsage(uint64_t androidUsage) {
    uint64_t ohUsage = 0;

    if (androidUsage & ANDROID_USAGE_SW_READ_OFTEN)
        ohUsage |= OH_USAGE_CPU_READ;
    if (androidUsage & ANDROID_USAGE_SW_READ_RARELY)
        ohUsage |= OH_USAGE_CPU_READ;
    if (androidUsage & ANDROID_USAGE_SW_WRITE_OFTEN)
        ohUsage |= OH_USAGE_CPU_WRITE;
    if (androidUsage & ANDROID_USAGE_SW_WRITE_RARELY)
        ohUsage |= OH_USAGE_CPU_WRITE;
    if (androidUsage & ANDROID_USAGE_HW_TEXTURE)
        ohUsage |= OH_USAGE_HW_TEXTURE;
    if (androidUsage & ANDROID_USAGE_HW_RENDER)
        ohUsage |= OH_USAGE_HW_RENDER;
    if (androidUsage & ANDROID_USAGE_HW_COMPOSER)
        ohUsage |= OH_USAGE_HW_COMPOSER;

    // Always enable DMA for GPU-accessible buffers
    if (ohUsage & (OH_USAGE_HW_RENDER | OH_USAGE_HW_TEXTURE | OH_USAGE_HW_COMPOSER))
        ohUsage |= OH_USAGE_MEM_DMA;

    // Default: GPU renderable + DMA
    if (ohUsage == 0)
        ohUsage = OH_USAGE_HW_RENDER | OH_USAGE_HW_TEXTURE | OH_USAGE_MEM_DMA;

    return ohUsage;
}

}  // namespace oh_adapter

#endif  // PIXEL_FORMAT_MAPPER_H
