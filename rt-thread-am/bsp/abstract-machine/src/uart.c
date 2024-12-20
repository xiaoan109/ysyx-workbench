/*
 * Copyright (c) 2006-2020, RT-Thread Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date           Author       Notes
 */

#include <am.h>
#include <klib-macros.h>
#include <rtdevice.h>
#include <rtthread.h>
#include <am.h>
#include <klib.h>

#define UART_DEFAULT_BAUDRATE 115200

struct device_uart {
  rt_ubase_t hw_base;
  rt_uint32_t irqno;
};

static void *uart0_base = (void*)0x10000000;
static struct rt_serial_device serial0;
static struct device_uart uart0;

static rt_err_t _uart_configure(struct rt_serial_device *serial, struct serial_configure *cfg) {
  return (RT_EOK);
}

static rt_err_t _uart_control(struct rt_serial_device *serial, int cmd, void *arg) {
  return (RT_EOK);
}

static int _uart_putc(struct rt_serial_device *serial, char c) {
  putch(c);
  return 1;
}

static int _uart_getc(struct rt_serial_device *serial) {
  static const char *const PREDEF_INPUT =
      "help\ndate\nversion\nfree\nps\npwd\nls\nmemtrace\nmemcheck\nutest_list\n";
  static const char *p = PREDEF_INPUT;
  static bool exhausted = false;

  if (exhausted) {
    return io_read(AM_UART_RX).data;
  }
  if (*p != '\0') {
    return *(p++);
  } else {
    exhausted = true;
    return io_read(AM_UART_RX).data;
  }
}

const struct rt_uart_ops _uart_ops = {
  _uart_configure,
  _uart_control,
  _uart_putc,
  _uart_getc,
  // TODO: add DMA support
  RT_NULL};

/*
 * UART Initiation
 */
int rt_hw_uart_init(void) {
  struct rt_serial_device *serial;
  struct device_uart *uart;
  struct serial_configure config = RT_SERIAL_CONFIG_DEFAULT;
  // register device
  serial = &serial0;
  uart = &uart0;

  serial->ops = &_uart_ops;
  serial->config = config;
  serial->config.baud_rate = UART_DEFAULT_BAUDRATE;
  uart->hw_base = (rt_ubase_t)uart0_base;
  uart->irqno = 0x0a;

  rt_hw_serial_register(serial,
      RT_CONSOLE_DEVICE_NAME,
      RT_DEVICE_FLAG_STREAM | RT_DEVICE_FLAG_RDWR | RT_DEVICE_FLAG_INT_RX,
      uart);
  return 0;
}

/* WEAK for SDK 0.5.6 */
rt_weak void uart_debug_init(int uart_channel)
{
}
