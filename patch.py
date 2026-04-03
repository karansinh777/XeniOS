import codecs

path = r"c:\Users\Designer\Downloads\xeni os\source_code\src\xenia\ui\windowed_app_main_ios.mm"
with codecs.open(path, 'r', 'utf-8') as f:
    text = f.read()

# 1. Add #import "xeni_virtual_controller.mm" at the top
import_str = '#import "xeni_virtual_controller.mm"\n'
if import_str not in text:
    text = text.replace('#import <GameController/GameController.h>', '#import <GameController/GameController.h>\n' + import_str)

# 2. Add property
prop = '@property(nonatomic, strong) XeniVirtualControllerOverlay* virtualControllerOverlay;\n'
if prop not in text:
    text = text.replace('@property(nonatomic, assign) xe::ui::IOSWindowedAppContext* appContext;',
                        '@property(nonatomic, assign) xe::ui::IOSWindowedAppContext* appContext;\n' + prop)

# 3. Add to viewDidLoad
init_view = '''
  self.virtualControllerOverlay = [[XeniVirtualControllerOverlay alloc] initWithFrame:self.view.bounds];
  self.virtualControllerOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.virtualControllerOverlay.hidden = YES;
  [self.view addSubview:self.virtualControllerOverlay];
'''
if "self.virtualControllerOverlay =" not in text:
    text = text.replace('[self.view addSubview:self.metalView];', '[self.view addSubview:self.metalView];\n' + init_view)

# 4. Show/Hide properly.
if "self.virtualControllerOverlay.hidden = YES;" not in text:
    text = text.replace('self.launcherOverlay.hidden = NO;', 'self.launcherOverlay.hidden = NO;\n  self.virtualControllerOverlay.hidden = YES;')

if "self.virtualControllerOverlay.hidden = NO;" not in text:
    text = text.replace('self.launcherOverlay.hidden = YES;', 'self.launcherOverlay.hidden = YES;\n  self.virtualControllerOverlay.hidden = NO;')

# 5. Inject virtual controller data
inject_code = '''
  if (self.virtualControllerOverlay && !self.virtualControllerOverlay.hidden) {
      buttons |= self.virtualControllerOverlay.outButtons;
      out_state->gamepad.left_trigger = MAX(out_state->gamepad.left_trigger, self.virtualControllerOverlay.outLT);
      out_state->gamepad.right_trigger = MAX(out_state->gamepad.right_trigger, self.virtualControllerOverlay.outRT);
      if (self.virtualControllerOverlay.outThumbLX != 0) out_state->gamepad.thumb_lx = self.virtualControllerOverlay.outThumbLX;
      if (self.virtualControllerOverlay.outThumbLY != 0) out_state->gamepad.thumb_ly = self.virtualControllerOverlay.outThumbLY;
      if (self.virtualControllerOverlay.outThumbRX != 0) out_state->gamepad.thumb_rx = self.virtualControllerOverlay.outThumbRX;
      if (self.virtualControllerOverlay.outThumbRY != 0) out_state->gamepad.thumb_ry = self.virtualControllerOverlay.outThumbRY;
      
      out_state->packet_number = ++native_controller_packet_number_;
      out_state->gamepad.buttons = buttons;
      return YES;
  }
'''
if "self.virtualControllerOverlay.outButtons" not in text:
    text = text.replace('    out_state->packet_number = ++native_controller_packet_number_;', inject_code + '\n    out_state->packet_number = ++native_controller_packet_number_;')

with codecs.open(path, 'w', 'utf-8') as f:
    f.write(text)

print("Patched windowed_app_main_ios.mm with Virtual Controller Hooks!")
