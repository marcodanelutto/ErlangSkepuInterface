/* 

   sample functions to be used in map and reduce skeletons

*/

UNARY_FUNC(sq,  double, x, return(x*x);)
UNARY_FUNC(inc, double, x, return(x+1.0);)
UNARY_FUNC(dec, double, x, return(x-1.0);)
UNARY_FUNC(sins,double, x, for(int i=0;i<800000;i++) x = sin(x); return(x); )
UNARY_FUNC(sqi, int, x, return(x*x);)
BINARY_FUNC(pairmul, double, x, y, return(x*y);)
BINARY_FUNC(sum, double, x, y, return(x+y);)


ERL_GPU_MAP(sq,mapsq)
ERL_GPU_MAP(inc,mapinc)
ERL_GPU_REDUCE(sum,reducesum)
ERL_GPU_MAPZIP(sum,mapzipsum)
ERL_GPU_MAPREDUCE(sq,sum,mapreducesqsum)
