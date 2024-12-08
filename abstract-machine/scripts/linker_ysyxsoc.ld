ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }

MEMORY {
  mrom : ORIGIN = 0x20000000, LENGTH = 4K
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = ORIGIN(mrom);
  .text : 
  {
    *(entry)
    *(.text*)
  } > mrom AT >mrom : text

  .rodata : 
  {
    _rodata = .;
    *(.rodata*)
    *(.srodata*)
    _erodata = .;
  } > mrom AT >mrom

  .data :
  {
    _data = .;
    *(.data*)
    *(.sdata*)
    . = ALIGN(4);
    _edata = .;
  } > sram AT >mrom : data
  
  .bss : 
  {
	  _bstart = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    _bend = .;
  } > sram AT >mrom

  _stack_top = ALIGN(4);
  . = _stack_top + 0x800;
  _stack_pointer = .;
  end = .;
  _end = .;
  _heap_start = ALIGN(4);
  _heap_end = _heap_start + 0x400;
}