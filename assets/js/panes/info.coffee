#= require ./../../vendor/script/dist/script

#= require ./../services/panes
#= require ./../services/session
#= require ./../services/activity
#= require ./../services/url

#= require ./../directives/inlineuser
#= require ./../directives/markdown
#= require ./../directives/timeago

#= require ./../../vendor/jquery.autosize/jquery.autosize


module = angular.module("plunker.panes")

module.requires.push "plunker.session"
module.requires.push "plunker.activity"
module.requires.push "plunker.inlineuser"
module.requires.push "plunker.markdown"
module.requires.push "plunker.url"
module.requires.push "plunker.timeago"


module.run [ "$timeout", "panes", "session", "activity", "url", ($timeout, panes, session, activity, url) ->

  panes.add
    id: "info"
    icon: "dashboard"
    size: 430
    title: "Info"
    hidden: true
    description: """
      Plunk information.
    """
    template: """
      <div class="plunker-info">
        <h3>
          <a class="permalink pull-right" ng-href="{{session.plunk.raw_url}}" target="_blank"><i class="icon icon-link"></i></a>
          {{session.plunk.description}}
        </h3>
        <div class="info-creation">
          <plunker-plunk-info plunk="session.plunk" class="pull-right"></plunker-plunk-info>
          <plunker-inline-user user="session.plunk.user"></plunker-inline-user>
          <abbr class="timeago updated_at" title="{{session.plunk.updated_at}}" timeago="{{session.plunk.updated_at | date:'medium'}}"></abbr>
        </div>
        <plunker-taglist tags="session.plunk.tags" ng-show="tags.length"></plunker-taglist>
        <p></p>
        <div class="info-ad" ng-show="adcode">
          <div id="carbonads-container">
            <div class="carbonad">
              <div id="azcarbon"></div>
            </div>
          </div>
        </div>
        <div class="info-readme" ng-show="session.plunk.getReadme()" markdown="session.plunk.getReadme()">
        </div>
        <div class="alert alert-info" ng-hide="session.plunk.getReadme()">
          <h4>Describe your plunks in Markdown</h4>
          <p>You can give your plunks long-form descriptions now by creating a README.md
            file. The first two paragraphs of the readme (including title) will be shown
            on the plunk 'cards' on the front page. The readme will also be available in its
            full form here and at other relevant places in the Plunker ecosystem.
          </p>
        </div>
        <div style="display: none">
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
      </div>
    """
    link: ($scope, $el, attrs) ->
      pane = @
      
      $scope.$watch ( -> pane.active), (active) ->
        if active and !$scope.adcode and url.carbonadsH
          $scope.adcode = true
          $timeout -> $script(url.carbonadsH)
    
      $scope.session = session
      
      $scope.$watch "session.plunk.id", (id) ->
        pane.hidden = !id
      
      $textarea = $(".plunker-comment-box textarea", $el).autosize(append: "\n").css("height", "24px")
      $textarea.on "blur", -> $textarea.css("height", "24px")
      $textarea.on "focus", -> $textarea.trigger "autosize"
]