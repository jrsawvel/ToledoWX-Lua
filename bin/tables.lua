
t = {"Jan", "Feb", "Mar", "Apr"}

-- for k,v in ipairs(t) do
--    print(k,v)
-- end

x = {"May", "Jun", "Jul", "Aug"}


for k,v in ipairs(x) do
    table.insert(t, v)
end

for k,v in ipairs(t) do
    print(k, v) 
end
