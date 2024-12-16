ENTRY(_start)

/* MEMORY {
  sram  (rwx) : ORIGIN = 0x0f000000, LENGTH = 8K
  mrom  (r x) : ORIGIN = 0x20000000, LENGTH = 4K
  flash (rwx) : ORIGIN = 0x30000000, LENGTH = 16M
  psram (rwx) : ORIGIN = 0x80000000, LENGTH = 4M
} */

SECTIONS {
  _sram_start = ORIGIN(sram);
  _sram_end = _sram_start + LENGTH(sram);
  _mrom_start = ORIGIN(mrom);
  _mrom_end = _mrom_start + LENGTH(mrom);
  _flash_start = ORIGIN(flash);
  _flash_end = _flash_start + LENGTH(flash);
  _psram_start = ORIGIN(psram);
  _psram_end = _psram_start + LENGTH(psram);

  . = _flash_start;

  .bl.f : ALIGN(4) {
    *(.bl.f*)

    . = ALIGN(4);
  } > flash

  .bl.s : ALIGN(4) {
    _bl_s = .;

    *(.bl.s*)

    . = ALIGN(4);
    _ebl_s = .;
  } > sram AT> flash
  _bl_s_load = LOADADDR(.bl.s);
  _ebl_s_load = _bl_s_load + SIZEOF(.bl.s);

  .text : ALIGN(4) {
    _text = .;

    *(.text*)

    . = ALIGN(4);
    PROVIDE(etext = .);
    _etext = .;
  } > psram AT> flash
  _text_load = LOADADDR(.text);
  _etext_load = _text_load + SIZEOF(.text);

  .rodata : ALIGN(4) {
    *(.rodata*)
    *(.srodata*)
  } > flash

  .data : ALIGN(4) {
    _data = .;

    *(.data*)
    *(.sdata*)
    
    . = ALIGN(4);
    PROVIDE(edata = .);
    _edata = .;
  } > psram AT> flash
  _data_load = LOADADDR(.data);
  _edata_load = _data_load + SIZEOF(.data);

  _data_extra = DEFINED(_data_extra) ? _data_extra : 0;
  _edata_extra = DEFINED(_edata_extra) ? _edata_extra : 0;
  _data_extra_load = DEFINED(_data_extra_load) ? _data_extra_load : 0;
  _edata_extra_load = DEFINED(_edata_extra_load) ? _edata_extra_load : 0;

  .bss (NOLOAD) : ALIGN(4) {
    _bss_start = .;

    *(.bss*)
    *(.sbss*)
    *(.scommon)

    . = ALIGN(4);
    _ebss = .;
  } > psram

  _bss_extra_start = DEFINED(_bss_extra_start) ? _bss_extra_start : 0;
  _ebss_extra = DEFINED(_ebss_extra) ? _ebss_extra : 0;

  PROVIDE(end = .);
  _end = .;

  . = ALIGN(8);
  _heap_start = .;

  .stack (NOLOAD) : ALIGN(8) {
    _stack_top = .;

    . += _stack_size;

    . = ALIGN(8);
    _stack_pointer = .;
  } > sram
}