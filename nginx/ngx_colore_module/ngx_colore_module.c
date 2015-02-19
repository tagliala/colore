#ifndef _H_NGX_COLORE
#define _H_NGX_COLORE

#include <ndk.h>
#include <ngx_md5.h>

static ngx_int_t ngx_colore_set_subdirectory(ngx_http_request_t *r, ngx_str_t *res, ngx_http_variable_value_t *v);

static ndk_set_var_t  ngx_colore_set_subdirectory_filter = {
    NDK_SET_VAR_MULTI_VALUE,
    (void*) ngx_colore_set_subdirectory,
    2,
    NULL
};

static ngx_command_t ngx_colore_commands[] = {

	{ ngx_string("set_colore_subdir"),
	  NGX_HTTP_MAIN_CONF|NGX_HTTP_SRV_CONF|NGX_HTTP_SIF_CONF|NGX_HTTP_LOC_CONF|NGX_HTTP_LIF_CONF|NGX_CONF_TAKE3,
	  ndk_set_var_multi_value,
	  0,
	  0,
	  &ngx_colore_set_subdirectory_filter },

	ngx_null_command
};

ngx_http_module_t ngx_colore_module_ctx = { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL };

ngx_module_t ngx_colore_module = {
	NGX_MODULE_V1,
	&ngx_colore_module_ctx,             /* module context */
	ngx_colore_commands,                /* module directives */
	NGX_HTTP_MODULE,                    /* module type */
	NULL,                               /* init master */
	NULL,                               /* init module  */
	NULL,                               /* init process */
	NULL,                               /* init thread */
	NULL,                               /* exit thread */
	NULL,                               /* exit process */
	NULL,                               /* exit master */
	NGX_MODULE_V1_PADDING
};

#ifndef MD5_DIGEST_LENGTH
#define MD5_DIGEST_LENGTH 16
#endif

#define COLORE_MD5_HEX_LENGTH (MD5_DIGEST_LENGTH * 2)

/*
 * Constructs a Colore subdirectory. Takes an input string, constructs a MD5 hash, then takes the first N
 * characters and sets it in the result.
 *
 * Usage:   set_colore_subdir {target} {source} {num-chars}
 *
 * For example:
 *   set_colore_subdir $target $source 2
 */
static ngx_int_t ngx_colore_set_subdirectory
(ngx_http_request_t *r, ngx_str_t *res, ngx_http_variable_value_t *v) {

	ngx_http_variable_value_t *p_length;
	ngx_int_t                  length = 0;
	u_char                     p[COLORE_MD5_HEX_LENGTH+1] = {0};
    u_char                     *subdir;
    ngx_md5_t                  md5;
    u_char                     md5_buf[MD5_DIGEST_LENGTH];

	/* get length */

	p_length = v + 1;
	length = ngx_atoi(p_length->data, p_length->len);
	if( length <= 0 || length > COLORE_MD5_HEX_LENGTH) {
       	ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "set_colore_subdir: bad \"length\" argument: %v", p_length );
       	return NGX_ERROR;
	}

	/* construct MD5 */

    ngx_md5_init(&md5);
    ngx_md5_update(&md5, v->data, v->len);
    ngx_md5_final(md5_buf, &md5);

    ngx_hex_dump(p, md5_buf, sizeof(md5_buf));

	/* take substring */

	ndk_palloc_re(subdir, r->pool, length);
	ngx_memcpy(subdir, p, length);

	/* return */

    res->data = subdir;
    res->len = length;
	return NGX_OK;
}

#endif // _H_NGX_COLORE
