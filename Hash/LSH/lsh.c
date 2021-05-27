/*
 * Copyright (c) 2016 NSR (National Security Research Institute)
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy 
 * of this software and associated documentation files (the "Software"), to deal 
 * in the Software without restriction, including without limitation the rights 
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
 * copies of the Software, and to permit persons to whom the Software is 
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in 
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
 * THE SOFTWARE.
 */

/* SRV 05/26/2021 - headers are in the same directory for Hash */
/* #include "../include/lsh.h" */
#include "lsh.h"
#include "lsh256.h"
#include "lsh512.h"

lsh_err lsh_init(union LSH_Context * state, const lsh_type algtype){
	if (state == NULL){
		return LSH_ERR_NULL_PTR;
	}

	if (LSH_IS_LSH256(algtype)){
		return lsh256_init(&state->ctx256, algtype);
	}
	else if (LSH_IS_LSH512(algtype)){
		return lsh512_init(&state->ctx512, algtype);
	}
	else{
		return LSH_ERR_INVALID_ALGTYPE;
	}
}
lsh_err lsh_update(union LSH_Context * state, const lsh_u8 * data, size_t databitlen){
	if (state == NULL){
		return LSH_ERR_NULL_PTR;
	}
	
	if (LSH_IS_LSH256(state->algtype)){
		return lsh256_update(&state->ctx256, data, databitlen);
	}
	else{
		return lsh512_update(&state->ctx512, data, databitlen);
	}
}
lsh_err lsh_final(union LSH_Context * state, lsh_u8 * hashval){
	if (state == NULL){
		return LSH_ERR_NULL_PTR;
	}

	if (LSH_IS_LSH256(state->algtype)){
		return lsh256_final(&state->ctx256, hashval);
	}
	else{
		return lsh512_final(&state->ctx512, hashval);
	}

}

lsh_err lsh_digest(const lsh_type algtype, const lsh_u8 * data, size_t databitlen, lsh_u8 * hashval){
	if (LSH_IS_LSH256(algtype)){
		return lsh256_digest(algtype, data, databitlen, hashval);
	}
	else if(LSH_IS_LSH512(algtype)){
		return lsh512_digest(algtype, data, databitlen, hashval);
	}
	else{
		return LSH_ERR_INVALID_ALGTYPE;
	}
}
