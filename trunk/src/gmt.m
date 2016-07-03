function varargout = gmt(cmd, varargin)
% Helper function to call the gmtmex MEX function

%	$Id$

	if (nargin == 0)
		fprintf(sprintf('Usage: to call a GMT program\n\tgmt(''module_name options'', numeric_opts)\n\n'))
		fprintf(sprintf(['       To create a Grid struct from a 2d Z array and a 1x9 header vector\n\t' ...
		                 'G = gmt(''_fill_grid_struct'', Z, head)\n\n']))
		fprintf(sprintf(['       To create an Image struct from a 2d img array and a 1x9 header vector\n\t' ...
		                 'I = gmt(''_fill_img_struct'', img, head [,cmap])\n' ...
						 '       Here, and above, HEAD is a vector with [x_min x_max, y_min y_max z_min z_max reg x_inc y_inc]\n' ...
						 '       and CMAP is a color palette structure or a Matlab Mx3 cmap array (not yet).\n\n']))
		fprintf(sprintf(['       To join two color palette structures\n\t' ...
		                 'cpt = gmt(''_cptjoin'', cpt1, cpt2)\n']))
		fprintf(sprintf(['       To merge all segments across an array of structures\n\t' ...
		                 'all = gmt(''_merge'', segments)\n']))
		return
	end

	if (cmd(1) == '_')
		[varargout{1:nargout}] = feval(cmd(2:end), varargin{:});
	else
		[varargout{1:nargout}] = gmtmex(cmd, varargin{:});
	end

% -------------------------------------------------------------------------------------------------
function all = merge (A, ~)
% MERGE  Combine all segment arrays to a single array
%   all = merge (A, opt)
%
% Concatenate all data segment arrays in the structures A
% into a single array.  If the optional argument opt is given
% the we start each segment with a NaN record.

n_segments = length(A); n = 0;
	[~, nc] = size (A(1).data);
	for k = 1:n_segments
	    n = n + length(A(k).data);
	end
	if nargin == 2
	    all = zeros (n+n_segments, nc);
	else
	    all = zeros (n, nc);
	end
	n = 1;
	for k = 1:n_segments
	    [nr, ~] = size (A(k).data);
	    if nargin == 2 % Add NaN-record
	        all(n,:) = NaN;
	        n = n + 1;
	    end
	    all(n:(n+nr-1),:) = A(k).data;
	    n = n + nr;
	end

% -------------------------------------------------------------------------------------------------
function cpt = cptjoin(cpt1, cpt2)
% Join two CPT1 and CPT2 color palette structures. 
% Note, the two palettes should be continuous across its common border. No testing on that is donne here

	if (nargin ~= 2)
		error('    Must provide 2 input arguments.')
	elseif (cpt1.depth ~= cpt2.depth)
		error('    Cannot join two palletes that have different bit depths.')
	end
	if (size(cpt1.colormap,1) ~= size(cpt1.range))
		% A continuous palette so the join would have one color in excess. We could average
		% the top cpt1 color and bottom cpt2 but that would blur the transition. 
		%cpt.colormap = [cpt1.colormap(1:end-1,:); (cpt1.colormap(end,:)+cpt2.colormap(1,:))/2; cpt2.colormap(2:end,:)];
		cpt.colormap = [cpt1.colormap(1:end-1,:); cpt2.colormap];
		cpt.alpha    = [cpt1.alpha(1:end-1,:);    cpt2.alpha];
	else
		cpt.colormap = [cpt1.colormap; cpt2.colormap];
		cpt.alpha    = [cpt1.alpha;    cpt2.alpha];
	end
	cpt.range  = [cpt1.range;    cpt2.range];
	cpt.minmax = [cpt1.minmax(1) cpt2.minmax(2)];
	cpt.bfn    = cpt1.bfn;			% Just keep the first one
	cpt.depth  = cpt1.depth;

% -------------------------------------------------------------------------------------------------
function G = fill_grid_struct(Z, head)
% Fill the Grid struct used in gmtmex. HEAD is the old 1x9 header vector.

	if (nargin ~= 2)
		error('    Must provide 2 input arguments.')
	elseif (size(Z,1) < 2 || size(Z,2) < 2)
		error('    First argin must be a decent 2D array.')
	elseif (any(size(head) ~= [1 9]))
		error('    Second argin must be a 1x9 header vector.')
	end

	if (~isa(head, 'double')),	head = double(head);	end
	G.projection_ref_proj4 = '';
	G.projection_ref_wkt = '';	
	G.range = head(1:6);
	G.inc = head(8:9);
	G.registration = head(7);
	G.no_data_value = NaN;
	G.title = '';
	G.remark = '';
	G.command = '';
	G.datatype = 'float32';
	G.x = linspace(head(1), head(2), size(Z,2));
	G.y = linspace(head(3), head(4), size(Z,1));
	G.z = Z;
	G.x_unit = '';
	G.y_unit = '';
	G.z_unit = '';	

% -------------------------------------------------------------------------------------------------
function I = fill_img_struct(img, head, cmap)
% Fill the Image struct used in gmtmex. HEAD is the old 1x9 header vector.

	if (nargin < 2)
		error('    Must provide at least 2 input arguments.')
	end
	if (size(img,1) < 2 || size(img,2) < 2)
		error('    First argin must be a decent 2D image array.')
	elseif (any(size(head) ~= [1 9]))
		error('    Second argin must be a 1x9 header vector.')
	end

	if (~isa(head, 'double')),	head = double(head);	end
	I.projection_ref_proj4 = '';
	I.projection_ref_wkt = '';	
	I.range = head(1:6);
	I.inc = head(8:9);
	I.no_data_value = NaN;
	I.registration = head(7);
	I.title = '';
	I.remark = '';
	I.command = '';
	I.datatype = 'uint8';
	I.x = linspace(head(1), head(2), size(img,2));
	I.y = linspace(head(3), head(4), size(img,1));
	I.image = img;
	I.x_unit = '';
	I.y_unit = '';
	I.z_unit = '';	
	if (nargin == 3)
		if (~isa(cmap, 'struct'))
			% TODO: write a function that converts from Mx3 Matlab cmap to color struct used in MEX
			error('The third argin (cmap) must be a colormap struct.')
		end
		I.colormap = cmap;	
	else
		I.colormap = [];	
	end
	if (size(img,3) == 4)			% Not obvious that this is the best choice
		I.alpha = img(:,:,4);
		I.n_bands = 3;
	else
		I.alpha = [];	
	end
