#include <am.h>
#include <nemu.h>

#define AUDIO_FREQ_ADDR      (AUDIO_ADDR + 0x00)
#define AUDIO_CHANNELS_ADDR  (AUDIO_ADDR + 0x04)
#define AUDIO_SAMPLES_ADDR   (AUDIO_ADDR + 0x08)
#define AUDIO_SBUF_SIZE_ADDR (AUDIO_ADDR + 0x0c)
#define AUDIO_INIT_ADDR      (AUDIO_ADDR + 0x10)
#define AUDIO_COUNT_ADDR     (AUDIO_ADDR + 0x14)

void __am_audio_init() {
  outl(AUDIO_INIT_ADDR, 0);
}

void __am_audio_config(AM_AUDIO_CONFIG_T* cfg) {
  cfg->present = true;
  cfg->bufsize = inl(AUDIO_SBUF_SIZE_ADDR);
}

void __am_audio_ctrl(AM_AUDIO_CTRL_T* ctrl) {
  outl(AUDIO_FREQ_ADDR, ctrl->freq);
  outl(AUDIO_CHANNELS_ADDR, ctrl->channels);
  outl(AUDIO_SAMPLES_ADDR, ctrl->samples);
  outl(AUDIO_INIT_ADDR, 1);
}

void __am_audio_status(AM_AUDIO_STATUS_T* stat) {
  stat->count = inl(AUDIO_COUNT_ADDR);
}

void __am_audio_play(AM_AUDIO_PLAY_T* ctl) {
  uintptr_t ptr = (uintptr_t)ctl->buf.start, end = (uintptr_t)ctl->buf.end;
  int block_size = inl(AUDIO_SBUF_SIZE_ADDR);
  for (;ptr < end;) {
    int count = inl(AUDIO_COUNT_ADDR);
    if (count == block_size) continue;
    for (;ptr < end && count < block_size;++ptr, ++count) {
      outb(AUDIO_SBUF_ADDR + count, *((unsigned char*)ptr));
    }
    outl(AUDIO_COUNT_ADDR, count);
  }
}
