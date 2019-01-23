$(function(){
	print();
});

function print(){
	var rows=$("#rollTb")[0].rows.length;
		console.log(rows);//9
	for(var i=0;i<(rows-1)/3-1;i++){
		$("body").append($("#main").clone(true));
	}
	var tbs=$("table").filter("#rollTb");
	console.log(tbs);
	$.each(tbs, function(k,v) {
		console.log(k+"::::::");
		console.log(v);
		console.log("kkkkkkkkk")
		for(var i=1;i<rows;i++){
			console.log(i);
			if(i<1+k*3){//i<4
				$("table").filter("#rollTb")[k].deleteRow(1);
				console.log(1+"in");
			}
			if(i>3+k*3){//i>6
				$("table").filter("#rollTb")[k].deleteRow(4+k*3-(k*3));
				console.log(4+k*3+"in");
			}
		}
		console.log("dddddddddd")
		console.log(v);
		console.log("dddddddddd")
	});
}
