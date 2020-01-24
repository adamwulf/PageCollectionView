//
//  ViewController.m
//  PinchTest
//
//  Created by Adam Wulf on 1/24/20.
//  Copyright © 2020 Milestone Made. All rights reserved.
//

#import "ViewController.h"
#import <PageCollectionView/PageCollectionView.h>


@interface ViewController ()

@property(nonatomic, strong) MMPinchVelocityGestureRecognizer *pinchGesture;
@property(nonatomic, strong) UIView *redDot;
@property(nonatomic, strong) UIView *greenDot;
@property(nonatomic, strong) UIView *orangeDot;
@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _pinchGesture = [[MMPinchVelocityGestureRecognizer alloc] initWithTarget:self action:@selector(didPinch:)];

    [[self view] addGestureRecognizer:_pinchGesture];

    _redDot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [[_redDot layer] setCornerRadius:10];
    [_redDot setBackgroundColor:[UIColor redColor]];
    [_redDot setHidden:YES];
    [[self view] addSubview:_redDot];

    _orangeDot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [_orangeDot setHidden:YES];
    [[_orangeDot layer] setCornerRadius:10];
    [_orangeDot setBackgroundColor:[UIColor orangeColor]];
    [[self view] addSubview:_orangeDot];

    _greenDot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [_greenDot setHidden:YES];
    [[_greenDot layer] setCornerRadius:10];
    [_greenDot setBackgroundColor:[UIColor greenColor]];
    [[self view] addSubview:_greenDot];
}

- (void)didPinch:(MMPinchVelocityGestureRecognizer *)pinchGesture
{
    if ([pinchGesture state] == UIGestureRecognizerStateBegan) {
        [_redDot setHidden:NO];
        [_greenDot setHidden:NO];
        [_orangeDot setHidden:NO];
    }

    [_redDot setCenter:[pinchGesture oldLocationInView:[self view]]];
    [_orangeDot setCenter:[pinchGesture firstLocationInView:[self view]]];
    [_greenDot setCenter:[pinchGesture locationInView:[self view]]];

    NSLog(@"=====");
    NSLog(@"adjustment: %@", NSStringFromCGPoint([pinchGesture adjustment]));

    if ([pinchGesture state] == UIGestureRecognizerStateEnded || [pinchGesture state] == UIGestureRecognizerStateFailed || [pinchGesture state] == UIGestureRecognizerStateCancelled) {
        [_redDot setHidden:YES];
        [_greenDot setHidden:YES];
        [_orangeDot setHidden:YES];
    }
}

@end
