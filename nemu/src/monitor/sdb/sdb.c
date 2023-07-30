/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"
#include "watchpoint.h"

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();
word_t vaddr_read(vaddr_t addr, int len);

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}


static int cmd_q(char *args) {
  nemu_state.state = NEMU_QUIT;
  return -1;
}

static int cmd_si(char* args) {
  char* arg = strtok(NULL, " ");
  int steps;

  if (arg == NULL) {
      cpu_exec(1);
      return 0;
  }
  sscanf(arg, "%d", &steps);

  cpu_exec(steps);
  return 0;
}

static int cmd_info(char* args) {
  char* arg = strtok(NULL, " ");
  if (arg == NULL) {
      Log("Missing parameter r or w");
      return 0;
  }
  if (strcmp(arg, "r") == 0) {
      isa_reg_display();
  }
  if (strcmp(arg, "w") == 0) {
      print_wp();
  }
  return 0;
}

static int cmd_x(char* args) {
  char* N = strtok(NULL, " ");
  char* EXPR = strtok(NULL, " ");
  int num;
  bool success = true;
  vaddr_t addr;
  if (N == NULL || EXPR == NULL) {
      Log("Need two parameters N and EXPR");
      return 0;
  }
  sscanf(N, "%d", &num);
  // sscanf(EXPR, "%x", &addr);
  addr = expr(EXPR, &success);
  if(success) {
    for (int i = 0; i < num; i++) {
        word_t data = vaddr_read(addr + i * 4, 4);
        printf("addr: " FMT_PADDR, addr + i * 4);
        printf("\tdata: " FMT_WORD, data);
        printf("\n");
    }
  }
  else
    Log(ANSI_FG_RED"EXPR is illegal!"ANSI_NONE);
  return 0;
}

static int cmd_p(char* args) {
  bool success = true;
  if (args == NULL) {
      Log("Need parameter EXPR");
      return 0;
  }
  word_t ans = expr(args, &success);
  if (success) {
      Log(ANSI_FG_GREEN"Successfully evaluate the EXPR!"ANSI_NONE);
      Log(ANSI_FG_MAGENTA"EXPR: %s"ANSI_NONE, args);
      Log(ANSI_FG_MAGENTA"ANSWER:\n[Dec] unsigned: %u signed: %d\n[Hex]"FMT_WORD ANSI_NONE, ans, ans, ans);
  } else
      Log(ANSI_FG_RED"EXPR is illegal!"ANSI_NONE);
  return 0;
}

static int cmd_w(char* args) {
  if (args == NULL) {
      Log(ANSI_FG_RED"Missing parameter EXPR"ANSI_NONE);
      return 0;
  }
  WP* wp = new_wp(args);
  Log("watchpoint %d: %s is set!", wp->NO, wp->e);
  return 0;
}

static int cmd_d(char* args) {
  if (args == NULL) {
      Log(ANSI_FG_RED"Missing parameter N"ANSI_NONE);
      return 0;
  }
  int N;
  bool search = true;
  sscanf(args, "%d", &N);
  WP* wp = delete_wp(N, &search);
  if (search) {
      Log("Delete watchpoint %d: %s", wp->NO, wp->e);
      free_wp(wp);
      return 0;
  } else {
      Log(ANSI_FG_RED"Can't find watchpoint %d"ANSI_NONE, N);
      return 0;
  }
  return 0;
}

static int cmd_help(char *args);

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },
  {"si", "Step over, default N=1", cmd_si},
  {"info", "info r: print register info; info w: print watchpoint info", cmd_info},
  {"x", "x N EXPR: print N * 4 bytes info in mem from addr=EXPR", cmd_x},
  {"p", "p EXPR: evaluate the expression", cmd_p},
  {"w", "w EXPR: set a watchpoint on the value of EXPR", cmd_w},
  {"d", "d N: delete the watchpoint with N", cmd_d},

  /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}
