package {

    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.ui.Mouse;

    public class Cursor extends MovieClip {

        public function Cursor() {
            if (!MainMenuView.DEBUG) {
                Mouse.hide();
            }
            mouseEnabled = false;
            addEventListener(Event.ENTER_FRAME, enterFrameHandler);
        }

        public function enterFrameHandler(event:Event):void {
            var screen:MovieClip = root as MovieClip;
            x = screen.mouseX;
            y = screen.mouseY;
        }

    }

}
