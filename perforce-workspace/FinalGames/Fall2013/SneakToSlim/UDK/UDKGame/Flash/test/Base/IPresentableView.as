package {

    import scaleform.clik.controls.Button;

    public interface IPresentableView {

        function get navigationBackButton():Button;
        function get navigationButtons():Vector.<Button>;

        function viewWillAppear():void;
        function viewDidAppear():void;
        function viewWillDisappear():void;
        function viewDidDisappear():void;

    }

}
