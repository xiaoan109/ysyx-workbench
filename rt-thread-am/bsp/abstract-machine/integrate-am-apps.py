#!/usr/bin/env python3

import sys, os, shutil, subprocess
from pathlib import Path

# global settings
AM_HOME = Path(os.environ["AM_HOME"])
AM_KERNELS_HOME = (AM_HOME / ".." / "am-kernels").resolve()
app_dir_list = [
  AM_KERNELS_HOME / "kernels" / "hello",
  AM_KERNELS_HOME / "benchmarks" / "microbench",
  AM_KERNELS_HOME / "kernels" / "typing-game",
  AM_KERNELS_HOME / "kernels" / "snake",
  AM_KERNELS_HOME / ".." / "fceux-am",
]

if len(sys.argv) != 3:
    print("Usage: python3 integrate-am-apps.py ARCH=[AM arch] CROSS_COMPILE=[prefix]")
    exit(-1)
if not sys.argv[1].startswith("ARCH="):
    print("Bad ARCH argument")
    exit(-1)
ARCH = sys.argv[1][5:]
if not sys.argv[2].startswith("CROSS_COMPILE="):
    print("Bad CROSS_COMPILE argument")
    exit(-1)
CROSS_COMPILE = sys.argv[2][14:]

Path("build").mkdir(exist_ok=True)
am_app_mk_fp = open(f"build/{ARCH}/am-apps.mk", "w")
am_app_c_fp  = open("build/am-apps.c" , "w")
lib_sym = [
  "memset", "memcpy", "memmove", "memcmp",
  "strlen", "strcat", "strcpy", "strncpy", "strcmp", "strncmp",
  "srand", "rand", "malloc", "free", "abs", "atoi",
  "printf", "sprintf", "snprintf", "vsprintf", "vsnprintf",
]
am_init_sym = [ "trm_init", "ioe_init", "cte_init", "vme_init", "mpe_init" ]

def read_lib_symbols(lib):
    libfile = AM_HOME / lib / "build" / f"{lib}-{ARCH}.a"
    if (not libfile.exists()):
        os.system("make -j ARCH=" + ARCH + " -C " + str(AM_HOME / lib))
    cmd = f"{CROSS_COMPILE}nm -g --defined-only --format=just-symbols {str(libfile)}"
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    global lib_sym
    lib_sym = list(set(lib_sym + res.stdout.strip().split('\n')))

def integrate(app_dir):
    app_name = app_dir.name.replace("-", "_")
    os.system(f"make -j ARCH={ARCH} -C {str(app_dir)}")
    dst = Path("build") / ARCH / "am-apps" / app_name
    dst.mkdir(parents=True, exist_ok=True)
    shutil.copytree(app_dir / "build" / ARCH / "", dst, dirs_exist_ok=True)
    objs = dst.rglob("*.o")
    redefine_sym_file = "redefine_sym.txt"
    redefine_sym_fp = open(redefine_sym_file, "w")
    for f in lib_sym:
        if f in am_init_sym:
            redefine_sym_fp.write(f"__am_{app_name}_{f} __dummy_{f}\n")
        elif f == "halt":
            redefine_sym_fp.write(f"__am_{app_name}_{f} __rt_am_halt\n")
        else:
            redefine_sym_fp.write(f"__am_{app_name}_{f} {f}\n")
    redefine_sym_fp.close()
    for obj in objs:
        os.system(f"{CROSS_COMPILE}objcopy --prefix-symbols=__am_{app_name}_ --set-section-flags .text*=readonly,noload --set-section-flags .*rodata*=readonly,noload {str(obj)}")
        os.system(f"{CROSS_COMPILE}objcopy --redefine-syms=redefine_sym.txt --prefix-alloc-sections=__am_apps {str(obj)}")
        os.system(f"{CROSS_COMPILE}objcopy --set-section-flags .text*=readonly,code,alloc --set-section-flags .*rodata*=readonly,data,alloc {str(obj)}")
        am_app_mk_fp.write("SRCS += " + str(obj.relative_to("build/" + ARCH)) + "\n")
    os.remove(redefine_sym_file)
    am_app_c_fp.write(f"""extern int __am_{app_name}_main(const char *);
static void am_{app_name}(int argc, char *argv[]) {{
  am_app_start_wrapper("{app_name}", __am_{app_name}_main, argc, argv);
}}
MSH_CMD_EXPORT(am_{app_name}, AM {app_name});
""")

read_lib_symbols("am")
read_lib_symbols("klib")

am_app_mk_fp.write("SRCS += build/am-apps.c\n")
am_app_c_fp.write("""#include <am.h>
#include <klib.h>
#include <rtthread.h>
extern Area am_apps_heap, am_apps_data, am_apps_bss;
extern uint8_t * am_apps_data_content;
static void am_app_start_thread(void *args) {
  void (*fn)(const char *mainargs) = ((void **)args)[0];
  const char *mainargs = ((void **)args)[1];
  fn(mainargs);
}
static void am_app_start_wrapper(const char *app_name, void *app_main, int argc, char *argv[]) {
  memcpy(am_apps_data.start, am_apps_data_content, am_apps_data.end - am_apps_data.start);
  memset(am_apps_bss.start, 0, am_apps_bss.end - am_apps_bss.start);
  heap = am_apps_heap;
  void *args[2] = { app_main, (argc >= 2 ? argv[1] : "") };
  rt_thread_t tid = rt_thread_create(app_name, am_app_start_thread, args, 0x4000, 0, 20);
  rt_thread_startup(tid);
}
bool __dummy_ioe_init() { return true; }
bool __dummy_cte_init(Context *(*handler)(Event ev, Context *ctx)) { return true; }
bool __dummy_vme_init(void *(*pgalloc)(int), void (*pgfree)(void *)) { return true; }
bool __dummy_mpe_init(void (*entry)()) { return true; }
void __rt_am_halt(int code) {
  void rt_thread_exit(void);
  rt_thread_exit();
}
""")
for app in app_dir_list:
    integrate(app)
am_app_mk_fp.close()
am_app_c_fp.close()
