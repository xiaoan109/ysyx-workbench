#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

#define printf_max_size 1024

void int_to_string(int num , char * value) {

  char reverse_value[100] = {0};
  int index = 0;
  if(num == 0) {
    // printf("num = %d\n",num);
    reverse_value[0] = 0 + '1' - 1;
    index = 1;
  }
  while(num != 0) {
    reverse_value [index]  = num%10 + '1' - 1 ;
    num = num / 10;
    index ++ ;
  }
  
  index --;
  for(int i = 0;i <= index;i++) {
    value[i] =  reverse_value [ index - i ];
  }
  value [(index + 1)]  = '\0';
} 

int sprintf(char *out, const char *fmt, ...) {

    va_list ap;
    va_start(ap, fmt);
    int i = vsprintf(out, fmt, ap);
    return i;
}


int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  char out[printf_max_size] ;
  int i = vsprintf(out, fmt, ap);
  putstr(out);
  return i;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  int d  = 0;
  char *s;
  char sb_s = 0;
  int length = 0;
  while (*fmt) {
    if(*fmt == '%')   {
      fmt++ ;
      if(*fmt < '0' || *fmt > '9') {
        switch (*fmt) {
        case 's':              /* string */
            s = va_arg(ap, char *);
            out = memcpy(out,s,strlen(s));
            length += strlen(s);
            out = out + strlen(s);
            break;
        case 'd':              /* int */
            d = va_arg(ap, int);
            char num_string[100] = {0};
            int_to_string(d,num_string);
            out = memcpy(out,num_string,strlen(num_string));
            length += strlen(num_string);
            out += strlen(num_string);
            break;
        case 'c':
            sb_s = (char)va_arg(ap, int);
            *out = sb_s;
            out++;
        default : out = out;        
        }
      }else{
        char presion_buff[1000];
        int i_presion = 0 ;
        for(;*fmt >= '0' && *fmt <= '9';fmt++) {
          presion_buff[i_presion++] = *fmt;
        }
        presion_buff[i_presion] = '\0' ;
        int presion_data = atoi(presion_buff);
        switch (*fmt) {
          case 'd':              /* int */
              d = va_arg(ap, int);
              char num_string[100] = {0};
              int_to_string(d,num_string);
              int presion_temp_num = 0;
              for(;presion_temp_num < presion_data - strlen(num_string);presion_temp_num ++ ) {
                if(presion_buff[0] == '0') {
                  *out = '0';
                }else {
                  *out = ' ';
                }
                out++;  
              }
              out = memcpy(out,num_string,strlen(num_string));
              length += strlen(num_string);
              out += strlen(num_string);
              break;
          default : out = out;       
        }
      }
    }else{
      out[0] = *fmt;
      out++;
      length ++;
    }
    fmt++;
            // printf(" fmt = %c\n",*fmt);
    }
    *out = '\0';
    return length;
}


#endif