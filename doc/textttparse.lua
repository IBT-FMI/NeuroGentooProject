buf=io.stdin:read("*a");
repeat
	i=string.find(buf,[[\texttt]])
	if not i then
		io.stdout:write(buf)
		break;
	end
	i=i+string.len([[\texttt]]);
	io.stdout:write(string.sub(buf,0,i))
	io.stdout:write([[\sloppy{}]]);
	buf=string.sub(buf,i+1);
	i=string.find(buf,"}");
	ins=string.sub(buf,0,i);
	ins,_=string.gsub(ins,[[/]],[[\slash{}]])
	io.stdout:write(ins)
	buf=string.sub(buf,i+1);
until string.len(buf)==0
