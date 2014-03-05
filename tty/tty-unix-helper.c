/*
 * Binding helper functions for UNIX TTY support
 *
 * Author: Ingo Albrecht <prom@berlin.ccc.de>
 * Copyright: see accompanying file LICENSE
 *
 */
#include <termios.h>
#include <unistd.h>

#include <run-time.h>

/* allocation wrapper for "struct termios" */
struct termios *unix_make_termios() {
  return (struct termios *)primitive_allocate(sizeof(struct termios));
}

/* enum wrapper for tcsetattr(x, TCSANOW, y) */
int unix_tcsetattr_now(int fd, struct termios *termios) {
  return tcsetattr(fd, TCSANOW, termios);
}

/* enum wrapper for tcsetattr(x, TCSADRAIN, y) */
int unix_tcsetattr_drain(int fd, struct termios *termios) {
  return tcsetattr(fd, TCSADRAIN, termios);
}

/* enum wrapper for tcsetattr(x, TCSAFLUSH, y) */
int unix_tcsetattr_flush(int fd, struct termios *termios) {
  return tcsetattr(fd, TCSAFLUSH, termios);
}
