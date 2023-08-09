#ifndef __COMMON_H__
#define __COMMON_H__

#include <stdint.h>
#include <inttypes.h>
#include <stdbool.h>
#include <string.h>
#include <macro.h>
#include <assert.h>
#include <stdlib.h>
#include <debug.h>

#define CONFIG_MSIZE 0x8000000
#define CONFIG_MBASE 0x80000000
#define CONFIG_PC_RESET_OFFSET 0x0

#if CONFIG_MBASE + CONFIG_MSIZE > 0x100000000ul
#define PMEM64 1
#endif

typedef uint32_t word_t;
typedef int32_t sword_t;
#define FMT_WORD "0x%08" PRIx32

typedef word_t vaddr_t;
typedef MUXDEF(PMEM64, uint64_t, uint32_t) paddr_t;
#define FMT_PADDR MUXDEF(PMEM64, "0x%016" PRIx64, "0x%08" PRIx32)
typedef uint16_t ioaddr_t;

typedef struct
{
  word_t gpr[32];
  vaddr_t pc;
} CPU_state;

#define CONFIG_DEVICE 1
#define CONFIG_HAS_TIMER 1
#define CONFIG_TIMER_GETTIMEOFDAY 1
#define CONFIG_HAS_SERIAL 1
// #define CONFIG_HAS_KEYBOARD 1
// #define CONFIG_HAS_VGA 1
// #define CONFIG_HAS_DISK 1
// #define CONFIG_HAS_AUDIO 1

#define DEVICE_BASE 0xa0000000
#define MMIO_BASE 0xa0000000

#define CONFIG_RTC_MMIO (DEVICE_BASE + 0x0002000)
#define CONFIG_SERIAL_MMIO (DEVICE_BASE + 0x0000000)
#define CONFIG_I8042_DATA_MMIO (DEVICE_BASE + 0x0001000)
#define CONFIG_FB_ADDR (MMIO_BASE + 0x1000000)
#define CONFIG_VGA_CTL_MMIO (DEVICE_BASE + 0x0003000)
#define CONFIG_VGA_SHOW_SCREEN 1
#define CONFIG_VGA_SIZE_400x300 1
#define CONFIG_SDCARD_CTL_MMIO 0xa3000000
#define CONFIG_SDCARD_IMG_PATH "The path of sdcard image"
#define CONFIG_AUDIO_CTL_MMIO (DEVICE_BASE + 0x0004000)
#define CONFIG_SB_ADDR (MMIO_BASE + 0x1200000)
#define CONFIG_SB_SIZE 0x10000
#endif
