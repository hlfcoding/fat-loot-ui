package {

    import flash.system.fscommand;

    public class Utility {

        public function Utility() {}

        public static function sendCommand(name:String, endpoint:String, value:String=''):void {
            trace('[COMMAND]', name, endpoint, value);
            fscommand(name, endpoint.concat(' ', value));
        }

    }
}
