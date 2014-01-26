package {

    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.ui.Mouse;

    public class Cursor extends MovieClip {

        public function Cursor() {
            Mouse.hide();
            mouseEnabled = false;
            addEventListener(Event.ENTER_FRAME, enterFrameHandler);
        }

        public function enterFrameHandler(event:Event):void {
            var screen:MovieClip = MovieClip(root);
            x = screen.mouseX;
            y = screen.mouseY;
        }

    }

}
