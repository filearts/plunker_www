path = require("path")

module.exports = (grunt) ->
  grunt.initConfig 
    pkg: grunt.file.readJSON('package.json')

    build:
      src: 'assets',
      dest: 'public'
    
    less:
      development:
        files:
          '<%=build.dest%>/css/plunker.css': ['<%=build.src%>/css/plunker.less']
        options:
          strictImports: true
          syncImports: true
      production:
        options:
          compress: true
          strictImports: true
          syncImports: true
        files:
          '<%=build.dest%>/css/plunker-min.css': ['<%=build.src%>/css/plunker.less']
          
    watch:
      scripts:
        files: ['<%=build.src%>/**/*.coffee', '<%=build.src%>/**/*.js', '<%=build.src%>/**/*.html']
        tasks: ['browserify:development']
      styles:
        files: ["<%=build.src%>/**/*.less", "<%=build.src%>/**/*.css"]
        tasks: ['less:development']
      options:
        nospawn: true

    browserify:
      development:
        files:
          '<%=build.dest%>/js/plunker.js': ['<%=build.src%>/js/plunker.coffee']
        options:
          debug: true
          transform: ['caching-coffeeify', 'brfs']
          shim:
            emmet:
              path: "<%=build.src%>/vendor/emmet/emmet.js"
              exports: "emmet"
          noParse: [
            '<%=build.src%>/vendor/angular/angular.js'
            '<%=build.src%>/vendor/angular/angular-cookies.js'
            '<%=build.src%>/vendor/angular-growl/angular-growl.js'
            '<%=build.src%>/vendor/angular-ui/ui-bootstrap.js'
            '<%=build.src%>/vendor/angular-ui/ui-router.js'
            '<%=build.src%>/vendor/angular-deckgrid/angular-deckgrid.js'
            '<%=build.src%>/vendor/dominatrix/dominatrix.js'
            '<%=build.src%>/vendor/share/bcsocket-uncompressed.js'
            '<%=build.src%>/vendor/share/share.uncompressed.js'
            '<%=build.src%>/vendor/emmet/emmet.js'
          ]
      production:
        files:
          '<%=build.dest%>/js/plunker.js': ['<%=build.src%>/js/plunker.coffee', '<%=build.src%>/js/partials.coffee']
        options:
          debug: false
          transform: ['caching-coffeeify', 'brfs']
          shim:
            emmet:
              path: "<%=build.src%>/vendor/emmet/emmet.js"
              exports: "emmet"
          noParse: [
            '<%=build.src%>/vendor/angular/angular.js'
            '<%=build.src%>/vendor/angular/angular-cookies.js'
            '<%=build.src%>/vendor/angular-growl/angular-growl.js'
            '<%=build.src%>/vendor/angular-ui/ui-bootstrap.js'
            '<%=build.src%>/vendor/angular-ui/ui-router.js'
            '<%=build.src%>/vendor/angular-deckgrid/angular-deckgrid.js'
            '<%=build.src%>/vendor/dominatrix/dominatrix.js'
            '<%=build.src%>/vendor/share/bcsocket-uncompressed.js'
            '<%=build.src%>/vendor/share/share.uncompressed.js'
            '<%=build.src%>/vendor/emmet/emmet.js'
          ]

    uglify:
      build:
        files:
          '<%=build.dest%>/js/plunker-min.js': ['<%=build.dest%>/js/plunker.js']
        

  # load plugins
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-browserify'

  # tasks
  grunt.task.registerTask 'clean', 'clears out temporary build files', ->
    grunt.file.delete grunt.config.get('build').tmp

  grunt.registerTask 'default', ['compile', 'watch']
  grunt.registerTask 'compile', ['browserify:development', 'less:development']
  grunt.registerTask 'build', ['browserify:production', 'uglify', 'less:production']
