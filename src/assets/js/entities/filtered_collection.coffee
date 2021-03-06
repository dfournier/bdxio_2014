FilteredCollection = (options) ->
  original = options.collection;
  filtered = new original.constructor()
  filtered.add(original.models)
  filtered.filterFunction = options.filterFunction

  applyFilter = (filterCriterion, filterStrategy, collection) ->
    collection = collection || original
    criterion = if filterStrategy is "filter"
      filterCriterion.trim()
    else
      filterCriterion

    items = []
    if criterion
      if filterStrategy is "filter"
        unless filtered.filterFunction?
          throw("Attempted to use 'filter' function, but none was defined")

        filterFunction = filtered.filterFunction(criterion)
        items = collection.filter(filterFunction)
      else
        items = collection.where(criterion)
    else
      items = collection.models

    # store current criterion
    filtered._currentCriterion = criterion

    return items

  filtered.filter = (filterCriterion) ->
    filtered._currentFilter = "filter"
    items = applyFilter(filterCriterion, "filter")

    # reset the filtered collection with the new items
    filtered.reset(items)
    return filtered

  filtered.where = (filterCriterion) ->
    filtered._currentFilter = "where"
    items = applyFilter(filterCriterion, "where")

    # reset the filtered collection with the new items
    filtered.reset(items)
    return filtered

  # when the original collection is reset,
  # the filtered collection will re-filter itself
  # and end up with the new filtered result set
  original.on "reset", ->
    items = applyFilter(filtered._currentCriterion, filtered._currentFilter)

    # reset the filtered collection with the new items
    filtered.reset(items)

  # if the original collection gets models added to it:
  # 1. create a new collection
  # 2. filter it
  # 3. add the filtered models (i.e. the models that were added *and*
  #     match the filtering criterion) to the `filtered` collection
  original.on "add", (models) ->
    coll = new original.constructor()
    coll.add(models)
    items = applyFilter(filtered._currentCriterion, filtered._currentFilter, coll)
    filtered.add(items)

  return filtered

`export default FilteredCollection`
