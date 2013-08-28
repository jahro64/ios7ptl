//
//  PathTextContainer.m
//  CircleLayout
//
//  Created by Rob Napier on 8/27/13.
//  Copyright (c) 2013 Rob Napier. All rights reserved.
//

#import "PathTextContainer.h"

@implementation PathTextContainer

CGRect clipRectToPath(CGRect rect, CGPathRef path, CGRect *remainingRect) {
  size_t width = floorf(rect.size.width);
  size_t height = floorf(rect.size.height);
  uint8_t *bits = calloc(width * height, sizeof(*bits));
  CGContextRef bitmapContext =
  CGBitmapContextCreate(bits,
                        width,
                        height,
                        sizeof(*bits) * 8,
                        width,
                        NULL,
                        (CGBitmapInfo)kCGImageAlphaOnly);
  CGContextSetShouldAntialias(bitmapContext, NO);

  CGContextTranslateCTM(bitmapContext, -rect.origin.x, -rect.origin.y);
  CGContextAddPath(bitmapContext, path);
  CGContextFillPath(bitmapContext);

  BOOL foundStart = NO;
  NSRange range = NSMakeRange(0, 0);
  NSUInteger column = 0;
  for (; column < width; ++column) {
    BOOL isGoodColumn = YES;
    for (NSUInteger y = 0; y < height; ++y) {
      if (bits[y * width + column] < 128) {
        isGoodColumn = NO;
        break;
      }
    }

    if (isGoodColumn && ! foundStart) {
      foundStart = YES;
      range.location = rect.origin.x + column;
    }
    else if (!isGoodColumn && foundStart) {
      break;
    }
  }

  if (foundStart) {
    // x is 1 past the last full-height column
    range.length = rect.origin.x + column - range.location - 1;

    if (remainingRect) {
      *remainingRect = CGRectMake(rect.origin.x + column, CGRectGetMinY(rect),
                                  CGRectGetWidth(rect) - NSMaxRange(range) - 1,
                                  CGRectGetHeight(rect));
    }
  }

  CGContextRelease(bitmapContext);
  free(bits);

  CGRect clipRect =
  CGRectMake(range.location, rect.origin.y,
             range.length, rect.size.height);
  return clipRect;
}

- (CGRect)lineFragmentRectForProposedRect:(CGRect)proposedRect
                                  atIndex:(NSUInteger)characterIndex
                         writingDirection:(NSWritingDirection)baseWritingDirection
                            remainingRect:(CGRect *)remainingRect {
  CGRect rect = [super lineFragmentRectForProposedRect:proposedRect
                                               atIndex:characterIndex
                                      writingDirection:baseWritingDirection
                                         remainingRect:remainingRect];
  if (self.inclusionPaths) {
    CGMutablePathRef path = CGPathCreateMutable();
    for (UIBezierPath *inclusionPath in self.inclusionPaths) {
      CGPathAddPath(path, NULL, inclusionPath.CGPath);
    }

    CGRect boundingBox = CGPathGetPathBoundingBox(path);
    rect = CGRectIntersection(boundingBox, rect);
    if (! CGRectIsEmpty(rect)) {
      rect = clipRectToPath(rect, path, remainingRect);
    }
  }

  return rect;
}

@end