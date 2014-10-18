setData = require('../setData')

# adding a very rudimentary search service
searchService = do ->

	# the max number of results to return
	maxResults = 10

	# cleans the query value (and the value to be searched) of any characters
	# that may not be correctly typed by the user, like punctuation marks
	cleanQuery = (value) ->
		value = value.replace(/[,'"-]/g, '')
		value = value.replace(/Æ/g, 'Ae')
		value = value.toLowerCase()
		value

	{
		search: (query, done) ->
			cards = []
			clean = cleanQuery query
			for set in setData.sets
				for card in set.cards 
					if cleanQuery(card.name).indexOf(clean) > -1
						cards.push {
							card: card
							set: set
						}

						if cards.length >= maxResults
							break

				if cards.length >= maxResults
					break

			done? {
				cards: cards
			}
	}

class CardSearchResultUiModel
	constructor: (cardSearchResult) ->
		@card = {
			name: cardSearchResult.card.name,
			number: cardSearchResult.card.number
		}
		@set = {
			name: cardSearchResult.set.name
			code: cardSearchResult.set.code
		}

toUiModels = (searchResults) ->
	cards = (new CardSearchResultUiModel(cardSearchResult) for cardSearchResult in searchResults.cards)
	{
		cards: cards
	}

class SearchResource
	setup: (app) ->
		app.get '/search', => @handleSearch arguments...

	handleSearch: (request, response) -> 
		if !request.query.q?
			err = new Error('Missing search query parameter "q"')
			err.status = 400
			throw err

		searchService.search request.query.q, (results) ->
			response.json toUiModels(results)

module.exports = SearchResource