//
//  TUCalendarDayView.m
//  tutu
//
//  Created by Иван Смолин on 20/10/15.
//  Copyright © 2015 Touch Instinct. All rights reserved.
//

#import <UIColor_Hex/UIColor+Hex.h>
#import "TUCalendarDayView.h"
#import "UIImage+ImageDrawing.h"
#import "UIImage+RoundedCorners.h"

static CGFloat const kBackgroundImageViewHeight = 36.f;
static CGFloat const kDayButtonTodayLabelVerticalSpace = - 6.f;
static CGFloat const kTodayLabelHeight = 12.f;


@implementation TUCalendarDayViewState

- (id)copyWithZone:(NSZone *)zone {
    TUCalendarDayViewState *copyOfMe = [TUCalendarDayViewState new];
    copyOfMe.dateInMonth = self.dateInMonth;
    copyOfMe.selectionOptions = self.selectionOptions;
    copyOfMe.isInvisibleDay = self.isInvisibleDay;
    copyOfMe.isOldDay = self.isOldDay;
    copyOfMe.isToday = self.isToday;

    return copyOfMe;
}

- (BOOL)isLeftBackgroundViewShown {
    return self.selectionOptions & TUCalendarDayViewSelectionLeftFull;
}

- (BOOL)isRightBackgroundViewShown {
    return self.selectionOptions & TUCalendarDayViewSelectionRightFull;
}

@end


@implementation TUCalendarDayViewAppearance

- (instancetype)init {
    self = [super init];

    if (self) {
        self.selectedBackgroundColor = [UIColor colorWithHex:0xE5F4FF];

        self.highlightedBackgroundImage = [TUCalendarDayViewAppearance backgroundImageWithColor:[UIColor colorWithHex:0x0099FF]];
        self.selectedBackgroundImage = [TUCalendarDayViewAppearance backgroundImageWithColor:self.selectedBackgroundColor];
        
        self.titleFont = [UIFont systemFontOfSize:18.f];
        self.titleColor = [UIColor colorWithHex:0x6D7F8D];
        self.hightlightedTitleColor = [UIColor whiteColor];
        self.disabledTitleColor = [UIColor colorWithHex:0xD1DAE1];
        self.rangeTitleColor = self.titleColor;
        
        self.todayTitleFont = [UIFont systemFontOfSize:10.f weight:UIFontWeightLight];
        self.todayTitleColor = [UIColor colorWithHex:0x91A7B8];
        NSString *todayString = NSLocalizedString(@"common_calendar_word_today", @"cегодня");
        self.todayText = todayString ? todayString : @"today";
        self.isTodaySelected = NO;

        self.backgroundColor = [UIColor whiteColor];
    }

    return self;
}

+ (UIImage *)backgroundImageWithColor:(UIColor *)color {
    UIImage *backgroundImage = [UIImage imageWithColor:color
                                               andSize:CGSizeMake(kBackgroundImageViewHeight, kBackgroundImageViewHeight)];

    return [backgroundImage circleImage];
}

@end


@interface TUCalendarDayView ()

@property (weak, nonatomic) UIButton *dayButton;
@property (weak, nonatomic) UIImageView *backgroundImageView;

@property (weak, nonatomic) UILabel *todayLabel;

@property (weak, nonatomic) UIView *leftBackgroundView;
@property (weak, nonatomic) UIView *rightBackgroundView;

@property (strong, nonatomic) TUCalendarDayViewState *currentState;

@end

@implementation TUCalendarDayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self createViews];

        [self.dayButton addTarget:self action:@selector(dayButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [self.dayButton addTarget:self action:@selector(updateBackgroundForButtonState) forControlEvents:UIControlEventAllEvents];
    }
    
    return self;
}

- (void)createViews {
    UIView *leftBackgroundView = [UIView new];
    [self addSubview:leftBackgroundView];
    self.leftBackgroundView = leftBackgroundView;
    
    UIView *rightBackgroundView = [UIView new];
    [self addSubview:rightBackgroundView];
    self.rightBackgroundView = rightBackgroundView;
    
    UIImageView *backgroundImageView = [UIImageView new];
    [self addSubview:backgroundImageView];
    self.backgroundImageView = backgroundImageView;
    
    UIButton *dayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:dayButton];
    self.dayButton = dayButton;
    
    UILabel *todayLabel = [UILabel new];
    todayLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:todayLabel];
    self.todayLabel = todayLabel;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect leftBackgroundViewFrame = self.bounds;
    leftBackgroundViewFrame.size.width /= 2.f;
    self.leftBackgroundView.frame = leftBackgroundViewFrame;
    
    CGRect rightBackgroundViewFrame = leftBackgroundViewFrame;
    rightBackgroundViewFrame.origin.x += rightBackgroundViewFrame.size.width;
    self.rightBackgroundView.frame = rightBackgroundViewFrame;

    CGSize size = self.frame.size;
    
    self.backgroundImageView.frame = CGRectMake(0.f, 0.f, kBackgroundImageViewHeight, kBackgroundImageViewHeight);
    self.backgroundImageView.center = CGPointMake(size.width / 2.f, size.height / 2.f);
    
    self.dayButton.frame = self.bounds;
    
    CGRect todayLabelFrame = CGRectMake(0.f, CGRectGetMaxY(self.dayButton.frame) + kDayButtonTodayLabelVerticalSpace, size.width, kTodayLabelHeight);
    self.todayLabel.frame = todayLabelFrame;
}

- (void)dayButtonTouchUpInside:(UIButton *)sender {
    [self.delegate calendarDayView:self didSelectDate:self.date];
}

- (void)setState:(TUCalendarDayViewState *)state {
    self.currentState = state;

    if (!self.dayViewAppearance) {
        self.dayViewAppearance = [TUCalendarDayViewAppearance new];
    }

    self.dayButton.selected = NO;
    self.dayButton.highlighted = NO;
    self.dayButton.enabled = NO;

    if (state.isInvisibleDay) {
        [self.dayButton setTitle:@"" forState:UIControlStateDisabled];
    } else if (state.isOldDay) {
        [self.dayButton setTitle:state.dateInMonth forState:UIControlStateDisabled];
    } else {
        [self.dayButton setTitle:state.dateInMonth forState:UIControlStateNormal];
        [self.dayButton setTitle:state.dateInMonth forState:UIControlStateSelected];
        [self.dayButton setTitle:state.dateInMonth forState:UIControlStateHighlighted];

        self.dayButton.enabled = YES;
    }

    self.todayLabel.hidden = !state.isToday || state.isInvisibleDay;

    [self updateDayButtonState];
    [self updateBackgroundForState:state];

    self.leftBackgroundView.hidden = !state.isLeftBackgroundViewShown;
    self.rightBackgroundView.hidden = !state.isRightBackgroundViewShown;

    [self configureTextRangeColorForRangeState:[self isTextHeighlighted]];
}

- (void)updateDayButtonState {
    if (!self.currentState.isOldDay && self.currentState != nil) {
        BOOL overlapsTodayLabel = self.currentState.selectionOptions & TUCalendarDayViewSelectionDate
        || self.currentState.selectionOptions & TUCalendarDayViewSelectionDateStrong;

        self.todayLabel.hidden = self.todayLabel.hidden || overlapsTodayLabel;


        if (self.currentState.selectionOptions == TUCalendarDayViewSelectionNone) {
            self.dayButton.selected = NO;
            self.dayButton.highlighted = NO;
        } else if (!self.currentState.isInvisibleDay) {
            if (self.currentState.selectionOptions & TUCalendarDayViewSelectionDateStrong) {
                self.dayButton.highlighted = YES;
            } else if (self.currentState.selectionOptions & TUCalendarDayViewSelectionDate) {
                self.dayButton.selected = YES;
            }
        }
    }
}

- (BOOL)isTextHeighlighted {
    return self.currentState.isLeftBackgroundViewShown || self.currentState.isRightBackgroundViewShown ||
    self.dayButton.state & UIControlStateHighlighted || self.dayButton.state & UIControlStateSelected ||
    [self shouldShowTodaySelectedForState:self.currentState];
}

- (BOOL)shouldShowTodaySelectedForState:(TUCalendarDayViewState *)state {
    return state.isToday && !state.isInvisibleDay && self.dayViewAppearance.isTodaySelected;
}

- (void)configureTextRangeColorForRangeState:(BOOL)isRangeState {
    if (isRangeState) {
        [self.dayButton setTitleColor:self.dayViewAppearance.rangeTitleColor forState:UIControlStateNormal];
    } else {
        [self.dayButton setTitleColor:self.dayViewAppearance.titleColor forState:UIControlStateNormal];
    }
}

- (void)setDayViewAppearance:(TUCalendarDayViewAppearance *)dayViewAppearance {
    _dayViewAppearance = dayViewAppearance;

    self.leftBackgroundView.backgroundColor = self.dayViewAppearance.selectedBackgroundColor;
    self.rightBackgroundView.backgroundColor = self.dayViewAppearance.selectedBackgroundColor;

    self.dayButton.titleLabel.font = self.dayViewAppearance.titleFont;
    [self.dayButton setTitleColor:self.dayViewAppearance.hightlightedTitleColor forState:UIControlStateHighlighted];
    [self.dayButton setTitleColor:self.dayViewAppearance.disabledTitleColor forState:UIControlStateDisabled];
    [self configureTextRangeColorForRangeState:[self isTextHeighlighted]];

    self.todayLabel.font = self.dayViewAppearance.todayTitleFont;
    self.todayLabel.textColor = self.dayViewAppearance.todayTitleColor;
    self.todayLabel.text = dayViewAppearance.todayText;

    self.backgroundColor = self.dayViewAppearance.backgroundColor;
}

- (void)updateBackgroundForButtonState {
    UIControlState buttonState = self.dayButton.state;

    if (!(buttonState & UIControlStateHighlighted || buttonState & UIControlStateSelected)) {
        [self updateDayButtonState];
        buttonState = self.dayButton.state;
    }

    if (buttonState & UIControlStateHighlighted) {
        self.backgroundImageView.image = self.dayViewAppearance.highlightedBackgroundImage;
        [self configureTextRangeColorForRangeState:[self isTextHeighlighted]];
    } else if (buttonState & UIControlStateSelected) {
        self.backgroundImageView.image = self.dayViewAppearance.selectedBackgroundImage;
        [self configureTextRangeColorForRangeState:[self isTextHeighlighted]];
    } else {
        self.backgroundImageView.image = nil;
        [self configureTextRangeColorForRangeState:[self isTextHeighlighted]];
    }
}

- (void)updateBackgroundForState:(TUCalendarDayViewState *)state {
    if ([self shouldShowTodaySelectedForState:state]) {
        self.backgroundImageView.image = self.dayViewAppearance.selectedBackgroundImage;
        [self configureTextRangeColorForRangeState:YES];
    } else {
        [self updateBackgroundForButtonState];
    }
}

@end
