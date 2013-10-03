path = require("path")

module.exports = (grunt) ->
  grunt.initConfig 
    pkg: grunt.file.readJSON('package.json')

    build:
      src: 'assets',
      dest: 'public'
    
    coffeelint:
      files:
        src: ['<%=build.src%>/js/**/*.coffee']
      options:
        max_line_length:
          value: false
          level: "warn"
        no_trailing_whitespace:
          value: true
          level: false
          
    
    less:
      compile:
        files:
          '<%=build.dest%>/css/apps/landing.css': ['<%=build.src%>/css/apps/landing.less']
          '<%=build.dest%>/css/apps/editor.css': ['<%=build.src%>/css/apps/editor.less']
        options:
          strictImports: true
          syncImports: true
      build:
        #options:
        #  compress: true
        files:
          '<%=build.dest%>/css/apps/landing.css': ['<%=build.src%>/css/apps/landing.less']
          '<%=build.dest%>/css/apps/editor.css': ['<%=build.src%>/css/apps/editor.less']
          
    watch:
      scripts:
        files: ['<%=build.src%>/**/*.coffee', '<%=build.src%>/**/*.js']
        tasks: ['browserify:compile']
      styles:
        files: ["<%=build.src%>/**/*.less", "<%=build.src%>/**/*.css"]
        tasks: ['less:compile']
      options:
        nospawn: true

    browserify:
      compile:
        files:
          '<%=build.dest%>/js/apps/landing.js': ['<%=build.src%>/js/apps/landing.coffee']
          '<%=build.dest%>/js/apps/editor.js': ['<%=build.src%>/js/apps/editor.coffee']
        options:
          debug: true
          transform: ['caching-coffeeify']
          noParse: ['<%=build.src%>/vendor/angular/angular.js','<%=build.src%>/vendor/angular/angular-cookies.js','<%=build.src%>/vendor/angular-ui/ui-bootstrap.js']
      build:
        files:
          '<%=build.dest%>/js/apps/landing.js': ['<%=build.src%>/js/apps/landing.coffee']
          '<%=build.dest%>/js/apps/editor.js': ['<%=build.src%>/js/apps/editor.coffee']
        options:
          debug: false
          transform: ['caching-coffeeify']
          noParse: ['<%=build.src%>/vendor/angular/angular.js','<%=build.src%>/vendor/angular/angular-cookies.js','<%=build.src%>/vendor/angular-ui/ui-bootstrap.js']

    uglify:
      build:
        expand: true
        cwd: '<%=build.dest%>/js/'
        src: ['**/*.js']
        dest: '<%=build.dest%>/js/'
        ext: ".min.js"

    express:
      options: 
        port: process.env.PORT
      livereload:
        options:
          server: path.resolve('./server/index.coffee')
          #livereload: true
          #serverreload: true
          #bases: [path.resolve('./public')]
          

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
  grunt.registerTask 'compile', ['browserify:compile', 'less:compile']
  grunt.registerTask 'build', ['browserify:main', 'uglify', 'less:build']
  grunt.registerTask 'spec', ['compile', 'browserify:specs', 'jasmine']