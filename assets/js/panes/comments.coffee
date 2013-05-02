#= require ./../services/panes
#= require ./../services/session
#= require ./../services/activity

#= require ./../directives/inlineuser

#= require ./../../vendor/jquery.autosize/jquery.autosize


module = angular.module("plunker.panes")

module.requires.push "plunker.session"
module.requires.push "plunker.activity"
module.requires.push "plunker.inlineuser"


module.run [ "panes", "session", "activity", (panes, session, activity) ->

  panes.add
    id: "comments"
    icon: "comments-alt"
    size: 328
    title: "Comments"
    description: """
      Comment on Plunks.
    """
    template: """
      <div class="plunker-comments">
        <ul class="plunker-comment-list">
          <li ng-repeat="comment in session.plunk.comments">
            <plunker-inline-user user="comment.user"></plunker-inline-comment>
            <div ng-bind="comment.body"></div>
          </li>
        </ul>
        <div class="plunker-comment-box">
          <textarea ng-keypress="onKeyPress()" ng-model="draft"></textarea>
        </div>
      </div>
    """
    link: ($scope, $el, attrs) ->
      pane = @
      
      $scope.session = session
      
      $textarea = $(".plunker-comment-box textarea", $el).autosize(append: "\n").css("height", "24px")
      $textarea.on "blur", -> $textarea.css("height", "24px")
      $textarea.on "focus", -> $textarea.trigger "autosize"
]