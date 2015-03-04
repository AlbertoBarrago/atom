{Emitter} = require 'event-kit'
{Subscriber} = require 'emissary'
Gutter = require './gutter'

# This class encapsulates the logic for adding and modifying a set of gutters.

module.exports =
class GutterContainer
  Subscriber.includeInto(this)
  constructor: ->
    @gutters = []
    @emitter = new Emitter

  destroy: ->
    @gutters = null
    @emitter.dispose()
    @unsubscribe()

  # Creates and returns a {Gutter}.
  # * `options` An {Object} with the following fields:
  #   * `name` (required) A unique {String} to identify this gutter.
  #   * `priority` (optional) A {Number} that determines stacking order between
  #       gutters. Lower priority items are forced closer to the edges of the
  #       window. (default: -100)
  #   * `visible` (optional) {Boolean} specifying whether the gutter is visible
  #       initially after being created. (default: true)
  addGutter: (options) ->
    options = options ? {}
    gutterName = options.name
    if gutterName == null
      throw new Error 'A name is required to create a gutter.'
    if @gutterWithName gutterName
      throw new Error 'Tried to create a gutter with a name that is already in use.'
    newGutter = new Gutter this, options

    inserted = false
    # Insert the gutter into the gutters array, sorted in ascending order by 'priority'.
    # This could be optimized, but there are unlikely to be many gutters.
    for i in [0...@gutters.length]
      if @gutters[i].priority >= newGutter.priority
        @gutters.splice(i, 0, newGutter)
        inserted = true
        break
    if !inserted
      @gutters.push newGutter
    return newGutter

  getGutters: ->
    @gutters.slice()

  gutterWithName: (name) ->
    for gutter in @gutters
      if gutter.name == name then return gutter
    null

  ###
  Section: Event Subscription
  ###

  # @param callback: function( nameOfRemovedGutter )
  onDidRemoveGutter: (callback) ->
    @emitter.on 'did-remove-gutter', callback

  ###
  Section: Private Methods
  ###

  # Processes the destruction of the gutter. Throws an error if this gutter is
  # not within this gutterContainer.
  removeGutter: (gutter) ->
    index = @gutters.indexOf gutter
    if index > -1
      @gutters.splice(index, 1)
      @unsubscribe gutter
      @emitter.emit 'did-remove-gutter', gutter.name
    else
      throw new Error 'The given gutter cannot be removed because it is not ' +
          'within this GutterContainer.'