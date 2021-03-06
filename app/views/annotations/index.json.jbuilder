json.array!(@annotations) do |annotation|
  json.extract! annotation, :id
  json.data do
    json.set! :text, '<a href="'+entity_path(annotation.entity)+'">'+JSON.parse(annotation.data)['text']+'</a><p>'+annotation.entity.description+'</p>'
    json.set! :src, JSON.parse(annotation.data)['src']
    json.set! :shapes, JSON.parse(annotation.data)['shapes']
    json.set! :context, JSON.parse(annotation.data)['context']
  end
end