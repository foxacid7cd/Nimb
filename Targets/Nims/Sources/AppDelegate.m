//
//  AppDelegate.m
//  Nims
//
//  Created by Yevhenii Matviienko on 10.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#include "nvims.h"

#import <Cocoa/Cocoa.h>

#define NS_STRING(arg) [[NSString alloc] initWithBytes:arg.data length:arg.size encoding:NSUTF8StringEncoding]

@interface AppDelegate : NSObject <NSApplicationDelegate> {
  NSWindow *window;
}

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  self->window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 300)
                                          styleMask:NSWindowStyleMaskTitled
                                            backing:NSBackingStoreBuffered
                                              defer:true
                                             screen:NULL];
  [self->window orderFront:NULL];
  
  [self start_nvim];
}

- (void) start_nvim {
  nvims_ui_t nvims_ui;
  
  nvims_ui.mode_info_set = ^(_Bool enabled, nvim_array_t cursor_styles) {
    NSLog(@"nvims_ui.mode_info_set");
  };
  
  nvims_ui.update_menu = ^() {
    NSLog(@"nvims_ui.update_menu");
  };
  
  nvims_ui.busy_start = ^() {
    NSLog(@"nvims_ui.busy_start");
  };
  
  nvims_ui.busy_stop = ^() {
    NSLog(@"nvims_ui.busy_stop");
  };
  
  nvims_ui.mouse_on = ^() {
    NSLog(@"nvims_ui.mouse_on");
  };
  
  nvims_ui.mouse_off = ^() {
    NSLog(@"nvims_ui.mouse_off");
  };
  
  nvims_ui.mode_change = ^(nvim_string_t mode, int64_t mode_idx) {
    NSLog(@"nvims_ui.mode_change");
  };
  
  nvims_ui.bell = ^() {
    NSLog(@"nvims_ui.bell");
  };
  
  nvims_ui.visual_bell = ^() {
    NSLog(@"nvims_ui.visual_bell");
  };
  
  nvims_ui.flush = ^() {
    NSLog(@"nvims_ui.flush");
  };
  
  nvims_ui.suspend = ^() {
    NSLog(@"nvims_ui.suspend");
  };
  
  nvims_ui.set_title = ^(nvim_string_t title) {
    dispatch_async(dispatch_get_main_queue(), ^{
      id object = NS_STRING(title);
      NSLog(@"nvims_ui.set_title %@", object);
      [self->window setTitle:object];
    });
  };
  
  nvims_ui.set_icon = ^(nvim_string_t icon) {
    NSLog(@"nvims_ui.set_icon %@", NS_STRING(icon));
  };
  
  nvims_ui.screenshot = ^(nvim_string_t path) {
    NSLog(@"nvims_ui.screenshot %@", NS_STRING(path));
  };
  
  nvims_ui.option_set = ^(nvim_string_t name, nvim_object_t value) {
    NSLog(@"nvims_ui.option_set %@", NS_STRING(name));
  };
  
  nvims_ui.stop = ^() {
    NSLog(@"nvims_ui.stop");
  };
  
  nvims_ui.default_colors_set = ^(int64_t rgb_fg, int64_t rgb_bg, int64_t rgb_sp, int64_t cterm_fg, int64_t cterm_bg) {
    NSLog(@"nvims_ui.default_colors_set");
  };
  
  nvims_ui.hl_attr_define = ^(int64_t _id, nvim_hl_attrs_t rgb_attrs, nvim_hl_attrs_t cterm_attrs, nvim_array_t info) {
    NSLog(@"nvims_ui.hl_attr_define");
  };
  
  nvims_ui.hl_group_set = ^(nvim_string_t name, int64_t _id) {
    NSLog(@"nvims_ui.hl_group_set %@", NS_STRING(name));
  };
  
  nvims_ui.grid_resize = ^(int64_t grid, int64_t rows, int64_t cols) {
    NSLog(@"nvims_ui.grid_resize %lli %lli %lli", grid, rows, cols);
  };
  
  nvims_ui.grid_clear = ^(int64_t grid) {
      NSLog(@"nvims_ui.grid_clear %lli", grid);
  };
  
  nvims_ui.grid_cursor_goto = ^(int64_t grid, int64_t row, int64_t col) {
      NSLog(@"nvims_ui.grid_cursor_goto %lli %lli %lli", grid, row, col);
  };
  
  nvims_ui.grid_scroll = ^(int64_t grid, int64_t top, int64_t bot, int64_t left, int64_t right, int64_t rows, int64_t cols) {
      NSLog(@"nvims_ui.grid_scroll");
  };
  
  nvims_ui.raw_line = ^(int64_t grid, int64_t row, int64_t startcol, int64_t endcol, int64_t clearcol, int64_t clearattr, int64_t flags, const nvim_schar_t *chunk, const nvim_sattr_t *attrs) {
      NSLog(@"nvims_ui.raw_line");
  };
  
  nvims_ui.event = ^(char *name, nvim_array_t args) {
    NSLog(@"nvims_ui.event %s", name);
  };
  
  nvims_ui.msg_set_pos = ^(int64_t grid, int64_t row, _Bool scrolled, nvim_string_t sep_char){
    NSLog(@"nvims_ui.msg_set_pos");
  };
  
  nvims_ui.win_viewport = ^(int64_t grid, nvim_handle_t win, int64_t topline, int64_t botline, int64_t curline, int64_t curcol, int64_t line_count) {
    NSLog(@"nvims_ui.win_viewport");
  };
  
  nvims_ui.wildmenu_show = ^(nvim_array_t items) {
    NSLog(@"nvims_ui.wildmenu_show");
  };
  
  nvims_ui.wildmenu_select = ^(int64_t selected) {
    NSLog(@"nvims_ui.wildmenu_select");
  };
  
  nvims_ui.wildmenu_hide = ^() {
    NSLog(@"nvims_ui.wildmenu_hide");
  };
  
  nvims_start(nvims_ui);
}

@end
