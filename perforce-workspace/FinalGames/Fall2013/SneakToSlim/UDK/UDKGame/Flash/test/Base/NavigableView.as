package {

    import flash.display.DisplayObjectContainer;
    import flash.display.MovieClip;
    import flash.utils.getDefinitionByName;

    import scaleform.clik.controls.Button;
    import scaleform.clik.events.ButtonEvent;

    public class NavigableView extends MovieClip {

        public static const TRANSITION_DEFAULT:String = 'default';

        public var defaultTransition:String;

        protected var _navigationStack:Vector.<MovieClip>;

        public function NavigableView() {
            super();
            _navigationStack = new <MovieClip>[];
            defaultTransition = NavigableView.TRANSITION_DEFAULT;
        }

        public function load(className:String, propertyName:String=null):MovieClip {
            var classRef:Class;
            var view:MovieClip;
            var shouldAutoAssign:Boolean = propertyName != null;
            if (shouldAutoAssign && this[propertyName] != null) {
                return this[propertyName];
            }
            try {
                classRef = getDefinitionByName(className) as Class;
            } catch (error:*) {
                throw new Error('No view class named: ' + className);
            }
            view = new classRef();
            if (shouldAutoAssign) {
                this[propertyName] = view;
            }
            for each (var button:Button in view.navigationButtons) {
                button.addEventListener(ButtonEvent.CLICK, handleNavigationRequest);
            }
            return view;
        }
        public function teardownView(view:MovieClip):void {}

        public function get currentView():MovieClip { return _navigationStack[_navigationStack.length - 1]; }
        public function get previousView():MovieClip { return _navigationStack[_navigationStack.length - 2]; }

        public function get rootView():MovieClip { return _navigationStack[0]; }
        public function set rootView(value:MovieClip):void {
            _navigationStack[0] = value;
            navigate(value);
        }

        public function handleNavigationRequest(sender:Object):void {}

        public function navigate(toView:MovieClip, fromView:MovieClip=null, transition:String=null):Boolean {
            if (fromView == null && currentView != rootView) {
                fromView = currentView;
            }
            if (transition == null) {
                transition = defaultTransition;
            }
            // Update stack and buttons.
            var toViewIndex:int = _navigationStack.indexOf(toView);
            // Popping.
            if (toViewIndex !== -1 && toViewIndex !== _navigationStack.length - 1) {
                _navigationStack.splice(toViewIndex + 1, _navigationStack.length - (toViewIndex + 1));
                if (fromView != null && fromView.navigationBackButton != null) {
                    fromView.navigationBackButton.removeEventListener(ButtonEvent.CLICK, navigateBack);
                }
            // Pushing.
            } else {
                _navigationStack.push(toView);
                if (toView.navigationBackButton != null) {
                    toView.navigationBackButton.addEventListener(ButtonEvent.CLICK, navigateBack);
                }
            }
            // Render and present.
            for each (var view:MovieClip in _navigationStack) {
                view.visible = false;
            }
            if (fromView != null) {
                fromView.viewWillDisappear();
                transitionOut(fromView, transition);
                fromView.viewDidDisappear();
                removeChild(fromView);
            }
            addChild(view);
            toView.viewWillAppear();
            transitionIn(toView, transition);
            toView.viewDidAppear();
            return true;
        }
        public function navigateBack(sender:Object):Boolean {
            return navigate(previousView);
        }
        protected function transitionIn(view:MovieClip, transition:String):void {
            view.visible = true;
            if (transition === NavigableView.TRANSITION_DEFAULT) {
                centerToStage(view);
            }
        }
        protected function transitionOut(view:MovieClip, transition:String):void {
            if (view != null) {
                view.visible = false;
            }
        }

        // Helpers

        public function centerToStage(view:MovieClip) {
            view.x = stage.stageWidth / 2;
            view.y = stage.stageHeight / 2;
        }

    }

}
