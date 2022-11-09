
#ifndef nvim_main_h
#define nvim_main_h

#include <nvim/event/loop.h>

extern Loop main_loop;

extern int nvim_main(int argc, char **argv);

#endif /* nvim_main_h */
