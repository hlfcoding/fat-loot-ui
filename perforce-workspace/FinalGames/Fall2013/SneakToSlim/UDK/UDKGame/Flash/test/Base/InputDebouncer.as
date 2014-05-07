package {

    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;

    import scaleform.clik.core.UIComponent;

    public class InputDebouncer extends Timer {

        public var currentInput:UIComponent;
        public var handlerFunction:Function;

        public function InputDebouncer(handlerFunction:Function, delay:Number=500) {
            super(delay, 1);
            this.handlerFunction = handlerFunction;
        }

        public function addEventListeners():void {
            addEventListener(TimerEvent.TIMER_COMPLETE, debouncedFunction);
        }
        public function removeEventListeners():void {
            removeEventListener(TimerEvent.TIMER_COMPLETE, debouncedFunction);
        }

        public function debouncedFunction(event:Event):void {
            // On first change event, update.
            if (event.type !== TimerEvent.TIMER_COMPLETE && !running) {
                start();
                currentInput = event.target as UIComponent;
            // On subsequent change events, debounce.
            } else if (running) {
                return;
            // On debouncer completion, submit changes and reset.
            } else if (event.type === TimerEvent.TIMER_COMPLETE && currentInput != null) {
                handlerFunction(event);
                currentInput = null;
            }
        }

    }
}
