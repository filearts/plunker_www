module = angular.module "plunker.service.keybindings", [
]

module.factory "keybindings", [ "$rootScope", "$injector", ($rootScope, $injector) ->
  KeyBinding = ace.require("ace/keyboard/keybinding").KeyBinding
  HashHandler = ace.require("ace/keyboard/hash_handler").HashHandler
  event = ace.require("ace/lib/event")
  
  return new class KeyBindings
    constructor: ->
      @commands = new HashHandler()
      @commands.exec = (command) ->
        command.exec()
        true

      @keyBinding = new KeyBinding(@)

    attachTo: (el) ->
      event.addCommandKeyListener el, @keyBinding.onCommandKey.bind(@keyBinding)

    addCommand: (command) ->
      exec = command.exec or angular.noop
      command.exec = ->
        if $rootScope.$$phase then $injector.invoke(exec)
        else $rootScope.$apply -> $injector.invoke(exec)

      @commands.addCommand(command)
]
