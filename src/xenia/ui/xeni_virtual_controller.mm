#import "xeni_virtual_controller.h"

#ifndef X_INPUT_GAMEPAD_DPAD_UP
#define X_INPUT_GAMEPAD_DPAD_UP         0x0001
#define X_INPUT_GAMEPAD_DPAD_DOWN       0x0002
#define X_INPUT_GAMEPAD_DPAD_LEFT       0x0004
#define X_INPUT_GAMEPAD_DPAD_RIGHT      0x0008
#define X_INPUT_GAMEPAD_START           0x0010
#define X_INPUT_GAMEPAD_BACK            0x0020
#define X_INPUT_GAMEPAD_LEFT_THUMB      0x0040
#define X_INPUT_GAMEPAD_RIGHT_THUMB     0x0080
#define X_INPUT_GAMEPAD_LEFT_SHOULDER   0x0100
#define X_INPUT_GAMEPAD_RIGHT_SHOULDER  0x0200
#define X_INPUT_GAMEPAD_A               0x1000
#define X_INPUT_GAMEPAD_B               0x2000
#define X_INPUT_GAMEPAD_X               0x4000
#define X_INPUT_GAMEPAD_Y               0x8000
#endif

// =========================================================
// XeniVirtualButton
// =========================================================
@implementation XeniVirtualButton {
    UIPanGestureRecognizer* _panGesture;
}

- (instancetype)initWithName:(NSString*)name mask:(uint16_t)mask position:(CGPoint)pos {
    if (self = [super initWithFrame:CGRectMake(0, 0, 60, 60)]) {
        self.center = pos;
        self.buttonMask = mask;
        self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.5];
        self.layer.cornerRadius = 30;
        self.layer.borderWidth = 2;
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.3].CGColor;
        
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.text = name;
        self.label.textColor = [UIColor whiteColor];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.font = [UIFont boldSystemFontOfSize:20];
        [self addSubview:self.label];
        
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = YES;
        
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        _panGesture.enabled = NO;
        [self addGestureRecognizer:_panGesture];
    }
    return self;
}

- (void)setIsEditMode:(BOOL)isEditMode {
    _isEditMode = isEditMode;
    _panGesture.enabled = isEditMode;
    self.layer.borderColor = isEditMode ? [UIColor greenColor].CGColor : [UIColor colorWithWhite:1.0 alpha:0.3].CGColor;
}

- (void)handlePan:(UIPanGestureRecognizer*)gesture {
    if (!_isEditMode) return;
    CGPoint translation = [gesture translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.superview];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (_isEditMode) return;
    self.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.7];
    if (self.delegate) [self.delegate virtualButtonPressed:self.buttonMask];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (_isEditMode) return;
    self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.5];
    if (self.delegate) [self.delegate virtualButtonReleased:self.buttonMask];
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}
@end

// =========================================================
// XeniVirtualJoystick
// =========================================================
@implementation XeniVirtualJoystick {
    UIView* _thumb;
    UIPanGestureRecognizer* _editPan;
    UITouch* _activeTouch;
    CGFloat _radius;
}

- (instancetype)initWithPosition:(CGPoint)pos isRight:(BOOL)isRight {
    if (self = [super initWithFrame:CGRectMake(0, 0, 140, 140)]) {
        self.center = pos;
        self.isRightJoystick = isRight;
        _radius = 70.0;
        
        self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.3];
        self.layer.cornerRadius = _radius;
        self.layer.borderWidth = 2;
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
        
        _thumb = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        _thumb.center = CGPointMake(_radius, _radius);
        _thumb.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
        _thumb.layer.cornerRadius = 25;
        [self addSubview:_thumb];
        
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = YES;
        
        _editPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        _editPan.enabled = NO;
        [self addGestureRecognizer:_editPan];
    }
    return self;
}

- (void)setIsEditMode:(BOOL)isEditMode {
    _isEditMode = isEditMode;
    _editPan.enabled = isEditMode;
    self.layer.borderColor = isEditMode ? [UIColor greenColor].CGColor : [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
}

- (void)handlePan:(UIPanGestureRecognizer*)gesture {
    if (!_isEditMode) return;
    CGPoint translation = [gesture translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.superview];
}

- (void)updateJoystickWithTouch:(UITouch*)touch {
    CGPoint loc = [touch locationInView:self];
    CGFloat dx = loc.x - _radius;
    CGFloat dy = loc.y - _radius;
    CGFloat dist = sqrt(dx*dx + dy*dy);
    
    CGFloat maxRadius = _radius - 15.0;
    if (dist > maxRadius) {
        dx = (dx / dist) * maxRadius;
        dy = (dy / dist) * maxRadius;
    }
    
    _thumb.center = CGPointMake(_radius + dx, _radius + dy);
    
    int16_t outX = (int16_t)((dx / maxRadius) * 32767.0);
    int16_t outY = (int16_t)((-dy / maxRadius) * 32767.0); // Up is positive
    
    if (self.delegate) {
        [self.delegate virtualJoystickUpdatedX:outX y:outY isRight:self.isRightJoystick];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (_isEditMode || _activeTouch) return;
    _activeTouch = [touches anyObject];
    [self updateJoystickWithTouch:_activeTouch];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (_isEditMode || !_activeTouch) return;
    if ([touches containsObject:_activeTouch]) {
        [self updateJoystickWithTouch:_activeTouch];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (_isEditMode || !_activeTouch) return;
    if ([touches containsObject:_activeTouch]) {
        _activeTouch = nil;
        [UIView animateWithDuration:0.2 animations:^{
            self->_thumb.center = CGPointMake(self->_radius, self->_radius);
        }];
        if (self.delegate) [self.delegate virtualJoystickUpdatedX:0 y:0 isRight:self.isRightJoystick];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}
@end


// =========================================================
// XeniVirtualControllerOverlay
// =========================================================
@implementation XeniVirtualControllerOverlay {
    NSMutableArray<XeniVirtualButton*>* _buttons;
    XeniVirtualJoystick* _leftStick;
    
    // Camera Pan handling
    UITouch* _cameraTouch;
    CGPoint _lastCameraTouchPos;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = YES;
        
        _buttons = [NSMutableArray array];
        
        // 1. Setup Camera Pan Area (Right side)
        _cameraPanArea = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width / 2, 0, frame.size.width / 2, frame.size.height)];
        _cameraPanArea.backgroundColor = [UIColor clearColor];
        _cameraPanArea.userInteractionEnabled = YES; // Handled manually in overlay's touchesMoved
        [self addSubview:_cameraPanArea];
        
        // 2. Setup Joystick
        _leftStick = [[XeniVirtualJoystick alloc] initWithPosition:CGPointMake(120, frame.size.height - 120) isRight:NO];
        _leftStick.delegate = self;
        [self addSubview:_leftStick];
        
        // 3. Setup Buttons (Xbox Layout)
        CGFloat rightX = frame.size.width - 150;
        CGFloat rightY = frame.size.height - 160;
        [self addButton:@"A" mask:X_INPUT_GAMEPAD_A position:CGPointMake(rightX, rightY + 70)];
        [self addButton:@"B" mask:X_INPUT_GAMEPAD_B position:CGPointMake(rightX + 70, rightY)];
        [self addButton:@"X" mask:X_INPUT_GAMEPAD_X position:CGPointMake(rightX - 70, rightY)];
        [self addButton:@"Y" mask:X_INPUT_GAMEPAD_Y position:CGPointMake(rightX, rightY - 70)];
        
        [self addButton:@"LB" mask:X_INPUT_GAMEPAD_LEFT_SHOULDER position:CGPointMake(80, 50)];
        [self addButton:@"RB" mask:X_INPUT_GAMEPAD_RIGHT_SHOULDER position:CGPointMake(frame.size.width - 80, 50)];
        
        // D-Pad (Just 4 small buttons for simplicity, placed like a cross)
        [self addButton:@"↑" mask:X_INPUT_GAMEPAD_DPAD_UP position:CGPointMake(120, frame.size.height - 250)];
        [self addButton:@"↓" mask:X_INPUT_GAMEPAD_DPAD_DOWN position:CGPointMake(120, frame.size.height - 150)];
        [self addButton:@"←" mask:X_INPUT_GAMEPAD_DPAD_LEFT position:CGPointMake(70, frame.size.height - 200)];
        [self addButton:@"→" mask:X_INPUT_GAMEPAD_DPAD_RIGHT position:CGPointMake(170, frame.size.height - 200)];
        
        // Start/Back
        [self addButton:@"VIEW" mask:X_INPUT_GAMEPAD_BACK position:CGPointMake(frame.size.width / 2 - 50, 40)];
        [self addButton:@"MENU" mask:X_INPUT_GAMEPAD_START position:CGPointMake(frame.size.width / 2 + 50, 40)];

        self.cameraSensitivity = 800.0;
        
        self.sensitivitySlider = [[UISlider alloc] initWithFrame:CGRectMake(frame.size.width / 2 - 100, 140, 200, 30)];
        self.sensitivitySlider.minimumValue = 100.0;
        self.sensitivitySlider.maximumValue = 3000.0;
        self.sensitivitySlider.value = self.cameraSensitivity;
        [self.sensitivitySlider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
        self.sensitivitySlider.hidden = YES;
        [self addSubview:self.sensitivitySlider];
        
        self.sensitivityLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width / 2 - 100, 170, 200, 20)];
        self.sensitivityLabel.text = @"Camera Sensitivity";
        self.sensitivityLabel.textColor = [UIColor whiteColor];
        self.sensitivityLabel.textAlignment = NSTextAlignmentCenter;
        self.sensitivityLabel.hidden = YES;
        [self addSubview:self.sensitivityLabel];

        // Edit Mode Button
        _editModeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _editModeButton.frame = CGRectMake(frame.size.width / 2 - 80, 90, 160, 40);
        [_editModeButton setTitle:@"Edit Controls" forState:UIControlStateNormal];
        [_editModeButton setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:0.8]];
        [_editModeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _editModeButton.layer.cornerRadius = 10;
        [_editModeButton addTarget:self action:@selector(toggleEditMode) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_editModeButton];
    }
    return self;
}

- (void)addButton:(NSString*)name mask:(uint16_t)mask position:(CGPoint)pos {
    XeniVirtualButton* b = [[XeniVirtualButton alloc] initWithName:name mask:mask position:pos];
    b.delegate = self;
    [_buttons addObject:b];
    [self addSubview:b];
}

- (void)sliderChanged:(UISlider*)slider {
    self.cameraSensitivity = slider.value;
}

- (void)toggleEditMode {
    self.isEditMode = !self.isEditMode;
    [_editModeButton setTitle:(self.isEditMode ? @"Finish Editing" : @"Edit Controls") forState:UIControlStateNormal];
    
    self.sensitivitySlider.hidden = !self.isEditMode;
    self.sensitivityLabel.hidden = !self.isEditMode;
    
    _leftStick.isEditMode = self.isEditMode;
    for (XeniVirtualButton* b in _buttons) {
        b.isEditMode = self.isEditMode;
    }
}

// Delegate methods
- (void)virtualButtonPressed:(uint16_t)mask {
    self.outButtons |= mask;
}
- (void)virtualButtonReleased:(uint16_t)mask {
    self.outButtons &= ~mask;
}
- (void)virtualJoystickUpdatedX:(int16_t)x y:(int16_t)y isRight:(BOOL)isRight {
    if (isRight) {
        self.outThumbRX = x; self.outThumbRY = y;
    } else {
        self.outThumbLX = x; self.outThumbLY = y;
    }
}

// Global touches for Camera Pan (Right-side background)
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.isEditMode) return;
    for (UITouch* t in touches) {
        // If touch is on right half and not hitting a specific button
        if (t.view == self || t.view == _cameraPanArea) {
            CGPoint loc = [t locationInView:self];
            if (loc.x >= self.bounds.size.width / 2.0 && !_cameraTouch) {
                _cameraTouch = t;
                _lastCameraTouchPos = loc;
            }
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.isEditMode || !_cameraTouch) return;
    if ([touches containsObject:_cameraTouch]) {
        CGPoint loc = [_cameraTouch locationInView:self];
        CGFloat dx = loc.x - _lastCameraTouchPos.x;
        CGFloat dy = loc.y - _lastCameraTouchPos.y;
        
        // Accumulate delta into right thumbstick simply
        // A real game engine uses look deltas, Xenia emulates an Xbox thumbstick.
        // We simulate pushing the stick in the direction of the drag.
        int16_t stickX = (int16_t)(dx * self.cameraSensitivity);
        int16_t stickY = (int16_t)(-dy * self.cameraSensitivity);
        
        self.outThumbRX = MAX((int16_t)-32767, MIN((int16_t)32767, stickX));
        self.outThumbRY = MAX((int16_t)-32767, MIN((int16_t)32767, stickY));
        
        _lastCameraTouchPos = loc;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.isEditMode || !_cameraTouch) return;
    if ([touches containsObject:_cameraTouch]) {
        _cameraTouch = nil;
        self.outThumbRX = 0;
        self.outThumbRY = 0;
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

// Pass-through layer: If a touch is in empty space on the left, maybe ignore it so underlying views get it?
// Actually, as an overlay, we WANT to capture gameplay touches.
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self && point.x < self.bounds.size.width / 2) {
        // Let touches on the left background pass through just in case
        return nil; 
    }
    return hitView;
}

@end
