'''
authour: Rahul ghuge.

script to print name type and path for all the objects in database.
useful while accessing the object type id or path.

'''
#databse object
db = WSApplication.current_database

#root model object collection.
moc = db.root_model_objects()

#function display name type and path.
def displayObProp(ob)
  if ob.respond_to?(:name) & ob.respond_to?(:path) & ob.respond_to?(:type)
    puts "Name: #{ob.name}, Type: #{ob.type}, Path: #{ob.path}"
  elsif ob.respond_to?(:name) & ob.respond_to?(:path)
    puts "Name: #{ob.name},Type: #{ob.type}, Path: #{ob.path}"
  elsif ob.respond_to?(:name) & ob.respond_to?(:type)
    puts "Name: #{ob.name}, Type: #{ob.type}"
  else
    puts "Name: #{ob.name}"
  end
  
  if ob.respond_to?(:children)
    for child in ob.children() do
      displayObProp(child)
    end
  end
end

for ob in moc do
  displayObProp(ob)
end
