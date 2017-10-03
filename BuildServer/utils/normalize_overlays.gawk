{gsub("#.*","");}

match($0, "^[[:blank:]]*\\[([^\\]]+)\\][[:blank:]]*$",a){
	overlay=a[1]
}

match($0, "^[[:blank:]]*([^[:blank:]=]+)[[:blank:]]*=[[:blank:]]*(.*)$", a){
	gsub("[[:blank:]]*$", "", a[2]);
	list[overlay][a[1]]=a[2];
}

END{
	first=1;
	for(o in list){
		if(first==1)
			first=0
		else
			printf("\n");
		printf("[%s]\n", o);
		for(i in list[o]){
			printf("%s = %s\n", i, list[o][i]);
		}
	}
}
