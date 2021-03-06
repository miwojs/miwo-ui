SelectionModel = require '../selection/SelectionModel'
GridRenderer = require './renderer/GridRenderer'
CheckerColumn = require './column/CheckerColumn'
ActionColumn = require './column/ActionColumn'
Operations = require './Operations'
Paginator = require '../pagination/Paginator'
Pane = require '../panel/Pane'


class Grid extends Pane

	# @event render (grid)
	# @event renderheader (grid, th, column)
	# @event beforerowrender (grid, tbody, record, index)
	# @event rowrender (grid, tr, record, index)
	# @event beforecellrender (grid, tr, value, record)
	# @event cellrender (grid, td, value, record)
	# @event cellclick (grid, td, record, info, e)
	# @event celldblclick (grid, td, record, info, e)
	# @event destroyrow (grid, tr, index)
	# @event destroycell (grid, td)
	# @event refresh (grid)
	# @event action (grid, name, records)
	# @event selectionchange (grid, sm, selection)
	# @event beforesync (grid, groups)
	# @event sync (grid, positions)
	# @event aftersync (grid)

	isGrid: true
	xtype: 'grid'
	condensed: false
	stripe: false
	nowrap: true
	rowclickable: false
	maskOnLoad: false
	verticalAlign: null # top or middle(by default)
	store: null
	renderer: null
	selectable: false
	selector: "auto"
	selection: "multi"
	groupBy: null
	paginator: false
	# @cfg string Default action button size. You can set size by bootstrap: 'xs', 'sm', ... Default is 'sm'
	actionBtnSize: null
	role: 'grid'
	size: 'md'

	layout: false
	baseCls: "grid"
	checker: null
	operations: null
	selectionModel: null
	headerEl: null
	bodyEl: null
	footerEl: null
	lastAddedColumn: null
	actionColumnIndex: 0


	@registerColumn: (columnName, fn) ->
		if !fn then throw new Error("Error in registry control #{controlName}, constructor is undefined")
		addMethod = 'add'+columnName.capitalize()
		@prototype[addMethod] = (name, config = {}) ->
			return @addColumn(name, new fn(config))
		return


	afterInit: ->
		super
		if @maskOnLoad
			@showMask()

		if @store
			if Type.isString(@store)
				@setStore(miwo.store(@store))
			else
				@setStore(@store)

		if @renderer
			@rendererOptions = @renderer
			@renderer = null

		contentEl = @getContentEl()
		contentEl.addClass(@getBaseCls('container'))

		@headerEl = new Element "div",
			parent: contentEl
			cls: @getBaseCls("header")

		@mainEl = new Element "div",
			parent: contentEl
			cls: @getBaseCls("main")

		@bodyEl = new Element "div",
			parent: @mainEl
			cls: @getBaseCls("body")

		@footerEl = new Element "div",
			parent: contentEl
			cls: @getBaseCls("footer")

		@contentEl = @bodyEl
		@scrollableCt = @mainEl
		@scrollableEl = @bodyEl
		return


	addedComponent: (column) ->
		@lastAddedColumn = column
		return


	addColumn: (name, column) ->
		if !column.isColumn
			throw new Error("Object is not instance of column")
		return @add(name, column)


	addCheckerColumn: (name, config) ->
		return @addColumn(name, new CheckerColumn(config))


	addActionColumn: (name, config) ->
		return @addColumn(name, new ActionColumn(config))


	addOperation: (name, config) ->
		return @getOperations().addAction(name, config)


	addAction: (name, config) ->
		return @getActionColumn().addAction(name, config)


	getActionColumn: ->
		if !@lastAddedColumn.isActionColumn
			@addActionColumn('actions'+@actionColumnIndex)
			@actionColumnIndex++
		return @lastAddedColumn


	getOperations: ->
		if !@operations
			@operations = new Operations(this)
		return @operations


	getColumns: ->
		return @getComponents().toArray()


	setSelectionModel: (@selectionModel) ->
		if !@store then throw new Error("Before set selection model, first set store")
		@selectionModel.setStore(@store)
		@mon(selectionModel, 'change', 'onSelectionModelChange')
		return


	getSelectionModel: ->
		return @selectionModel


	onSelectionModelChange: (sm, selection) ->
		@emit('selectionchange', this, sm, selection)
		return


	setSelector: (@selector) ->
		@selector.setGrid(this)
		@selector.setSelectionModel(@getSelectionModel())
		return


	onOperationSubmit: (action) ->
		records = @getSelectionModel().getRecords()
		action.callback(records) if action.callback
		@emit("action", this, action.name, records)
		return


	onActionSubmit: (action, record) ->
		action.callback(record) if action.callback
		@emit("action", this, action.name, [record])
		return


	showMask: ->
		if !@loadMask
			@loadMask = miwo.mask.create(this)
		@loadMask.show()
		return


	hideMask: ->
		if @loadMask
			@loadMask.hide()
		return


	setStore: (store) ->
		@munon(@store, store, 'add', 'onStoreAdd')
		@munon(@store, store, 'remove', 'onStoreRemove')
		@munon(@store, store, 'refresh', 'onStoreRefresh')
		@munon(@store, store, 'update', 'onStoreUpdate')
		@munon(@store, store, 'beforeload', 'onStoreBeforeload')
		@munon(@store, store, 'load', 'onStoreLoad')
		@munon(@store, store, 'reload', 'onStoreReload')
		@store = store
		return


	getStore: ->
		return @store


	onStoreAdd: (store, record) ->
		@renderer.recordAdded(record)  if @rendered
		return


	onStoreRemove: (store, record) ->
		@renderer.recordRemoved(record)  if @rendered
		return


	onStoreUpdate: (store, record) ->
		@renderer.recordUpdated(record)  if @rendered
		return


	setAutoSync: (autoSync) ->
		@getRenderer().setAutoSync(autoSync)
		return


	onStoreRefresh: ->
		@refresh()
		return


	onStoreBeforeload: ->
		@loadMask.show()  if @loadMask && @maskOnLoad
		return


	onStoreLoad: ->
		@refresh()
		@loadMask.hide()  if @loadMask
		return


	onStoreReload: ->
		@refresh()
		@loadMask.hide()  if @loadMask
		return


	refresh: ->
		@renderer.refresh()  if @rendered
		return


	sync: ->
		@renderer.syncRows()  if @rendered
		return


	getRecords: ->
		return @store.getRecords()


	doRender: ->
		if @selectable or @operations
			if !@selectionModel
				if Type.isString(@selection)
					config = {type: @selection}
				else
					config = @selection || {}
				@setSelectionModel(new SelectionModel(config))

			if !Type.isObject(@selector) || !@selector.isSelector
				if Type.isString(@selector)
					type = @selector
					config = null
				else
					type = @selector.type
					config = @selector
				if type is 'auto'
					type = if @operations then 'check' else 'row'
				@setSelector(miwo.service('selectorFactory').create(type, config))

			if @selector.checkerRequired
				@checker = @addCheckerColumn('checker')

		@getRenderer().render()
		return


	afterRender: ->
		super()
		@getRenderer().afterRender()
		# On refresh is called when Store is loaded. If Store was loaded before grid render
		# then is need to simulate refresh event by onRefresh().
		@onRefresh() if @store.loaded
		return


	getRenderer: ->
		if !@renderer
			@renderer = @createRenderer(@rendererOptions)
		return @renderer


	createRenderer: (options)->
		return new GridRenderer(this, options)


	createComponentPaginator: ->
		config = if @paginator is true then {} else @paginator
		paginator = new Paginator(config)
		paginator.setStore(@store) if @store
		return paginator


	onRefresh: ->
		@emit("refresh", this)
		return


	doDestroy: ->
		@renderer.destroy() if @renderer
		@selector.destroy() if @selector
		@selectionModel.destroy() if @selectionModel
		@selectionModel = null
		@renderer = null
		@selector = null
		@store = null
		super


module.exports = Grid