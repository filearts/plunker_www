#= require ./../services/menu


module = angular.module "plunker.discussion", [
  "plunker.menu"
]


module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/group",
    template: """
      <div class="container">
        <iframe id="forum_embed" src="javascript:void(0)" scrolling="no" frameborder="0" width="100%" height="500"></iframe>
      </div>
    """

    controller: ["$rootScope", "$scope", "$timeout", "menu", ($rootScope, $scope, $timeout, menu) ->
      $rootScope.page_title = "Group"          
      
      menu.activate "group"
      
      $iframe = $("#forum_embed")
      $footer = $(".container footer")
    
      $scope.$parent.section = "discuss"
      
      $scope.resizeDiscussion = ->
        minHeight = 400
        $iframe.height(Math.max(minHeight, $(window).height() - 60 - 8 - $footer.outerHeight()))
      
      $(window).resize($scope.resizeDiscussion)
      $timeout ->
        $scope.resizeDiscussion()
      , 2000
    
      $iframe.attr("src", 'https://groups.google.com/forum/embed/?place=forum/plunker&showsearch=true&showpopout=true&hideforumtitle=true&showtabs=false&parenturl=' + encodeURIComponent(window.location.href));
    ]
]


module.run ["menu", (menu) ->
  menu.addItem "discuss",
    title: "Open the discussion group"
    href: "/group"
    'class': "icon-comments-alt"
    text: "Group"
]