package {

    import flash.system.fscommand;

    public class Utility {

        public function Utility() {}

        public static function sendCommand(name:String, value:String=''):void {
            trace('[COMMAND]', name, value);
            // NOTE: The below needs to be disabled for a preview build.
            fscommand('callConsoleCommand', name.concat(' ', value));
        }

    }
}
