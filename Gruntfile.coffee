path = require("path")

module.exports = (grunt) ->
  grunt.initConfig 
    pkg: grunt.file.readJSON('package.json')

    build:
      src: 'assets',
      dest: 'build'
    
    bump:
      options:
        files: ['package.json']
        updateConfigs: []
        commit: true
        commitMessage: 'Release v%VERSION%'
        commitFiles: ['-a']
        createTag: false
        push: false
    
    less:
      development:
        files:
          '<%=build.dest%>/css/embed.css': ['<%=build.src%>/css/apps/embed.less']
        options:
          strictImports: true
          syncImports: true
      production:
        options:
          compress: true
          strictImports: true
          syncImports: true
        files:
          '<%=build.dest%>/css/embed-min.css': ['<%=build.src%>/css/apps/embed.less']
          
    watch:
      scripts:
        files: ['<%=build.src%>/**/*.coffee', '<%=build.src%>/**/*.js']
        tasks: ['browserify:development']
      styles:
        files: ["<%=build.src%>/**/*.less", "<%=build.src%>/**/*.css"]
        tasks: ['less:development']
      options:
        nospawn: true

    browserify:
      development:
        files:
          '<%=build.dest%>/js/embed.js': ['<%=build.src%>/js/apps/embed.coffee']
        options:
          debug: true
          transform: ['caching-coffeeify', 'brfs']
          noParse: [
            '<%=build.src%>/vendor/angular-1.2.3.js'
            '<%=build.src%>/vendor/ui-router/ui-router.js'
            '<%=build.src%>/vendor/marked.js'
            '<%=build.src%>/vendor/angularytics/dist/angularytics.js'
          ]
      production:
        files:
          '<%=build.dest%>/js/embed.js': ['<%=build.src%>/js/apps/embed.coffee']
        options:
          debug: false
          transform: ['caching-coffeeify', 'brfs']
          noParse: [
            '<%=build.src%>/vendor/angular-1.2.3.js'
            '<%=build.src%>/vendor/ui-router/ui-router.js'
            '<%=build.src%>/vendor/marked.js'
            '<%=build.src%>/vendor/angularytics/dist/angularytics.js'
          ]

    uglify:
      build:
        files:
          '<%=build.dest%>/js/embed-min.js': ['<%=build.dest%>/js/embed.js']
    
    exec:
      editor: 'NODE_ENV=production node build.js'

  # load plugins
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-bump'
  grunt.loadNpmTasks 'grunt-exec'

  # tasks
  grunt.task.registerTask 'clean', 'clears out temporary build files', ->
    grunt.file.delete grunt.config.get('build').tmp

  grunt.registerTask 'default', ['compile', 'watch']
  grunt.registerTask 'compile', ['browserify:development', 'less:development']
  grunt.registerTask 'build', ['exec:editor', 'less:production']
  grunt.registerTask 'release', ['bump', 'build']
