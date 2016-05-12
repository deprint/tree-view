{Emitter, CompositeDisposable, Disposable} = require 'atom'

module.exports =

  deactivate: ->
    @providers = []
    @emitter?.dispose()

  onWillAddEntry: (cb) ->
    @emitter ?= new Emitter
    @emitter.on 'will-add-entry', cb

  onWillAddFSEntry: (cb) ->
    @emitter ?= new Emitter
    @emitter.on 'will-add-fs-entry', cb

  onDidCollapseDirectory: (cb) ->
    @emitter ?= new Emitter
    @emitter.on 'did-collapse-directory', cb

  onWillExpandDirectory: (cb) ->
    @emitter ?= new Emitter
    @emitter.on 'will-expand-directory', cb

  addEntryProvider: (cb) ->
    @providers ?= []
    @providers.push cb
    new Disposable( =>
      return if (index = @providers.indexOf(cb)) is -1
      @providers.splice(index, 1)
    )

  addedEntry: (parentView, view, model) ->
    @emitter ?= new Emitter
    @emitter.emit 'will-add-entry', {parentView, view, model}

  addedFSEntry: (parentView, view, model) ->
    @emitter ?= new Emitter
    @emitter.emit 'will-add-fs-entry', {parentView, view, model}

  expandDirectory: (view, isRecursive) ->
    @emitter ?= new Emitter
    @emitter.emit 'will-expand-directory', {view, isRecursive}

  collapsedDirectory: (view, isRecursive) ->
    @emitter ?= new Emitter
    @emitter.emit 'did-collapse-directory', {view, isRecursive}

  getViewFromProvider: (model, parent) ->
    @providers ?= []
    valid = (view, type, fun) ->
      if not view[fun]?
        atom.notifications?.addError "Custom tree-view #{type} must provide a .#{fun} function"
        return false
      return true
    for provider in @providers
      if (view = provider(model, parent))?
        continue unless valid(view, 'elements', 'isCustom')
        continue unless valid(view, 'elements', 'isDirectory')
        continue unless valid(view, 'elements', 'getPath')
        continue unless valid(view, 'elements', 'isPathEqual')
        if view.isDirectory()
          continue unless valid(view, 'directories', 'hasEntries')
          continue unless valid(view, 'directories', 'expand')
          continue unless valid(view, 'directories', 'collapse')
          continue unless valid(view, 'directories', 'toggleExpansion')
        else if view.isCustom()
          continue unless valid(view, 'files', 'click')
        return view
    return null
