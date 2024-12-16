#include "trap.h"

void init_uart(uint32_t baud_rate);
void init_spi(uint32_t spi_clock, uint8_t spi_ss, uint8_t char_len, uint8_t tx_neg, uint8_t rx_neg, uint8_t lsb);
void spi_tx(uint8_t *tx_data, uint8_t len);
void spi_rx(uint8_t *rx_data, uint8_t len);
void spi_tx_start();

__attribute__((noinline))
bool getbit(void *buf, int offset){
	int byte = offset >> 3;
	offset &= 7;
	uint8_t mask = 1 << offset;
	return (((uint8_t *)buf)[byte] & mask) != 0;
}
__attribute__((noinline))
void setbit(void *buf, int offset, bool bit){
	int byte = offset >> 3;
	offset &= 7;
	uint8_t mask = 1 << offset;

	uint8_t * volatile p = buf + byte;
	*p = (bit == 0 ? (*p & ~mask) : (*p | mask));
}

uint8_t bitrev(uint8_t data) {
  uint8_t ret = 0;
  for(int i = 0; i < 8; i++) {
    setbit(&ret, i, getbit(&data, 7-i));
  }
  return ret;
}

int main() {
  // init_uart(115200);
  init_spi(2500000, 1 << 7, 16, 0, 1, 0); //TX rising edge, RX falling edge
  uint8_t tx_data[2];
  uint8_t rx_data[2];
  for(int i = 0; i < 256; i++) {
    tx_data[0] = 0;
    tx_data[1] = i; 
    spi_tx(tx_data, 16);
    spi_tx_start();
    spi_rx(rx_data, 16);
    check(rx_data[0] == bitrev((uint8_t)i));
  } 
  return 0;
}