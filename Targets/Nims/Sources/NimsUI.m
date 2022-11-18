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
#import "MainLayer.h"
#import "MainWindow.h"

#define STRING(arg) [[NSString alloc] initWithBytes:arg.data length:arg.size encoding:NSUTF8StringEncoding]

#define GRIDS_CAPACITY 128

static void *ViewLayerContentsScaleContext = &ViewLayerContentsScaleContext;

@implementation NimsUI {
  GridSize _outerGridSize;
  NimsFont *_font;
  NimsUIHighlights *_highlights;
  
  NSMutableDictionary<NSNumber *, NimsUIGrid *> *_grids;
  MainLayer *_mainLayer;
  MainWindow *_mainWindow;
  
  NSMutableSet<NSNumber *> *_idsOfGridsWithChangedFrame;
  NSMutableDictionary<NSNumber *, NSMutableSet<NSNumber *> *> *_ysOfGridsWithChangedText;
  BOOL _windowInitiallyOrderedFront;
  BOOL _highlightsUpdated;
  
  nvims_ui_t _nvims_ui;
}

- (instancetype)init
{
  self = [super init];
  if (self != nil) {
    self->_outerGridSize = GridSizeMake(110, 40);
    
    self->_font = [[NimsFont alloc] initWithFont:[NSFont fontWithName:@"MesloLGS NF" size:13]];
    self->_grids = [[NSMutableDictionary alloc] initWithCapacity:GRIDS_CAPACITY];
    self->_highlights = [[NimsUIHighlights alloc] init];
    
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
    id mainWindow = [[MainWindow alloc] initWithContentRect:contentRect
                                                  styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                                                    backing:NSBackingStoreBuffered
                                                      defer:true];
    [mainWindow setContentView:mainView];
    [mainWindow setCellSize:[self->_font cellSize]];
    self->_mainWindow = mainWindow;
    
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
        
        if (self->_highlightsUpdated) {
          [self->_grids enumerateKeysAndObjectsUsingBlock:^(NSNumber *gridID, NimsUIGrid *grid, BOOL *stop) {
            [grid highlightsUpdated];
            
            [self->_mainLayer setBackgroundColor:[grid backgroundColor] forGridWithID:gridID];
            
            NSMutableArray<NSValue *> *rowFrames = [@[] mutableCopy];
            for (NimsUIGridRow *row in [grid rows]) {
              NSValue *value = [NSValue valueWithRect:[row layerFrame]];
              [rowFrames addObject:value];
            }
            
            [self->_mainLayer setFrame:[grid layerFrame]
                          andRowFrames:[rowFrames copy]
                         forGridWithID:gridID];
            
            [[grid rows] enumerateObjectsUsingBlock:^(NimsUIGridRow *row, NSUInteger index, BOOL *stop) {
              [self->_mainLayer setRowAttributedString:[row attributedString]
                                                   atY:index
                                         forGridWithID:gridID];
            }];
          }];
          
        } else {
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
          
          [self->_ysOfGridsWithChangedText enumerateKeysAndObjectsUsingBlock:^(NSNumber *gridID, NSMutableSet<NSNumber *> *ys, BOOL *stop) {
            NimsUIGrid *grid = [self->_grids objectForKey:gridID];
            
            for (NSNumber *yNumber in ys) {
              int64_t y = [yNumber longLongValue];
              NimsUIGridRow *row = [[grid rows] objectAtIndex:y];
              [self->_mainLayer setRowAttributedString:[row attributedString]
                                                   atY:y
                                         forGridWithID:gridID];
            }
          }];
        }
        
        [CATransaction commit];
        
        if (!self->_windowInitiallyOrderedFront) {
          [self->_mainWindow orderFront:nil];
          
          self->_windowInitiallyOrderedFront = true;
        }
        
        [self->_idsOfGridsWithChangedFrame removeAllObjects];
        [self->_ysOfGridsWithChangedText removeAllObjects];
        self->_highlightsUpdated = false;
      });
    };
    
    self->_nvims_ui.suspend = ^() {
    };
    
    self->_nvims_ui.set_title = ^(nvim_string_t cTitle) {
      NSString *title = STRING(cTitle);
      
      dispatch_sync(dispatch_get_main_queue(), ^{
        [self->_mainWindow setTitle:title];
      });
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
      
      HighlightAttributes *attributes = [[HighlightAttributes alloc] initWithFlags:0
                                                                      rgbForegound:(int32_t)rgb_fg
                                                                     rgbBackground:(int32_t)rgb_bg
                                                                        rgbSpecial:(int32_t)rgb_sp
                                                                   ctermForeground:(int32_t)cterm_fg
                                                                   ctermBackground:(int32_t)cterm_bg
                                                                             blend:100];
      [self->_highlights setDefaultAttributes:attributes];
    };
    
    self->_nvims_ui.hl_attr_define = ^(int64_t _id, nvim_hl_attrs_t rgb_attrs, nvim_hl_attrs_t cterm_attrs, nvim_array_t info) {
      self->_highlightsUpdated = true;
      
      HighlightAttributes *attributes = [[HighlightAttributes alloc] initWithFlags:rgb_attrs.rgb_ae_attr
                                                                      rgbForegound:rgb_attrs.rgb_fg_color
                                                                     rgbBackground:rgb_attrs.rgb_bg_color
                                                                        rgbSpecial:rgb_attrs.rgb_sp_color
                                                                   ctermForeground:rgb_attrs.cterm_fg_color
                                                                   ctermBackground:rgb_attrs.cterm_bg_color
                                                                             blend:rgb_attrs.hl_blend];
      [self->_highlights setAttributes:attributes forID:_id];
    };
    
    self->_nvims_ui.hl_group_set = ^(nvim_string_t cName, int64_t _id) {
      id name = [NSString stringWithCString:cName.data encoding:NSUTF8StringEncoding];
      [self->_highlights setName:name forID:_id];
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
        [self->_grids setObject:grid forKey:_id];
        
      } else {
        [grid setSize:size];
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
    
    self->_nvims_ui.raw_line = ^(int64_t cGridID, int64_t y, int64_t startcol, int64_t endcol, int64_t clearcol, int64_t clearattr, int64_t flags, const nvim_schar_t *chunk, const nvim_sattr_t *attrs) {
      id gridID = [NSNumber numberWithInteger:cGridID];
      
      NimsUIGrid *grid = [self->_grids objectForKey:gridID];
      if (grid == nil) {
        NSLog(@"nvims_ui.raw_line called for unexisting grid with id: %@", gridID);
        return;
      }
      
      NimsUIGridRow *row = [[grid rows] objectAtIndex:y];
      
      int64_t length = endcol - startcol;
      int64_t x = startcol;
      
      NSMutableString *changedText = [[NSString stringWithCString:chunk[0] encoding:NSUTF8StringEncoding] mutableCopy];
      int64_t highlightID = attrs[0];
      int64_t currentHighlightLength = [changedText length];
      
      for (int64_t i = 1; i < length; i++) {
        NSString *string = [NSString stringWithCString:chunk[i] encoding:NSUTF8StringEncoding];
        if (attrs[i] == highlightID) {
          [changedText appendString:string];
          currentHighlightLength += [string length];
          
        } else {
          [row applyChangedText:changedText
                withHighlightID:highlightID
                    startingAtX:x];
          
          [changedText setString:string];
          highlightID = attrs[i];
          
          x += currentHighlightLength;
          currentHighlightLength = [string length];
        }
      }
      [row applyChangedText:changedText
            withHighlightID:highlightID
                startingAtX:x];
      
      if (clearcol > endcol) {
        id clearString = [@"" stringByPaddingToLength:clearcol - endcol withString:@" " startingAtIndex:0];
        [row applyChangedText:clearString withHighlightID:clearattr startingAtX:endcol];
      }
      
      NSMutableSet<NSNumber *> *ys = [self->_ysOfGridsWithChangedText objectForKey:gridID];
      if (ys == nil) {
        ys = [[NSSet set] mutableCopy];
        [self->_ysOfGridsWithChangedText setObject:ys forKey:gridID];
      }
      [ys addObject:[NSNumber numberWithLongLong:y]];
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
        
        [self->_idsOfGridsWithChangedFrame addObject:gridID];
        
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
        
        [self->_idsOfGridsWithChangedFrame addObject:gridID];
        
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
