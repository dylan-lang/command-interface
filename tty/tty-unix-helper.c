/*
 * Binding helper functions for UNIX TTY support
 *
 * Author: Ingo Albrecht <prom@berlin.ccc.de>
 * Copyright: see accompanying file COPYING
 *
 */
#include <termios.h>
#include <unistd.h>

#include <run-time.h>

struct termios *unix_make_termios() {
  return (struct termios *)primitive_allocate(sizeof(struct termios));
}

int unix_tcsetattr_now(int fd, struct termios *termios) {
  return tcsetattr(fd, TCSANOW, termios);
}

int unix_tcsetattr_drain(int fd, struct termios *termios) {
  return tcsetattr(fd, TCSADRAIN, termios);
}

int unix_tcsetattr_flush(int fd, struct termios *termios) {
  return tcsetattr(fd, TCSAFLUSH, termios);
}
