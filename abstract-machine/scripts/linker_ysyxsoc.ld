ENTRY(_start)
/* PHDRS { text PT_LOAD; data PT_LOAD; bss PT_LOAD; } */

MEMORY {
  mrom  : ORIGIN = 0x20000000, LENGTH = 4K
  sram  : ORIGIN = 0x0f000000, LENGTH = 8K
  flash : ORIGIN = 0x30000000, LENGTH = 64M
  psram : ORIGIN = 0x80000000, LENGTH = 4M
}

SECTIONS {
  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = ORIGIN(flash);

  fsbl :{
    _fsbl = .;
    *(entry)
    *(.text._trm_init)
    *(.text.fsbl)
    . = ALIGN(4);
    _efsbl = .;
  } > flash AT >flash

  ssbl :{
    _ssbl = .;
    *(.text.ssbl)
    . = ALIGN(4);
    _essbl = .;
  } > sram AT >flash

  _test_origin = LOADADDR(.text);
  .text :
  {
    _text = .;
    *(.text*)
    . = ALIGN(4);
    _etext = .;
  } > psram AT >flash

  .rodata :
  {
    _rodata = .;
    *(.rodata*)
    *(.srodata*)
    . = ALIGN(4);
    _erodata = .;
  } > psram AT >flash

  .data :
  {
    _data = .;
    *(.data*)
    *(.sdata*)
    . = ALIGN(4);
    _edata = .;
  } > psram AT >flash

  .bss :
  {
    _bstart = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    . = ALIGN(4);
    _bend = .;
  } > psram AT >flash

  end = .;
  _end = .;

  _heap_start = ALIGN(4);
  _heap_end = _heap_start + 0x40000;

  _stack_top = _sram_start;
  . = _stack_top + LENGTH(sram) - 0x100;
  _stack_pointer = .;
}