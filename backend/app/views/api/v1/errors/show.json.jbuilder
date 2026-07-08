if local_assigns.key?(:errors)
  json.errors errors
end

if local_assigns.key?(:error)
  json.error error
end

if local_assigns.key?(:message)
  json.message message
end
