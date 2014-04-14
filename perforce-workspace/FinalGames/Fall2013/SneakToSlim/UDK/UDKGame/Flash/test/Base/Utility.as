package {

    import flash.system.fscommand;

    public class Utility {

        public static const reNumeric:RegExp = /^\d+$/;

        public function Utility() {}

        public static function sendCommand(name:String, value:String=''):void {
            trace('[COMMAND]', name, value);
            fscommand('callConsoleCommand', name.concat(' ', value));
        }

    }
}
