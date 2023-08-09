#include <am.h>
#include <nemu.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)

void __am_gpu_init() {
  int i;
  int h = inw(VGACTL_ADDR);
  int w = inw(VGACTL_ADDR + 2);
  for (i = 0; i < w * h; i++) {
    uint32_t color = (i/40000)<1 ? 0xFF0000 : (i/40000)<2 ? 0x00FF00 : 0x0000FF;
    outl(FB_ADDR + i * 4, color);
  }
  outl(SYNC_ADDR, 1);
}

void __am_gpu_config(AM_GPU_CONFIG_T* cfg) {
  uint32_t sreen_wh = inl(VGACTL_ADDR);
  uint32_t w = sreen_wh >> 16;
  uint32_t h = sreen_wh & 0xffff;
  *cfg = (AM_GPU_CONFIG_T){
    .present = true, .has_accel = false,
    .width = w, .height = h,
    .vmemsz = w * h * sizeof(uint32_t)
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T* ctl) {
  int x = ctl->x;
  int y = ctl->y;
  int w = ctl->w;
  int h = ctl->h;
  if (!ctl->sync && (w == 0 || h == 0)) return;
  uint32_t* pixels = ctl->pixels;
  uint32_t screen_w = inl(VGACTL_ADDR) >> 16;
  for (int i = y; i < y + h; i++) {
    for (int j = x; j < x + w; j++) {
      outl(FB_ADDR + (i * screen_w + j) * 4, pixels[w * (i - y) + (j - x)]);
    }
  }
  if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T* status) {
  status->ready = true;
}
