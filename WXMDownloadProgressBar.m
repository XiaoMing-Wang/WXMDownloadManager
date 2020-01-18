//
//  WXMDownloadProgressBar.m
//  TianMiMi
//
//  Created by wq on 2019/12/15.
//  Copyright © 2019 sdjgroup. All rights reserved.
//

#import "WXMDownloadProgressBar.h"

@implementation WXMDownloadProgressBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.alpha = 0;
        self.radius = 20;
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wimplicit-retain-self"
- (void)setProgress:(CGFloat)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        _progress = MAX(0, MIN(progress, 1));
        [self setNeedsDisplay];
        self.hidden = (_progress == 0);
        if (_progress < 1 && self.alpha == 0) self.alpha = 1;
        if (_progress == 1) {
            [UIView animateWithDuration:0.6 animations:^{ self.alpha = 0; }];
        }
    });
}
#pragma clang diagnostic pop

- (void)drawRect:(CGRect)rect {
    [[UIColor colorWithWhite:0 alpha:0.1] set];
    
    CGPoint point = CGPointMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0);
    UIBezierPath *backgroundPath = [UIBezierPath bezierPathWithArcCenter:point
                                                                  radius:self.radius
                                                              startAngle:-M_PI_2
                                                                endAngle:2 * M_PI - M_PI_2
                                                               clockwise:YES];
    [backgroundPath fill];
    
    
    [[UIColor colorWithWhite:1 alpha:0.9] set];
    [backgroundPath addArcWithCenter:point
                              radius:self.radius
                          startAngle:-M_PI_2
                            endAngle:2 * M_PI - M_PI_2
                           clockwise:YES];
    [backgroundPath stroke];
    
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:point
                                                        radius:self.radius - 2
                                                    startAngle:-M_PI_2
                                                      endAngle:self.progress*2 * M_PI - M_PI_2
                                                     clockwise:YES];
    [path addLineToPoint:point];
    [path fill];
}


@end
