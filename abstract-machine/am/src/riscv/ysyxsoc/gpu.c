#include <am.h>
#include "ysyxsoc.h"
#include <stdio.h>
#include <string.h>

static uint32_t Width = 640;
static uint32_t Height = 480;

void __am_gpu_init() {
  // int i;

  // uint32_t config = inl(VGACTL_ADDR);
  // Width = (config >> 16) & 0x0000ffff;
  // Height = config & 0x0000ffff;
  // printf("%d %d\n",Width,Height);
  uint32_t *fb = (uint32_t *)(uintptr_t)VGA_FB_ADDR;
  for (int i = 0; i < Width * Height; i ++){
    fb[i] = 0;
  } 
  outl(VGA_SYNC_ADDR, 1);
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  // uint32_t config = inl(VGACTL_ADDR);
  // int w = (config >> 16) & 0x0000ffff;
  // int h = config & 0x0000ffff;

  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, 
    .has_accel = false,
    .width = Width, 
    .height = Height,
    .vmemsz = Width * Height * sizeof(uint32_t)
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  uint32_t x = ctl->x, y = ctl->y;
  uint32_t w = ctl->w, h = ctl->h;
  // uint32_t *pixels = (uint32_t *)ctl->pixels;
  // uint32_t *fb = (uint32_t *)FB_ADDR;
  // memcpy(fb + ((y * Width) + x),pixels,w*h*4);
  if (ctl->sync) {
    outl(VGA_SYNC_ADDR, 1);
  }else{
    outl(VGA_SYNC_ADDR, 0);
  }
  if(w==0 || h==0) return;
  uint32_t *pixels = (uint32_t *)ctl->pixels;
  uint32_t *fb = (uint32_t *)VGA_FB_ADDR;
  // memset(fb + (y*Width + x), (int)pixels, h*w*4);
  for (int i = 0; i < h; i ++){
    for(int j = 0; j < w; j++){
      fb[(i+y)*Width + x + j] = pixels[i*w + j];
    }
  }
 
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}