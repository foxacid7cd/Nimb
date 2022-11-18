//
//  NimsUI.m
//  Nims
//
//  Created by Yevhenii Matviienko on 11.11.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

#import "nvims.h"
#import "NimsUIGrid.h"
#import "NimsUI.h"
#import "NimsFont.h"
#import "MainLayer.h"

#define STRING(arg) [[NSString alloc] initWithBytes:arg.data length:arg.size encoding:NSUTF8StringEncoding]

#define GRIDS_CAPACITY 128

static void *ViewLayerContentsScaleContext = &ViewLayerContentsScaleContext;

@implementation NimsUI {
  GridSize _outerGridSize;
  NimsFont *_font;
  NSMutableDictionary<NSNumber *, NimsUIGrid *> *_grids;
  MainLayer *_mainLayer;
  NSWindow *_window;
  
  NSMutableSet<NSNumber *> *_idsOfGridsWithChangedFrame;
  NSMutableDictionary<NSNumber *, NSMutableSet<NSNumber *> *> *_ysOfGridsWithChangedText;
  BOOL _windowInitiallyOrderedFront;
  
  nvims_ui_t _nvims_ui;
}

- (instancetype)init
{
  self = [super init];
  if (self != nil) {
    self->_outerGridSize = GridSizeMake(110, 40);
    
    self->_font = [[NimsFont alloc] initWithFont:[NSFont fontWithName:@"MesloLGS NF" size:13]];
    self->_grids = [[NSMutableDictionary alloc] initWithCapacity:GRIDS_CAPACITY];
    
    id mainLayer = [[MainLayer alloc] init];
    [mainLayer setContentsScale:[[NSScreen mainScreen] backingScaleFactor]];
    [mainLayer setNeedsDisplay];
    self->_mainLayer = mainLayer;
    
    id mainView = [[NSView alloc] init];
    [mainView setWantsLayer:true];
    [mainView setLayer:mainLayer];
    
    CGSize cellSize = [self->_font cellSize];
    CGRect contentRect = CGRectMake(0,
                                    0,
                                    self->_outerGridSize.width * cellSize.width,
                                    self->_outerGridSize.height * cellSize.height);
    id window = [[NSWindow alloc] initWithContentRect:contentRect
                                            styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                                              backing:NSBackingStoreBuffered
                                                defer:true];
    [window setContentView:mainView];
    self->_window = window;
    
    self->_idsOfGridsWithChangedFrame = [[NSSet set] mutableCopy];
    self->_ysOfGridsWithChangedText = [@{} mutableCopy];
    
    self->_nvims_ui.width = (int)self->_outerGridSize.width;
    self->_nvims_ui.height = (int)self->_outerGridSize.height;
    
    self->_nvims_ui.mode_info_set = ^(_Bool enabled, nvim_array_t cursor_styles) {
    };
    
    self->_nvims_ui.update_menu = ^() {
    };
    
    self->_nvims_ui.busy_start = ^() {
    };
    
    self->_nvims_ui.busy_stop = ^() {
    };
    
    self->_nvims_ui.mouse_on = ^() {
    };
    
    self->_nvims_ui.mouse_off = ^() {
    };
    
    self->_nvims_ui.mode_change = ^(nvim_string_t mode, int64_t mode_idx) {
    };
    
    self->_nvims_ui.bell = ^() {
    };
    
    self->_nvims_ui.visual_bell = ^() {
    };
    
    self->_nvims_ui.flush = ^() {
      dispatch_sync(dispatch_get_main_queue(), ^{
        [CATransaction begin];
        [CATransaction setDisableActions:true];
        
        for (NSNumber *gridID in self->_idsOfGridsWithChangedFrame) {
          NimsUIGrid *grid = [self->_grids objectForKey:gridID];
          
          NSMutableArray<NSValue *> *rowFrames = [@[] mutableCopy];
          for (NimsUIGridRow *row in [grid rows]) {
            NSValue *value = [NSValue valueWithRect:[row layerFrame]];
            [rowFrames addObject:value];
          }
          
          [self->_mainLayer setFrame:[grid layerFrame]
                        andRowFrames:[rowFrames copy]
                       forGridWithID:gridID];
        }
        
        [self->_ysOfGridsWithChangedText enumerateKeysAndObjectsUsingBlock:^(NSNumber *gridID, NSMutableSet<NSNumber *> *ys, BOOL * _Nonnull stop) {
          NimsUIGrid *grid = [self->_grids objectForKey:gridID];
          
          for (NSNumber *yNumber in ys) {
            int64_t y = [yNumber longLongValue];
            NimsUIGridRow *row = [[grid rows] objectAtIndex:y];
            [self->_mainLayer setRowAttributedString:[row attributedString]
                                                 atY:y
                                       forGridWithID:gridID];
          }
        }];
        
        [CATransaction commit];
        
        if (!self->_windowInitiallyOrderedFront) {
          [self->_window orderFront:nil];
          
          self->_windowInitiallyOrderedFront = true;
        }
      });
      
      [self->_idsOfGridsWithChangedFrame removeAllObjects];
      [self->_ysOfGridsWithChangedText removeAllObjects];
    };
    
    self->_nvims_ui.suspend = ^() {
    };
    
    self->_nvims_ui.set_title = ^(nvim_string_t cTitle) {
      NSString *title = STRING(cTitle);
      
      dispatch_sync(dispatch_get_main_queue(), ^{
        [self->_window setTitle:title];
      });
    };
    
    self->_nvims_ui.set_icon = ^(nvim_string_t icon) {
    };
    
    self->_nvims_ui.screenshot = ^(nvim_string_t path) {
    };
    
    self->_nvims_ui.option_set = ^(nvim_string_t name, nvim_object_t value) {
      dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"option_set %@", STRING(name));
      });
    };
    
    self->_nvims_ui.stop = ^() {
    };
    
    self->_nvims_ui.default_colors_set = ^(int64_t rgb_fg, int64_t rgb_bg, int64_t rgb_sp, int64_t cterm_fg, int64_t cterm_bg) {
    };
    
    self->_nvims_ui.hl_attr_define = ^(int64_t _id, nvim_hl_attrs_t rgb_attrs, nvim_hl_attrs_t cterm_attrs, nvim_array_t info) {
    };
    
    self->_nvims_ui.hl_group_set = ^(nvim_string_t name, int64_t _id) {
    };
    
    self->_nvims_ui.grid_resize = ^(int64_t cID, int64_t width, int64_t height) {
      id _id = [NSNumber numberWithLongLong:cID];
      GridSize size = GridSizeMake(width, height);
      
      NimsUIGrid *grid = [self->_grids objectForKey:_id];
      if (grid == nil) {
        grid = [[NimsUIGrid alloc] initWithFont:self->_font
                                          frame:GridRectMake(GridPointZero, size)
                               andOuterGridSize:self->_outerGridSize];
        [self->_grids setObject:grid forKey:_id];
        
      } else {
        GridPoint origin = [grid frame].origin;
        GridRect frame = GridRectMake(origin, size);
        [grid setFrame:frame andOuterGridSize:self->_outerGridSize];
      }
      
      [self->_idsOfGridsWithChangedFrame addObject:_id];
    };
    
    self->_nvims_ui.grid_clear = ^(int64_t cID) {
      id _id = [NSNumber numberWithLongLong:cID];
      
      NimsUIGrid *grid = [self->_grids objectForKey:_id];
      if (grid == nil) {
        NSLog(@"nvims_ui.grid_clear called for unexisting grid with id: %@", _id);
        return;
      }
      
      NSMutableSet<NSNumber *> *ys = [self->_ysOfGridsWithChangedText objectForKey:_id];
      if (ys == nil) {
        ys = [[NSSet set] mutableCopy];
        [self->_ysOfGridsWithChangedText setObject:ys forKey:_id];
      }
      
      [[grid rows] enumerateObjectsUsingBlock:^(NimsUIGridRow *row, NSUInteger index, BOOL *stop) {
        [row clearText];
        [ys addObject:[NSNumber numberWithLongLong:index]];
      }];
    };
    
    self->_nvims_ui.grid_cursor_goto = ^(int64_t grid, int64_t row, int64_t col) {
    };
    
    self->_nvims_ui.grid_scroll = ^(int64_t grid, int64_t top, int64_t bot, int64_t left, int64_t right, int64_t rows, int64_t cols) {
    };
    
    self->_nvims_ui.raw_line = ^(int64_t cGridID, int64_t row, int64_t startcol, int64_t endcol, int64_t clearcol, int64_t clearattr, int64_t flags, const nvim_schar_t *chunk, const nvim_sattr_t *attrs) {
      id gridID = [NSNumber numberWithInteger:cGridID];
      
      NimsUIGrid *grid = [self->_grids objectForKey:gridID];
      if (grid == nil) {
        NSLog(@"nvims_ui.raw_line called for unexisting grid with id: %@", gridID);
        return;
      }
      
      NSMutableString *changedText = [NSMutableString stringWithCapacity:endcol - startcol];
      for (int64_t i = startcol; i < endcol; i++) {
        NSString *string = [NSString stringWithCString:chunk[i - startcol] encoding:NSUTF8StringEncoding];
        if (string != nil) {
          [changedText appendString: string];
        }
      }
      [[[grid rows] objectAtIndex:row] applyChangedText:changedText
                                            startingAtX:startcol];
      
      NSMutableSet<NSNumber *> *ys = [self->_ysOfGridsWithChangedText objectForKey:gridID];
      if (ys == nil) {
        ys = [[NSSet set] mutableCopy];
        [self->_ysOfGridsWithChangedText setObject:ys forKey:gridID];
      }
      [ys addObject:[NSNumber numberWithLongLong:row]];
    };
    
    self->_nvims_ui.event = ^(char *cName, nvim_array_t args) {
      NSString *name = [NSString stringWithCString:cName encoding:NSUTF8StringEncoding];
      if ([name isEqualToString:@"win_pos"]) {
        int64_t cGridID = args.items[0].data.integer;
        NSNumber *gridID = [NSNumber numberWithLongLong:cGridID];
        NimsUIGrid *grid = [self->_grids objectForKey:gridID];
        
        int64_t start_row = args.items[2].data.integer;
        int64_t start_col = args.items[3].data.integer;
        int64_t width = args.items[4].data.integer;
        int64_t height = args.items[5].data.integer;
        GridRect frame = GridRectMake(GridPointMake(start_col, start_row),
                                      GridSizeMake(width, height));
        
        [grid setFrame:frame andOuterGridSize:self->_outerGridSize];
        
      } else {
        NSLog(@"Unknown nvims_ui.event with name: %@", name);
      }
    };
    
    self->_nvims_ui.msg_set_pos = ^(int64_t grid, int64_t row, _Bool scrolled, nvim_string_t sep_char) {
    };
    
    self->_nvims_ui.win_viewport = ^(int64_t grid, nvim_handle_t win, int64_t topline, int64_t botline, int64_t curline, int64_t curcol, int64_t line_count) {
      dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"win_viewport %lli %lli %lli %lli %lli", topline, botline, curline, curcol, line_count);
      });
    };
    
    self->_nvims_ui.wildmenu_show = ^(nvim_array_t items) {
    };
    
    self->_nvims_ui.wildmenu_select = ^(int64_t selected) {
    };
    
    self->_nvims_ui.wildmenu_hide = ^() {
    };
  }
  return self;
}

- (void)start
{
  nvims_start(self->_nvims_ui);
}

@end
