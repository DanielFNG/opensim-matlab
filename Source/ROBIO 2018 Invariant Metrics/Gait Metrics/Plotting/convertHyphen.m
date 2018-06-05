function val = convertHyphen(string)

str = strsplit(string, '_');
str{1}(1) = upper(str{1}(1));
val = [];
for i=1:length(str)
    val = [val str{i} '. '];
end

val(end) = [];

end