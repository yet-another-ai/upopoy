json.results @documents do |document|
  json.partial! "api/v1/search/result", document: document
end
