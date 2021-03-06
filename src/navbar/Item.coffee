class NavbarItem extends Miwo.Component

	xtype: "navbaritem"
	isNavbarItem: true
	handler: null
	text: ""
	disabled: false
	active: false
	el: 'li'
	baseCls: 'dropdown'
	contentEl: 'a'


	setDisabled: (disabled, silent) ->
		@el.toggleClass('disabled', disabled)
		@el.set('tabindex', -disabled)
		@disabled = disabled
		(if disabled then @emit('disabled', this) else @emit('enabled', this)) unless silent
		return


	setText: (@text) ->
		@textEl.set("html", @text) if @textEl
		return


	setActive: (active, silent) ->
		@el.toggleClass('active', active)
		@active = active
		@emit('active', this, active) if !silent && active
		return


	isActive: ->
		return @active and not @disabled


	click: (e) ->
		if Type.isFunction(@handler)
			@handler(this, e)
		else if Type.isString(@handler)
			if @handler.indexOf('#') is 0
				miwo.redirect(@handler)
			else
				document.location = @handler
		return


	doRender: ->
		@el.addClass('active')  if @active
		@el.addClass('disabled')  if @disabled
		@el.set('tabindex', -1)  if @disabled
		@getContentEl().set('href', '#')
		@getContentEl().on("click", @bound("onClick"))
		@textEl = new Element("span", {html: @text, parent: @getContentEl()})
		return


	onClick: (e) ->
		e.preventDefault()
		if @disabled then return

		@preventClick = false
		@emit('beforeclick', this, e)
		if @preventClick then return

		@emit('click', this, e)
		@click(e)
		return


module.exports = NavbarItem