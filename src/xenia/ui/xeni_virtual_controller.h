#pragma once
#import <UIKit/UIKit.h>

// Simple delegate to report events
@protocol XeniVirtualButtonDelegate <NSObject>
- (void)virtualButtonPressed:(uint16_t)mask;
- (void)virtualButtonReleased:(uint16_t)mask;
@end

@interface XeniVirtualButton : UIView
@property (nonatomic, assign) uint16_t buttonMask;
@property (nonatomic, strong) UILabel* label;
@property (nonatomic, weak) id<XeniVirtualButtonDelegate> delegate;
@property (nonatomic, assign) BOOL isEditMode;
- (instancetype)initWithName:(NSString*)name mask:(uint16_t)mask position:(CGPoint)pos;
@end

@protocol XeniVirtualJoystickDelegate <NSObject>
- (void)virtualJoystickUpdatedX:(int16_t)x y:(int16_t)y isRight:(BOOL)isRight;
@end

@interface XeniVirtualJoystick : UIView
@property (nonatomic, weak) id<XeniVirtualJoystickDelegate> delegate;
@property (nonatomic, assign) BOOL isEditMode;
@property (nonatomic, assign) BOOL isRightJoystick;
- (instancetype)initWithPosition:(CGPoint)pos isRight:(BOOL)isRight;
@end


@interface XeniVirtualControllerOverlay : UIView <XeniVirtualButtonDelegate, XeniVirtualJoystickDelegate>

@property (nonatomic, assign) BOOL isEditMode;

// Output State buffer
@property (nonatomic, assign) uint16_t outButtons;
@property (nonatomic, assign) uint8_t outLT;
@property (nonatomic, assign) uint8_t outRT;
@property (nonatomic, assign) int16_t outThumbLX;
@property (nonatomic, assign) int16_t outThumbLY;
@property (nonatomic, assign) int16_t outThumbRX;
@property (nonatomic, assign) int16_t outThumbRY;

@property (nonatomic, strong) UIButton* editModeButton;
@property (nonatomic, strong) UIView* cameraPanArea;

@property (nonatomic, assign) CGFloat cameraSensitivity;
@property (nonatomic, strong) UISlider* sensitivitySlider;
@property (nonatomic, strong) UILabel* sensitivityLabel;

- (void)toggleEditMode;

@end
