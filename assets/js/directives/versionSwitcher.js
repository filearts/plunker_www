const template = `
<div class="plunker-version-switcher">
    <div>
        <button type="button" class="close" aria-label="close" ng-click="$ctrl.onClickClose($event)">
            <span aria-hidden="true">&times;</span>
        </button>
        &#x1F4A5;Plunker is getting a big upgrade&#x1F4A5;
        <a ng-href="{{$ctrl.redirectTo}}"
            ng-click="$ctrl.onClickTry($event)"
            title="Don't worry, you can easily switch back">Click heree to try it out</a>
    </div>
</div>`.trim();

angular
    .module('plunker.versionSwitcher', [])
    .directive('plunkerVersionSwitcher', ['$rootScope',
        ($rootScope) => {
            return {
                restrict: 'E',
                replace: true,
                scope: true,
                link: function($scope, $element, $attrs) {
                    var $ctrl = {};

                    $scope.$ctrl = $ctrl;

                    $ctrl.redirectTo =
                        window.location.protocol +
                        '//' +
                        window.location.host + $attrs.path;

                    $ctrl.onClickClose = $event => {
                        $event.preventDefault();
                        $event.stopPropagation();

                        $scope.$destroy();
                        $element.remove();

                        $rootScope.$evalAsync(() => $rootScope.$broadcast('editor-resize'));
                    };

                    $ctrl.onClickTry = $event => {
                        $event.preventDefault();
                        $event.stopPropagation();

                        document.cookie =
                            'plnkr.version=next;path=/;expires=' +
                            new Date(
                                Date.now() + 1000 * 60 * 60 * 24 * 14
                            ).toUTCString();
                        window.location =
                            $ctrl.redirectTo +
                            '?utm_source=legacy&utm_medium=banner&utm_campaign=next';
                    };
                },
                template,
            };
        },
    ]);
