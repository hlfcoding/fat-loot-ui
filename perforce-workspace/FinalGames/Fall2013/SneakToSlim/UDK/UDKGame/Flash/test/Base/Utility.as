package {

    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.system.fscommand;

    public class Utility {

        public static const reNumeric:RegExp = /^\d+$/;

        public function Utility() {}

        // System:

        public static function sendCommand(name:String, value:String=''):void {
            trace('[COMMAND]', name, value);
            fscommand('callConsoleCommand', name.concat(' ', value));
        }

        // Data:

        public static function pluck(items:Array, filterKey:String):Array {
            var results:Array = [];
            for each (var item in items) {
                for (var key:String in item) {
                    if (key === filterKey) {
                        results.push(item[key]);
                    }
                }
            }
            return results;
        }

        // View:

        public static function centerToStage(view:DisplayObject) {
            view.x = view.stage.stageWidth / 2;
            view.y = view.stage.stageHeight / 2;
        }

        public static function hideViewOverflow(view:DisplayObject):DisplayObject {
            var mask:Sprite = new Sprite();
            mask.graphics.beginFill(0xFFFFFF);
            mask.graphics.drawRect(0, 0, view.width, view.height);
            mask.graphics.endFill();
            mask.x = view.x;
            mask.y = view.y;
            view.mask = mask;
            return mask;
        }

    }
}
