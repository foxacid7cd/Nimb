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
#import "NimsUIHighlights.h"
#import "NimsFont.h"
#import "MainWindow.h"

#define STRING(arg) [[NSString alloc] initWithBytes:arg.data length:arg.size encoding:NSUTF8StringEncoding]

#define GRIDS_CAPACITY 128

static void *ViewLayerContentsScaleContext = &ViewLayerContentsScaleContext;

@implementation NimsUI {
  GridSize _outerGridSize;
  NimsFont *_font;
  NimsUIHighlights *_highlights;
  
  CGFloat _plainGridsZPositionCounter;
  CGFloat _windowGridsZPositionCounter;
  CGFloat _floatingWindowGridsZPositionCounter;
  
  NSMutableDictionary<NSNumber *, NimsUIGrid *> *_grids;
  CALayer *_layer;
  MainWindow *_mainWindow;
  
  NSMutableSet<NSNumber *> *_changedGridIDs;
  NSMutableArray<CALayer *> *_removedLayers;
  BOOL _highlightsUpdated;
  
  int64_t _cursorGridID;
  GridPoint _cursorPosition;
  CGRect _cursorLayerFrame;
  BOOL _cursorLayerFrameChanged;
  CALayer *_cursorLayer;
  
  nvims_ui_t _nvims_ui;
}

- (instancetype)init
{
  self = [super init];
  if (self != nil) {
    self->_outerGridSize = GridSizeMake(80, 24);
    
    self->_font = [[NimsFont alloc] initWithFont:[NSFont fontWithName:@"MesloLGS NF" size:13]];
    self->_grids = [[NSMutableDictionary alloc] initWithCapacity:GRIDS_CAPACITY];
    self->_highlights = [[NimsUIHighlights alloc] init];
    
    self->_plainGridsZPositionCounter = 0;
    self->_windowGridsZPositionCounter = 1000;
    self->_floatingWindowGridsZPositionCounter = 2000;
    
    id layer = [[CALayer alloc] init];
    [layer setContentsScale:[[NSScreen mainScreen] backingScaleFactor]];
    [layer setNeedsDisplay];
    self->_layer = layer;
    
    id mainView = [[NSView alloc] init];
    [mainView setWantsLayer:true];
    [mainView setLayer:layer];
    
    CGSize cellSize = [self->_font cellSize];
    CGRect contentRect = CGRectMake(0,
                                    0,
                                    self->_outerGridSize.width * cellSize.width,
                                    self->_outerGridSize.height * cellSize.height);
    id mainWindow = [[MainWindow alloc] initWithContentRect:contentRect
                                                  styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                                                    backing:NSBackingStoreBuffered
                                                      defer:true];
    [mainWindow setContentView:mainView];
    [mainWindow setCellSize:[self->_font cellSize]];
    [mainWindow makeMainWindow];
    [mainWindow makeKeyAndOrderFront:nil];
    self->_mainWindow = mainWindow;
    
    self->_changedGridIDs = [[NSSet set] mutableCopy];
    self->_removedLayers = [@[] mutableCopy];
    
    id cursorLayer = [[CALayer alloc] init];
    [cursorLayer setBackgroundColor:[[NSColor whiteColor] CGColor]];
    [cursorLayer setZPosition:3000];
    [cursorLayer setCompositingFilter:@"differenceBlendMode"];
    [layer addSublayer:cursorLayer];
    self->_cursorLayer = cursorLayer;
    
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
       
        if ([self->_removedLayers count] > 0) {
          for (id layer in self->_removedLayers) {
            [layer removeFromSuperlayer];
          }
          
          [self->_removedLayers removeAllObjects];
        }
        
        for (id gridID in self->_changedGridIDs) {
          id grid = [self->_grids objectForKey:gridID];
          [grid flush];
          
          if ([[grid layer] superlayer] == nil) {
            [self->_layer addSublayer:[grid layer]];
          }
        }
        
        [self->_changedGridIDs removeAllObjects];
        
        if (self->_cursorLayerFrameChanged) {
          [self->_cursorLayer setFrame:self->_cursorLayerFrame];
          
          self->_cursorLayerFrameChanged = false;
        }
        
        if (self->_highlightsUpdated) {
          for (id grid in [self->_grids allValues]) {
            [grid highlightsUpdated];
          }
          
          self->_highlightsUpdated = false;
        }
        
        [CATransaction commit];
      });
    };
    
    self->_nvims_ui.suspend = ^() {
    };
    
    self->_nvims_ui.set_title = ^(nvim_string_t cTitle) {
    };
    
    self->_nvims_ui.set_icon = ^(nvim_string_t icon) {
    };
    
    self->_nvims_ui.screenshot = ^(nvim_string_t path) {
    };
    
    self->_nvims_ui.option_set = ^(nvim_string_t name, nvim_object_t value) {
    };
    
    self->_nvims_ui.stop = ^() {
    };
    
    self->_nvims_ui.default_colors_set = ^(int64_t rgb_fg, int64_t rgb_bg, int64_t rgb_sp, int64_t cterm_fg, int64_t cterm_bg) {
      self->_highlightsUpdated = true;
      
      [self->_highlights applyDefaultColorsSetWithRGB_fg:(int32_t)rgb_fg
                                                  rgb_bg:(int32_t)rgb_bg
                                                  rgb_sp:(int32_t)rgb_sp];
    };
    
    self->_nvims_ui.hl_attr_define = ^(int64_t hlID, nvim_hl_attrs_t rgb_attrs, nvim_hl_attrs_t cterm_attrs, nvim_array_t info) {
      self->_highlightsUpdated = true;
      
      id highlightID = [NSNumber numberWithLongLong:hlID];
      [self->_highlights applyAttrDefineForHighlightID:highlightID
                                             rgb_attrs:rgb_attrs];
    };
    
    self->_nvims_ui.hl_group_set = ^(nvim_string_t cName, int64_t _id) {
    };
    
    self->_nvims_ui.grid_resize = ^(int64_t cID, int64_t width, int64_t height) {
      id _id = [NSNumber numberWithLongLong:cID];
      GridSize size = GridSizeMake(width, height);
      
      NimsUIGrid *grid = [self->_grids objectForKey:_id];
      if (grid == nil) {
        grid = [[NimsUIGrid alloc] initWithHighlights:self->_highlights
                                                 font:self->_font
                                               origin:GridPointZero
                                                 size:size
                                     andOuterGridSize:self->_outerGridSize];
        [grid setContentsScale:[[NSScreen mainScreen] backingScaleFactor]];
        [grid setZPosition:self->_plainGridsZPositionCounter];
        self->_plainGridsZPositionCounter += 0.1;
        
        [self->_grids setObject:grid forKey:_id];
        
      } else {
        [grid setSize:size];
      }
      
      [grid setHidden:false];
      
      [self->_changedGridIDs addObject:_id];
    };
    
    self->_nvims_ui.grid_clear = ^(int64_t cGridID) {
      id gridID = [NSNumber numberWithLongLong:cGridID];
      
      NimsUIGrid *grid = [self->_grids objectForKey:gridID];
      if (grid != nil) {
        [grid clearText];
        
        [self->_changedGridIDs addObject:gridID];
      }
    };
    
    self->_nvims_ui.grid_cursor_goto = ^(int64_t grid, int64_t row, int64_t col) {
      self->_cursorGridID = grid;
      self->_cursorPosition = GridPointMake(col, row);
      
      CGSize cellSize = [self->_font cellSize];
      
      id cursorGridIDNumber = [NSNumber numberWithLongLong:self->_cursorGridID];
      id cursorGrid = [self->_grids objectForKey:cursorGridIDNumber];
      if (cursorGrid != nil) {
        GridPoint cursorOffset = [cursorGrid origin];
        GridPoint cursorPosition = GridPointMake(self->_cursorPosition.x + cursorOffset.x,
                                                 self->_cursorPosition.y + cursorOffset.y);
        
        self->_cursorLayerFrame = CGRectMake(cellSize.width * cursorPosition.x,
                                             cellSize.height * (self->_outerGridSize.height - cursorPosition.y - 1),
                                             cellSize.width,
                                             cellSize.height);
        self->_cursorLayerFrameChanged = true;
      };
    };
    
    self->_nvims_ui.grid_scroll = ^(int64_t cGridID, int64_t top, int64_t bot, int64_t left, int64_t right, int64_t rows, int64_t cols) {
      id gridID = [NSNumber numberWithLongLong:cGridID];
      
      NimsUIGrid *grid = [self->_grids objectForKey:gridID];
      if (grid == nil) {
        return;
      }
      
      int64_t width = right - left;
      int64_t height = bot - top;
      GridRect rect = GridRectMake(GridPointMake(left, top),
                                   GridSizeMake(width, height));
      
      GridPoint delta = GridPointMake(cols, rows);
      
      [grid scrollGrid:rect delta:delta];
      
      [self->_changedGridIDs addObject:gridID];
    };
    
    self->_nvims_ui.raw_line = ^(int64_t cGridID, int64_t y, int64_t startcol, int64_t endcol, int64_t clearcol, int64_t clearattr, int64_t flags, const nvim_schar_t *chunk, const nvim_sattr_t *attrs) {
      id gridID = [NSNumber numberWithLongLong:cGridID];
      
      NimsUIGrid *grid = [self->_grids objectForKey:gridID];
      if (grid == nil) {
        return;
      }
      
      int64_t length = endcol - startcol;
      int64_t x = startcol;
      
      NSMutableString *changedText = [[NSString stringWithCString:chunk[0] encoding:NSUTF8StringEncoding] mutableCopy];
      int64_t hlID = attrs[0];
      NSNumber *highlightID = [NSNumber numberWithLongLong:hlID];
      int64_t currentHighlightLength = [changedText length];
      
      for (int64_t i = 1; i < length; i++) {
        NSString *string = [NSString stringWithCString:chunk[i] encoding:NSUTF8StringEncoding];
        if (attrs[i] == hlID) {
          [changedText appendString:string];
          currentHighlightLength += [string length];
          
        } else {
          [grid setString:changedText withHighlightID:highlightID atIndex:x forRowAtY:y];
          
          [changedText setString:string];
          
          hlID = attrs[i];
          highlightID = [NSNumber numberWithLongLong:hlID];
          
          x += currentHighlightLength;
          currentHighlightLength = [string length];
        }
      }
      [grid setString:changedText withHighlightID:highlightID atIndex:x forRowAtY:y];
      
      if (clearcol > endcol) {
        id clearString = [@"" stringByPaddingToLength:clearcol - endcol - 1
                                           withString:@" "
                                      startingAtIndex:0];
        [grid setString:clearString
        withHighlightID:[NSNumber numberWithLongLong:clearattr]
                atIndex:x
              forRowAtY:y];
      }
      
      [self->_changedGridIDs addObject:gridID];
    };
    
    self->_nvims_ui.event = ^(char *cName, nvim_array_t args) {
      NSString *name = [NSString stringWithCString:cName encoding:NSUTF8StringEncoding];
      if ([name isEqualToString:@"win_pos"]) {
        int64_t cGridID = args.items[0].data.integer;
        NSNumber *gridID = [NSNumber numberWithLongLong:cGridID];
        NimsUIGrid *grid = [self->_grids objectForKey:gridID];
        
        int64_t start_row = args.items[2].data.integer;
        int64_t start_col = args.items[3].data.integer;
        [grid setOrigin:GridPointMake(start_col, start_row)];
        
        int64_t width = args.items[4].data.integer;
        int64_t height = args.items[5].data.integer;
        [grid setSize:GridSizeMake(width, height)];
        
        [grid setZPosition:self->_windowGridsZPositionCounter];
        self->_windowGridsZPositionCounter += 0.1;
        
        [grid setHidden:false];
        
        [self->_changedGridIDs addObject:gridID];
        
      } else if ([name isEqualToString:@"win_float_pos"]) {
        int64_t cGridID = args.items[0].data.integer;
        NSNumber *gridID = [NSNumber numberWithLongLong:cGridID];
        NimsUIGrid *grid = [self->_grids objectForKey:gridID];
        
        nvim_string_t anchor = args.items[2].data.string;
        [grid setNvimAnchor:anchor];
        
        int64_t cAnchorGridID = args.items[3].data.integer;
        NSNumber *anchorGridID = [NSNumber numberWithLongLong:cAnchorGridID];
        NimsUIGrid *anchorGrid = [self->_grids objectForKey:anchorGridID];
        
        int64_t anchor_row = floor(args.items[4].data.floating);
        int64_t anchor_col = floor(args.items[5].data.floating);
        GridPoint anchorOrigin = [anchorGrid origin];
        [grid setOrigin:GridPointMake(anchorOrigin.x + anchor_col,
                                      anchorOrigin.y + anchor_row)];
        
        [grid setZPosition:self->_floatingWindowGridsZPositionCounter];
        self->_floatingWindowGridsZPositionCounter += 0.1;
        
        [grid setHidden:false];
        
        [self->_changedGridIDs addObject:gridID];
        
      } else if ([name isEqualToString:@"win_close"]) {
        int64_t cGridID = args.items[0].data.integer;
        NSNumber *gridID = [NSNumber numberWithLongLong:cGridID];
        id grid = [self->_grids objectForKey:gridID];
        if (grid != nil) {
          [self->_removedLayers addObject:[grid layer]];
          [self->_grids removeObjectForKey:gridID];
        }
        
      } else if ([name isEqualToString:@"grid_destroy"]) {
        int64_t cGridID = args.items[0].data.integer;
        NSNumber *gridID = [NSNumber numberWithLongLong:cGridID];
        id grid = [self->_grids objectForKey:gridID];
        if (grid != nil) {
          [self->_removedLayers addObject:[grid layer]];
          [self->_grids removeObjectForKey:gridID];
        }
        
      } else if ([name isEqualToString:@"win_hide"]) {
        int64_t cGridID = args.items[0].data.integer;
        NSNumber *gridID = [NSNumber numberWithLongLong:cGridID];
        id grid = [self->_grids objectForKey:gridID];
        
        [grid setHidden:true];
        
        [self->_changedGridIDs addObject:gridID];
        
      } else {
        NSLog(@"Unknown nvims_ui.event with name: %@", name);
      }
    };
    
    self->_nvims_ui.msg_set_pos = ^(int64_t grid, int64_t row, _Bool scrolled, nvim_string_t sep_char) {
    };
    
    self->_nvims_ui.win_viewport = ^(int64_t grid, nvim_handle_t win, int64_t topline, int64_t botline, int64_t curline, int64_t curcol, int64_t line_count) {
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