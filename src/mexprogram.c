/*--------------------------------------------------------------------
 *	$Id$
 *
 *	Copyright (c) 1991-$year by P. Wessel, W. H. F. Smith, R. Scharroo, J. Luis and F. Wobbe
 *	See LICENSE.TXT file for copying and redistribution conditions.
 *
 *	This program is free software; you can redistribute it and/or modify
 *	it under the terms of the GNU Lesser General Public License as published by
 *	the Free Software Foundation; version 3 or any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU Lesser General Public License for more details.
 *
 *	Contact info: gmt.soest.hawaii.edu
 *--------------------------------------------------------------------*/
/*
 * The template for all GMT5 mex programs that call their GMT module.
 * The Makefile will replace FUNC with the module name.
 * We also need to feed in the correct KEY and N_KEYS settings, somehow.
 * Version:	5
 * Created:	10-Jul-2011
 *
 */

#include "gmt_mex.h"

int FUNC (struct GMTAPI_CTRL *API, struct GMT_OPTION *options);

void mexFunction (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
	int status = 0;				/* Status code from GMT API */
	struct GMTAPI_CTRL *API = NULL;		/* GMT API control structure */
	struct GMT_OPTION *options = NULL;	/* Linked list of options */
	char *cmd = NULL;
	char *keys = KEY;

	cmd = mxArrayToString (prhs[0]);	/* First argument is the command string, e.g., '$ -R0/5/0/5 -I1' */

	/* 1. Initializing new GMT session */
	if ((API = GMT_Create_Session ("GMT/MEX-API", 2U, 0U)) == NULL) mexErrMsgTxt ("Failure to create GMT Session\n");

	/* 2. Convert command line arguments to local linked option list */
	if (GMT_Create_Options (API, 0, cmd, &options)) mexErrMsgTxt ("Failure to parse GMT command options\n");
	free (cmd);

	/* 3. Parse the mex command, update GMT option lists, register in/out resources */
	if (GMTMEX_parser (API, plhs, nlhs, prhs, nrhs, keys, options)) mexErrMsgTxt ("Failure to parse mex command options\n");
	
	/* 3. Run GMT cmd function, or give usage message if errors arise during parsing */
	status = FUNC (API, -1, options);

	/* 4. Destroy local linked option list */
	if (GMT_Destroy_Options (API, &options)) mexErrMsgTxt ("Failure to destroy GMT options\n");

	/* 5. Destroy GMT session */
	if (GMT_Destroy_Session (API)) mexErrMsgTxt ("Failure to destroy GMT session\n");

	exit (status);		/* Return the status from mex FUNC */
}