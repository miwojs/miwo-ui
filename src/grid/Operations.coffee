Action = require './Action'
Button = require '../buttons/Button'
Select = require '../input/Select'
PopoverSubmit = require './utils/PopoverSubmit'


class Operations extends Miwo.Component

	componentCls: 'grid-operations'
	actions: null
	select: null
	submit: null


	constructor: (@grid, config)->
		super(config)
		@actions = {}


	addAction: (name, config) ->
		action = new Action(config)
		action.name = name
		@actions[name] = action
		return action


	doRender: () ->
		@select = new Select({id:@id+'-operation'})
		@select.render(@el)
		@select.addOption(action.name, action.text)  for name,action of @actions

		@submit = new Button
			text: miwo.tr("miwo.grid.execute")
			handler: =>
				action = @actions[@select.getValue()]
				@onOperationSubmit(action)
				return
		@submit.render(@el)
		return


	onOperationSubmit: (action) ->
		if !action.confirm
			@grid.onOperationSubmit(action)
		else
			@popover = new PopoverSubmit
				renderTo: miwo.body
				target: @submit.el
				title: miwo.tr("miwo.grid.confirm")
				placement: action.confirmPlacement || 'top'
				onSubmit: () => @grid.onOperationSubmit(action)
			@popover.show()
		return


module.exports = Operations