class HorizontalRenderer

	options: null


	constructor: (options = {}) ->
		@options =
			baseColSize: options.baseColSize || 8


	renderForm: (form) ->
		form.el.addClass('form-horizontal')
		if form.preventAutoLogin
			username = new Element('input', {name:'_username', styles:{display:'none'}})
			username.inject(form.el)
			username = new Element('input', {name:'_password', type:'password', styles:{display:'none'}})
			username.inject(form.el)
		return


	renderButtons: (buttons, ct) ->
		ct.addClass('form-actions')
		if ct.generated
			ct.addClass("col-sm-offset-#{12-@options.baseColSize}")
			ct.addClass("col-sm-#{@options.baseColSize}")
		for button in buttons
			button.render(ct)
		return


	renderGroup: (control, ct) ->
		if !control.groupEl
			control.groupEl = control.el
			control.groupEl.inject(ct)
			control.groupEl.addClass('form-group')

		control.el = control.groupEl

		if !control.labelRendered
			@renderLabel(control, control.groupEl)

		if !control.controlsRendered
			@renderControls(control, control.groupEl)
		else if !control.controlRendered
			@renderControl(control, control.controlsEl)
		else if !control.inputRendered
			control.getInput().replace(control.inputEl)
		return


	renderLabel: (control, ct) ->
		labelEl = control.renderLabel(ct)
		if labelEl
			labelEl.addClass('control-label')
			labelEl.addClass('col-sm-'+(12-@options.baseColSize))
		return


	renderControls: (control, ct) ->
		if !control.controlsEl
			controlsEl = new Element('div')
			controlsEl.inject(ct)
			controlsEl.addClass('col-sm-'+@options.baseColSize)
			controlsEl.addClass('form-controls')
			control.controlsEl = controlsEl
		controlsEl = control.controlsEl

		# label was not rendered
		if !controlsEl.getPrevious('.control-label')
			controlsEl.addClass('col-sm-offset-'+(12-@options.baseColSize))

		if control.help
			helpEl = new Element "span",
				parent: controlsEl
				cls: "help-block"
				html: control.help
			control.helpEl = helpEl

		@renderControl(control, controlsEl)

		if control.desc
			descEl = new Element "div",
				parent: controlsEl
				cls: "help-block"
				html: control.desc
			control.descEl = descEl
		return


	renderControl: (control, ct) ->
		if !control.controlEl
			inputCt = new Element('div')
			inputCt.inject(ct)
			control.controlEl = inputCt

		control.renderControl(control.controlEl)
		return


module.exports = HorizontalRenderer