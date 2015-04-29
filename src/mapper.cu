/* 
   map and reduce patterns on GPUs for Erlang 
   (2013 marcod, paraphrase)
 
*/

/* 

  end of targeting macros here

*/
#include "erl_nif.h"
#include <iostream>
#include <time.h>
#include <math.h>
            
#include <skepu/vector.h>
#include <skepu/map.h>
#include <skepu/reduce.h>
#include <skepu/mapreduce.h>

using namespace std;

skepu::Vector<double> * list_to_vector(ErlNifEnv *env, ERL_NIF_TERM list);
ERL_NIF_TERM            vector_to_list(ErlNifEnv *env, skepu::Vector<double> x); 

/*
  map function: processes a list of floating point to get a list of 
                floating point

		the function used to compute the new elements is
		the one whose name is #defined in MAP_UNARY_FUNC_NAME

*/
#define ERL_GPU_MAP(FUNNAME,MAPNAME) static ERL_NIF_TERM MAPNAME(ErlNifEnv * env, int argc, const ERL_NIF_TERM argv[]) { \
  skepu::Vector<double> *x, *y; \
  ERL_NIF_TERM list = argv[0], res; \
  if(enif_is_list(env, list)) { \
    unsigned int len = 0;  \
    enif_get_list_length(env, list, &len); \
    x = list_to_vector(env,list); \
    y = new skepu::Vector<double>[(*x).size()]; \
    skepu::Map<FUNNAME> skepu_mapper(new FUNNAME); \
    skepu_mapper(*x,*y); \
    res = vector_to_list(env, *y); \
  } else { \
    cerr << "ERRROR :: " << MAPNAME << ": unknown parameter type" << endl ; \
  } \
  return res; \
} \

/*
  reduce skeleton: processes a list of floating point to get a float 

		the function used to reduce the list is
		the one whose name is #defined in REDUCE_BINARY_FUNC_NAME

*/

#define ERL_GPU_REDUCE(FUNNAME,REDUCENAME) static ERL_NIF_TERM REDUCENAME(ErlNifEnv * env, int argc, const ERL_NIF_TERM argv[]) { \
  skepu::Vector<double> *x; \
  ERL_NIF_TERM list = argv[0], res; \
  if(enif_is_list(env, list)) { \
    x = list_to_vector(env,list); \
    skepu::Reduce<FUNNAME> reducer(new FUNNAME); \
    double res = reducer(*x); \
    ERL_NIF_TERM erl_ris = enif_make_double(env, res); \
    return(erl_ris); \
  } else { \
    cerr << REDUCENAME << " called with non list parameter" << endl;	\
  } \
} \

/*
  computes a map of a BINARY_FUNC over two lists of double (map(f)(zip))
*/

#define ERL_GPU_MAPZIP(FUNNAME, MAPZIPNAME) static ERL_NIF_TERM MAPZIPNAME(ErlNifEnv * env, int argc, const ERL_NIF_TERM argv[]) { \
  skepu::Vector<double> *x, *y, *z; \
  ERL_NIF_TERM list1 = argv[0], list2=argv[1], res; \
  if(enif_is_list(env, list1) && enif_is_list(env,list2)) { \
    unsigned int len = 0, len2; \
    x = list_to_vector(env,list1); \
    y = list_to_vector(env,list2); \
    if(x->size() != y->size()) { \
      cerr << "ERROR :: map2f: processing lists with different lenghts" << endl; \
    } \
    z = new skepu::Vector<double>[x->size()]; \
    skepu::Map<FUNNAME> sk_pairmapper(new FUNNAME); \
    sk_pairmapper(*x,*y,*z); \
    res = vector_to_list(env,*z); \
  } else { \
    cout << "ERRROR :: " << MAPZIPNAME << " : unknown parameter type" << endl ; \
  }  \
  return res; \
} \

/* 
   The map reduce wrapping
*/
#define ERL_GPU_MAPREDUCE(FUN_F, FUN_OPLUS, MAPREDUCENAME) static ERL_NIF_TERM MAPREDUCENAME(ErlNifEnv * env, int argc, const ERL_NIF_TERM argv[]) { \
  skepu::Vector<double> *x, *y; \
  double double_res; \
  ERL_NIF_TERM list = argv[0], res; \
  if(enif_is_list(env, list)) { \
    unsigned int len = 0; \
    enif_get_list_length(env, list, &len); \
    x = list_to_vector(env,list); \
    skepu::MapReduce<FUN_F, FUN_OPLUS> skepu_mapreducer(new FUN_F, new FUN_OPLUS); \
    double_res = skepu_mapreducer(*x); \
    res = enif_make_double(env, double_res); \
  } else { \
    cerr << "ERRROR :: mapreduce1f: unknown parameter type" << endl ; \
  } \
  return res; \
} \


/* user functions used as parameters to the map and reduce */ 

#include "user.h"

/* used to close static nif function array decls below */

static ERL_NIF_TERM skeletonlib(ErlNifEnv * env, int argc, const ERL_NIF_TERM argv[]) {
  return enif_make_string(env,"ParaPhrase Erlang GPU intial pattern library (1.0): up and running",ERL_NIF_LATIN1);
}
/********************************************************************
   former definition of the map as a function, rather than as a macro
   ******************************************************************
 
static ERL_NIF_TERM map1f(ErlNifEnv * env, int argc, const ERL_NIF_TERM argv[]) {
  skepu::Vector<double> *x, *y; 
#ifdef TIME
  struct timespec t0,t1,t2,t3;
  clock_getres(CLOCK_THREAD_CPUTIME_ID, &t0);
  cout << "time resolution is " << t0.tv_nsec << " nsecs" << endl;
  clock_gettime(CLOCK_THREAD_CPUTIME_ID, &t0);
#endif
  ERL_NIF_TERM list = argv[0], res;
  if(enif_is_list(env, list)) {
    // convert the list to an array 
    unsigned int len = 0; 
    enif_get_list_length(env, list, &len); 
    // convert the input list to a skepu vector
    x = list_to_vector(env,list); 
    // create the skepu vector to host the results
    y = new skepu::Vector<double>[(*x).size()]; 
    // now compute the map 
#ifdef TIME
    clock_gettime(CLOCK_THREAD_CPUTIME_ID, &t1);
#endif
    skepu::Map<MAP_UNARY_FUNC_NAME> skepu_mapper(new MAP_UNARY_FUNC_NAME);
    skepu_mapper(*x,*y);
#ifdef TIME
    clock_gettime(CLOCK_THREAD_CPUTIME_ID, &t2);
#endif
    // move back results to Erlang
    res = vector_to_list(env, *y);
  } else { 
    cerr << "ERRROR :: map1f: unknown parameter type" << endl ; 
  } 
#ifdef TIME
  clock_gettime(CLOCK_THREAD_CPUTIME_ID, &t3);
  long el, elm; 
  elm = (t2.tv_sec - t1.tv_sec)*1000000L + (t2.tv_nsec - t1.tv_nsec) / 1000; 
  el  = (t3.tv_sec - t0.tv_sec)*1000000L + (t3.tv_nsec - t0.tv_nsec) / 1000 - elm; 
  cout << "spent total " << el << " usecs for marshalling and unmarshalling and " << 
    elm << " usecs in the map " << endl;
#endif
  return res; 
}
*************************************************************/


//
//
//  auxiliary functions to marshal/unmarshal Erlang data
//
//
ERL_NIF_TERM vector_to_list(ErlNifEnv *env, skepu::Vector<double> x) {
  int len = x.size();
  ERL_NIF_TERM * y = new ERL_NIF_TERM[len]; 
  for(int i=0; i<len; i++) {
    y[i] = enif_make_double(env, x[i]); 
    cout << x[i] << " ";
  }
  ERL_NIF_TERM res = enif_make_list_from_array(env, y, len);
  return res; 
}

skepu::Vector<double> *list_to_vector(ErlNifEnv *env, ERL_NIF_TERM list) {
  skepu::Vector<double> *x; 
  if(enif_is_list(env, list)) {
    unsigned int len = 0;
    enif_get_list_length(env, list, &len);
    x = new skepu::Vector<double>(len); 
    // cout << "Created vector of lenght " << len << endl; 
    for(int i=0; i<len; i++) {
      double temp; 
      ERL_NIF_TERM hd, tl;
      enif_get_list_cell(env, list, &hd, &tl);
      if(!(enif_get_double(env,hd,&((*x)[i])))) {
	cerr << "attempt to read float from something else!" << endl; 
      }
      // cout << " >> " << (*x)[i] << " " << endl;
      list = tl;
    }
  } else {
    cerr << "Error: trying to convert a non list as a list\n\r"; 
  }
  return(x);
}

/*

  NIF interface bindings 

*/
static ErlNifFunc nif_funcs[] = {
#include "NIF_bindings.h"
  {"skeletonlib", 1,  skeletonlib}
};

ERL_NIF_INIT(mapper,nif_funcs,NULL,NULL,NULL,NULL)

 
