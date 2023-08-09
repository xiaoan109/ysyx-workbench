#include <common.h>
#include <device/map.h>
#include <SDL2/SDL.h>

enum {
  reg_freq,
  reg_channels,
  reg_samples,
  reg_sbuf_size,
  reg_init,
  reg_count,
  nr_reg
};

static uint8_t* sbuf = NULL;
static uint32_t* audio_base = NULL;

#define AUDIO_FREQ_ADDR      0x00
#define AUDIO_CHANNELS_ADDR  0x04
#define AUDIO_SAMPLES_ADDR   0x08
#define AUDIO_SBUF_SIZE_ADDR 0x0c
#define AUDIO_INIT_ADDR      0x10
#define AUDIO_COUNT_ADDR     0x14

SDL_AudioSpec s = {};
static int front = 0, tail = 0;

void work(uint32_t x);

static void audio_io_handler(uint32_t offset, int len, bool is_write) {
  switch (offset) {
  case AUDIO_FREQ_ADDR: assert(is_write);
    s.freq = *(audio_base + AUDIO_FREQ_ADDR / 4);
    break;
  case AUDIO_CHANNELS_ADDR: assert(is_write);
    s.channels = *(audio_base + (AUDIO_CHANNELS_ADDR) / 4);
    break;
  case AUDIO_SAMPLES_ADDR: assert(is_write);
    s.samples = *(audio_base + (AUDIO_SAMPLES_ADDR) / 4);
    break;
  case AUDIO_SBUF_SIZE_ADDR: assert(!is_write);
    assert(*(audio_base + (AUDIO_SBUF_SIZE_ADDR) / 4) == CONFIG_SB_SIZE);
    break;
  case AUDIO_COUNT_ADDR:
    if (is_write) tail = *(audio_base + AUDIO_COUNT_ADDR / 4);
    else *(audio_base + (AUDIO_COUNT_ADDR) / 4) = tail;
    assert(tail <= CONFIG_SB_SIZE);
    break;
  case AUDIO_INIT_ADDR:
    assert(is_write); work(*(audio_base + (AUDIO_INIT_ADDR) / 4)); break;
  default: printf("%d\n", offset);assert(0);
  }
}

volatile uint32_t get_the_status() { return *(audio_base + (AUDIO_INIT_ADDR) / 4); }

static void mycallback(void* userdata, uint8_t* stream, int len) {
  int nread = len;
  if (tail - front < len) nread = tail - front;
  memcpy(stream, sbuf + front, nread);
  front += nread;
  if (len > nread) memset(stream + nread, 0, len - nread);
  if (front == tail) front = tail = 0;
  return;
}

void work(uint32_t x) {
  if (!x) return;
  *(audio_base + (AUDIO_INIT_ADDR) / 4) = 0;
  if (x) {
    int ret = SDL_InitSubSystem(SDL_INIT_AUDIO);
    if (!ret) {
      SDL_OpenAudio(&s, NULL);
      SDL_PauseAudio(0);
    }
  }
  return;
}

void init_audio() {
  uint32_t space_size = sizeof(uint32_t) * nr_reg;
  audio_base = (uint32_t*)new_space(space_size);
#ifdef CONFIG_HAS_PORT_IO
  add_pio_map("audio", CONFIG_AUDIO_CTL_PORT, audio_base, space_size, audio_io_handler);
#else
  add_mmio_map("audio", CONFIG_AUDIO_CTL_MMIO, audio_base, space_size, audio_io_handler);
#endif

  sbuf = (uint8_t*)new_space(CONFIG_SB_SIZE);
  add_mmio_map("audio-sbuf", CONFIG_SB_ADDR, sbuf, CONFIG_SB_SIZE, NULL);

  s.format = AUDIO_S16SYS;
  s.userdata = NULL;
  s.callback = mycallback;
  s.size = *(audio_base + (AUDIO_SBUF_SIZE_ADDR / 4)) = CONFIG_SB_SIZE;

  SDL_InitSubSystem(SDL_INIT_AUDIO);
}